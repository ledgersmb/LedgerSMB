=head1 NAME

            ($form->{"$partnumber_$i"}) = split(/--/, $form->{"$partnumber_$i"});
LedgerSMB::IS - Inventory Invoicing

=cut
#====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: Jim Rawlings <jim@your-dba.com>
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# Inventory invoicing module
#
#======================================================================

package IS;
use LedgerSMB::Tax;
use LedgerSMB::PriceMatrix;
use LedgerSMB::Sysconfig;
use LedgerSMB::Setting;
use LedgerSMB::App_State;
use LedgerSMB::Num2text;
use Log::Log4perl;

use LedgerSMB::IS qw(BC_SALES_INVOICE);


my $logger = Log::Log4perl->get_logger('LedgerSMB::IS');


sub add_cogs {
    my ($self, $form) = @_;
    my $dbh = $form->{dbh};
    my $query =
     "select cogs__add_for_ar_line(id) FROM invoice WHERE trans_id = ?";
    my $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute($form->{id}) || $form->dberror($query);
}

=over

=item get_files

Returns a list of files associated with the existing transaction.  This is
provisional, and will change for 1.4 as the GL transaction functionality is
                  {ref_key => $self->{id}, file_class => 1}
rewritten

=cut

sub get_files {
     my ($self, $form, $locale) = @_;
     return if !$form->{id};
     my $file = LedgerSMB::File->new(%$form);
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 1});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 1}
     );

}

