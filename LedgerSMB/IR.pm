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
use LedgerSMB::Sysconfig;
use Math::BigFloat;

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
     my $file = LedgerSMB::File->new();
     $file->new_dbobject({base => $form, locale => $locale});
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 1});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 1}
     );

}

sub add_cogs {
    my ($self, $form) = @_;
    my $dbh = $form->{dbh};
    my $query = 
     "select cogs__add_for_ap_line(id) FROM invoice WHERE trans_id = ?";
    my $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute($form->{id}) || $form->dberror($query);
}

sub post_invoice {
    my ( $self, $myconfig, $form ) = @_;

    $form->all_business_units;
    if ($form->{id}){
        delete_invoice($self, $myconfig, $form);
    }
    my $dbh = $form->{dbh};
    $form->{invnumber} = $form->update_defaults( $myconfig, "vinumber", $dbh )
      unless $form->{invnumber};

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
    my $project_id;
    my $exchangerate = 0;
    my $allocated;
    my $taxrate;
    my $taxamount;
    my $diff = 0;
    my $item;
    my $invoice_id;
    my $keepcleared;

    ( $null, $form->{employee_id} ) = split /--/, $form->{employee};

    unless ( $form->{employee_id} ) {
        ( $form->{employee}, $form->{employee_id} ) = $form->get_employee($dbh);
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
		SELECT inventory_accno_id, income_accno_id, expense_accno_id
		  FROM parts
		 WHERE id = ?|;

    my $pth = $dbh->prepare($query) || $form->dberror($query);

    my %updparts = ();

    if ( $form->{id} ) {

        my $sth;

        $keepcleared = 1;

        $query = qq|SELECT id FROM ap WHERE id = ?|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{id} );

        if ( $sth->fetchrow_array ) {
            $query = qq|
				SELECT p.id, p.inventory_accno_id, 
				       p.income_accno_id
				  FROM invoice i
				  JOIN parts p ON (p.id = i.parts_id)
				 WHERE i.trans_id = ?|;
            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);
            while ( $ref = $sth->fetchrow_hashref ) {
                if (   $ref->{inventory_accno_id}
                    && $ref->{income_accno_id} )
                {

                    $updparts{ $ref->{id} } = 1;
                }
            }
            $sth->finish;

            &reverse_invoice( $dbh, $form );
        }
        else {
            $query = qq|INSERT INTO ap (id) VALUES (?)|;
            $sth   = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);
        }
    }

    my $uid = localtime;
    $uid .= "$$";

    if ( !$form->{id} ) {

        $query = qq|
			INSERT INTO ap (invnumber, person_id, entity_credit_account)
			VALUES ('$uid', (SELECT entity_id FROM users
			                  WHERE username = ?), ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{login}, $form->{vendor_id} ) || $form->dberror($query);

        $query = qq|SELECT id FROM ap WHERE invnumber = '$uid'|;
        $sth   = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        ( $form->{id} ) = $sth->fetchrow_array;
        $sth->finish;

    }

    my $amount;
    my $grossamount;
    my $invamount    = 0;
    my $invnetamount = 0;

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        $form->{exchangerate} = 1;
    }
    else {
        $exchangerate =
          $form->check_exchangerate( $myconfig, $form->{currency},
            $form->{transdate}, 'sell' );
    }

    $form->{exchangerate} =
      ($exchangerate)
      ? $exchangerate
      : $form->parse_amount( $myconfig, $form->{exchangerate} );

    
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

            # project

            if ( $form->{"projectnumber_$i"} ne "" ) {
                ( $null, $project_id ) =
                  split /--/, $form->{"projectnumber_$i"};
            }

            # undo discount formatting
            $form->{"discount_$i"} =
              $form->parse_amount( $myconfig, $form->{"discount_$i"} ) / 100;

            # keep entered selling price
            my $fxsellprice =
              $form->parse_amount( $myconfig, $form->{"sellprice_$i"} );

            my ($dec) = ( $fxsellprice =~ /\.(\d+)/ );
            # deduct discount
            my $moneyplaces = $LedgerSMB::Sysconfig::decimal_places;
            $decimalplaces = ($form->{"precision_$i"} > $moneyplaces) 
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

                $tax   = Math::BigFloat->bzero();
                $fxtax = Math::BigFloat->bzero();
    
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
            $allocated = 0;

            # adjust and round sellprice
            $form->{"sellprice_$i"} =
              $form->round_amount(
                $form->{"sellprice_$i"} * $form->{exchangerate},
                $decimalplaces );

            # save detail record in invoice table
            $query = qq|
				INSERT INTO invoice (description)
				     VALUES ('$uid')|;
            $dbh->do($query) || $form->dberror($query);

            $query = qq|
				SELECT id FROM invoice
				 WHERE description = '$uid'|;
            ($invoice_id) = $dbh->selectrow_array($query);

            $query = qq|
				UPDATE invoice 
				   SET trans_id = ?,
				       parts_id = ?,
				       description = ?,
				       qty = ?,
				       sellprice = ?,
				       fxsellprice = ?,
				       discount = ?,
				       allocated = ?,
				       unit = ?,
				       deliverydate = ?,
				       serialnumber = ?,
                                       precision = ?,
				       notes = ?
				 WHERE id = ?|;
            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{id},               $form->{"id_$i"},
                $form->{"description_$i"}, $form->{"qty_$i"} * -1,
                $form->{"sellprice_$i"},   $fxsellprice,
                $form->{"discount_$i"},    $allocated,
                $form->{"unit_$i"},        $form->{"deliverydate_$i"},
                $form->{"serialnumber_$i"},
                $form->{"precision_$i"},   $form->{"notes_$i"},       
                $invoice_id
            ) || $form->dberror($query);

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
                       $form->error($locale->text('Batch ID Missing'));
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
		if($form->{"qty_$i"}<0) {
                    # check for unallocated entries at the same price to match our entry
                    $query = qq|
				  SELECT i.id, i.qty, i.allocated, a.transdate
			    	    FROM invoice i
			            JOIN parts p ON (p.id = i.parts_id)
				    JOIN ap a ON (a.id = i.trans_id)
				   WHERE i.parts_id = ? AND (i.qty + i.allocated) < 0 AND i.sellprice = ?
			    	ORDER BY transdate
				    |;
            	    $sth = $dbh->prepare($query);
                    $sth->execute( $form->{"id_$i"}, $form->{"sellprice_$i"}) || $form->dberror($query);
                    my $totalqty = $form->{"qty_$i"};
            	    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
                        $form->db_parse_numeric(sth=>$sth, hashref => $ref);
                    	my $qty = $ref->{qty} + $ref->{allocated};
                        if ( ( $qty - $totalqty ) < 0 ) { $qty = $totalqty; }
                    	# update allocated for sold item
                        $form->update_balance( $dbh, "invoice", "allocated", qq|id = $ref->{id}|, $qty * -1 );
                        $allocated += $qty;
                        last if ( ( $totalqty -= $qty ) >= 0 );
            	    }
		} 

                # add purchase to inventory
                push @{ $form->{acc_trans}{lineitems} },
                  {
                    chart_id      => $form->{"inventory_accno_id_$i"},
                    amount        => $amount,
                    fxgrossamount => $fxlinetotal +
                      $form->round_amount( $fxtax, 2 ),
                    grossamount => $grossamount,
                    project_id  => $project_id,
                    invoice_id  => $invoice_id
                  };

                $updparts{ $form->{"id_$i"} } = 1;

                # update parts table
                $form->update_balance( $dbh, "parts", "onhand",
                    qq|id = $form->{"id_$i"}|,
                    $form->{"qty_$i"} )
                  unless $form->{shipped};

            }
            else {

                # add purchase to expense
                push @{ $form->{acc_trans}{lineitems} },
                  {
                    chart_id      => $form->{"expense_accno_id_$i"},
                    amount        => $amount,
                    fxgrossamount => $fxlinetotal +
                      $form->round_amount( $fxtax, 2 ),
                    grossamount => $grossamount,
                    project_id  => $project_id,
                    invoice_id  => $invoice_id
                  };

            }
        }
    }

    $form->{paid} = 0;
    for $i ( 1 .. $form->{paidaccounts} ) {
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
    for ( split / /, $form->{taxaccounts} ) {
        $amount += $form->{acc_trans}{ $form->{id} }{$_}{amount} =
          $form->round_amount( $form->{acc_trans}{ $form->{id} }{$_}{amount},
            2 );

        $form->{acc_trans}{ $form->{id} }{$_}{amount} *= -1;
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

    foreach $ref ( sort { $b->{amount} <=> $a->{amount} }
        @{ $form->{acc_trans}{lineitems} } )
    {

        $amount = $ref->{amount} + $diff + $fxdiff;
        $query  = qq|
			INSERT INTO acc_trans (trans_id, chart_id, amount,
			            transdate, invoice_id)
			            VALUES (?, ?, ?, ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute(
            $form->{id},        $ref->{chart_id},   $amount * -1,
            $form->{transdate}, $ref->{invoice_id}
        ) || $form->dberror($query);
        $diff   = 0;
        $fxdiff = 0;
        for my $cls(@{$form->{bu_class}}){
            if ($form->{"b_unit_$cls->{id}_$i"}){
             $b_unit_sth_ac->execute($cls->{id}, $form->{"b_unit_$cls->{id}_$i"});
            }
        }
    }

    $form->{payables} = $invamount;

    delete $form->{acc_trans}{lineitems};

    # update exchangerate
    if ( ( $form->{currency} ne $form->{defaultcurrency} ) && !$exchangerate ) {
        $form->update_exchangerate( $dbh, $form->{currency}, $form->{transdate},
            0, $form->{exchangerate} );
    }
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
        for $taccno (split / /, $form->{taxaccounts}){
            my $taxamount;
            my $taxbasis;
            my $taxrate;
            my $fx = $form->{exchangerate} || 1;
            $taxamount = $form->parse_amount($myconfig, 
                                             $form->{"mt_amount_$taccno"});
            $taxbasis = $form->parse_amount($myconfig,
                                           $form->{"mt_basis_$taccno"});
            $taxrate=$form->parse_amount($myconfig,$form->{"mt_rate_$taccno"});
            my $fx_taxamount = $taxamount * $fx;
            my $fx_taxbasis = $taxbasis * $fx;
            $form->{payables} += $fx_taxamount;
            $invamount += $fx_taxamount;
            $ac_sth->execute($taccno, $form->{id}, $fx_taxamount * -1, 
                             $form->{"mt_ref_$taccno"}, 
                             $form->{"mt_desc_$taccno"});
            $tax_sth->execute($fx_taxbasis * -1, $taxrate);
        }
        $ac_sth->finish;
        $tax_sth->finish;
    }


    # record payable
    if ( $form->{payables} ) {
        ($accno) = split /--/, $form->{AP};

        $query = qq|
			INSERT INTO acc_trans (trans_id, chart_id, amount,
                	            transdate)
                	     VALUES (?, (SELECT id FROM chart WHERE accno = ?),
                	            ?, ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id}, $accno, $form->{payables},
            $form->{transdate} )
          || $form->dberror($query);
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
	            			VALUES (?, (SELECT id FROM chart
		                        WHERE accno = ?),
                    			?, ?)|;
                $sth = $dbh->prepare($query);
                $sth->execute( $trans_id, $accno, $amount, $form->{transdate} )
                  || $form->dberror($query);
            }
        }
    }

    # if there is no amount but a payment record payable
    if ( $invamount == 0 ) {
        $form->{payables} = 1;
    }

    my $cleared = 0;

    # record payments and offsetting AP
    for my $i ( 1 .. $form->{paidaccounts} ) {

        if ( $form->{"paid_$i"} ) {
            my ($accno) = split /--/, $form->{"AP_paid_$i"};
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
                    $form->{"datepaid_$i"}, 'sell' );

                $form->{"exchangerate_$i"} =
                  ($exchangerate)
                  ? $exchangerate
                  : $form->parse_amount( $myconfig,
                    $form->{"exchangerate_$i"} );
            }

            # record AP
            $amount = (
                $form->round_amount(
                    $form->{"paid_$i"} * $form->{exchangerate}, 2
                )
            ) * -1;

            if ( $form->{payables} ) {
                $query = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, amount,
		    			            transdate)
		    			VALUES (?, (SELECT id FROM chart
					             WHERE accno = ?),
		    			             ?, ?)|;

                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id}, $form->{AP}, $amount,
                    $form->{"datepaid_$i"} )
                  || $form->dberror($query);
            }

            if ($keepcleared) {
                $cleared = ( $form->{"cleared_$i"} ) ? 1 : 0;
            }

            # record payment
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, amount, 
				            transdate, source, memo, cleared)
				     VALUES (?, (SELECT id FROM chart 
				                  WHERE accno = ?),
				            ?, ?, ?, ?, ?)|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id}, $accno, $form->{"paid_$i"},
                $form->{"datepaid_$i"},
                $form->{"source_$i"}, $form->{"memo_$i"}, $cleared )
              || $form->dberror($query);

            # exchangerate difference
            $amount = $form->round_amount(
                $form->{"paid_$i"} * $form->{"exchangerate_$i"} -
                  $form->{"paid_$i"},
                2
            );

            if ($amount) {
                $query = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, amount,
					            transdate, source, 
					            fx_transaction, cleared)
					     VALUES (?, (SELECT id FROM chart
					                  WHERE accno = ?),
					            ?, ?, ?, '1', ?)|;
                $sth = $dbh->prepare($query);
                $sth->execute( $form->{id}, $accno, $amount,
                    $form->{"datepaid_$i"},
                    $form->{"source_$i"}, $cleared )
                  || $form->dberror($query);

            }

            # gain/loss
            $amount = $form->round_amount(
                $form->round_amount( $form->{"paid_$i"} * $form->{exchangerate},
                    2 ) - $form->round_amount(
                    $form->{"paid_$i"} * $form->{"exchangerate_$i"}, 2
                    ),
                2
            );

            if ($amount) {
                my $accno_id =
                  ( $amount > 0 )
                  ? $fxgain_accno_id
                  : $fxloss_accno_id;
                $query = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, amount,
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

                $form->update_exchangerate( $dbh, $form->{currency},
                    $form->{"datepaid_$i"},
                    0, $form->{"exchangerate_$i"} );
            }
        }
    }

    # set values which could be empty
    $form->{taxincluded} *= 1;

    my $approved = 1;
    $approved = 0 if $form->{separate_duties};

    # save AP record
    $query = qq|
		UPDATE ap 
		   SET invnumber = ?,
		       ordnumber = ?,
		       quonumber = ?,
                       description = ?,
		       transdate = ?,
		       amount = ?,
		       netamount = ?,
		       paid = ?,
		       datepaid = ?,
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
                       approved = ?
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute(
        $form->{invnumber},     $form->{ordnumber},     $form->{quonumber},
        $form->{description},   $form->{transdate},     $invamount,
        $invnetamount,          $form->{paid},          $form->{datepaid},
        $form->{duedate},       $form->{shippingpoint}, $form->{shipvia},
        $form->{taxincluded},   $form->{notes},         $form->{intnotes},
        $form->{currency},
        $form->{language_code}, $form->{ponumber},      
        $approved,              $form->{id}
    ) || $form->dberror($query);

    if ($form->{batch_id}){
        $sth = $dbh->prepare(
           'INSERT INTO voucher (batch_id, trans_id, batch_class)
            VALUES (?, ?, ?)');
        $sth->execute($form->{batch_id}, $form->{id}, 9);
    }

    # add shipto
    $form->{name} = $form->{vendor};
    $form->{name} =~ s/--$form->{vendor_id}//;
    $form->add_shipto( $dbh, $form->{id} );

    my %audittrail = (
        tablename => 'ap',
        reference => $form->{invnumber},
        formname  => $form->{type},
        action    => 'posted',
        id        => $form->{id}
    );

    if (!$form->{separate_duties}){
        $self->add_cogs($form);
    }

    $form->audittrail( $dbh, "", \%audittrail );

    foreach $item ( keys %updparts ) {
        $item  = $dbh->quote($item);
        $query = qq|
			UPDATE parts 
			   SET avgcost = avgcost($item),
			       lastcost = lastcost($item)
			 WHERE id = $item|;
        $dbh->do($query) || $form->dberror($query);
    }
    my $rc = $dbh->commit;

    $rc;

}

