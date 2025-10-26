package LedgerSMB::Routes::ERP::API::Invoices;

=head1 NAME

LedgerSMB::Routes::ERP::API::Invoices - Webservice routes for invoices

=head1 DESCRIPTION

Webservice routes for invoices

=head2 Treatment of totals

The invoice schema describes multiple fields which can be calculated from
details elsewhere in the invoice, such as C<lines_total>, C<taxes_total>
and C<total>.  When these fields are submitted on invoice creation or
modification, their presence is ignored: their value will be recalculated
from the elements in the invoice.  The next request for the invoice shows
the recalculated totals.


=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Invoices;

=head1 METHODS

This module doesn't export any methods.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_CREATED HTTP_FOUND
    HTTP_NOT_FOUND HTTP_BAD_REQUEST HTTP_UNSUPPORTED_MEDIA_TYPE
    HTTP_NOT_IMPLEMENTED );
use JSONSchema::Validator;
use List::Util qw( reduce sum0 uniq );
use Plack::Request::WithEncoding;
use Scalar::Util qw( blessed reftype );
use Workflow::Context;
use YAML::PP;

use LedgerSMB::App_State;
use LedgerSMB::Company;
use LedgerSMB::Entity::Credit_Account;
use LedgerSMB::Magic qw( EC_CUSTOMER EC_VENDOR );
use LedgerSMB::PGNumber;
use LedgerSMB::Part;
use LedgerSMB::Setting;

use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.invoices';

sub _create_validator {
    my $reader = YAML::PP->new(boolean => 'JSON::PP');
    my $schema = $reader->load_string(
        do {
            # slurp __DATA__ section
            local $/ = undef;
            <DATA>;
        });
    return JSONSchema::Validator->new(
        schema => $schema,
        specification => 'OAS30');
}

my $validator = _create_validator();


sub _not_implemented {
    return [ HTTP_NOT_IMPLEMENTED, [], [] ];
}