sub invoice_details {
    my ( $self, $myconfig, $form ) = @_;

    $form->{duedate} = $form->{transdate} unless ( $form->{duedate} );

    # connect to database

    my $dbh = $form->{dbh};

    my $query = qq|
        SELECT ?::date - ?::date
                       AS terms, value
          FROM defaults
         WHERE setting_key = 'weightunit'|;
    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{duedate}, $form->{transdate} )
      || $form->dberror($query);

    ( $form->{terms}, $form->{weightunit} ) = $sth->fetchrow_array;
    $sth->finish;

    # this is for the template
    $form->{invdate} = $form->{transdate};

    my $tax = 0;
    my $item;
    my $i;
    my @sortlist = ();
    my $projectnumber;
    my $projectdescription;
    my $projectnumber_id;
    my $translation;
    my @taxaccounts;
    my %taxaccounts;
    my $taxrate;
    my $taxamount;

    $query = qq|
           SELECT p.description, t.description
             FROM project p
        LEFT JOIN translation t
                  ON (t.trans_id = p.id
                  AND t.language_code = ?)
            WHERE id = ?|;
    my $prh = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|
        SELECT inventory_accno_id, income_accno_id,
               expense_accno_id, assembly, weight FROM parts
         WHERE id = ?|;
    my $pth = $dbh->prepare($query) || $form->dberror($query);

    my $sortby;


    # sort items by project and partsgroup
    foreach my $i ( 1 .. $form->{rowcount} - 1 ) {

        # account numbers
        $pth->execute( $form->{"id_$i"} );
        $ref = $pth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }
        $pth->finish;

        $projectnumber_id      = 0;
        $projectnumber         = "";
        $form->{partsgroup}    = "";
        $form->{projectnumber} = "";

        if ( $form->{groupprojectnumber} || $form->{grouppartsgroup} ) {

            $inventory_accno_id =
              ( $form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"} )
              ? "1"
              : "";

            if ( $form->{groupprojectnumber} ) {
                ( $projectnumber, $projectnumber_id ) =
                  split /--/, $form->{"projectnumber_$i"};
            }
            if ( $form->{grouppartsgroup} ) {
                ( $form->{partsgroup} ) =
                  split /--/, $form->{"partsgroup_$i"};
            }

            if ( $projectnumber_id && $form->{groupprojectnumber} ) {
                if ( $translation{$projectnumber_id} ) {
                    $form->{projectnumber} = $translation{$projectnumber_id};
                }
                else {

                    # get project description
                    $prh->execute( $projectnumber_id, $form->{language_code} );

                    ( $projectdescription, $translation ) =
                      $prh->fetchrow_array;

                    $prh->finish;

                    $form->{projectnumber} =
                      ($translation)
                      ? "$projectnumber, $translation"
                      : "$projectnumber, " . "$projectdescription";

                    $translation{$projectnumber_id} = $form->{projectnumber};
                }
            }

            if ( $form->{grouppartsgroup} && $form->{partsgroup} ) {
                $form->{projectnumber} .= " / "
                  if $projectnumber_id;
                $form->{projectnumber} .= $form->{partsgroup};
            }
        }

        $sortby = qq|$projectnumber$form->{partsgroup}|;
        if ( $form->{sortby} ne 'runningnumber' ) {
            for (qw(partnumber description bin)) {
                $sortby .= $form->{"${_}_$i"}
                  if $form->{sortby} eq $_;
            }
        }

        push @sortlist,
          [
            $i,
            qq|$projectnumber$form->{partsgroup}| . qq|$inventory_accno_id|,
            $form->{projectnumber},
            $projectnumber_id,
            $form->{partsgroup},
            $sortby
          ];

    }

    # sort the whole thing by project and group

    @sortlist = sort { $a->[5] cmp $b->[5] } @sortlist;  ## no critic (ProhibitMagicNumbers) sniff

    my $runningnumber = 1;
    my $sameitem      = "";
    my $subtotal;
    my $k = scalar @sortlist;
    my $j = 0;

    foreach my $item (@sortlist) {

        $i = $item->[0];
        $j++;

        # heading
        if ( $form->{groupprojectnumber} || $form->{grouppartsgroup} ) {
            if ( $item->[1] ne $sameitem ) {
                $sameitem = $item->[1];

                $ok = 0;

                if ( $form->{groupprojectnumber} ) {
                    $ok = $form->{"projectnumber_$i"};
                }
                if ( $form->{grouppartsgroup} ) {
                    $ok = $form->{"partsgroup_$i"}
                      unless $ok;
                }

                if ($ok) {

                    if (   $form->{"inventory_accno_id_$i"}
                        || $form->{"assembly_$i"} )
                    {

                        push( @{ $form->{part} },    "" );
                        push( @{ $form->{service} }, NULL );
                    }
                    else {
                        push( @{ $form->{part} },    NULL );
                        push( @{ $form->{service} }, "" );
                    }

                    push( @{ $form->{description} }, $item->[2] );
                    for (
                        qw(taxrates runningnumber number
                        sku serialnumber bin qty ship
                        unit deliverydate projectnumber
                        sellprice listprice netprice
                        discount discountrate linetotal
                        weight itemnotes)
                      )
                    {
                        push( @{ $form->{$_} }, "" );
                    }
                    push( @{ $form->{lineitems} }, { amount => 0, tax => 0 } );
                }
            }
        }

        $form->{"qty_$i"} = $form->parse_amount( $myconfig, $form->{"qty_$i"} );
        if ( $form->{"qty_$i"} ) {

            $form->{discount} = [] if ref $form->{discount} ne 'ARRAY';
            $form->{totalqty}  += $form->{"qty_$i"};
            $form->{totalship} += $form->{"qty_$i"};
            $form->{"weight_$i"} ||= 0;
            $form->{totalweight} +=
              ( $form->{"qty_$i"} * $form->{"weight_$i"} );

            $form->{totalweightship} +=
              ( $form->{"qty_$i"} * $form->{"weight_$i"} );

            # add number, description and qty to $form->{number}...
            push( @{ $form->{runningnumber} }, $runningnumber++ );
            push( @{ $form->{number} },        $form->{"partnumber_$i"} );
            push( @{ $form->{image} },        $form->{"image_$i"} );
            push( @{ $form->{sku} },           $form->{"sku_$i"} );
            push( @{ $form->{serialnumber} },  $form->{"serialnumber_$i"} );

            push( @{ $form->{bin} },         $form->{"bin_$i"} );
            push( @{ $form->{item_description} }, $form->{"description_$i"} );
            push( @{ $form->{itemnotes} },   $form->{"notes_$i"} );
            push(
                @{ $form->{qty} },
                $form->format_amount( $myconfig, $form->{"qty_$i"} )
            );

            push(
                @{ $form->{ship} },
                $form->format_amount( $myconfig, $form->{"qty_$i"} )
            );

            push( @{ $form->{unit} },         $form->{"unit_$i"} );
            push( @{ $form->{deliverydate} }, $form->{"deliverydate_$i"} );

            push( @{ $form->{projectnumber} }, $form->{"projectnumber_$i"} );

            push( @{ $form->{sellprice} }, $form->{"sellprice_$i"} );

            push( @{ $form->{listprice} }, $form->{"listprice_$i"} );

            push(
                @{ $form->{weight} },
                $form->format_amount(
                    $myconfig, $form->{"weight_$i"} * $form->{"qty_$i"}
                )
            );

            my $sellprice =
              $form->parse_amount( $myconfig, $form->{"sellprice_$i"} );

            my ($dec) = ( $sellprice =~ /\.(\d+)/ );
            $dec = length $dec;
            my $dp = LedgerSMB::Setting->get('decimal_places');
            my $decimalplaces = ( $dec > $dp ) ? $dec : $dp;

            my $discount = $form->round_amount(
                $sellprice *
                  $form->parse_amount( $myconfig, $form->{"discount_$i"} ) /
                  100,
                $decimalplaces
            );

            # keep a netprice as well, (sellprice - discount)
            $form->{"netprice_$i"} = $sellprice - $discount;

            my $linetotal =
              $form->round_amount( $form->{"qty_$i"} * $form->{"netprice_$i"},
                2 );

            if (   $form->{"inventory_accno_id_$i"}
                || $form->{"assembly_$i"} )
            {

                push( @{ $form->{part} },    $form->{"sku_$i"} );
                push( @{ $form->{service} }, NULL );
                $form->{totalparts} += $linetotal;
            }
            else {
                push( @{ $form->{service} }, $form->{"sku_$i"} );
                push( @{ $form->{part} },    NULL );
                $form->{totalservices} += $linetotal;
            }

            push(
                @{ $form->{netprice} },
                ( $form->{"netprice_$i"} )
                ? $form->format_amount( $myconfig, $form->{"netprice_$i"},
                    $decimalplaces )
                : " "
            );

            $discount =
              ($discount)
              ? $form->format_amount( $myconfig, $discount * -1,
                $decimalplaces )
              : " ";

            push( @{ $form->{discount} }, $discount );
            push(
                @{ $form->{discountrate} },
                $form->format_amount( $myconfig, $form->{"discount_$i"} )
            );

            $form->{total} += $linetotal;

            # this is for the subtotals for grouping
            $subtotal += $linetotal;

            $form->{"linetotal_$i"} =
              $form->format_amount( $myconfig, $linetotal, 2 );
            $form->{"linetotal_$i"} = '0.00' unless $form->{"linetotal_$i"};

            push( @{ $form->{linetotal} }, $form->{"linetotal_$i"} );

            @taxaccounts = Tax::init_taxes(
                $form,
                $form->{"taxaccounts_$i"},
                $form->{"taxaccounts"}
            );

            my $ml       = 1;
            my @taxrates = ();

            $tax = 0;

            if ( $form->{taxincluded} ) {
                $taxamount =
                  Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 1 );
                $taxbase = ( $linetotal - $taxamount );
                $tax += Tax::extract_taxes( \@taxaccounts, $form, $linetotal );
            }
            else {
                $taxamount =
                  Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 0 );
                $tax += Tax::apply_taxes( \@taxaccounts, $form, $linetotal );
            }

            foreach my $item (@taxaccounts) {
                push @taxrates, 100 * $item->rate;
                if (defined $form->{"mt_amount_" . $item->account}){
                    $taxaccounts{ $item->account } +=
                        $form->{"mt_amount_" . $item->account};
                    $taxbase{ $item->account } +=
                        $form->{"mt_basis_" . $item->account};
                    next;
                }
                $taxaccounts{ $item->account } += $item->value;
                if ( $form->{taxincluded} ) {
                    $taxbase{ $item->account } += $taxbase;
                }
                else {
                    $taxbase{ $item->account } += $linetotal;
                }
            }

            push(
                @{ $form->{lineitems} },
                {
                    amount => $linetotal,
                    tax    => $form->round_amount( $tax, 2 )
                }
            );

            push( @{ $form->{taxrates} },
                join ' ', sort { $a <=> $b } @taxrates );

        }

        # add subtotal
        if ( $form->{groupprojectnumber} || $form->{grouppartsgroup} ) {
            if ($subtotal) {
                if ( $j < $k ) {

                    # look at next item
                    if ( $sortlist[$j]->[1] ne $sameitem ) {

                        if (   $form->{"inventory_accno_id_$j"}
                            || $form->{"assembly_$i"} )
                        {

                            push( @{ $form->{part} },    "" );
                            push( @{ $form->{service} }, NULL );
                        }
                        else {
                            push( @{ $form->{service} }, "" );

                            push( @{ $form->{part} }, NULL );
                        }

                        for (
                            qw(taxrates
                            runningnumber number sku
                            serialnumber bin qty
                            ship unit deliverydate
                            projectnumber sellprice
                            listprice netprice
                            discount discountrate
                            weight itemnotes)
                          )
                        {

                            push( @{ $form->{$_} }, "" );
                        }

                        push(
                            @{ $form->{description} },
                            $form->{groupsubtotaldescription}
                        );

                        push(
                            @{ $form->{lineitems} },
                            {
                                amount => 0,
                                tax    => 0
                            }
                        );

                        if ( $form->{groupsubtotaldescription} ne "" ) {

                            push(
                                @{ $form->{linetotal} },
                                $form->format_amount( $myconfig, $subtotal, 2 )
                            );
                        }
                        else {
                            push( @{ $form->{linetotal} }, "" );
                        }
                        $subtotal = 0;
                    }

                }
                else {

                    # got last item
                    if ( $form->{groupsubtotaldescription} ne "" ) {

                        if (   $form->{"inventory_accno_id_$j"}
                            || $form->{"assembly_$i"} )
                        {

                            push( @{ $form->{part} }, "" );

                            push( @{ $form->{service} }, NULL );
                        }
                        else {
                            push( @{ $form->{service} }, "" );

                            push( @{ $form->{part} }, NULL );
                        }

                        for (
                            qw(taxrates
                            runningnumber number sku
                            serialnumber bin qty
                            ship unit deliverydate
                            projectnumber sellprice
                            listprice netprice
                            discount discountrate
                            weight itemnotes)
                          )
                        {

                            push( @{ $form->{$_} }, "" );
                        }

                        push(
                            @{ $form->{description} },
                            $form->{groupsubtotaldescription}
                        );

                        push(
                            @{ $form->{linetotal} },
                            $form->format_amount( $myconfig, $subtotal, 2 )
                        );
                        push(
                            @{ $form->{lineitems} },
                            {
                                amount => 0,
                                tax    => 0
                            }
                        );
                    }
                }
            }
        }
    }

    $tax = 0;
    foreach my $item ( sort keys %taxaccounts ) {
        if ( $form->round_amount( $taxaccounts{$item}, 2 ) ) {
            $tax += $taxamount = $form->round_amount( $taxaccounts{$item}, 2 );

            push(
                @{ $form->{taxbaseinclusive} },
                $form->{"${item}_taxbaseinclusive"} =
                  $form->format_amount( $myconfig, $taxbase{$item} + $tax, 2 )
            );

            push(
                @{ $form->{taxbase} },
                $form->{"${item}_taxbase"} =
                  $form->format_amount( $myconfig, $taxbase{$item}, 2 )
            );
            push(
                @{ $form->{taxsummary} },
                $form->format_amount( $myconfig, $taxbase{$item} + $taxamount, 2 )
            );

            push(
                @{ $form->{tax} },
                $form->{"${item}_tax"} =
                  $form->format_amount( $myconfig, $taxamount, 2 )
            );

            push( @{ $form->{taxdescription} },
                $form->{"${item}_description"} );

            $form->{"${item}_taxrate"} =
              $form->format_amount( $myconfig, $form->{"${item}_rate"} * 100 );
            push( @{ $form->{taxrate} },   $form->{"${item}_taxrate"} );
            push( @{ $form->{taxnumber} }, $form->{"${item}_taxnumber"} );
        }
    }

    # adjust taxes for lineitems
    my $total = 0;
    for ( @{ $form->{lineitems} } ) {
        $total += $_->{tax};
    }
    if ( $form->round_amount( $total, 2 ) != $form->round_amount( $tax, 2 ) ) {

        # get largest amount
        for ( reverse sort { $a->{tax} <=> $b->{tax} } @{ $form->{lineitems} } )
        {

            $_->{tax} -= $total - $tax;
            last;
        }
    }
    $i = 1;
    for ( @{ $form->{lineitems} } ) {
        push(
            @{ $form->{linetax} },
            $form->format_amount( $myconfig, $_->{tax}, 2, "" )
        );
    }

    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        if ( $form->{"paid_$i"} ) {
            push( @{ $form->{payment} }, $form->{"paid_$i"} );
            my ( $accno, $description ) = split /--/, $form->{"AR_paid_$i"};

            push( @{ $form->{paymentaccount} }, $description );
            push( @{ $form->{paymentdate} },    $form->{"datepaid_$i"} );
            push( @{ $form->{paymentsource} },  $form->{"source_$i"} );
            push( @{ $form->{paymentmemo} },    $form->{"memo_$i"} );

            $form->{paid} +=
              $form->parse_amount( $myconfig, $form->{"paid_$i"} );
        }
    }

    for (qw(totalparts totalservices)) {
        $form->{$_} = $form->format_amount( $myconfig, $form->{$_}, 2 );
    }
    for (qw(totalqty totalship totalweight)) {
        $form->{$_} = $form->format_amount( $myconfig, $form->{$_} );
    }
    $form->{subtotal} = $form->format_amount( $myconfig, $form->{total}, 2 );
    $form->{subtotal} = '0.00' unless $form->{subtotal};
    $form->{invtotal} =
      ( $form->{taxincluded} ) ? $form->{total} : $form->{total} + $tax;

    my $c;
    if ( $form->{language_code} ne "" ) {
        $c = LedgerSMB::Num2text->new( $form->{language_code});
    }
    else {
        $c = LedgerSMB::Num2text->new( $myconfig->{countrycode});
    }
    $c->init;
    my $whole;
    ( $whole, $form->{decimal} ) = split /\./, $form->{invtotal};
    $form->{decimal} .= "00";
    $form->{decimal}        = substr( $form->{decimal}, 0, 2 );
    $form->{text_decimal}   = $c->num2text( $form->{decimal} * 1 );
    $form->{text_amount}    = $c->num2text($whole);
    $form->{integer_amount} = $form->format_amount( $myconfig, $whole );

    $form->{invtotal} ||= 0;
    $form->{paid} ||= 0;
    $form->{total} =
      $form->format_amount( $myconfig, $form->{invtotal} - $form->{paid}, 2 );

    $form->{invtotal} = $form->format_amount( $myconfig, $form->{invtotal}, 2 );

    $form->{paid} = $form->format_amount( $myconfig, $form->{paid}, 2 );
}