sub reverse_invoice {
    my ( $dbh, $form ) = @_;

    my $query = qq|SELECT id FROM ap
                 WHERE id = $form->{id}|;
    my ($id) = $dbh->selectrow_array($query);

    return unless $id;

    # reverse inventory items
    $query = qq|
		SELECT i.parts_id, p.inventory_accno_id, p.expense_accno_id,
		       i.qty, i.allocated, i.sellprice, i.project_id
		  FROM invoice i, parts p
		 WHERE i.parts_id = p.id
		       AND i.trans_id = ?|;
    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $netamount = 0;

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $netamount +=
          $form->round_amount( $ref->{sellprice} * $ref->{qty} * -1, 2 );

        if ( $ref->{inventory_accno_id} ) {

            # update onhand
            $form->update_balance( $dbh, "parts", "onhand",
                qq|id = $ref->{parts_id}|,
                $ref->{qty} );

            # if $ref->{allocated} > 0 than we sold that many items
            if ( $ref->{allocated} > 0 ) {

                # get references for sold items
                $query = qq|
					  SELECT i.id, i.trans_id, i.allocated, 
					         a.transdate
					    FROM invoice i, ar a
					   WHERE i.parts_id = ?
					         AND i.allocated < 0
					         AND i.trans_id = a.id
					ORDER BY transdate DESC|;
                my $sth = $dbh->prepare($query);
                $sth->execute( $ref->{parts_id} )
                  || $form->dberror($query);

                while ( my $pthref = $sth->fetchrow_hashref(NAME_lc) ) {

                    my $qty = $ref->{allocated};

                    if ( ( $ref->{allocated} + $pthref->{allocated} ) > 0 ) {
                        $qty = $pthref->{allocated} * -1;
                    }

                    my $amount =
                      $form->round_amount( $ref->{sellprice} * $qty, 2 );

                    #adjust allocated
                    $form->update_balance( $dbh, "invoice", "allocated",
                        qq|id = $pthref->{id}|, $qty );

                    # add reversal for sale
                    $ref->{project_id} *= 1;
                    $query = qq|
						INSERT INTO acc_trans 
						            (trans_id, 
							    chart_id, amount, 
						            transdate, 
						            project_id)
						     VALUES (?, ?, ?, ?, ?)|;
                    $sth = $dbh->prepare($query);
                    $sth->execute( $pthref->{trans_id},
                        $ref->{expense_accno_id},
                        $amount, $form->{transdate}, $ref->{project_id} )
                      || $form->dberror($query);

                    $query = qq|
						INSERT INTO acc_trans 
						            (trans_id, chart_id,
						            amount, transdate, 
						            project_id)
						     VALUES (?, ?, ?, ?, ?)|;
                    $sth = $dbh->prepare($query);
                    $sth->execute(
                        $pthref->{trans_id},
                        $ref->{inventory_accno_id},
                        $amount * -1,
                        $form->{transdate}, $ref->{project_id}
                    ) || $form->dberror($query);
                    last if ( ( $ref->{allocated} -= $qty ) <= 0 );
                }
                $sth->finish;
            }
        }
    }
    $sth->finish;

    #tshvr delete tax_extended invoice_tax_form 
    $query=qq|SELECT entry_id FROM acc_trans ac JOIN tax_extended t using(entry_id) WHERE ac.trans_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute($form->{id}) || $form->dberror($query);
    while ( my $entry_id=$sth->fetchrow_array ) {
     my $query1="DELETE FROM tax_extended WHERE entry_id=?";
     my $sth1   = $dbh->prepare($query1);
     $sth1->execute($entry_id) || $form->dberror($query);
     $sth1->finish;
    }#while entry_id
    $sth->finish;
    $query=qq|select id from invoice WHERE trans_id=?|;
    $sth   = $dbh->prepare($query);
    $sth->execute($form->{id}) || $form->dberror($query);
    while(my $invoice_id=$sth->fetchrow()){
     my $query1=qq|delete from invoice_tax_form where invoice_id=?|;
     my $sth1   = $dbh->prepare($query1);
     $sth1->execute($invoice_id) || $form->dberror($query);
     $sth1->finish;
    }#while invoice_id
    $sth->finish;
    #tshvr delete tax_extended invoice_tax_form end
    # delete acc_trans
    $query = qq|DELETE FROM acc_trans WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    # delete invoice entries
    $query = qq|DELETE FROM invoice WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM new_shipto WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    #$dbh->commit;#tshvr lower-level sub should not commit on behalf of higher-level sub

}

