package LedgerSMB::Routes::ERP::API::Orders;

=head1 NAME

LedgerSMB::Routes::ERP::API::Orders - Webservice routes for orders

=head1 DESCRIPTION

Webservice routes for orders

=head2 Treatment of totals

The invoice schema describes multiple fields which can be calculated from
details elsewhere in the invoice, such as C<lines_total>, C<taxes_total>
and C<total>.  When these fields are submitted on invoice creation or
modification, their presence is ignored: their value will be recalculated
from the elements in the invoice.  The next request for the invoice shows
the recalculated totals.


=head1 SYNOPSIS

  use LedgerSMB::Routes::ERP::API::Orders;

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
use LedgerSMB::Magic qw( EC_CUSTOMER EC_VENDOR OEC_SALES_ORDER OEC_PURCHASE_ORDER );
use LedgerSMB::PGNumber;
use LedgerSMB::Part;

use LedgerSMB::Router appname => 'erp/api';

set logger => 'erp.api.orders';

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

sub _get_orders_by_id {
    my ($env, $r, $c, $body, $params) = @_;
    my %ord = ( id => $params->{id} );

    # return error( $r, HTTP_BAD_REQUEST, [],
    #               [ q|'id' parameter missing| ])
    #     if defined $params->{id} and $params->{id} eq '';

    my $query = q|
        SELECT CASE WHEN oe_class_id = 1 THEN 'customer'
                    WHEN oe_class_id = 2 THEN 'vendor'
                    ELSE 'unknown' END as type,
              ordnumber, quonumber, ponumber, transdate, reqdate,
              entity_credit_account, person_id,
              language_code, notes, intnotes, shippingpoint, shipvia,
              curr, amount_tc, netamount_tc, closed, workflow_id
          FROM oe
        WHERE NOT quotation AND oe_class_id IN (1, 2) AND id = ?
        |;
    my $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $params->{id} )
        or die $sth->errstr;

    my $ref = $sth->fetchrow_hashref( 'NAME_lc' );
    die $sth->errstr if not $ref and $sth->err;

    return [ HTTP_NOT_FOUND,
             [ ],
             [ ] ]
        unless $ref;

    my $workflow_id = $ref->{workflow_id};
    my %map = ('reqdate'    => 'required-by',
               'transdate'  => 'order');
    for my $d (qw( transdate reqdate )) {
        $ord{dates}->{$map{$d}} = $ref->{$d};
    }
    %map = qw(
       ord order-
       quo quote-
       po  po-
        );
    for my $key (keys %map) {
        $ord{$map{$key}.'number'} = $ref->{$key.'number'} // '';
    }
    %map = qw(
        type          type
        curr          currency
        notes         notes
        intnotes      internal-notes
        shippingpoint shipping-point
        shipvia       ship-via
        );
    @ord{(values %map)} = $ref->@{(keys %map)};

    $query = q|
        SELECT *
          FROM orderitems i
         WHERE i.trans_id = $1
        ORDER BY id
        |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute( $params->{id} )
        or die $sth->errstr;

    $ord{lines} = [];
    my $item = 1;
    while (my $line = $sth->fetchrow_hashref( 'NAME_lc' )) {
        $line->{item} = $item;
        delete $line->@{qw(allocated assemblyitem trans_id)};
        $line->{price}         = delete $line->{sellprice};
        $line->{'required-by'} = delete $line->{reqdate};
        $line->{price_fixated} = (delete $line->{priceFixated}) ? \1 : \0;
        $line->{discount_type} = defined $line->{discount} ? '%' : '';
        $line->{discount} *= 100 if defined $line->{discount};

        # Why?
        $line->{qty} += 0; # Force string to number conversion
        $line->{price} += 0; # Force string to number conversion
        $line->{total} = ($line->{price} * $line->{qty} * (1 - $line->{discount}/100));

        my $part = LedgerSMB::Part->new(
            _dbh => $env->{'lsmb.db'}
            );
        $part = $part->get_by_id($line->{parts_id});
        $line->{part} = {
            number => $part->{partnumber},
            $part->%{qw( unit weight onhand description )}
        };
        delete $line->{parts_id};

        push $ord{lines}->@*, {
            $line->%{qw/id item price required-by total discount_type
                         part description unit price_fixated qty discount
                         notes serialnumber/}
        };
        $item++;
    }
    die $sth->errstr if $sth->err;

    $query = q|
        SELECT oe_tax.*, account.accno, account.description
          FROM oe_tax
          JOIN account ON oe_tax.tax_id = account.id
         WHERE oe_id = ?
    |;
    $sth = $env->{'lsmb.db'}->prepare($query)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute($ord{id})
        or die $sth->errstr;
    $ord{taxes} = {};
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        $ord{taxes}->{$row->{accno}} = $row;
    }
    die $sth->errstr
        if $sth->err;
    for my $tax (keys $ord{taxes}->%*) {
        my $ref = $ord{taxes}->{$tax};
        $ref->{tax} = {
            category => delete $ref->{accno},
            name => delete $ref->{description},
            rate => delete $ref->{rate},
        };
        delete $ref->{oe_id};
        delete $ref->{tax_id};
        delete $ref->{exempt} unless $ref->{exempt};
        delete $ref->{source} unless defined $ref->{source};
    }

    ###TODO: calculate taxes here...
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

    $credit_limit_used->[0] = 0 if $credit_limit_used->[0] eq 'NaN';

    $ord{eca} = {
        id     => $eca->{id},
        number => $eca->{meta_number},
        type   => ($eca->{entity_class} == EC_CUSTOMER) ? 'customer' : 'vendor',
        description => $eca->{description},
        pay_to_name => $eca->{pay_to_name},
        credit_limit => {
            used => $credit_limit_used->[0] || 0,
            total => $eca->{creditlimit} || 0,
            available => (($eca->{creditlimit} || 0) - ($credit_limit_used->[0] || 0)),
        },
        entity => {
            $entity->%{qw/name control_code/}
        }
    };

    ###TODO: query shipping in `new_shipto` table
    $ord{lines_total} = reduce { $a + $b->{total} } 0, $ord{lines}->@*;
    $ord{taxes_total} = reduce { $a + $b->{amount} } 0, values $ord{taxes}->%*;
    $ord{total}       = $ord{lines_total} + $ord{taxes_total};

    local $LedgerSMB::App_State::DBH = $env->{'lsmb.db'};
    my $wf = $env->{wire}->get('workflows')
        ->fetch_workflow( 'Order/Quote', $workflow_id );

    $ord{workflow} = {
        state => $wf->state,
        actions => [ grep { ($wf->get_action( $_ )->ui // '') ne 'none' }
                     sort $wf->get_current_actions ]
    };

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json' ],
             \%ord ];
}