sub project_description {
    my ( $self, $dbh2, $id ) = @_;
    $dbh = $form->{dbh};
    my $query = qq|
        SELECT description
          FROM project
         WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute($id);
    ($_) = $sth->fetchrow_array;

    $_;

}

sub customer_details {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    # get rest for the customer
    my $query = qq|
        SELECT meta_number as customernumber,
                       e.name, l.line_one as address1,
               l.line_two as address2, l.city AS city,
               l.state as state, l.mail_code AS zipcode,
               country.name as country,
               '' as contact, '' as customerphone, '' as customerfax,
               '' AS customertaxnumber, sic_code AS sic, iban, remark,
                bic,eca.startdate,eca.enddate
          FROM (SELECT id, entity_id,
                '' AS first_name, '' AS middle_name, legal_name,
                '' AS personal_id, tax_id, sales_tax_id, license_number,
                sic_code
            FROM company
            UNION
            SELECT id, entity_id,
                first_name, middle_name, last_name,
                personal_id, '', '', '', ''
            FROM person)
            cm
          JOIN entity e ON (cm.entity_id = e.id)
                  JOIN entity_credit_account eca ON e.id = eca.entity_id
                  LEFT JOIN entity_bank_account eba ON eca.entity_id = eba.entity_id
          LEFT JOIN eca_to_location el ON eca.id = el.credit_id
                               and el.location_class=1
          LEFT JOIN entity_to_location el2
                            ON eca.entity_id = el2.entity_id
                               and el2.location_class=1
          LEFT JOIN location l
                            ON coalesce(el.location_id,el2.location_id) = l.id
          LEFT JOIN country ON l.country_id = country.id
         WHERE eca.id = ? limit 1|;


    my $sth = $dbh->prepare($query);

    $sth->execute( $form->{customer_id} ) || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;

}