sub retrieve_invoice {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query;

    if ( $form->{id} ) {

        my $tax_sth = $dbh->prepare(
                  qq| SELECT amount, source, memo, tax_basis, rate, accno
                        FROM acc_trans ac
                        JOIN tax_extended t USING(entry_id)
                        JOIN account c ON c.id = ac.chart_id
                       WHERE ac.trans_id = ?|);
        $tax_sth->execute($form->{id});
        while (my $taxref = $tax_sth->fetchrow_hashref('NAME_lc')){
              $form->db_parse_numeric(sth=>$tax_sth,hashref=>$taxref);
              $form->{manual_tax} = 1;
              my $taccno = $taxref->{accno};
              $form->{"mt_amount_$taccno"} = Math::BigFloat->new($taxref->{amount} * -1);
              $form->{"mt_rate_$taccno"}  = $taxref->{rate};
              $form->{"mt_basis_$taccno"} = Math::BigFloat->new($taxref->{tax_basis} * -1);
              $form->{"mt_memo_$taccno"}  = $taxref->{memo};
              $form->{"mt_ref_$taccno"}  = $taxref->{source};
        }

        # get default accounts and last invoice number
        $query = qq|
			SELECT (select c.accno FROM account c 
			         WHERE c.id = (SELECT value::int FROM defaults 
			                        WHERE setting_key = 
			                              'inventory_accno_id'))
			       AS inventory_accno,

			       (SELECT c.accno FROM account c
				 WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'income_accno_id'))
			       AS income_accno,

			       (SELECT c.accno FROM account c
			         WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'expense_accno_id'))
			       AS expense_accno,

			       (SELECT c.accno FROM account c
			         WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'fxgain_accno_id'))
			       AS fxgain_accno,

			       (SELECT c.accno FROM account c
			         WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'fxloss_accno_id'))
			       AS fxloss_accno, 
			       (SELECT value FROM defaults
			         WHERE setting_key = 'curr') AS currencies|;
    }
    else {
        $query = qq|
			SELECT (select c.accno FROM account c 
			         WHERE c.id = (SELECT value::int FROM defaults 
			                        WHERE setting_key = 
			                              'inventory_accno_id'))
			       AS inventory_accno,

			       (SELECT c.accno FROM account c
				 WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'income_accno_id'))
			       AS income_accno,

			       (SELECT c.accno FROM account c
			         WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'expense_accno_id'))
			       AS expense_accno,

			       (SELECT c.accno FROM account c
			         WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'fxgain_accno_id'))
			       AS fxgain_accno,

			       (SELECT c.accno FROM account c
			         WHERE c.id = (SELECT value::int FROM defaults
			                        WHERE setting_key =
			                              'fxloss_accno_id'))
			       AS fxloss_accno, 
			       (SELECT value FROM defaults
			         WHERE setting_key = 'curr') AS currencies,
			       current_date AS transdate|;
    }
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) {
        $form->{$_} = $ref->{$_};
    }
    $sth->finish;

    if ( $form->{id} ) {

        $query = qq|
			SELECT a.invnumber, a.transdate, a.duedate,
			       a.ordnumber, a.quonumber, a.paid, a.taxincluded,
			       a.notes, a.intnotes, a.curr AS currency, 
			       a.entity_credit_account as vendor_id, a.language_code, a.ponumber,
			       a.on_hold, a.reverse, a.description
			  FROM ap a
			 WHERE id = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        for ( keys %$ref ) {
            $form->{$_} = $ref->{$_};
        }
        $sth->finish;

        # get shipto
        $query = qq|SELECT ns.*, l.* FROM new_shipto ns JOIN location l ON ns.location_id = l.id WHERE ns.trans_id = ?|;
        $sth   = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) {
            $form->{$_} = $ref->{$_};
        }
        $sth->finish;

        # retrieve individual items
        $query = qq|
			   SELECT i.id as invoice_id,p.partnumber, i.description, i.qty, 
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
			LEFT JOIN translation t 
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

        # exchangerate defaults
        &exchangerate_defaults( $dbh, $form );

        # price matrix and vendor partnumber
        my $pmh = PriceMatrix::price_matrix_query( $dbh, $form );

        # tax rates for part
        $query = qq|
			SELECT c.accno
			  FROM chart c
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
                $ref->{fxsellprice} * $form->{ $form->{currency} },
                $decimalplaces );

            $ref->{sellprice} = $ref->{fxsellprice};
            $ref->{qty} *= -1;

            $ref->{partsgroup} = $ref->{partsgrouptranslation}
              if $ref->{partsgrouptranslation};

            push @{ $form->{invoice_details} }, $ref;

        }

        $sth->finish;

    }

    my $rc = $dbh->commit;

    $rc;

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
        $var = $dbh->quote( $form->like( lc $form->{"partnumber_$i"} ) );
        $where .= " AND lower(p.partnumber) LIKE $var or mm.barcode is not null";
    }

    if ( $form->{"description_$i"} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{"description_$i"} ) );
        if ( $form->{language_code} ne "" ) {
            $where .= " AND lower(t1.description) LIKE $var";
        }
        else {
            $where .= " AND lower(p.description) LIKE $var";
        }
    }

    if ( $form->{"partsgroup_$i"} ne "" ) {
        ( $null, $var ) = split /--/, $form->{"partsgroup_$i"};
        $var = $dbh->quote($var);
        $where .= qq| AND p.partsgroup_id = $var|;
    }

    if ( $form->{"description_$i"} ne "" ) {
        $where .= " ORDER BY 3";
    }
    else {
        $where .= " ORDER BY 2";
    }

    my $query = qq|
		   SELECT p.id, p.partnumber, p.description,
		          pg.partsgroup, p.partsgroup_id,
		          p.lastcost AS sellprice, p.unit, p.bin, p.onhand, 
		          p.notes, p.inventory_accno_id, p.income_accno_id, 
		          p.expense_accno_id, p.partnumber AS sku, p.weight,
		          t1.description AS translation, 
		          t2.description AS grouptranslation
		     FROM parts p
                LEFT JOIN makemodel mm ON (mm.parts_id = p.id AND mm.barcode = |
                             . $dbh->quote($form->{"partnumber_$i"}) . qq|)
		LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		LEFT JOIN translation t1 
		          ON (t1.trans_id = p.id AND t1.language_code = ?)
		LEFT JOIN translation t2 
		          ON (t2.trans_id = p.partsgroup_id 
		          AND t2.language_code = ?)
	         $where|;
    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{language_code}, $form->{language_code} )
      || $form->dberror($query);

    # foreign currency
    &exchangerate_defaults( $dbh, $form );

    # taxes
    $query = qq|
		SELECT c.accno
		  FROM chart c
		  JOIN partstax pt ON (pt.chart_id = c.id)
		 WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);

    # price matrix
    my $pmh = PriceMatrix::price_matrix_query( $dbh, $form );

    my $ref;
    my $ptref;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        PriceMatrix::price_matrix( $pmh, $ref, '', $decimalplaces, $form,
            $myconfig );
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);

        my ($dec) = ( $ref->{sellprice} =~ /\.(\d+)/ );
        my $moneyplaces = $LedgerSMB::Sysconfig::decimal_places;
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

