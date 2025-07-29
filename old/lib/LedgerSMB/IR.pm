=head1 NAME

LedgerSMB::IR - Inventory received module

=cut

#=====================================================================
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
# Inventory received module
#
#======================================================================

package IR;
use LedgerSMB::Tax;
use LedgerSMB::PriceMatrix;
use LedgerSMB::Setting;
use LedgerSMB::PGNumber;
use LedgerSMB::IIAA;

use LedgerSMB::Magic qw(BC_VENDOR_INVOICE);

use Workflow::Context;

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

sub post_invoice {
    my ( $self, $myconfig, $form ) = @_;
    $form->{crdate} ||= 'now';
    delete $form->{reverse} unless $form->{reverse};

    $form->all_business_units;

    my $dbh = $form->{dbh};
    $form->{invnumber} = $form->update_defaults( $myconfig, "vinumber", $dbh )
      if $form->should_update_defaults('invnumber');

    for ( 1 .. $form->{rowcount} ) {
        $form->{"qty_$_"} *= -1 if $form->{reverse};
        unless ( $form->{"deliverydate_$_"} ) {
            $form->{"deliverydate_$_"} = $form->{transdate};
        }

    }
    my $query;
    my $sth;
    my $ref;
    my $null;
    my $exchangerate = 0;
    my $taxrate;
    my $diff = 0;
    my $item;
    my $invoice_id;
    my $fxdiff = 0;

    $form->{acc_trans} = ();


    ( $null, $form->{employee_id} ) = split /--/, $form->{employee}
        if $form->{employee};

    unless ( $form->{employee_id} ) {
        ( $form->{employee}, $form->{employee_id} ) = $form->get_employee;
    }

    $form->{department_id} = 0;
    ( $null, $form->{department_id} ) = split( /--/, $form->{department} )
        if $form->{department};
    $form->{department_id} *= 1;

    $query = qq|
        SELECT inventory_accno_id, income_accno_id, expense_accno_id
          FROM parts
         WHERE id = ?|;

    my $pth = $dbh->prepare($query) || $form->dberror($query);

    my %updparts = ();

    # check if id really exists
    if ( $form->{id} ) {
        # delete detail records
        $query = qq|SELECT draft__delete_lines(?)|;
        $dbh->do($query, {}, $form->{id}) || $form->dberror($query);
    }
    else {
        my $uid = localtime;
        $uid .= "$$";

        $query = qq|
            INSERT INTO ap (invnumber, person_id, entity_credit_account)
                 VALUES ('$uid', ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{employee_id}, $form->{vendor_id}) || $form->dberror($query);

        $query = qq|SELECT id FROM ap WHERE invnumber = '$uid'|;
        $sth   = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        ( $form->{id} ) = $sth->fetchrow_array;

        $query = q|UPDATE transactions SET workflow_id = ?, reversing = ? WHERE id = ? AND workflow_id IS NULL|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{workflow_id}, $form->{reversing}, $form->{id} )
            || $form->dberror($query);
    }

    my $amount;
    my $grossamount;
    my $invamount    = 0;
    my $invnetamount = 0;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        $form->{exchangerate} = 1;
    }
    else {
        $exchangerate = "";
    }
    $form->{exchangerate} = $form->parse_amount( $myconfig, $form->{exchangerate} );


    my $taxformfound=IR->taxform_exist($form,$form->{"vendor_id"});#tshvr this always returns true!!

    my $b_unit_sth = $dbh->prepare(
         "INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
          VALUES (currval('invoice_id_seq'), ?, ?)"
    );

    my $b_unit_sth_ac = $dbh->prepare(
         "INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
          VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
    );

    for my $i ( 1 .. $form->{rowcount} ) {
        $form->{"qty_$i"} = $form->parse_amount( $myconfig, $form->{"qty_$i"} );

        if ( $form->{"qty_$i"} ) {

            $pth->execute( $form->{"id_$i"} );
            $ref = $pth->fetchrow_hashref(NAME_lc);
            for ( keys %$ref ) {
                $form->{"${_}_$i"} = $ref->{$_};
            }
            $pth->finish;

            # undo discount formatting
            $form->{"discount_$i"} =
              $form->parse_amount( $myconfig, $form->{"discount_$i"} ) / 100;

            # keep entered selling price
            my $fxsellprice =
              $form->parse_amount( $myconfig, $form->{"sellprice_$i"} );

            my ($dec) = ( $fxsellprice =~ /\.(\d+)/ );
            # deduct discount
            my $moneyplaces = LedgerSMB::Setting->new(%$form)->get('decimal_places');
            $decimalplaces = ($form->{"precision_$i"} && $form->{"precision_$i"} > $moneyplaces)
                             ? $form->{"precision_$i"}
                             : $moneyplaces;
            $form->{"sellprice_$i"} = $fxsellprice -
              $form->round_amount( $fxsellprice * $form->{"discount_$i"},
                $decimalplaces );

            # linetotal
            my $fxlinetotal =
              $form->round_amount( $form->{"sellprice_$i"} * $form->{"qty_$i"},
                $moneyplaces );

            $amount = $fxlinetotal * $form->{exchangerate};
            my $linetotal = $form->round_amount( $amount, $moneyplaces );
            $fxdiff += $amount - $linetotal;

            if (!$form->{manual_tax}){
                @taxaccounts = Tax::init_taxes(
                    $form,
                    $form->{"taxaccounts_$i"},
                    $form->{'taxaccounts'}
                );

                $tax   = LedgerSMB::PGNumber->bzero();
                $fxtax = LedgerSMB::PGNumber->bzero();

                if ( $form->{taxincluded} ) {
                    $tax += $amount =
                      Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 1 );

                    $form->{"sellprice_$i"} -= $amount / $form->{"qty_$i"};
                }
                else {
                    $tax += $amount =
                      Tax::calculate_taxes( \@taxaccounts, $form, $linetotal, 0 );

                    $fxtax +=
                      Tax::calculate_taxes( \@taxaccounts, $form, $fxlinetotal, 0 );
                }

                for (@taxaccounts) {
                    $form->{acc_trans}{ $form->{id} }{ $_->account }{amount} +=
                      $_->value;
                }
            }
            $grossamount = $form->round_amount( $linetotal, $moneyplaces );

            if ( $form->{taxincluded} ) {
                $amount = $form->round_amount( $tax, $moneyplaces );
                $linetotal -= $form->round_amount( $tax - $diff, $moneyplaces );
                $diff = ( $amount - $tax );
            }

            $amount = $form->round_amount( $linetotal, $moneyplaces );

            # adjust and round sellprice
            $form->{"sellprice_$i"} =
              $form->round_amount(
                $form->{"sellprice_$i"} * $form->{exchangerate},
                $decimalplaces );

            # save detail record in invoice table
            $query = qq|
                INSERT INTO invoice (
                         trans_id, parts_id, description, qty, sellprice,
                         fxsellprice, discount, allocated, unit,
                         deliverydate, serialnumber, precision, notes, vendor_sku)
                       VALUES (
                         ?, ?, ?, ?, ?,
                         ?, ?, ?, ?,
                         ?, ?, ?, ?, ?)
                RETURNING id
                |;
            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{id},               $form->{"id_$i"},
                $form->{"description_$i"}, $form->{"qty_$i"} * -1,
                $form->{"sellprice_$i"},   $fxsellprice,
                $form->{"discount_$i"},    0,
                $form->{"unit_$i"},        $form->{"deliverydate_$i"},
                $form->{"serialnumber_$i"},
                $form->{"precision_$i"},   $form->{"notes_$i"},
                $form->{"partnumber_$i"},
            ) || $form->dberror($query);
            ($invoice_id) = $sth->fetchrow_array();

            for my $cls(@{$form->{bu_class}}){
                if ($form->{"b_unit_$cls->{id}_$i"}){
                 $b_unit_sth->execute($cls->{id}, $form->{"b_unit_$cls->{id}_$i"});
                }
            }

            if($taxformfound)
            {
             my $report=$form->{"taxformcheck_$i"}?"true":"false";
             IR->update_invoice_tax_form($form,$dbh,$invoice_id,$report);
            }

            if (defined $form->{approved}) {

                $query = qq| UPDATE ap SET approved = ? WHERE id = ?|;
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

            if ( $form->{"inventory_accno_id_$i"} ) {
                my $totalqty = $form->{"qty_$i"};

                # add purchase to inventory
                push @{ $form->{acc_trans}{lineitems} },
                {
                    row_num       => $i,
                    chart_id      => $form->{"inventory_accno_id_$i"},
                    amount        => $amount,
                    fxlinetotal   => $fxlinetotal,
                    fxgrossamount => $fxlinetotal +
                      $form->round_amount( $fxtax, 2 ),
                    grossamount => $grossamount,
                    invoice_id  => $invoice_id
                  };

                $updparts{ $form->{"id_$i"} } = 1;

                # update parts table
                $form->update_balance( $dbh, "parts", "onhand",
                    qq|id = $form->{"id_$i"}|,
                    $form->{"qty_$i"} );
                 # unless $form->{shipped};

            }
            else {

                # add purchase to expense
                push @{ $form->{acc_trans}{lineitems} },
                {
                    row_num       => $i,
                    chart_id      => $form->{"expense_accno_id_$i"},
                    amount        => $amount,
                    fxlinetotal   => $fxlinetotal,
                    fxgrossamount => $fxlinetotal +
                      $form->round_amount( $fxtax, 2 ),
                    grossamount => $grossamount,
                    invoice_id  => $invoice_id
                  };

            }
        }
    }

    $form->{paid} = 0;
    foreach my $i ( 1 .. ( $form->{paidaccounts} || 0 )) {
        $form->{"paid_$i"} =
          $form->parse_amount( $myconfig, $form->{"paid_$i"} );
        $form->{"paid_$i"} *= -1 if $form->{reverse};
        $form->{paid} += $form->{"paid_$i"};
        $form->{datepaid} = $form->{"datepaid_$i"}
          if ( $form->{"datepaid_$i"} );
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
    if ($form->{taxaccounts}) {
        for ( split / /, $form->{taxaccounts} ) {
            $amount += $form->{acc_trans}{ $form->{id} }{$_}{amount} =
              $form->round_amount( $form->{acc_trans}{ $form->{id} }{$_}{amount},
                2 );

            $form->{acc_trans}{ $form->{id} }{$_}{amount} *= -1;
        }
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

    my $approved = 1;
    $approved = 0 if $form->get_setting('separate_duties');


    foreach my $ref ( sort { $b->{amount} <=> $a->{amount} }
        @{ $form->{acc_trans}{lineitems} } )
    {

        $amount = $ref->{amount} + $diff;
        $fxlinetotal = $ref->{fxlinetotal} + $diff/$form->{exchangerate};
        $query  = qq|
         INSERT INTO acc_trans (trans_id, chart_id, amount_bc, curr, amount_tc,
                     transdate, approved, invoice_id)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute(
            $form->{id},        $ref->{chart_id},  $amount * -1,
            $form->{currency},  $fxlinetotal * -1, $form->{transdate},
            $approved, $ref->{invoice_id}
        ) || $form->dberror($query);

        $diff   = 0;
        $fxdiff = 0;
        for my $cls(@{$form->{bu_class}}){
            if ($form->{"b_unit_$cls->{id}_$ref->{row_num}"}){
             $b_unit_sth_ac->execute(
                 $cls->{id},
                 $form->{"b_unit_$cls->{id}_$ref->{row_num}"});
            }
        }
    }

    $form->{payables} = $invamount;

    delete $form->{acc_trans}{lineitems};

    if ($form->{manual_tax}){
        $invamount +=
            IIAA->post_form_manual_tax($myconfig, $form, -1, "payables");
    }

    # record payable
    if ( $form->{payables} ) {
        ($accno) = split /--/, $form->{AP};

        $query = qq|
          INSERT INTO acc_trans (trans_id, chart_id,
                                amount_bc, curr, amount_tc, transdate, approved)
                       VALUES (?, (SELECT id FROM account WHERE accno = ?),
                              ?, ?, ?, ?, ?)|;
        $sth = $dbh->prepare($query)
            or $form->dberror($dbh->errstr);
         $sth->execute( $form->{id}, $accno,
                       $form->{payables}, $form->{currency},
                    $form->{payables}/$form->{exchangerate},
                       $form->{transdate}, $approved)
          || $form->dberror($query);
    }

    # post taxes, if !$form->{manual} (see above)
    foreach my $trans_id ( keys %{ $form->{acc_trans} } ) {
        foreach my $accno ( keys %{ $form->{acc_trans}{$trans_id} } ) {
            $amount =
              $form->round_amount(
                $form->{acc_trans}{$trans_id}{$accno}{amount}, 2 );

            if ($amount) {
                $query = qq|
                    INSERT INTO acc_trans
                           (trans_id, chart_id, amount_bc, curr, amount_tc,
                                transdate, approved)
                            VALUES (?, (SELECT id FROM account
                                WHERE accno = ?),
                           ?, ?, ?, ?, ?)|;
                $sth = $dbh->prepare($query)
                    || $form->dberror($dbh->errstr);
                $sth->execute( $trans_id, $accno,
                               $amount, $form->{defaultcurrency}, $amount,
                               $form->{transdate}, $approved )
                  || $form->dberror($query);
            }
        }
    }

    # if there is no amount but a payment record payable
    if ( $invamount == 0 ) {
        $form->{payables} = 1;
    }

    my $cleared = 0;

    IIAA->process_form_payments($myconfig, $form);

    # set values which could be empty
    $form->{taxincluded} //= 0;
    $form->{taxincluded} *= 1;

    # save AP record
    $query = qq|
        UPDATE ap
           SET invnumber = ?,
               ordnumber = ?,
               quonumber = ?,
                       description = ?,
               transdate = ?,
             amount_bc = ?,
             amount_tc = ?,
             netamount_bc = ?,
             netamount_tc = ?,
               duedate = ?,
               invoice = '1',
               shippingpoint = ?,
               shipvia = ?,
               taxincluded = ?,
               notes = ?,
               intnotes = ?,
               curr = ?,
               language_code = ?,
               ponumber = ?,
                       approved = ?,
                       reverse = ?,
               crdate = ?,
               shipto = ?
         WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute(
        $form->{invnumber},     $form->{ordnumber},     $form->{quonumber},
        $form->{description},   $form->{transdate},     $invamount,
        $invamount/$form->{exchangerate},
        $invnetamount,          $invnetamount/$form->{exchangerate},
        $form->{duedate},       $form->{shippingpoint}, $form->{shipvia},
        $form->{taxincluded},   $form->{notes},         $form->{intnotes},
        $form->{currency},
        $form->{language_code}, $form->{ponumber},
        $approved,              $form->{reverse},       $form->{crdate},
        $form->{shiptolocationid},
        $form->{id}
    ) || $form->dberror($query);

    if ($form->{batch_id}){
        $sth = $dbh->prepare(
           'INSERT INTO voucher (batch_id, trans_id, batch_class)
            VALUES (?, ?, ?)');
        $sth->execute($form->{batch_id}, $form->{id}, BC_VENDOR_INVOICE);
    }

    # add shipto
    $form->{name} = $form->{vendor};
    $form->{name} =~ s/--$form->{vendor_id}//
        if $form->{vendor} && $form->{vendor_id};
    $form->add_shipto($form->{id});

    foreach my $item ( keys %updparts ) {
        $item  = $dbh->quote($item);
        $query = qq|
            UPDATE parts
               SET avgcost = avgcost($item),
                   lastcost = lastcost($item)
             WHERE id = $item|;
        $dbh->do($query) || $form->dberror($query);
    }

    return 1;
}

sub retrieve_invoice {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query;

    if ( $form->{id} ) {

        my $tax_sth = $dbh->prepare(
                  qq| SELECT amount_bc as amount, source, memo, tax_basis,
                             rate, accno
                        FROM acc_trans ac
                        JOIN tax_extended t USING(entry_id)
                        JOIN account c ON c.id = ac.chart_id
                       WHERE ac.trans_id = ?|);
        $tax_sth->execute($form->{id});
        my $reverse = $form->{reverse} ? -1 : 1;
        while (my $taxref = $tax_sth->fetchrow_hashref('NAME_lc')){
              $form->db_parse_numeric(sth=>$tax_sth,hashref=>$taxref);
              $form->{manual_tax} = 1;
              my $taccno = $taxref->{accno};
              $form->{"mt_amount_$taccno"} =
                  LedgerSMB::PGNumber->new($taxref->{amount} * -1 * $reverse);
              $form->{"mt_rate_$taccno"}  = $taxref->{rate};
              $form->{"mt_basis_$taccno"} =
                  LedgerSMB::PGNumber->new($taxref->{tax_basis} * -1 * $reverse);
              $form->{"mt_memo_$taccno"}  = $taxref->{memo};
              $form->{"mt_ref_$taccno"}  = $taxref->{source};
        }
    }

    my $setting = LedgerSMB::Setting->new(%$form);
    $form->{$_} = $setting->get($_)
        for (qw/ inventory_accno_id income_accno_id
                 fxgain_accno_id fxloss_accno_id /);
    @{$form->{currencies}} =
        (LedgerSMB::Setting->new(%$form))->get_currencies;

    if ( $form->{id} ) {

        $query = qq|
            SELECT a.invnumber, a.transdate, a.duedate,
                   a.ordnumber, a.quonumber, a.taxincluded,
                   a.notes, a.intnotes, a.curr AS currency,
                   a.entity_credit_account as vendor_id, a.language_code,
                   a.ponumber, a.crdate, a.on_hold, a.reverse, a.description,
                   a.shipto as shiptolocationid, l.line_one, l.line_two,
                   l.line_three, l.city, l.state, l.country_id, l.mail_code,
                   tran.workflow_id
              FROM ap a
              JOIN transactions tran USING (id)
            LEFT JOIN location l on a.shipto = l.id
             WHERE a.id = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        for ( keys %$ref ) {
            $form->{$_} = $ref->{$_};
        }
        $sth->finish;

        # retrieve individual items
        $query = qq|
               SELECT i.id as invoice_id,
                                  coalesce(i.vendor_sku, p.partnumber)
                                        as partnumber,
                                  i.description, i.qty,
                      i.fxsellprice, i.sellprice, i.precision,
                      i.parts_id AS id, i.unit, p.bin,
                      i.deliverydate,
                      i.serialnumber,
                      i.discount, i.notes, pg.partsgroup,
                      p.partsgroup_id, p.partnumber AS sku,
                      p.weight, p.onhand, p.inventory_accno_id,
                      p.income_accno_id, p.expense_accno_id,
                      t.description AS partsgrouptranslation
                 FROM invoice i
                 JOIN parts p ON (i.parts_id = p.id)
            LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
            LEFT JOIN partsgroup_translation t
                      ON (t.trans_id = p.partsgroup_id
                      AND t.language_code = ?)
                WHERE i.trans_id = ?
                 ORDER BY i.id|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{language_code}, $form->{id} )
          || $form->dberror($query);

        my $bu_sth = $dbh->prepare(
            qq|SELECT * FROM business_unit_inv
                WHERE entry_id = ?  |
        );

        # price matrix and vendor partnumber
        my $pmh = PriceMatrix::price_matrix_query( $dbh, $form );

        # tax rates for part
        $query = qq|
            SELECT c.accno
              FROM account c
              JOIN partstax pt ON (pt.chart_id = c.id)
             WHERE pt.parts_id = ?|;
        my $tth = $dbh->prepare($query);

        my $ptref;

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            PriceMatrix::price_matrix( $pmh, $ref, '', $decimalplaces, $form,
                $myconfig );
            $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
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
            my $taxrate = 0;

            while ( $ptref = $tth->fetchrow_hashref(NAME_lc) ) {
                $form->db_parse_numeric(sth => $tth, hashref => $ptref);
                $ref->{taxaccounts} .= "$ptref->{accno} ";
                $taxrate += $form->{"$ptref->{accno}_rate"};
            }

            $tth->finish;
            chop $ref->{taxaccounts};

            # price matrix
            $ref->{sellprice} =
              $form->round_amount(
                $ref->{fxsellprice} * $form->{exchangerate},
                $decimalplaces );

            $ref->{sellprice} = $ref->{fxsellprice};
            $ref->{qty} *= -1;

            $ref->{partsgroup} = $ref->{partsgrouptranslation}
              if $ref->{partsgrouptranslation};

            push @{ $form->{invoice_details} }, $ref;

        }

        $sth->finish;

    }


}