sub post_invoice {

    my ( $self, $myconfig, $form ) = @_;
    $form->{invnumber} = undef if $form->{invnumber} eq '';
    delete $form->{reverse} unless $form->{reverse};

    $form->all_business_units;
    $form->{invnumber} = $form->update_defaults( $myconfig, "sinumber", $dbh )
      if $form->should_update_defaults('invnumber');

    my $dbh = $LedgerSMB::App_State::DBH;;

    my $query;
    my $sth;
    my $null;
    my $project_id;
    my $exchangerate = 0;
    my $keepcleared  = 0;

    $form->{acc_trans} = ();

    if ($form->{id}){
        delete_invoice($self, $myconfig, $form);
    }

    ( $null, $form->{employee_id} ) = split /--/, $form->{employee};
    unless ( $form->{employee_id} ) {
        ( $form->{employee}, $form->{employee_id} ) = $form->get_employee;
    }

    ( $null, $form->{department_id} ) = split( /--/, $form->{department} );
    $form->{department_id} *= 1;

    $query = qq|
        SELECT (SELECT value FROM defaults
                 WHERE setting_key = 'fxgain_accno_id')
               AS fxgain_accno_id,
               (SELECT value FROM defaults
                 WHERE setting_key = 'fxloss_accno_id')
               AS fxloss_accno_id|;
    my ( $fxgain_accno_id, $fxloss_accno_id ) = $dbh->selectrow_array($query);

    $query = qq|
        SELECT p.assembly, p.inventory_accno_id,
               p.income_accno_id, p.expense_accno_id
          FROM parts p
         WHERE p.id = ?|;
    my $pth = $dbh->prepare($query) || $form->dberror($query);
    $form->{is_return} ||= 0;

    if ( $form->{id} ) {
        $form->error("Can't re-post invoices.");
    }

    my $uid = localtime;
    $uid .= "$$";

    if ( !$form->{id} ) {

        $query = qq|
            INSERT INTO ar (invnumber, person_id, entity_credit_account)
                 VALUES ('$uid', ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{employee_id}, $form->{customer_id}) || $form->dberror($query);

        $query = qq|SELECT id FROM ar WHERE invnumber = '$uid'|;
        $sth   = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        ( $form->{id} ) = $sth->fetchrow_array;
        $sth->finish;

    }

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        $form->{exchangerate} = 1;
    }

    $form->{exchangerate} = $form->parse_amount( $myconfig, $form->{exchangerate} );

     my $return_cid = 0;

    my $i;
    my $item;
    my $taxrate;
    my $tax;
    my $fxtax;
    my @taxaccounts;
    my $amount;
    my $grossamount;
    my $invamount    = 0;
    my $invnetamount = 0;
    my $diff         = 0;
    my $ml;
    my $invoice_id;
    my $ndx;
    for (keys %$form) {
        if (UNIVERSAL::isa( $form->{$_}, 'LedgerSMB::PGNumber' )){
            $form->{$_} = $form->{$_}->bstr();
        }
    }


    my $taxformfound=IS->taxform_exist($form,$form->{"customer_id"});

    my $b_unit_sth = $dbh->prepare(
         "INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
          VALUES (currval('invoice_id_seq'), ?, ?)"
    );

    foreach my $i ( 1 .. $form->{rowcount} ) {
        my $allocated = 0;
        $form->{"qty_$i"} = $form->parse_amount( $myconfig, $form->{"qty_$i"} );
        if ($form->{reverse}){
            $form->{"qty_$i"} *= -1;
        }

        if ( $form->{"qty_$i"} ) {

            $pth->execute( $form->{"id_$i"} );
            $ref = $pth->fetchrow_hashref(NAME_lc);
            for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }
            $pth->finish;

            if ($form->{"qty_$i"} < 0 and $return_cid){
                $form->{"income_accno_id_$i"} = $return_cid;
            }


            # project
            if ( $form->{"projectnumber_$i"} ) {
                ( $null, $project_id ) = split /--/,
                  $form->{"projectnumber_$i"};
            }
            $project_id = $form->{"project_id_$i"}
              if $form->{"project_id_$i"};

            # keep entered selling price
            my $fxsellprice =
              $form->parse_amount( $myconfig, $form->{"sellprice_$i"} );

            my $moneyplaces = LedgerSMB::Setting->get('decimal_places');
            my $decimalplaces = ($form->{"precision_$i"} > $moneyplaces)
                             ? $form->{"precision_$i"}
                             : $moneyplaces;
            $form->{"sellprice_$i"} = $fxsellprice -
              $form->round_amount( $fxsellprice * $form->{"discount_$i"},
                $decimalplaces );


            # undo discount formatting
            $form->{"discount_$i"} =
              $form->parse_amount( $myconfig, $form->{"discount_$i"} ) / 100;

            # deduct discount
            $form->{"sellprice_$i"} = $fxsellprice -
              $form->round_amount( $fxsellprice * $form->{"discount_$i"},
                $decimalplaces );

            # linetotal - removing rounding due to fx issues
            my $fxlinetotal = $form->{"sellprice_$i"} * $form->{"qty_$i"};

            $amount = $fxlinetotal * $form->{exchangerate};
            my $linetotal = $form->round_amount( $amount, 2 );
            $fxdiff += $amount - $linetotal;
            $fxlinediff =  $amount - $fxlinetotal;
            if (!$form->{manual_tax}){
                @taxaccounts = Tax::init_taxes(
                    $form,
                    $form->{"taxaccounts_$i"},
                    $form->{"taxaccounts"}
                );
                $ml    = 1;
                $tax   = LedgerSMB::PGNumber->bzero();
                $fxtax = LedgerSMB::PGNumber->bzero();

                if ( $form->{taxincluded} ) {
                    $tax += $amount =
                      Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 1 );
                    $form->{"sellprice_$i"} -= $amount / $form->{"qty_$i"};

                    $fxtax +=
                      Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 1 );
                }
                else {
                    $tax += $amount =
                      Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 0 );
                    $fxtax +=
                      Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 0 );
                }
                for (@taxaccounts) {
                    $form->{acc_trans}{ $form->{id} }{ $_->account }{amount} +=
                      $_->value;
                }

                $grossamount = $form->round_amount( $linetotal, 2 );

                if ( $form->{taxincluded} ) {
                    $amount = $form->round_amount( $tax, 2 );
                    $linetotal -= $form->round_amount( $tax - $diff, 2 );
                    $diff = ( $amount - $tax );
                }
            }
            $grossamount ||= $form->round_amount( $linetotal, 2 );
            $fxtax ||=0;
            # add linetotal to income
            $amount = $form->round_amount( $linetotal, 2 );

            push @{ $form->{acc_trans}{lineitems} },
              {
                row_num       => $i,
                chart_id      => $form->{"income_accno_id_$i"},
                amount        => $amount,
                fxgrossamount => $fxlinetotal + $fxtax,
                grossamount   => $grossamount,
                project_id    => $project_id,
                fxdiff        => $fxlinediff
              };

            $ndx = $#{ @{ $form->{acc_trans}{lineitems} } };

            $form->{"sellprice_$i"} =
              $form->round_amount(
                $form->{"sellprice_$i"} * $form->{exchangerate},
                $decimalplaces );

            if (   $form->{"inventory_accno_id_$i"}
                || $form->{"assembly_$i"} )
            {

                    $form->update_balance(
                        $dbh, "parts", "onhand",
                        qq|id = $form->{"id_$i"}|,
                        $form->{"qty_$i"} * -1
                    ); # unless $form->{shipped};
            }
            # save detail record in invoice table
            $query = qq|
                INSERT INTO invoice (description)
                     VALUES ('$uid')|;

            $dbh->do($query) || $form->dberror($query);

            $query = qq|
                SELECT id FROM invoice
                WHERE description = '$uid'|;
            ($invoice_id) = $dbh->selectrow_array($query);

            unless ( $form->{"deliverydate_$i"} ) {
                undef $form->{"deliverydate_$i"};
            }
            $query = qq|
                UPDATE invoice
                   SET trans_id = ?,
                       parts_id = ?,
                       description = ?,
                       qty = ?,
                       sellprice = ?,
                                       precision = ?,
                       fxsellprice = ?,
                       discount = ?,
                       allocated = ?,
                       unit = ?,
                       deliverydate = ?,
                       serialnumber = ?,
                       notes = ?
                      WHERE id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{id},               $form->{"id_$i"},
                $form->{"description_$i"}, $form->{"qty_$i"},
                $form->{"sellprice_$i"},   $decimalplaces,
                $fxsellprice,              $form->{"discount_$i"},
                $allocated,                $form->{"unit_$i"},
                $form->{"deliverydate_$i"},
                $form->{"serialnumber_$i"}, $form->{"notes_$i"},
                $invoice_id
            ) || $form->dberror($query);

            if ($form->{batch_id}){
                $sth = $dbh->prepare(
                   'INSERT INTO voucher (batch_id, trans_id, batch_class)
                    VALUES (?, ?, ?)');
                $sth->execute($form->{batch_id}, $form->{id}, BC_SALES_INVOICE);
            }

            for my $cls(@{$form->{bu_class}}){
                if ($form->{"b_unit_$cls->{id}_$i"}){
                 $b_unit_sth->execute($cls->{id}, $form->{"b_unit_$cls->{id}_$i"});
                }
            }
       my $report=($taxformfound and $form->{"taxformcheck_$i"})?"true":"false";

       IS->update_invoice_tax_form($form,$dbh,$invoice_id,$report);


            if (defined $form->{approved}) {

                $query = qq| UPDATE ar SET approved = ? WHERE id = ?|;
                $dbh->prepare($query)->execute($form->{approved}, $form->{id})
                     || $form->dberror($query);
                if (!$form->{approved}){
                    if (not defined $form->{batch_id}){
                       $form->error('Batch ID Missing');
                   }
                   $query = qq|
            INSERT INTO voucher (batch_id, trans_id) VALUES (?, ?)|;
                   $sth = $dbh->prepare($query);
                   $sth->execute($form->{batch_id}, $form->{id}) ||
                        $form->dberror($query);
               }
            }

            # add invoice_id
            $form->{acc_trans}{lineitems}[$ndx]->{invoice_id} = $invoice_id;

        }
    }

    $form->{paid} = 0;
    foreach my $i ( 1 .. $form->{paidaccounts} ) {
        $form->{"paid_$i"} =
          $form->parse_amount( $myconfig, $form->{"paid_$i"} )->bstr();
        $form->{paid} += $form->{"paid_$i"};
        $form->{datepaid} = $form->{"datepaid_$i"}
          if ( $form->{"paid_$i"} );
    }

    # add lineitems + tax
    $amount        = 0;
    $grossamount   = 0;
    $fxgrossamount = 0;

    for ( @{ $form->{acc_trans}{lineitems} } ) {
        $amount        += $_->{amount};
        $grossamount   += $_->{grossamount};
        $fxgrossamount += $_->{fxgrossamount};
    }
    $invnetamount = $amount;

    $amount = 0;
    for ( split / /, $form->{taxaccounts} ) {
        $amount += $form->{acc_trans}{ $form->{id} }{$_}{amount} =
          $form->round_amount( $form->{acc_trans}{ $form->{id} }{$_}{amount},
            2 );
    }
    $invamount = $invnetamount + $amount;

    $diff = 0;

    if ( $form->{taxincluded} ) {
        $diff = $form->round_amount( $grossamount - $invamount, 2 );
        $invamount += $diff;
    }
    $fxdiff = $form->round_amount( $fxdiff, 2 );
    $invnetamount += $fxdiff;
    $invamount    += $fxdiff;

    if ( $form->round_amount( $form->{paid} - $fxgrossamount, 2 ) == 0 ) {
        $form->{paid} = $invamount;
    }
    else {
        $form->{paid} =
          $form->round_amount( $form->{paid} * $form->{exchangerate}, 2 );
    }

    $b_unit_sth = $dbh->prepare(
         "INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
          VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
    );

    foreach my $ref ( sort { $b->{amount} <=> $a->{amount} }
        @{ $form->{acc_trans}{lineitems} } )
    {
        $diff ||= 0;
        $ref->{fxdiff} ||= 0;

        $amount = $ref->{amount} + $diff; # Subtracting included taxes

        $query  = qq|
            INSERT INTO acc_trans
                        (trans_id, chart_id, amount,
                        transdate, invoice_id, fx_transaction)
                 VALUES (?, ?, ?, ?, ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id}, $ref->{chart_id}, $amount - $ref->{fxdiff},
            $form->{transdate}, $ref->{invoice_id}, 0)
          || $form->dberror($query);
        $sth->execute( $form->{id}, $ref->{chart_id}, $ref->{fxdiff},
            $form->{transdate}, $ref->{invoice_id}, 1)
          || $form->dberror($query);
        $diff   = 0;
        $fxdiff = 0;
        for my $cls(@{$form->{bu_class}}){
            if ($form->{"b_unit_$cls->{id}_$i"}){
               $b_unit_sth->execute($cls->{id}, $form->{"b_unit_$cls->{id}_$i"});
            }
        }
    }

    $form->{receivables} = $invamount * -1;

    delete $form->{acc_trans}{lineitems};

    if ($form->{manual_tax}){
        my $ac_sth = $dbh->prepare(
              "INSERT INTO acc_trans (chart_id, trans_id, amount, source, memo)
                    VALUES ((select id from account where accno = ?),
                            ?, ?, ?, ?)"
        );
        my $tax_sth = $dbh->prepare(
              "INSERT INTO tax_extended (entry_id, tax_basis, rate)
                    VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
        );
        foreach my $taccno (split / /, $form->{taxaccounts}){
            my $taxamount;
            my $taxbasis;
            my $taxrate;
            my $fx = $form->{exchangerate} || 1;
            $taxamount = $form->parse_amount($myconfig,
                                             $form->{"mt_amount_$taccno"});
            $taxbasis = $form->parse_amount($myconfig,
                                            $form->{"mt_basis_$taccno"});
            $taxrate = $form->parse_amount($myconfig,
                                           $form->{"mt_rate_$taccno"});
            my $fx_taxamount = $taxamount * $fx;
            my $fx_taxbasis = $taxbasis * $fx;
            $form->{receivables} -= $fx_taxamount;
            $invamount += $fx_taxamount;
            $ac_sth->execute($taccno, $form->{id}, $fx_taxamount,
                             $form->{"mt_ref_$taccno"},
                             $form->{"mt_desc_$taccno"})
                || $form->dberror();
            $tax_sth->execute($fx_taxbasis, $taxrate)
                || $form->dberror();
        }
        $ac_sth->finish;
        $tax_sth->finish;
    }

    # update exchangerate
    if ( ( $form->{currency} ne $form->{defaultcurrency} ) && !$exchangerate ) {
        $form->update_exchangerate( $dbh, $form->{currency}, $form->{transdate},
            $form->{exchangerate}, 0 );
    }

    # record receivable
    if ( $form->{receivables} ) {
        ($accno) = split /--/, $form->{AR};

        $query = qq|
            INSERT INTO acc_trans
                        (trans_id, chart_id, amount, transdate,
                                    fx_transaction)
                 VALUES (?, (SELECT id FROM account WHERE accno = ?),
                        ?, ?, ?)|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id}, $accno, $form->{receivables} / $form->{exchangerate},
            $form->{transdate}, 0)
          || $form->dberror($query);
        $sth->execute( $form->{id}, $accno, $form->{receivables} -
               $form->{receivables} / $form->{exchangerate},
               $form->{transdate}, 1) || $form->dberror($query);
    }

    foreach my $trans_id ( keys %{ $form->{acc_trans} } ) {
        foreach my $accno ( keys %{ $form->{acc_trans}{$trans_id} } ) {
            $amount =
              $form->round_amount(
                $form->{acc_trans}{$trans_id}{$accno}{amount}, 2 );
            if ($amount) {

                $query = qq|
                    INSERT INTO acc_trans
                                (trans_id, chart_id, amount,
                                transdate)
                    VALUES (?, (SELECT id FROM account
                                 WHERE accno = ?),
                           ?, ?)|;

                $sth = $dbh->prepare($query);
                $sth->execute( $trans_id, $accno, $amount, $form->{transdate} )
                  || $form->dberror($query);
            }
        }
    }

    # if there is no amount but a payment record receivable
    if ( $invamount == 0 ) {
        $form->{receivables} = 1;
    }

    my $cleared = 0;

    # record payments and offsetting AR
    foreach my $i ( 1 .. $form->{paidaccounts} ) {

        if ( $form->{"paid_$i"} ) {
            my ($accno) = split /--/, $form->{"AR_paid_$i"};
            $form->{"datepaid_$i"} = $form->{transdate}
              unless ( $form->{"datepaid_$i"} );

            $form->{datepaid} = $form->{"datepaid_$i"};

            $exchangerate = 0;

            if ( $form->{currency} eq $form->{defaultcurrency} ) {
                $form->{"exchangerate_$i"} = 1;
            }
            else {
                $exchangerate =
                  $form->check_exchangerate( $myconfig, $form->{currency},
                    $form->{"datepaid_$i"}, 'buy' );

                $form->{"exchangerate_$i"} =
                  ($exchangerate)
                  ? $exchangerate
                  : $form->parse_amount( $myconfig,
                    $form->{"exchangerate_$i"} );
            }

            # record AR
            $amount =
              $form->round_amount( $form->{"paid_$i"} * $form->{exchangerate},
                2 );

            if ( $form->{receivables} ) {
                $query = qq|
                    INSERT INTO acc_trans
                                (trans_id, chart_id, amount,
                                transdate)
                         VALUES (?, (SELECT id FROM account
                                      WHERE accno = ?),
                                ?, ?)|;
                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id}, $form->{AR}, $amount,
                    $form->{"datepaid_$i"} )
                  || $form->dberror($query);
            }

            # record payment
            $amount = $form->{"paid_$i"} * -1;
            if ($keepcleared) {
                $cleared = ( $form->{"cleared_$i"} ) ? 1 : 0;
            }

            $query = qq|
                INSERT INTO acc_trans
                            (trans_id, chart_id, amount,
                            transdate, source, memo, cleared)
                               VALUES (?, (SELECT id FROM account
                                           WHERE accno = ?),
                              ?, ?, ?, ?, ?)|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id}, $accno, $amount, $form->{"datepaid_$i"},
                $form->{"source_$i"}, $form->{"memo_$i"}, $cleared )
              || $form->dberror($query);

            # exchangerate difference
            $amount = $form->round_amount(
                (
                    $form->round_amount(
                        $form->{"paid_$i"} * $form->{"exchangerate_$i"} -
                          $form->{"paid_$i"},
                        2
                    )
                ) * -1,
                2
            );

            if ($amount) {
                $query = qq|
                    INSERT INTO acc_trans
                                (trans_id, chart_id, amount,
                                transdate, source,
                                fx_transaction, cleared)
                         VALUES (?, (SELECT id FROM account
                                       WHERE accno = >),
                                ?, ?, ?, '1', ?)|;

                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id}, $accno, $amount,
                    $form->{"datepaid_$i"},
                    $form->{"source_$i"}, $cleared )
                  || $form->dberror($query);
            }

            # gain/loss
            $amount = $form->round_amount(
                (
                    $form->round_amount(
                        $form->{"paid_$i"} * $form->{exchangerate}, 2 ) -
                      $form->round_amount(
                        $form->{"paid_$i"} * $form->{"exchangerate_$i"}, 2
                      )
                ) * -1,
                2
            );

            if ($amount) {
                my $accno_id =
                  ( $amount > 0 )
                  ? $fxgain_accno_id
                  : $fxloss_accno_id;

                $query = qq|
                    INSERT INTO acc_trans (
                                trans_id, chart_id, amount,
                                transdate, fx_transaction,
                                cleared)
                         VALUES (?, ?, ?, ?, '1', ?)|;

                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id}, $accno_id, $amount,
                    $form->{"datepaid_$i"}, $cleared )
                  || $form->dberror($query);
            }

            # update exchange rate
            if ( ( $form->{currency} ne $form->{defaultcurrency} )
                && !$exchangerate )
            {

                $form->update_exchangerate(
                    $dbh, $form->{currency},
                    $form->{"datepaid_$i"},
                    $form->{"exchangerate_$i"}, 0
                );
            }
        }
    }

    # set values which could be empty to 0
    $form->{terms}       *= 1;
    $form->{taxincluded} *= 1;


    my $approved = 1;
    $approved = 0 if $form->{separate_duties};
    # save AR record
    $query = qq|
        UPDATE ar set
               invnumber = ?,
               ordnumber = ?,
               quonumber = ?,
                       description = ?,
               transdate = ?,
               entity_credit_account = ?,
               amount = ?,
               netamount = ?,
               duedate = ?,
               invoice = '1',
               shippingpoint = ?,
               shipvia = ?,
               terms = ?,
               notes = ?,
               intnotes = ?,
               taxincluded = ?,
               curr = ?,
               person_id = ?,
               till = ?,
               language_code = ?,
               ponumber = ?,
                       approved = ?,
               crdate = ?,
                       reverse = ?,
                       is_return = ?,
                       setting_sequence = ?
         WHERE id = ?
             |;
    $sth = $dbh->prepare($query);
    $sth->execute(
        $form->{invnumber},     $form->{ordnumber},
        $form->{quonumber},     $form->{description},
        $form->{transdate} || 'now',
        $form->{customer_id},   $invamount,
        $invnetamount,
        $form->{duedate} || 'now',
        $form->{shippingpoint}, $form->{shipvia},
        $form->{terms},         $form->{notes},
        $form->{intnotes},      $form->{taxincluded},
        $form->{currency},
        $form->{employee_id},   $form->{till},
        $form->{language_code}, $form->{ponumber}, $approved,
        $form->{crdate} || 'today', $form->{reverse},
        $form->{is_return},     $form->{setting_sequence},
        $form->{id}
    ) || $form->dberror($query);

    # add shipto
    $form->{name} = $form->{customer};
    $form->{name} =~ s/--$form->{customer_id}//;
    $form->add_shipto($form->{id});

    # save printed, emailed and queued
    $form->save_status($dbh);

    if (!$form->{separate_duties}){
        $self->add_cogs($form);
    }

    return 1;
}