sub _post_orders {
    my ($env, $r, $c, $body, $params) = @_;
    my @errors;
    my $ord = {};
    # lookup the required fields: eca
    {
        my %map = ( 'customer' => EC_CUSTOMER(),
                    'vendor' => EC_VENDOR());
        my $eca = LedgerSMB::Entity::Credit_Account->new(
            _dbh => $env->{'lsmb.db'},
            entity_class => $map{$body->{eca}->{type}},
            );
        if (exists $body->{eca}->{id}) {
            $ord->{eca} = $eca->get_by_id($body->{eca}->{id});
        }
        else {
            $ord->{eca} = $eca->get_by_meta_number(
                $body->{eca}->{number},
                $map{$body->{eca}->{type}},
                );
        }
        unless ($ord->{eca}->{id}) {
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

        $ord->{curr} = $body->{currency};
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
            $ord->{$optmap{$field}} = $body->{$field};
        }
    }

    # process optional nested fields
    if (exists $body->{'ship-to'}) {
        ...;
    }

    {
        my %map = ('required-by' => 'reqdate',
                   'order'       => 'transdate');
        foreach my $d (qw( required-by order )) {
            next if not $body->{dates}->{$d};
            $ord->{$map{$d}} = $body->{dates}->{$d};
        }
    }

    {
        $ord->{lines} = [];
        for my $line ($body->{lines}->@*) {
            $line->{reqdate} = delete $line->{reqdate};
            # set the optional fields
            my $ord_line = {};
            push $ord->{lines}->@*, $ord_line;

            foreach my $field (qw( description price price_fixated unit qty
                               discount discount_type taxform required-by note
                               serialnumber group )) {
                if (exists $line->{$field}
                    and defined $line->{$field}
                    and $line->{$field} ne '') {
                    $ord_line->{$field} = $line->{$field};
                }
            }

            $ord_line->{qty}   = $ord_line->{qty} // 1;
            $ord_line->{discount} = $ord_line->{discount} / 100
                if $ord_line->{discount_type} eq '%';

            # determine price and description
            {
                my $part = LedgerSMB::Part->new(
                    _dbh => $env->{'lsmb.db'}
                    );
                $ord_line->{part} = $part->get_by_partnumber(
                    $line->{part}->{number}
                    );
                unless ($ord_line->{part}->{id}) {
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
                if ($ord->{eca}->entity_class == EC_CUSTOMER()) {
                    $ord_line->{part}->{price} =
                        delete $ord_line->{part}->{sellprice};
                }
                else {
                    $ord_line->{part}->{price} =
                        delete $ord_line->{part}->{lastcost};
                }

                $ord_line->{$_} //=
                    $ord_line->{part}->{$_} for (qw( price description ));
            }
        }
    }

    if (exists $body->{taxes}) {
        my %taxes;
        $ord->{taxes} = \%taxes;
        foreach my $tax (values $body->{taxes}->%*) {
            if (exists $taxes{$tax->{tax}->{category}}) {
                push @errors, {
                    msg => q|Expecting each tax category to be specified exactly once; second or later occurrance found|,                                                           val => $tax,
                };
                next;
            }

            my $ord_tax = {};
            $taxes{$tax->{tax}->{category}} = $ord_tax;

            foreach my $field (qw(base-amount amount source memo)) {
                if (exists $tax->{$field}
                    and defined $tax->{$field}
                    and $tax->{$field} ne '') {
                    $ord_tax->{$field} = $tax->{$field};
                }
            }

            # Note: a tax needs to be enabled for the
            # customer/vendor!
            #
            my $sth = $env->{'lsmb.db'}->prepare(
                q|
                    SELECT a.accno as category, a.description, t.rate, a.id
                      FROM account a JOIN tax t ON t.chart_id = a.id
                      WHERE a.accno = ?
                      AND coalesce(validto::timestamp, 'infinity')
                              >= coalesce(?::timestamp, now())
                    ORDER BY validto ASC
                    LIMIT 1
                |
                )
                or die $env->{'lsmb.db'}->errstr;
            $sth->execute($tax->{tax}->{category}, $ord->{transdate})
                or die $sth->errstr;
            $ord_tax->{tax} = $sth->fetchrow_hashref;
            die $sth->errstr
                if $sth->err;

            unless ($ord_tax->{tax}) {
                push @errors, {
                    msg => q|Tax category not found for given transaction date|,
                    val => {
                        tax       => $tax->{tax},
                        transdate => $ord->{transdate},
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
                      $ord->{lines}->@*) }
        uniq map { $_->{part}->{id} } $ord->{lines}->@*
        );


    # Step 2: Run the price matrix
    if (keys %part_qty) {
        my $sth;

        if ($ord->{eca}->entity_class == EC_CUSTOMER()) {
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
            if ($ord->{eca}->entity_class == EC_CUSTOMER()) {
                $sth->execute($ord->{eca}->{id},
                              $part_id, $ord->{transdate},
                              $part_qty{$part_id},
                              $ord->{currency})
                    or die $sth->errstr;
            }
            else {
                $sth->execute($ord->{eca}->{id}, $part_id)
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
                              $ord->{lines}->@*) {

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
    for my $line ($ord->{lines}->@*) {
        ###TODO: Verify that 'sellprice' isn't actually ever occurring
        my $total = $line->{qty} * ($line->{price} // $line->{sellprice});

        # Step 5: Calculate discounts
        if ($line->{discount_type}) {
            $total *= (1 - $line->{discount});
        }
        $line->{total} =
            LedgerSMB::PGNumber->new($total)->bfround(
                -$env->{'lsmb.settings'}->{decimal_places}
            );
    }
    $ord->{lines_total} = reduce { $a + $b->{total} } 0, $ord->{lines}->@*;

    #    if (not exists $ord->{taxes}) {
    {
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
        $sth->execute($ord->{eca}->{id}, $ord->{transdate})
            or die $sth->errstr;
        $ord->{taxes} = $sth->fetchall_hashref('accno');
        die $sth->errstr
            if $sth->err;
        if (keys $ord->{taxes}->%* and keys %part_qty) {
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
                        keys $ord->{taxes}->%*
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
            for my $line ($ord->{lines}->@*) {
                next unless exists $part_tax{$line->{part}->{id}};

                my @taxes =
                    sort {
                        $a->{pass} <=> $b->{pass}
                } values $ord->{taxes}->%*;
                ###BUG: this creates built-in the "Tax::Simple" module;
                # it also does not support tax extraction
                # apparently, there was originally a reason to support more
                # complex Tax modules...
                ###BUG: this does not support minvalue and maxvalue taxes yet

                my $base = $line->{total};
                my $passtax = 0;
                my $pass = 0;

                for my $tax (@taxes) {
                    print STDERR "Part: $line->{part}->{id}, tax: $tax->{accno}\n\n";
                    next unless exists $part_tax{$line->{part}->{id}}->{$tax->{accno}};
                    if ($pass != $tax->{pass}) {
                        $base += $passtax;
                        $passtax = 0;
                        $pass = $tax->{pass};
                    }

                    my $amount = $base*$tax->{rate};
                    $line->{taxes}->{$tax->{accno}} = {
                        base   => $base,
                        rate   => $tax->{rate},
                        amount => $amount,
                    };
                    $ord->{taxes}->{$tax->{accno}}->{base}   += $base;
                    $ord->{taxes}->{$tax->{accno}}->{amount} += $amount;
                }
            }
        }
    }
    ###BUG: These amounts in don't have these names in the invoice resource!!!
    $ord->{taxes_total} =
        reduce { $a + $b->{amount} } LedgerSMB::PGNumber->new(0), values $ord->{taxes}->%*;
    $ord->{netamount} = $ord->{lines_total};
    $ord->{amount}    = $ord->{netamount} + $ord->{taxes_total};
    ###TODO: We need to apply the type-of-business-based discount here
    # (on the totals, that is) -- how to work that into the line-items??


    ###TODO: Add multi-currency support
    $ord->{amount_tc}    = $ord->{amount};
    $ord->{netamount_tc} = $ord->{netamount};

    ###BUG: Assert that the invoice is posted in functional currency

    if (not $ord->{ordnumber}) {
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
             WHERE setting_key = 'sonumber'
            RETURNING (SELECT "value" FROM defaults WHERE setting_key = 'sonumber');
            /) or die $env->{'lsmb.db'}->errstr;

        $sth->execute()
            or die $sth->errstr;

        my ($ordnumber) = $sth->fetchrow_array();
        die $sth->errstr if not $ordnumber and $sth->err;
        $ord->{ordnumber} = $ordnumber;
    }
    my $sth = $env->{'lsmb.db'}->prepare(
        q|
        INSERT INTO oe ( oe_class_id,
            ordnumber, quonumber, ponumber,
            amount_tc, netamount_tc, curr,
            taxincluded,
            transdate, reqdate,
            notes, intnotes,
            shippingpoint, shipvia,
            person_id, language_code,
            entity_credit_account
            )
        VALUES ( ?,
                 ?, ?, ?,
                 ?, ?, ?,
                 ?,
                 ?, ?,
                 ?, ?,
                 ?, ?,
                 ?, ?,
                 ?)
        RETURNING id
        |)
        or die $env->{'lsmb.db'}->errstr;
    $sth->execute(
        OEC_SALES_ORDER(),
        $ord->@{
          qw/ ordnumber quonumber ponumber
              amount_tc netamount_tc curr
              taxincluded
              transdate reqdate
              notes intnotes
              shippingpoint shipvia
              person_id language_code
          / },
        $ord->{eca}->{id}
        )
        or die $sth->errstr;
    my ($ord_id) = $sth->fetchrow_array;
    die $sth->errstr
        if $sth->err;

    my $ctx = Workflow::Context->new;
    $ctx->param( trans_id => $ord_id );
    $ctx->param( transdate => $ord->{transdate} );
    local $LedgerSMB::App_State::DBH = $env->{'lsmb.db'};
    my $wf  = $env->{wire}->get('workflows')
        ->create_workflow( 'Order/Quote', $ctx );
    $env->{'lsmb.db'}->do(q{UPDATE oe SET workflow_id = ? where id = ?},
             {}, $wf->id, $ord_id)
        or die $env->{'lsmb.db'}->errstr;


    $sth = $env->{'lsmb.db'}->prepare(
        q|
        INSERT INTO orderitems (trans_id, parts_id,
              description, qty, sellprice, precision,
              discount, unit, reqdate, serialnumber, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        RETURNING id
        |)
        or die $env->{'lsmb.db'}->errstr;

    for my $line ($ord->{lines}->@*) {
        # generate line in 'orderitems' table
        ###TODO: extract the precision from the 'price'
        ###BUG: check signs!!!
        $sth->execute(
            $ord_id, $line->{part}->{id}, $line->{description}, $line->{qty},
            $line->{price}, 0, ###TODO: single currency
            (defined $line->{discount} ? $line->{discount} : undef),
            (map { $line->{$_} }
             qw/unit required-by serialnumber notes/)
            )
            or die $sth->errstr;
        my ($ordline_id) = $sth->fetchrow_array;
        die $sth->errstr
            if $sth->err;
    }

    $sth = $env->{'lsmb.db'}->prepare(
        q|
        INSERT INTO oe_tax (oe_id, tax_id,
             basis, rate, amount)
          VALUES (?, ?, ?, ?, ?)
        |)
        or die $env->{'lsmb.db'}->errstr;
    for my $tax (values $ord->{taxes}->%*) {
        next if not defined $tax->{base};

        $sth->execute($ord_id,
                      $tax->{id},
                      $tax->{base},
                      $tax->{rate},
                      $tax->{amount})
            or die $sth->errstr;
    }

    $wf->execute_action( 'save' ); # move to SAVED state

    return [
        HTTP_CREATED,
        [ 'Location' => "./$ord_id" ],  # We return this in a header?
        [  ] ];
}


get '/orders' => \&_not_implemented;
post api '/orders' => \&_post_orders;

get api '/orders/{id}' => \&_get_orders_by_id;
del '/orders/{id}' => \&_not_implemented;
patch '/orders/{id}' => \&_not_implemented;



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;

__DATA__
openapi: 3.0.0
info:
  title: Management of Orders
  version: 0.0.1
paths:
  /orders:
    description: Management of Orders
    get:
      tags:
        - Orders
        - Experimental
      summary: Lists orders
      operationId: getOrders
      responses:
        200:
          description: ...
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Order'
                example:
                  $ref: '#/components/examples/validOrder'
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
        - Orders
        - Experimental
      summary: Add an order
      operationId: postOrders
      requestBody:
        description: ...
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/newOrder'
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
                $ref: '#/components/schemas/Order'
        400:
          $ref: '#/components/responses/400'
        401:
          $ref: '#/components/responses/401'
        403:
          $ref: '#/components/responses/403'
        404:
          $ref: '#/components/responses/404'
  /orders/{id}:
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
          minLength: 1
    get:
      tags:
        - Orders
        - Experimental
      summary: Get a single order
      operationId: getOrdersById
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
              examples:
                validOrder:
                  $ref: '#/components/examples/validOrder'
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
        - Orders
        - Experimental
      summary: Update a single order
      operationId: putOrderById
      parameters:
        - $ref: '#/components/parameters/if-match'
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/newOrder'
      responses:
        200:
          description: ...
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
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
    newOrder:
      type: object
      required:
        - eca
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
        currency:
          type: string
          minLength: 3
          maxLength: 3
        notes:
          type: string
          nullable: true
        internal-notes:
          type: string
          nullable: true
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
            - order
          properties:
            order:
              type: string
              format: date
            required-by:
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
              required-by:
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
    Order:
      description: ...
      allOf:
        # TODO: Fix inheritance. The definitions below replace the ones
        # TODO: defined in newOrder, not complement them
        #- $ref: '#/components/schemas/newOrder'
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
            description:
              type: string
              nullable: true
            lines:
              type: array
              items:
                type: object
                properties:
                  required-by:
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
                  basis:
                    type: string
                  amount:
                    type: string
                  source:
                    type: string
            workflow:
              type: object
              properties:
                actions:
                  type: array
                state:
                  type: string
                  enum: [SAVED, DELETED]
  examples:
    validOrder:
      summary: Example Order
      description: Order entry
      value:
        currency: "USD"
        dates:
          order: "2022-09-01"
          required-by: "2022-10-01"
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
        lines:
          - required-by: "2022-10-27"
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
            total: 49.9664
            unit: "lbs"
        lines_total: 49.9664
        notes: "Notes"
        "order-number": "order 345"
        "po-number": "po 456"
        "quote-number": ""
        #TODO: Add/debug ship-to
        #"ship-to": "ship to there"
        "ship-via": "ship via"
        "shipping-point": "shipping from here"
        taxes:
          "2150":
            amount: "2.50"
            basis: "49.97"
            tax:
              category: "2150"
              name: Sales Tax
              rate: "0.05"
        taxes_total: 2.50
        total: 52.4664
        type: customer
        workflow:
          actions:
            - delete
            - e_mail
            - print
            - print_and_save
            - print_and_save_as_new
            - purchase_order
            - quotation
            - sales_invoice
            - save
            - save_as_new
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