sub _get_invoices_by_id {
    my ($env, $r, $c, $body, $params) = @_;
    my %inv = ( id => $params->{id} );

    return error( $r, HTTP_BAD_REQUEST, [],
                  [ q|'id' parameter missing| ])
        if defined $params->{id} and $params->{id} eq '';

    my $query = q|
        SELECT 'customer' as type,
              invnumber, ordnumber, quonumber, ponumber, transdate, duedate, crdate,
              approved, on_hold, reverse, is_return, force_closed,
              entity_credit_account, person_id,
              language_code, description, notes, intnotes, shippingpoint, shipvia,
              amount_bc, netamount_bc, curr, amount_tc, netamount_tc
          FROM ar
        WHERE invoice AND id = ?

        UNION ALL
        SELECT 'vendor' as type,
              invnumber, ordnumber, quonumber, ponumber, transdate, duedate, crdate,
              approved, on_hold, reverse, is_return, force_closed,
              entity_credit_account, person_id,
              language_code, description, notes, intnotes, shippingpoint, shipvia,
              amount_bc, netamount_bc, curr, amount_tc, netamount_tc
          FROM ap
        WHERE invoice and id = ?
        |;
    my $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $params->{id}, $params->{id} )
        or die $sth->errstr;

    my $ref = $sth->fetchrow_hashref( 'NAME_lc' );
    die $sth->errstr if not $ref and $sth->err;

    return [ HTTP_NOT_FOUND,
             [ ],
             [ ] ]
        unless $ref;


    my %map = ('duedate'    => 'due',
               'transdate'  => 'book',
               'crdate'     => 'created');
    for my $d (qw( transdate duedate crdate )) {
        $inv{dates}->{$map{$d}} = $ref->{$d};
    }
    %map = qw(
       inv invoice-
       ord order-
       quo quote-
       po  po-
        );
    for my $key (keys %map) {
        $inv{$map{$key}.'number'} = $ref->{$key.'number'} // '';
    }
    %map = qw(
        type          type
        curr          currency
        description   description
        notes         notes
        intnotes      internal-notes
        shippingpoint shipping-point
        shipvia       ship-via
        );
    @inv{(values %map)} = $ref->@{(keys %map)};

    $query = q|
        SELECT *
          FROM invoice i
          JOIN acc_trans a ON i.id = a.invoice_id
         WHERE i.trans_id = $1
        ORDER BY id
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $params->{id} )
        or die $sth->errstr;

    $inv{lines} = [];
    my $item = 1;
    while (my $line = $sth->fetchrow_hashref( 'NAME_lc' )) {
        $line->{item} = $item;
        delete $line->@{qw(allocated assemblyitem trans_id)};
        $line->{price}         = delete $line->{sellprice};
        $line->{delivery_date} = delete $line->{deliverydate};
        $line->{price_fixated} = (delete $line->{priceFixated}) ? \1 : \0;
        $line->{total} = $line->{amount_tc};
        $line->{discount_type} = defined $line->{discount} ? '%' : '';
        $line->{discount} *= 100 if defined $line->{discount};

        # Why?
        $line->{qty} += 0; # Force string to number conversion
        $line->{price} += 0; # Force string to number conversion

        my $part = LedgerSMB::Part->new(
            _dbh => $env->{'lsmb.db'}
            );
        $part = $part->get_by_id($line->{parts_id});
        $line->{part} = {
            number => $part->{partnumber},
            $part->%{qw( unit weight onhand description )}
        };
        delete $line->{parts_id};

        push $inv{lines}->@*, {
            $line->%{qw/id item price delivery_date total discount_type
                         part description unit price_fixated qty discount
                         notes serialnumber/}
        };
        $item++;
    }
    die $sth->errstr if $sth->err;


    $query = q|
        SELECT *
          FROM tax_extended te
          JOIN acc_trans ac ON ac.entry_id = te.entry_id
          JOIN account a ON a.id = ac.chart_id
         WHERE exists (select 1 from acc_trans ac
                        where te.entry_id = ac.entry_id
                              and ac.trans_id = $1)
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $params->{id} )
        or die $sth->errstr;

    $inv{taxes} = {};
    while (my $tax = $sth->fetchrow_hashref( 'NAME_lc' )) {
        $inv{taxes}->{$tax->{accno}} = {
            tax => {
                category => $tax->{accno},
                name     => $tax->{description},
                rate     => $tax->{rate},
            },
            'base-amount' => $tax->{tax_basis},
            'calculated-amount' => ($tax->{tax_basis} * $tax->{rate}),
            amount => $tax->{amount_tc},
            source => $tax->{source},
            memo   => $tax->{memo},
        };
    }
    die $sth->errstr if $sth->err;


    $query = q|
        SELECT *
          FROM account a
          JOIN account_link al ON a.id = al.account_id
         WHERE al.description = $2
               AND exists (select 1 from acc_trans ac
                            where a.id = ac.chart_id
                                  and ac.trans_id = $1)
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $params->{id}, ($inv{type} eq 'customer' ? 'AR':'AP') )
        or die $sth->errstr;

    my $account = $sth->fetchrow_hashref( 'NAME_lc' );
    die $sth->errstr if not $account and $sth->err;
    $inv{account} = { $account->%{qw(accno description)} };


    ###TODO: query payments here...
    ###TODO: query credit_account and entity here
    $query = q|
        SELECT *
          FROM entity_credit_account eca
         WHERE eca.id = ?
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $ref->{entity_credit_account} )
        or die $sth->errstr;

    my $eca = $sth->fetchrow_hashref( 'NAME_lc' );
    die $sth->errstr if not $eca and $sth->err;

    $query = q|
        SELECT *
          FROM entity
         WHERE entity.id = ?
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $eca->{entity_id} )
        or die $sth->errstr;

    my $entity = $sth->fetchrow_hashref( 'NAME_lc' );
    die $sth->errstr if not $entity and $sth->err;

    $query = q|
        SELECT *
          FROM credit_limit__used(?)
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $eca->{id} )
        or die $sth->errstr;

    my $credit_limit_used = $sth->fetchrow_arrayref();
    die $sth->errstr if not $credit_limit_used and $sth->err;


    $inv{eca} = {
        id     => $eca->{id},
        number => $eca->{meta_number},
        type   => ($eca->{entity_class} == EC_CUSTOMER) ? 'customer' : 'vendor',
        description => $eca->{description},
        pay_to_name => $eca->{pay_to_name},
        credit_limit => {
            used => $credit_limit_used->[0] // 0,
            total => $eca->{creditlimit} // 0,
            available => (($eca->{creditlimit} // 0) - ($credit_limit_used->[0] // 0)),
        },
        entity => {
            $entity->%{qw/name control_code/}
        }
    };

    ###TODO: query shipping in `new_shipto` table

    $inv{lines_total} = reduce { $a + $b->{total} } 0, $inv{lines}->@*;
    $inv{taxes_total} = reduce { $a + $b->{amount} } 0, values $inv{taxes}->%*;
    ###TODO
    # $inv{payments_total} = reduce { $a + $b->{amount} } 0, $inv{payments}->@*;
    $inv{total}       = $inv{lines_total} + $inv{taxes_total};
    ###TODO
    # $inv{due}         = $inv{total} - $inv{payments_total};

    $query =
        q|
        SELECT * FROM transactions WHERE id = ?
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $inv{id} )
        or die $sth->errstr;

    my $trans = $sth->fetchrow_hashref( 'NAME_lc' );
    die $sth->errstr if not $trans and $sth->err;

    local $LedgerSMB::App_State::DBH = $env->{'lsmb.db'};
    my $wf = $env->{wire}->get('workflows')
        ->fetch_workflow( 'AR/AP', $trans->{workflow_id} );

    $inv{workflow} = {
        state => $wf->state,
        actions => [ sort $wf->get_current_actions ]
    };

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json' ],
             \%inv ];
}