sub retrieve_invoice {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query;

    if ( $form->{id} ) {

        # get default accounts and last invoice number
        $query = qq|
            SELECT value AS currencies FROM defaults
             WHERE setting_key = 'curr'|;
    }
    else {
        $query = qq|
            SELECT value AS currencies, current_date AS transdate
              FROM defaults
             WHERE setting_key = 'curr'|;
    }
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    if ( $form->{id} ) {

        # retrieve invoice
        #HV TODO drop entity_id from ar
        $query = qq|
               SELECT a.invnumber, a.ordnumber, a.quonumber,
                      a.transdate,
                      a.shippingpoint, a.shipvia, a.terms, a.notes,
                      a.intnotes,
                      a.duedate, a.taxincluded, a.curr AS currency,
                      a.person_id, e.name AS employee, a.till,
                      a.reverse, a.entity_credit_account as customer_id,
                      a.language_code, a.ponumber, a.crdate,
                      a.on_hold, a.description, a.setting_sequence
                 FROM ar a
            LEFT JOIN entity_employee em ON (em.entity_id = a.person_id)
            LEFT JOIN entity e ON e.id = em.entity_id
                WHERE a.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        $form->db_parse_numeric(sth=> $sth, hashref=>$ref_);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        my $tax_sth = $dbh->prepare(
                  qq| SELECT amount, source, memo, tax_basis, rate, accno
                        FROM acc_trans ac
                        JOIN tax_extended t USING(entry_id)
                        JOIN account c ON c.id = ac.chart_id
                       WHERE ac.trans_id = ?|);
        $tax_sth->execute($form->{id});
        while (my $taxref = $tax_sth->fetchrow_hashref('NAME_lc')){
              $form->{manual_tax} = 1;
              my $taccno = $taxref->{accno};
              $form->{"mt_amount_$taccno"} = $taxref->{amount};
              $form->{"mt_rate_$taccno"}  = $taxref->{rate};
              $form->{"mt_basis_$taccno"} = $taxref->{tax_basis};
              $form->{"mt_memo_$taccno"}  = $taxref->{memo};
              $form->{"mt_ref_$taccno"}  = $taxref->{source};
        }


        # get shipto
        $query = qq|SELECT ns.*, l.* FROM new_shipto ns JOIN location l ON ns.location_id = l.id WHERE ns.trans_id = ?|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        $ref->{locationid} = $ref->{id};
        delete $ref->{id};
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} unless $_ eq 'id' };
        $sth->finish;

        # retrieve individual items
        $query = qq|
               SELECT i.id as invoice_id,i.description, i.qty, i.fxsellprice,
                      i.sellprice, i.precision, i.discount,
                                  i.parts_id AS id,
                      i.unit, i.deliverydate,
                      i.serialnumber, i.notes,
                      p.partnumber, p.assembly, p.bin,
                      pg.partsgroup, p.partsgroup_id,
                      p.partnumber AS sku, p.listprice, p.lastcost,
                      p.weight, p.onhand, p.inventory_accno_id,
                      p.income_accno_id, p.expense_accno_id,
                      t.description AS partsgrouptranslation,
                                  p.image
                 FROM invoice i
                     JOIN parts p ON (i.parts_id = p.id)
            LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
            LEFT JOIN translation t
                      ON (t.trans_id = p.partsgroup_id
                      AND t.language_code
                      = ?)
                WHERE i.trans_id = ?
                      AND NOT i.assemblyitem = '1'
             ORDER BY i.id|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{language_code}, $form->{id} )
          || $form->dberror($query);


        my $bu_sth = $dbh->prepare(
            qq|SELECT * FROM business_unit_inv
                WHERE entry_id = ?  |
        );


        # foreign currency
        &exchangerate_defaults( $dbh, $form );

        # query for price matrix
        my $pmh = PriceMatrix::price_matrix_query( $dbh, $form );

        # taxes
        $query = qq|
            SELECT c.accno
              FROM account c
              JOIN partstax pt ON (pt.chart_id = c.id)
             WHERE pt.parts_id = ?|;
        my $tth = $dbh->prepare($query) || $form->dberror($query);

        my $taxrate;
        my $ptref;

        my $c = 0;
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $c++;
            PriceMatrix::price_matrix( $pmh, $ref, $form->{transdate},
                $decimalplaces, $form, $myconfig );
            $form->db_parse_numeric(sth=>$sth, hashref => $ref);
            $ref->{qty} *= -1 if $form->{reverse};
            my ($dec) = ( $ref->{fxsellprice} =~ /\.(\d+)/ );
            $dec = length $dec;
            my $decimalplaces = ( $dec > 2 ) ? $dec : 2;

            $bu_sth->execute($ref->{invoice_id});
            while ( $buref = $bu_sth->fetchrow_hashref(NAME_lc) ) {
                $ref->{"b_unit_$buref->{class_id}"} = $buref->{bu_id};
            }

            $tth->execute( $ref->{id} );

            $ref->{taxaccounts} = "";
            $taxrate = 0;

            while ( $ptref = $tth->fetchrow_hashref(NAME_lc) ) {
                $ref->{taxaccounts} .= "$ptref->{accno} ";
                $taxrate += $form->{"$ptref->{accno}_rate"};
            }
            $tth->finish;
            chop $ref->{taxaccounts};

            # price matrix
            $ref->{sellprice} =
              ( $ref->{fxsellprice} * $form->{ $form->{currency} } );
            $ref->{sellprice} = $ref->{fxsellprice};

            $ref->{number} = $ref->{partnumber};
            $ref->{partsgroup} = $ref->{partsgrouptranslation}
              if $ref->{partsgrouptranslation};

            push @{ $form->{invoice_details} }, $ref;
            $form->{"id_$c"} = $ref->{id};
            $form->{"qty_$c"} = $ref->{qty};
        }
        $form->{rowcount} = scalar( @{ $form->{invoice_details} } ) + 1;

        $sth->finish;
    }

}