sub retrieve_item {
    my ( $self, $myconfig, $form ) = @_;

    $dbh = $form->{dbh};
    my $i = $form->{rowcount};
    my $null;
    my $var;

    # don't include assemblies or obsolete parts
    my $where = "WHERE p.assembly = '0' AND p.obsolete = '0'";

    if ( $form->{"partnumber_$i"} ne "" ) {
        $var = $dbh->quote( $form->{"partnumber_$i"} );
        $where .= " AND p.partnumber = $var or mm.barcode is not null";
    }

    if ( $form->{"partsgroup_$i"} ne "" ) {
        ( $null, $var ) = split /--/, $form->{"partsgroup_$i"};
        $var = $dbh->quote($var);
        $where .= qq| AND p.partsgroup_id = $var|;
    }

    my $query = qq|
           SELECT p.id, coalesce(
                                CASE WHEN pv.partnumber <> '' THEN pv.partnumber
                                     ELSE NULL END, p.partnumber) as partnumber,
                          p.description, pg.partsgroup, p.partsgroup_id,
                  coalesce(pv.lastcost, p.lastcost) AS sellprice,
                          p.unit, p.bin, p.onhand,
                  p.notes, p.inventory_accno_id, p.income_accno_id,
                  p.expense_accno_id, p.partnumber AS sku, p.weight,
                  t1.description AS translation,
                  t2.description AS grouptranslation
             FROM parts p
                LEFT JOIN makemodel mm ON (mm.parts_id = p.id AND mm.barcode = |
                             . $dbh->quote($form->{"partnumber_$i"}) . qq|)
        LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
                LEFT JOIN partsvendor pv ON (pv.parts_id = p.id
                                           AND pv.credit_id = ?)
        LEFT JOIN parts_translation t1
                  ON (t1.trans_id = p.id AND t1.language_code = ?)
        LEFT JOIN partsgroup_translation t2
                  ON (t2.trans_id = p.partsgroup_id
                  AND t2.language_code = ?)
             $where
         ORDER BY 2|;
    my $sth = $dbh->prepare($query);
    #die "$query:$i";
    $sth->execute( $form->{vendor_id}, $form->{language_code},
                   $form->{language_code} )
      || $form->dberror($query);


    # taxes
    $query = qq|
        SELECT c.accno
          FROM account c
          JOIN partstax pt ON (pt.chart_id = c.id)
         WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);
    $form->{item_list} = [];

    # price matrix
    my $pmh = PriceMatrix::price_matrix_query( $dbh, $form );

    my $ref;
    my $ptref;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        PriceMatrix::price_matrix( $pmh, $ref, '', $decimalplaces, $form,
            $myconfig );
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);

        my ($dec) = ( $ref->{sellprice} =~ /\.(\d+)/ );
        my $moneyplaces = LedgerSMB::Setting->new(%$form)->get('decimal_places');
        $dec = length $dec;
        my $decimalplaces = ( $dec > $moneyplaces ) ? $dec : $moneyplaces;

        # get taxes for part
        $tth->execute( $ref->{id} );

        $ref->{taxaccounts} = "";
        while ( $ptref = $tth->fetchrow_hashref(NAME_lc) ) {
            $ref->{taxaccounts} .= "$ptref->{accno} ";
        }
        $tth->finish;
        chop $ref->{taxaccounts};

        # get vendor price and partnumber

        $ref->{description} = $ref->{translation}
          if $ref->{translation};
        $ref->{partsgroup} = $ref->{grouptranslation}
          if $ref->{grouptranslation};

        push @{ $form->{item_list} }, $ref;

    }

    $sth->finish;

}