sub _post_invoices {
    my ($env, $r, $c, $body, $params) = @_;
    my @errors;
    my $inv = {};
    # lookup the required fields: eca
    {
        my %map = ( 'customer' => EC_CUSTOMER(),
                    'vendor' => EC_VENDOR());
        my $eca = LedgerSMB::Entity::Credit_Account->new(
            _dbh => $env->{'lsmb.db'},
            entity_class => $map{$body->{eca}->{type}},
            );
        if (exists $body->{eca}->{id}) {
            $inv->{eca} = $eca->get_by_id($body->{eca}->{id});
        }
        else {
            $inv->{eca} = $eca->get_by_meta_number(
                $body->{eca}->{number},
                $map{$body->{eca}->{type}},
                );
        }
        unless ($inv->{eca}->{id}) {
            push @errors, {
                msg => q|Specified customer/vendor not found|,
            };
        }
    }

    {
        my $query = q|select 1 from currency where curr = ?|;
        my $sth = $env->{'lsmb.db'}->prepare($query)
            or die $env->{'lsmb.db'}->errstr;

        $sth->execute( $body->{currency} )
            or die $sth->errstr;

        my $ref = $sth->fetchrow_arrayref;
        die $sth->errstr if not $ref and $sth->err;

        if (not $ref) {
            push @errors, {
                msg => qq|Currency "$body->{currency}" not configured|
            };
        }

        $inv->{curr} = $body->{currency};
    }

    # look up the AR/AP account by accno
    {
        my $account = $c->configuration->coa_nodes
            ->get(by => (accno => $body->{account}->{accno}));
        if (blessed $account) {
            $inv->{account} = $account;
        }
        else {
            push @errors, {
                msg => qq|Specified account ($body->{account}->{accno}) not found|,
            };
        }
    }

    # set the optional fields
    my %optmap = (
        currency => 'currency',
        description => 'description',
        notes => 'notes',
        'internal-notes' => 'intnotes',
        'invoice-number' => 'invnumber',
        'order-number' => 'ordnumber',
        'po-number' => 'ponumber',
        'ship-via' => 'shipvia',
        'shipping-point' => 'shippingpoint',
        );
    foreach my $field (qw( currency description notes internal-notes
                       invoice-number order-number po-number ship-via
                       shipping-point )) {
        if (exists $body->{$field}
            and defined $body->{$field}
            and $body->{$field} ne '') {
            $inv->{$optmap{$field}} = $body->{$field};
        }
    }

    # process optional nested fields
    if (exists $body->{'ship-to'}) {
        ...;
    }

    {
        my %map = ('due'     => 'duedate',
                   'book'    => 'transdate',
                   'created' => 'crdate');
        foreach my $d (qw( due book created )) {
            # due|created|book
            next if not $body->{dates}->{$d};
            $inv->{$map{$d}} = $body->{dates}->{$d};
        }
    }

    {
        $inv->{lines} = [];
        for my $line ($body->{lines}->@*) {
            $line->{deliverydate} = delete $line->{delivery_date};
            # set the optional fields
            my $inv_line = {};
            push $inv->{lines}->@*, $inv_line;

            foreach my $field (qw( description price price_fixated unit qty
                               discount discount_type taxform deliverydate note
                               serialnumber group )) {
                if (exists $line->{$field}
                    and defined $line->{$field}
                    and $line->{$field} ne '') {
                    $inv_line->{$field} = $line->{$field};
                }
            }

            $inv_line->{qty}   = $inv_line->{qty} // 1;
            $inv_line->{discount} = $inv_line->{discount} / 100
                if $inv_line->{discount_type} eq '%';

            # determine price and description
            {
                my $part = LedgerSMB::Part->new(
                    _dbh => $env->{'lsmb.db'}
                    );
                $inv_line->{part} = $part->get_by_partnumber(
                    $line->{part}->{number}
                    );
                unless ($inv_line->{part}->{id}) {
                    push @errors, {
                        msg => q|Specified part not found|,
                        val => $line->{part}->{number},
                    };
                }
                # "lastcost" is the price to put on
                # a vendor invoice, whereas "sellprice" goes
                # into the sales invoice....
                # Map either into the 'price' field, so we
                # can have unified handling from here.
                if ($inv->{eca}->entity_class == EC_CUSTOMER()) {
                    $inv_line->{part}->{price} =
                        delete $inv_line->{part}->{sellprice};
                }
                else {
                    $inv_line->{part}->{price} =
                        delete $inv_line->{part}->{lastcost};
                }

                $inv_line->{$_} //=
                    $inv_line->{part}->{$_} for (qw( price description ));
            }
        }
    }

    if (exists $body->{payments}) {
        $inv->{payments} = [];
        foreach my $payment ($body->{payments}->@*) {
            my $inv_payment = {};
            push $inv->{payments}->@*, $inv_payment;

            foreach my $field (qw( date source memo amount )) {
                if (exists $payment->{$field}
                    and defined $payment->{$field}
                    and $payment->{$field} ne '') {
                    $inv_payment->{$field} = $payment->{$field};
                }
            }

            if ($payment->{account}->{accno} ne '') {
                ###TODO: Payment account lookup
                my $account = $c->configuration->coa_nodes
                    ->get(by => (accno => $payment->{account}->{accno}));
                $inv_payment->{account} = $account;
                unless (blessed $account) {
                    push @errors, {
                        msg => 'Payment account not found',
                        val => $payment->{account}->{accno},
                    };
                }
            }
        }
    }

    if (exists $body->{taxes}) {
        my %taxes;
        $inv->{taxes} = \%taxes;
        foreach my $tax (values $body->{taxes}->%*) {
            if (exists $taxes{$tax->{tax}->{category}}) {
                push @errors, {
                    msg => q|Expecting each tax category to be specified exactly once; second or later occurrance found|,                                                           val => $tax,
                };
                next;
            }

            my $inv_tax = {};
            $taxes{$tax->{tax}->{category}} = $inv_tax;

            foreach my $field (qw(base-amount amount source memo)) {
                if (exists $tax->{$field}
                    and defined $tax->{$field}
                    and $tax->{$field} ne '') {
                    $inv_tax->{$field} = $tax->{$field};
                }
            }

            # Note: a tax needs to be enabled for the
            # customer/vendor!
            #
            my $sth = $env->{'lsmb.db'}->prepare(
                q|
                    SELECT a.accno as category, a.description, t.rate, a.id, t.chart_id
                      FROM account a JOIN tax t ON t.chart_id = a.id
                      WHERE a.accno = ?
                      AND coalesce(validto::timestamp, 'infinity')
                              >= coalesce(?::timestamp, now())
                    ORDER BY validto ASC
                    LIMIT 1
                |
                )
                or die $env->{'lsmb.db'}->errstr;
            $sth->execute($tax->{tax}->{category}, $inv->{transdate})
                or die $sth->errstr;
            $inv_tax->{tax} = $sth->fetchrow_hashref;
            die $sth->errstr
                if $sth->err;

            unless ($inv_tax->{tax}) {
                push @errors, {
                    msg => q|Tax category not found for given transaction date|,
                    val => {
                        tax       => $tax->{tax},
                        transdate => $inv->{transdate},
                    },
                };
                next;
            }

            $sth = $env->{'lsmb.db'}->prepare(
                q|
                    SELECT 1 FROM eca_tax et
                    JOIN entity_credit_account eca ON et.eca_id = eca.id
                    JOIN account a ON a.id = et.chart_id
                    WHERE accno = ?
                |
                )
                or die $env->{'lsmb.db'}->errstr;
            $sth->execute($tax->{tax}->{category})
                or die $sth->errstr;

            unless ($sth->rows) {
                push @errors, {
                    msg => q|Tax category not enabled for this customer/vendor|,
                    val => $tax->{tax},
                }
            }
        }
    }

    return error($r, HTTP_BAD_REQUEST, [], @errors)
        if scalar(@errors) > 0;

    #### So, we're now without errors, so lets start the required calculations

    #  1. Totalize the quantities on the rows per part
    #  2. Run the price matrix over the resulting parts counts
    #  3. Apply the resulting pricing on the lines by their parts
    #  4. Calculate the line totals based on price-matrix outcome
    #  5. Apply 'business type', 'price matrix' and 'line' discounts per line
    #  6. Determine the applicable tax types and rates per line
    #  7. Calculate the totals per tax rate over the lines
    #  8. Apply the tax rate to the rate total
    #  9. Calculate the totals of the lines and taxes

    # Step 1: Totalize the quantities on the rows per part into %part_qty
    my %part_qty = (
        map { my $id = $_;
              $id => (sum0 grep { not $_->{price_fixated}
                                  and $_->{part}->{id} eq $id }
                      $inv->{lines}->@*) }
        uniq map { $_->{part}->{id} } $inv->{lines}->@*
        );

    $inv->{transdate} //= $inv->{crdate};
    $inv->{crdate} //= $inv->{transdate};
    if (not $inv->{transdate}) {
        $env->{'psgix.logger'}->(
            {
                level => 'info',
                message => 'No transaction date supplied; setting default' });
        my ($now) = $env->{'lsmb.db'}->selectrow_array('SELECT NOW()::date')
            or die $env->{'lsmb.db'}->errstr;

        $inv->{crdate} =
            $inv->{transdate} =
            $now;
    }

    # Step 2: Run the price matrix
    if (keys %part_qty) {
        my $sth;

        if ($inv->{eca}->entity_class == EC_CUSTOMER()) {
            $sth = $env->{'lsmb.db'}->prepare(
                q|
                SELECT * FROM pricematrix__for_customer(?, ?, ?, ?, ?)
                |
                )
                or die $env->{'lsmb.db'}->errstr;
        }
        else { # vendor
            $sth = $env->{'lsmb.db'}->prepare(
                q|
                SELECT * FROM pricematrix__for_vendor(?, ?)
                |
                )
                or die $env->{'lsmb.db'}->errstr;
        }
        for my $part_id (keys %part_qty) {
            if ($inv->{eca}->entity_class == EC_CUSTOMER()) {
                $sth->execute($inv->{eca}->{id},
                              $part_id, $inv->{transdate},
                              $part_qty{$part_id},
                              $inv->{currency})
                    or die $sth->errstr;
            }
            else {
                $sth->execute($inv->{eca}->{id}, $part_id)
                    or die $sth->errstr;
            }

            my $ref = $sth->fetchrow_hashref('NAME_lc');
            die $sth->errstr
                if $sth->err;

            # Step 3: Apply the price matrix to the lines
            if ($ref) {
                # apply the price matrix to the rows in the invoice
                my $price_frac = ( 1 - ($ref->{pricebreak} // 0)/100 );
                my $eca_price = # customer // vendor
                    $ref->{sellprice} // $ref->{lastcost};

                for my $line (grep { not $_->{price_fixated}
                                     and $_->{part}->{id} eq $part_id }
                              $inv->{lines}->@*) {

                    ###TODO: Round price due to price matrix?
                    # Note: when we do, we need to round to the same number
                    # of digits as the precision in the database.
                    #
                    # $line->{part}->{price} is the part's default, not
                    # the value provided in the UI.
                    $line->{price} =
                        $price_frac * ($eca_price // $line->{part}->{price});
                }
            }
        }
    }

    # Step 4: Calculate the line totals
    for my $line ($inv->{lines}->@*) {
        ###TODO: Verify that 'sellprice' isn't actually ever occurring
        my $total = $line->{qty} * ($line->{price} // $line->{sellprice});

        # Step 5: Calculate discounts
        if ($line->{discount_type}) {
            $total *= (1 - $line->{discount});
        }
        # is a no-no due to its global state. We need access to the company
        # settings from the $env somehow
        $line->{total} =
            LedgerSMB::PGNumber->new($total)->bfround(
                -$env->{'lsmb.settings'}->{decimal_places}
            );
    }
    $inv->{lines_total} = reduce { $a + $b->{total} } 0, $inv->{lines}->@*;

    if (not exists $inv->{taxes}) {
        my $sth = $env->{'lsmb.db'}->prepare(
          q|
            WITH taxes AS (
              SELECT *,
                    LAG(validto) OVER (PARTITION BY tax.chart_id
                                        ORDER BY validto ASC NULLS LAST) as validfrom
                FROM tax
            )
            SELECT *
              FROM taxes
              JOIN account ON account.id = taxes.chart_id
              JOIN eca_tax et ON et.chart_id = account.id
              JOIN taxmodule tm ON taxes.taxmodule_id = tm.taxmodule_id
            WHERE et.eca_id = $1
                  AND (validfrom IS NULL OR $2 > validfrom)
                  AND (validto IS NULL OR $2 <= validto)
            |)
          or die $env->{'lsmb.db'}->errstr;
        $sth->execute($inv->{eca}->{id}, $inv->{transdate})
            or die $sth->errstr;
        while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
            $inv->{taxes}->{$ref->{accno}} = { tax => $ref };
        }
        die $sth->errstr
            if $sth->err;
        if (keys $inv->{taxes}->%* and keys %part_qty) {
            $sth = $env->{'lsmb.db'}->prepare(
                q|
                  SELECT *
                    FROM partstax pt
                    JOIN account a ON pt.chart_id = a.id
                  WHERE pt.parts_id = ?
                |)
                or die $env->{'lsmb.db'}->errstr;

            # intersect taxes applicable for the part with those
            # for the ECA
            my %part_tax = (
                map {
                    my $taxes = $_->{taxes};
                    $_->{part_id} =>
                    {
                        map {
                            $_ => $taxes->{$_}
                        }
                        grep { exists $taxes->{$_} }
                        keys $inv->{taxes}->%*
                    }
                }
                grep { $_->{taxes} }
                map {
                    my $part_id = $_;
                    $sth->execute($part_id)
                        or die $sth->errstr;

                    my $ref = $sth->fetchall_hashref('accno');
                    die $sth->errstr
                        if $sth->err;

                    { part_id => $part_id,
                      taxes => $ref }
                }
                keys %part_qty);

            # Apply the tax calculation
            for my $line ($inv->{lines}->@*) {
                next unless exists $part_tax{$line->{part}->{id}};

                my @taxes =
                    sort {
                        $a->{pass} <=> $b->{pass}
                } values $inv->{taxes}->%*;
                ###BUG: this creates built-in the "Tax::Simple" module;
                # it also does not support tax extraction
                # apparently, there was originally a reason to support more
                # complex Tax modules...
                ###BUG: this does not support minvalue and maxvalue taxes yet

                my $base = $line->{total};
                my $passtax = 0;
                my $pass = 0;

                for my $tax (@taxes) {
                    $env->{'psgix.logger'}->(
                        {
                            level => 'debug',
                            message => "Considering tax $tax->{tax}->{accnon} for part $line->{part}->{id}" });
                    next unless exists $part_tax{$line->{part}->{id}}->{$tax->{tax}->{accno}};
                    $env->{'psgix.logger'}->(
                        {
                            level => 'debug',
                            message => "processing tax for part ID $line->{part}->{id}" });
                    if ($pass != $tax->{tax}->{pass}) {
                        $base += $passtax;
                        $passtax = 0;
                        $pass = $tax->{tax}->{pass};
                    }

                    my $amount = $base*$tax->{tax}->{rate};
                    $line->{taxes}->{$tax->{tax}->{accno}} = {
                        'base-amount'   => $base,
                        rate   => $tax->{tax}->{rate},
                        amount => $amount,
                    };
                    $inv->{taxes}->{$tax->{tax}->{accno}}->{'base-amount'}   += $base;
                    $inv->{taxes}->{$tax->{tax}->{accno}}->{amount} += $amount;
                    $inv->{taxes}->{$tax->{tax}->{accno}}->{tax} = $tax->{tax};
                }
            }
        }
    }

    ###BUG: These amounts in don't have these names in the invoice resource!!!
    $inv->{taxes_total} =
        reduce { $a + $b->{amount} } LedgerSMB::PGNumber->new(0), values $inv->{taxes}->%*;
    $inv->{netamount} = $inv->{lines_total};
    $inv->{amount}    = $inv->{netamount} + $inv->{taxes_total};
    ###TODO: We need to apply the type-of-business-based discount here
    # (on the totals, that is) -- how to work that into the line-items??


    ###TODO: Add multi-currency support
    $inv->{amount_tc}    = $inv->{amount};
    $inv->{netamount_tc} = $inv->{netamount};

    ###BUG: Assert that the invoice is posted in functional currency

    if (not LedgerSMB::Setting->new(dbh => $env->{'lsmb.db'})->get('gapless_ar')
        and not $inv->{invnumber}) {
        # generate invoice number; if we have gapless, delay until posting

        ###BUG: This does not take "sequences" into account...
        my $sth = $env->{'lsmb.db'}->prepare(
            q/
            UPDATE defaults
               set "value" =
                 (select prefix || num || postfix from
                    (select p[1] as prefix,
                            lpad((p[2]::int+1)::text, length(p[2]), '0') as num,
                            p[3] as postfix from
                       (select regexp_matches("value",
                                              '^(.*?)(\d+)(\D*)$') as p)
                       as parts)
                    as upd)
             WHERE setting_key = 'sinumber'
            RETURNING (SELECT "value" FROM defaults WHERE setting_key = 'sinumber');
            /) or die $env->{'lsmb.db'}->errstr;

        $sth->execute()
            or die $sth->errstr;

        my ($invnumber) = $sth->fetchrow_array();
        die $sth->errstr if not $invnumber and $sth->err;
        $inv->{invnumber} = $invnumber;
    }
    my $sth = $env->{'lsmb.db'}->prepare(
        # What to do with 'setting_sequence' (for 'ar')?
        # and why does that not exist for 'ap'??
        q|
        INSERT INTO ar (invoice, approved,
            invnumber, ordnumber, quonumber, ponumber,
            amount_bc, netamount_bc, curr, amount_tc, netamount_tc, taxincluded,
            transdate, crdate, duedate,
            description, notes, intnotes,
            shippingpoint, shipvia,
            person_id, language_code,
            entity_credit_account
            )
        VALUES ('t'::boolean, 'f'::boolean,
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING id
        |)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute(
        $inv->@{
          qw/ invnumber ordnumber quonumber ponumber
              amount netamount curr amount_tc netamount_tc taxincluded
              transdate crdate duedate
              description notes intnotes
              shippingpoint shipvia
              person_id language_code
          / },
        $inv->{eca}->{id}
        )
        or die $sth->errstr;
    my ($inv_id) = $sth->fetchrow_array;
    die $sth->errstr
        if $sth->err;

    my $ctx = Workflow::Context->new;
    $ctx->param( trans_id => $inv_id );
    $ctx->param( transdate => $inv->{transdate} );
    local $LedgerSMB::App_State::DBH = $env->{'lsmb.db'};
    my $wf  = $env->{wire}->get('workflows')
        ->create_workflow( 'AR/AP', $ctx );
    $env->{'lsmb.db'}->do(q{UPDATE transactions SET workflow_id = ? where id = ?},
             {}, $wf->id, $inv_id)
        or die $env->{'lsmb.db'}->errstr;


    $sth = $env->{'lsmb.db'}->prepare(
        q|
        INSERT INTO invoice (trans_id, parts_id,
              description, qty, sellprice, precision, fxsellprice,
              discount, unit, deliverydate, serialnumber, vendor_sku, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING id
        |)
        or die $env->{'lsmb.db'}->errstr;
    my $asth = $env->{'lsmb.db'}->prepare(
        q|
        INSERT INTO acc_trans (approved, trans_id, invoice_id, chart_id,
              amount_bc, amount_tc, curr, transdate, source, memo )
          VALUES ('f'::boolean, ?, ?, ?,
                  ?, ?, ?, ?, ?, ?)
        RETURNING entry_id
        |)
        or die $env->{'lsmb.db'}->errstr;

    my $sign = ($inv->{eca}->entity_class == EC_CUSTOMER()) ? -1 : 1;
    ###BUG: check signs!!!
    $asth->execute($inv_id, undef, # no associated invoice line
                   ($inv->{account}->{id} =~ s/^A-//r),
                   $sign*$inv->{amount}, $sign*$inv->{amount},
                   (map { $inv->{$_} } qw/currency transdate/),
                   undef, undef,
        )
        or die $asth->errstr();
    for my $line ($inv->{lines}->@*) {
        ###TODO: This account determination only applies to services????
        my $account_id =
            (($inv->{eca}->entity_class == EC_CUSTOMER())
             ? $line->{part}->{income_accno_id}
             : $line->{part}->{expense_accno_id});

        # generate line in 'invoice' table
        ###TODO: extract the precision from the 'price'
        ###BUG: check signs!!!
        $sth->execute(
            $inv_id, $line->{part}->{id}, $line->{description}, $line->{qty},
            $line->{price}, 0, $line->{price}, ###TODO: single currency
            (defined $line->{discount} ? $line->{discount} : undef),
            (map { $line->{$_} }
             qw/unit deliverydate serialnumber vendor_sku notes/)
            )
            or die $sth->errstr;
        my ($invline_id) = $sth->fetchrow_array;
        die $sth->errstr
            if $sth->err;

        ###BUG: check signs!!!
        $asth->execute($inv_id, $invline_id, $account_id,
                       -$sign*$line->{total}, -$sign*$line->{total},
                       $inv->{currency}, $inv->{transdate}, undef, undef,
            )
            or die $asth->errstr;
    }

    $sth = $env->{'lsmb.db'}->prepare(
        q|
        INSERT INTO tax_extended (tax_basis, rate, entry_id)
        VALUES (?, ?, ?)
        |)
        or die $env->{'lsmb.db'}->errstr;
    for my $tax (values $inv->{taxes}->%*) {
        $asth->execute($inv_id, undef, $tax->{tax}->{chart_id},
                       -$sign*$tax->{amount}, -$sign*$tax->{amount},
                       $inv->{currency}, $inv->{transdate},
                       $tax->{source}, $tax->{memo})
            or die $asth->errstr;

        my ($entry_id) = $asth->fetchrow_array;
        die $asth->errstr
            if $asth->err;

        $sth->execute($tax->{'base-amount'}, $tax->{tax}->{rate}, $entry_id)
            or die $sth->errstr;
    }
    $wf->execute_action( 'post' ); # move to SAVED state

    return [
        HTTP_CREATED,
        [ 'Location' => "./$inv_id" ],  # We return this in a header?
        [  ] ];
}


get '/invoices' => \&_not_implemented;
post api '/invoices' => \&_post_invoices;

get api '/invoices/{id}' => \&_get_invoices_by_id;
del '/invoices/{id}' => \&_not_implemented;
patch '/invoices/{id}' => \&_not_implemented;



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2021 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;

__DATA__
openapi: 3.0.0
info:
  title: Management of Invoices
  version: 0.0.1
paths:
  /invoices:
    description: Management of Invoices
    get:
      tags:
        - Invoices
        - Experimental
      summary: Lists invoices
      operationId: getInvoices
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Invoice'
              examples:
                validInvoices:
                  $ref: '#/components/examples/validInvoices'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        default:
          description: ...
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/error'
    post:
      tags:
        - Invoices
        - Experimental
      summary: Add an invoice
      operationId: postInvoices
      requestBody:
        description: ...
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/newInvoice'
      responses:
        201:
          description: Created
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
            Location:
              schema:
                type: string
                format: uri-reference
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Invoice'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
  /invoices/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
          minLength: 1
    get:
      tags:
        - Invoices
        - Experimental
      summary: Get a single invoice
      operationId: getInvoicesById
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Invoice'
              examples:
                validInvoice:
                  $ref: '#/components/examples/validInvoice'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
    put:
      tags:
        - Invoices
        - Experimental
      summary: Update a single invoice
      operationId: putInvoiceById
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/newInvoice'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Invoice'
        304:
          description: ...
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
        412:
          $ref: '#/components/responses/412'
        413:
          $ref: '#/components/responses/413'
        428:
          $ref: '#/components/responses/428'
components:
  headers:
    ETag:
      description: ...
      required: true
      schema:
        type: string
  parameters:
    if-match:
      name: If-Match
      in: header
      description: ...
      required: true
      schema:
        type: string
  schemas:
    error:
      type: object
    newInvoice:
      type: object
      required:
        - eca
        - account
        - currency
        - dates
        - lines
      properties:
        eca:
          anyOf:
            - type: object
              required:
                - id
              properties:
                id:
                  type: integer
                  format: int64
                  minimum: 1
            - type: object
              required:
                - number
                - type
              properties:
                number:
                  type: string
                  minLength: 1
                type:
                  type: string
                  enum:
                    - customer
                    - vendor
        account:
          type: object
          properties:
            accno:
              type: string
              minLength: 1
        currency:
          type: string
          minLength: 3
          maxLength: 3
        description:
          type: string
          nullable: true
        notes:
          type: string
          nullable: true
        internal-notes:
          type: string
          nullable: true
        invoice-number:
          type: string
        order-number:
          type: string
        po-number:
          type: string
        ship-via:
          type: string
          nullable: true
        shipping-point:
          type: string
          nullable: true
        ship-to:
          type: object
        dates:
          type: object
          required:
            - book
          properties:
            due:
              type: string
              format: date
            book:
              type: string
              format: date
            created:
              type: string
              format: date
        lines:
          type: array
          items:
            type: object
            required:
              - part
            properties:
              description:
                type: string
              price:
                type: number
              price_fixated:
                type: boolean
                default: false
              unit:
                type: string
              qty:
                type: number
                default: 1
              taxform:
                type: boolean
                default: false
              serialnumber:
                type: string
                nullable: true
              discount:
                description: |
                  A value of 10 means the customer gets a 10% discount,
                  if discount_type has a value of '%'
                type: number
                minimum: 0
                maximum: 100
              discount_type:
                type: string
                enum:
                  - '%'
              delivery_date:
                type: string
                format: date
                nullable: true
              part:
                type: object
                required:
                  - number
                properties:
                  number:
                    type: string
                    minLength: 1
        taxes:
          type: object
          additionalProperties:
            type: object
            properties:
              tax:
                type: object
                required:
                  - category
                properties:
                  category:
                    type: string
              base-amount:
                type: number
              amount:
                type: number
              source:
                type: string
              memo:
                type: string
        payments:
          type: array
          items:
            type: object
            required:
              - account
              - amount
              - date
            properties:
              date:
                type: string
                format: date
              source:
                type: string
              memo:
                type: string
              amount:
                type: number
              account:
                type: object
                required:
                  - accno
                properties:
                  accno:
                    type: string
                    minLength: 1
    Invoice:
      description: ...
      allOf:
        # TODO: Fix inheritance. The definitions below replace the ones
        # TODO: defined in newInvoice, not complement them
        #- $ref: '#/components/schemas/newInvoice'
        - type: object
          properties:
            eca:
              type: object
              properties:
                credit_limit:
                  type: object
                  properties:
                    available:
                      type: number
                    total:
                      type: number
                    used:
                      type: number
                description:
                  type: string
                  nullable: true
                entity:
                  type: object
                  properties:
                    control_code:
                      type: string
                    name:
                      type: string
                id:
                  type: number
                number:
                  type: string
                  minLength: 1
                pay_to_name:
                  type: string
                  nullable: true
                type:
                  type: string
                  enum:
                    - customer
                    - vendor
            account:
              type: object
              properties:
                accno:
                  type: string
                  minLength: 1
                description:
                  type: string
                  minLength: 2
            description:
              type: string
              nullable: true
            lines:
              type: array
              items:
                type: object
                properties:
                  delivery_date:
                    type: string
                    format: date
                    nullable: true
                  description:
                    type: string
                  discount:
                    description: |
                      A value of 10 means the customer gets a 10% discount,
                      if discount_type has a value of '%'
                    type: number
                    minimum: 0
                    maximum: 100
                  discount_type:
                    type: string
                    enum:
                      - '%'
                  id:
                    type: number
                  item:
                    type: number
                  notes:
                    type: string
                    nullable: true
                  price:
                    type: number
                  price_fixated:
                    type: boolean
                    default: false
                  unit:
                    type: string
                  qty:
                    type: number
                    default: 1
                  serialnumber:
                    type: string
                    nullable: true
                  part:
                    type: object
                    required:
                      - number
                    properties:
                      _self:
                        type: string
                      number:
                        type: string
                        minLength: 1
                      description:
                        type: string
                      onhand:
                        type: string
                      unit:
                        type: string
                      weight:
                        type: string
                  total:
                    type: number
            payments:
              type: array
              items:
                type: object
                properties:
                  account:
                    type: object
                    properties:
                      description:
                        type: string
            taxes:
              type: object
              additionalProperties:
                type: object
                properties:
                  tax:
                    type: object
                    required:
                      - category
                    properties:
                      category:
                        type: string
                      rate:
                        type: string
                      name:
                        type: string
                  base-amount:
                    type: number
                  amount:
                    type: number
                  calculated-amount:
                    type: number
                  source:
                    type: string
                  memo:
                    type: string
            workflow:
              type: object
              properties:
                actions:
                  type: array
                state:
                  type: string
                  enum: [INITIAL, SAVED, POSTED, ONHOLD, VOIDED, REVERSED, DELETED]
  examples:
    validInvoices:
      summary: Valid invoices (collection response)
      description: Invoices collection response
      value:
        - account:
            accno: "1200"
            description: AR
          currency: "USD"
          dates:
            created: "2022-09-01"
            due: "2022-10-01"
            book: "2022-10-05"
          description:
          eca:
            number: "Customer 1"
            type: "customer"
            credit_limit:
              total: 0
              used: 0
              available: 0
            description:
            entity:
              control_code: C-0
              name: Customer 1
            id: 1
            pay_to_name:
          id: "1"
          "internal-notes": "Internal notes"
          "invoice-number": "2389434"
          lines:
            - delivery_date: "2022-10-27"
              description: "A description"
              discount: 12
              discount_type: "%"
              id: 1
              item: 1
              notes:
              part:
                description: Part 1
                number: "p1"
                onhand: "0"
                unit: "ea"
                weight: "0"
              price: 56.78
              price_fixated: false
              qty: 1
              serialnumber: "1234567890"
              total: 49.97
              unit: "lbs"
          lines_total: 49.97
          notes: "Notes"
          "order-number": "order 345"
          #TODO: Add payments here
          #payments:
          #  - account:
          #      accno: "5010"
          #    date: "2022-11-05"
          #    description: Payment 1
          #    amount: 20
          #    memo: "depot"
          #    source: "visa"
          "po-number": "po 456"
          "quote-number": ""
          #TODO: Add/debug ship-to
          #"ship-to": "ship to there"
          "ship-via": "ship via"
          "shipping-point": "shipping from here"
          taxes:
            "2150":
              amount: 6.78
              "base-amount": 50
              "calculated-amount": 2.5
              source: "Part 1"
              memo: "tax memo"
              tax:
                category: "2150"
                name: Sales Tax
                rate: "0.05"
          taxes_total: 6.78
          total: 56.75
          type: customer
          workflow:
            actions:
              - approve
              - copy_to_new
              - del
              - edit_and_save
              - new_screen
              - sales_order
              - save_info
              - schedule
              - ship_to
              - update
            state: SAVED
    validInvoice:
      summary: Example Invoice
      description: Invoice entry
      value:
        account:
          accno: "1200"
          description: AR
        currency: "USD"
        dates:
          created: "2022-09-01"
          due: "2022-10-01"
          book: "2022-10-05"
        description:
        eca:
          number: "Customer 1"
          type: "customer"
          credit_limit:
            total: 0
            used: 0
            available: 0
          description:
          entity:
            control_code: C-0
            name: Customer 1
          id: 1
          pay_to_name:
        id: "1"
        "internal-notes": "Internal notes"
        "invoice-number": "2389434"
        lines:
          - delivery_date: "2022-10-27"
            description: "A description"
            discount: 12
            discount_type: "%"
            id: 1
            item: 1
            notes:
            part:
              description: Part 1
              number: "p1"
              onhand: "0"
              unit: "ea"
              weight: "0"
            price: 56.78
            price_fixated: false
            qty: 1
            serialnumber: "1234567890"
            total: 49.97
            unit: "lbs"
        lines_total: 49.97
        notes: "Notes"
        "order-number": "order 345"
        #TODO: Add payments here
        #payments:
        #  - account:
        #      accno: "5010"
        #    date: "2022-11-05"
        #    description: Payment 1
        #    amount: 20
        #    memo: "depot"
        #    source: "visa"
        "po-number": "po 456"
        "quote-number": ""
        #TODO: Add/debug ship-to
        #"ship-to": "ship to there"
        "ship-via": "ship via"
        "shipping-point": "shipping from here"
        taxes:
          "2150":
            amount: 6.78
            "base-amount": 50
            "calculated-amount": 2.5
            source: "Part 1"
            memo: "tax memo"
            tax:
              category: "2150"
              name: Sales Tax
              rate: "0.05"
        taxes_total: 6.78
        total: 56.75
        type: customer
        workflow:
          actions:
            - approve
            - copy_to_new
            - del
            - edit_and_save
            - new_screen
            - sales_order
            - save_info
            - schedule
            - ship_to
            - update
          state: SAVED
  responses:
    400:
      description: Bad request
    401:
      description: Unauthorized
    403:
      description: Forbidden
    404:
      description: Not Found
    412:
      description: Precondition failed (If-Match header)
    413:
      description: Payload too large
    428:
      description: Precondition required