sub retrieve_item {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};
    $form->{item_list} = [];

    my $i = $form->{rowcount};
    my $null;
    my $var;

    my $where = "WHERE p.obsolete = '0' AND NOT p.income_accno_id IS NULL";

    if ( $form->{"partnumber_$i"} ne "" ) {
        $var = $dbh->quote( $form->{"partnumber_$i"} );
        $where .= " AND (p.partnumber = $var or mm.barcode is not null)";
    }

    if ( $form->{"partsgroup_$i"} ne "" ) {
        ( $null, $var ) = split /--/, $form->{"partsgroup_$i"};
        if ( ! $var ) {

            # search by partsgroup, this is for the POS
            $where .=
              qq| AND pg.partsgroup = |
              . $dbh->quote( $form->{"partsgroup_$i"} );
        }
        else {
            $var = $dbh->quote($var);
            $where .= qq| AND p.partsgroup_id = $var|;
        }
    }

    my $query = qq|
           SELECT p.id, p.partnumber, p.description, p.sellprice,
              p.listprice, p.lastcost, p.unit, p.assembly, p.bin,
                  p.onhand, p.notes, p.inventory_accno_id,
                  p.income_accno_id, p.expense_accno_id, pg.partsgroup,
                  p.partsgroup_id, p.partnumber AS sku, p.weight,
                  t1.description AS translation,
                  t2.description AS grouptranslation, p.image
                     FROM parts p
                LEFT JOIN makemodel mm ON (mm.parts_id = p.id AND mm.barcode = |
                             . $dbh->quote($form->{"partnumber_$i"}) . qq|)
        LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
        LEFT JOIN translation t1
                  ON (t1.trans_id = p.id AND t1.language_code = ?)
        LEFT JOIN translation t2
                  ON (t2.trans_id = p.partsgroup_id
                  AND t2.language_code = ?)
             $where
         ORDER BY 2|;
    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{language_code}, $form->{language_code} )
      || $form->dberror($query);

    my $ref;
    my $ptref;

    # setup exchange rates
    &exchangerate_defaults( $dbh, $form );

    # taxes
    $query = qq|
        SELECT c.accno
          FROM account c
          JOIN partstax pt ON (c.id = pt.chart_id)
         WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);

    # price matrix
    my $pmh = PriceMatrix::price_matrix_query( $dbh, $form );

    my $transdate = $form->datetonum( $myconfig, $form->{transdate} );

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        PriceMatrix::price_matrix( $pmh, $ref, $transdate, $decimalplaces,
            $form, $myconfig );
        $form->db_parse_numeric(sth => $sth, hashref => $ref);

        my ($dec) = ( $ref->{sellprice} =~ /\.(\d+)/ );
        $dec = length $dec;
        my $decimalplaces = ( $dec > 2 ) ? $dec : 2;

        # get taxes for part
        $tth->execute( $ref->{id} );

        $ref->{taxaccounts} = "";

        while ( $ptref = $tth->fetchrow_hashref(NAME_lc) ) {
            $ref->{taxaccounts} .= "$ptref->{accno} ";
        }
        $tth->finish;
        chop $ref->{taxaccounts};

        # get matrix

        $ref->{description} = $ref->{translation}
          if $ref->{translation};

        $ref->{partsgroup} = $ref->{grouptranslation}
          if $ref->{grouptranslation};

        push @{ $form->{item_list} }, $ref;

    }

    $sth->finish;

}