sub vendor_details {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    # get rest for the vendor
    my $query = qq|
        SELECT meta_number as vendornumber, e.name,
                       line_one as address1, line_two as address2, city, state,
               mail_code as zipcode, c.name as country,
                       pay_to_name as contact,
                       phone as vendorphone, fax as vendorfax,
               tax_id AS vendortaxnumber, sic_code AS sic, iban, bic, remark,
               -- gifi_accno AS gifi,
                       startdate, enddate
          FROM entity_credit_account eca
                  JOIN entity e ON eca.entity_id = e.id
                  JOIN company co ON co.entity_id = e.id
             LEFT JOIN eca_to_location e2l ON eca.id = e2l.credit_id
                                     and e2l.location_class = 1
             LEFT JOIN entity_to_location el ON eca.entity_id = el.entity_id
                                     and el.location_class = 1
             LEFT JOIN location l ON l.id =
                                     coalesce(e2l.location_id, el.location_id)
             LEFT JOIN country c ON l.country_id = c.id
             LEFT JOIN (select max(phone) as phone, max(fax) as fax, credit_id
                          FROM (SELECT CASE WHEN contact_class_id =1 THEN contact
                                       END as phone,
                                       CASE WHEN contact_class_id =9 THEN contact
                                       END as fax,
                                       credit_id
                                  FROM eca_to_contact) ct_base
                        GROUP BY credit_id) ct ON ct.credit_id = eca.id
             LEFT JOIN entity_bank_account ba ON ba.id = eca.bank_account
         WHERE eca.id = ?|;
    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{vendor_id} ) || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) {
        $form->{$_} = $ref->{$_};
    }

    $sth->finish;

}

sub item_links {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|
           SELECT accno, description, array_agg(l.description) as link
             FROM account a
             JOIN account_link l ON a.id = l.account-id
            WHERE l.description like 'IC%'
         ORDER BY accno|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        foreach my $key ( @{$ref->{link}} ) {
            push @{ $form->{IC_links}{$key} },
                  {
                    accno       => $ref->{accno},
                    description => $ref->{description}
                  };
        }
    }

    $sth->finish;
}



sub toggle_on_hold {

    my $self = shift @_;
    my $form = shift @_;

    if ($form->{id}) { # it's an existing (.. probably) invoice.

        my $dbh = $form->{dbh};

        $sth = $dbh->prepare("update ap set on_hold = not on_hold where ap.id = ?");
        my $code = $sth->execute($form->{id});#tshvr4

        return 1;

    } else { # This shouldn't even be possible, but check for it anyway.

        # Definitely, DEFINITELY check it.
        # happily return 0. Find out about proper error states.
        return 0;
    }
}





sub taxform_exist
{

   my ( $self,$form,$vendor_id) = @_;

   my $query = "select taxform_id from entity_credit_account where id=?";

   my $sth = $form->{dbh}->prepare($query);

   $sth->execute($vendor_id) || $form->dberror($query);

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