sub exchangerate_defaults {
    my ( $dbh, $form ) = @_;

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
		SELECT sell
		  FROM exchangerate
		 WHERE curr = ?
		       AND transdate = ?|;
    my $eth1 = $dbh->prepare($query) || $form->dberror($query);

    $query = qq/
		SELECT max(transdate || ' ' || sell || ' ' || curr)
		  FROM exchangerate
		 WHERE curr = ?/;
    my $eth2 = $dbh->prepare($query) || $form->dberror($query);

    # get exchange rates for transdate or max
    foreach $var ( split /:/, substr( $form->{currencies}, 4 ) ) {
        $eth1->execute( $var, $form->{transdate} );
        @array = $eth1->fetchrow_array;
	$form->db_parse_numeric(sth=> $eth1, arrayref=>\@array);
        $form->{$var} = shift @array;
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

sub vendor_details {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    # get rest for the vendor
    my $query = qq|
		SELECT meta_number as vendornumber, e.name, 
                       line_one as address1, line_two as address2, city, state,
		       mail_code as zipcode, c.name as country, 
                       pay_to_name as contact, 
                       phone as vendorphone, fax as vendorfax, 
		       tax_id AS vendortaxnumber, sic_code AS sic, iban, bic,
		       -- gifi_accno AS gifi, 
                       startdate, enddate
		  FROM entity_credit_account eca
                  JOIN entity e ON eca.entity_id = e.id
                  JOIN company co ON co.entity_id = e.id
             LEFT JOIN eca_to_location e2l ON eca.id = e2l.credit_id
             LEFT JOIN location l ON l.id = e2l.location_id
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
		 WHERE eca.id = ? and location_class = 1|;
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

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
		   SELECT accno, description, link
		     FROM chart
	            WHERE link LIKE '%IC%'
		 ORDER BY accno|;
    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        foreach my $key ( split( /:/, $ref->{link} ) ) {
            if ( $key =~ /IC/ ) {
                push @{ $form->{IC_links}{$key} },
                  {
                    accno       => $ref->{accno},
                    description => $ref->{description}
                  };
            }
        }
    }

    $sth->finish;
}



sub toggle_on_hold {
    
    my $self = shift @_;
    my $form = shift @_;
    
    if ($form->{id}) { # it's an existing (.. probably) invoice.
        
        my $dbh = $form->{dbh};
        my $sth = $dbh->prepare("SELECT on_hold from ar where ar.id = ?");
        $sth->execute($form->{id});
        my $state = $sth->fetchrow_array;
        my $n_s; # new state
        if ($state[0] == 't') {
            
            # Turn it off
            $n_s = 'f';
            
        } else {
            $n_s = 't';
        }
        
        $sth = $dbh->prepare("update ar set on_hold = ?::boolean where ar.id = ?");
        my $code = $dbh->execute($ns, $form->{id});
        
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

   #$dbh->commit();#tshvr lower-level sub should not commit on behalf of higher-level sub

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





1;