sub exchangerate_defaults {
    my ( $dbh2, $form ) = @_;
    $dbh = $form->{dbh};

    my $var;

    # get default currencies
    my $query = qq|
        SELECT substr(value,1,3), value FROM defaults
         WHERE setting_key = 'curr'|;
    my $eth = $dbh->prepare($query) || $form->dberror($query);
    $eth->execute;
    ( $form->{defaultcurrency}, $form->{currencies} ) = $eth->fetchrow_array;
    $eth->finish;

    $query = qq|
        SELECT buy
          FROM exchangerate
         WHERE curr = ?
               AND transdate = ?|;
    my $eth1 = $dbh->prepare($query) || $form->dberror($query);

    $query = qq/
        SELECT max(transdate || ' ' || buy || ' ' || curr)
          FROM exchangerate
         WHERE curr = ?/;
    my $eth2 = $dbh->prepare($query) || $form->dberror($query);

    # get exchange rates for transdate or max
    foreach my $var ( split /:/, substr( $form->{currencies}, 4 ) ) {  ## no critic (ProhibitMagicNumbers) sniff
        $eth1->execute( $var, $form->{transdate} );
        ( $form->{$var} ) = $eth1->fetchrow_array;

        if ( !$form->{$var} ) {
            $eth2->execute($var);

            ( $form->{$var} ) = $eth2->fetchrow_array;
            ( $null, $form->{$var} ) = split / /, $form->{$var};
            $form->{$var} = 1 unless $form->{$var};
            $eth2->finish;
        }
        $eth1->finish;
    }

    $form->{ $form->{currency} } = $form->{exchangerate}
      if $form->{exchangerate};
    $form->{ $form->{currency} } ||= 1;
    $form->{ $form->{defaultcurrency} } = 1;

}

=pod

=cut

sub toggle_on_hold {

    my $self = shift @_;
    my $form = shift @_;

    if ($form->{id}) { # it's an existing (.. probably) invoice.

        my $dbh = $form->{dbh};

        $sth = $dbh->prepare("update ar set on_hold = not on_hold where ar.id = ?");
        my $code = $sth->execute($form->{id});

        return 1;

    } else { # This shouldn't even be possible, but check for it anyway.

        # Definitely, DEFINITELY check it.
        # happily return 0. Find out about proper error states.
        return 0;
    }
}


sub list_locations_contacts
{

    my ( $self, $myconfig, $form ) = @_;



    my $dbh = $form->{dbh};

    # get rest for the customer
    my $query = qq|
                    WITH eca AS (select * from entity_credit_account
                                  where id = ?
                    )
            select  id as locationid,line_one as shiptoaddress1,line_two as shiptoaddress2,line_three as shiptoaddress3,city as shiptocity,
                state as shiptostate,mail_code as shiptozipcode,country as shiptocountry
            from (
                            select (eca__list_locations(id)).*
                              FROM eca
                             UNION
                            SELECT (entity__list_locations(entity_id)).*
                              FROM eca
                        ) l
                         WHERE location_class = 3;
          |;



    my $sth = $dbh->prepare($query);

    $sth->execute( $form->{customer_id} ) || $form->dberror($query);

    my $i=0;

    while($ref = $sth->fetchrow_hashref(NAME_lc))
    {
           $i++;
           for ( keys %$ref )
       {
         $form->{"$_\_$i"} = $ref->{$_};
       }

    }

    $form->{totallocations}=$i;

    $sth->finish();






    $query = qq|
            select c.class as shiptotype,ec.contact as shiptocontact,ec.description as shiptodescription
            from eca_to_contact ec
            join contact_class c on(c.id=ec.contact_class_id)
            where ec.credit_id=?;
          |;



    $sth = $dbh->prepare($query);

    $sth->execute( $form->{customer_id} ) || $form->dberror($query);

    $i=0;

    while($ref = $sth->fetchrow_hashref(NAME_lc))
    {
           $i++;
           for ( keys %$ref )
       {
         $form->{"$_\_$i"} = $ref->{$_};
       }

    }

    $form->{totalcontacts}=$i;

    $sth->finish();

    # for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
}


sub construct_countrys
{


    my ( $self,$form ) = @_;

    my $dbh = $form->{dbh};


    my $query = qq|
            select id,short_name  from location_list_country();
          |;



    my $sth = $dbh->prepare($query);

    $sth->execute() || $form->dberror($query);

    my $returnvalue=qq|<option value="">null</option>|;

    while(my $ref = $sth->fetchrow_hashref(NAME_lc))
    {

      $returnvalue.=qq|<option value="$ref->{id} ">$ref->{short_name}</option>|;

    }


   $sth->finish();

   return($returnvalue);

}


sub construct_types
{


    my ( $self,$form ) = @_;

    my $dbh = $form->{dbh};


    my $query = qq|
            select id,class from contact_class;
          |;



    my $sth = $dbh->prepare($query);

    $sth->execute() || $form->dberror($query);

    my $returnvalue=qq|<option value="">null</option>|;

    while(my $ref = $sth->fetchrow_hashref(NAME_lc))
    {

      $returnvalue.=qq|<option value="$ref->{id} ">|.substr($ref->{class},0,3).qq|</option>|;  ## no critic (ProhibitMagicNumbers) sniff

    }


   $sth->finish();

   return($returnvalue);

}


sub createlocation
{


  my ( $self,$form ) = @_;

  my $dbh=$form->{dbh};

  my $query="select * from eca__location_save(?,?,?,?,?,?,?,?,?,?, null);";

  my $sth=$dbh->prepare("$query");

   $sth->execute($form->{"customer_id"},
         undef,
         3,  ## no critic (ProhibitMagicNumbers) sniff
         $form->{"shiptoaddress1_new"},
         $form->{"shiptoaddress2_new"},
         $form->{"shiptoaddress3_new"},
         $form->{"shiptocity_new"},
         $form->{"shiptostate_new"},
         $form->{"shiptozipcode_new"},
         $form->{"shiptocountry_new"}
            ) || $form->dberror($query);
  my ($l_id) = $sth->fetchrow_array;
  $sth->finish();
  return $l_id;
}



sub createcontact
{

  my ( $self,$form ) = @_;

  my $dbh=$form->{dbh};

  my $query="select * from eca__save_contact(?,?,?,?,?,?);";

  my $sth=$dbh->prepare("$query");

  $sth->execute($form->{"customer_id"},$form->{"shiptotype_new"},$form->{"shiptodescription_new"},$form->{"shiptocontact_new"},$form->{"shiptocontact_new"},$form->{"shiptotype_new"}) || $form->dberror($query);

  $sth->finish();

}




sub taxform_exist
{

   my ( $self,$form,$customer_id) = @_;

   my $query = "select taxform_id from entity_credit_account where id=?";

   my $sth = $form->{dbh}->prepare($query);

   $sth->execute($customer_id) || $form->dberror($query);

   my $retval=0;

   while(my $val=$sth->fetchrow())
   {
        $retval=1;
   }

   return $retval;


}


sub update_invoice_tax_form
{

   my ( $self,$form,$dbh,$invoice_id,$report) = @_;

   my $query=qq|select count(*) from invoice_tax_form where invoice_id=?|;
   my $sth=$dbh->prepare($query);
   $sth->execute($invoice_id) ||  $form->dberror($query);

   my $found=0;

   while(my $ret1=$sth->fetchrow())
   {
      $found=1;

   }

   if($found)
   {
      my $query = qq|update invoice_tax_form set reportable=? where invoice_id=?|;
          my $sth = $dbh->prepare($query);
          $sth->execute($report,$invoice_id) || $form->dberror($query);
   }
  else
   {
          my $query = qq|insert into invoice_tax_form(invoice_id,reportable) values(?,?)|;
          my $sth = $dbh->prepare($query);
          $sth->execute($invoice_id,$report) || $form->dberror("$query");
   }

}


sub get_taxcheck
{

   my ( $self,$form,$invoice_id,$dbh) = @_;

   my $query=qq|select reportable from invoice_tax_form where invoice_id=?|;
   my $sth=$dbh->prepare($query);
   $sth->execute($invoice_id) ||  $form->dberror($query);

   my $found=0;

   while(my $ret1=$sth->fetchrow())
   {

      if($ret1 eq "t" || $ret1)   # this if is not required because when reportable is false, control would not come inside while itself.
      { $found=1;  }

   }

   return($found);

}

=back

=cut

1;


