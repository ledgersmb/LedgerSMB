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
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# Inventory received module
#
#======================================================================

package IR;
use LedgerSMB::Tax;
use LedgerSMB::PriceMatrix;

sub post_invoice {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database, turn off autocommit
  my $dbh = $form->dbconnect_noauto($myconfig);

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
  
  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  }

  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;
 
  $query = qq|SELECT fxgain_accno_id, fxloss_accno_id
              FROM defaults d|;
  my ($fxgain_accno_id, $fxloss_accno_id) = $dbh->selectrow_array($query);
  
  $query = qq|SELECT inventory_accno_id, income_accno_id, expense_accno_id
	      FROM parts
	      WHERE id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  my %updparts = ();
  
  if ($form->{id}) {
    $keepcleared = 1;
    $query = qq|SELECT id FROM ap
		WHERE id = $form->{id}|;
    
    if ($dbh->selectrow_array($query)) {
      $query = qq|SELECT p.id, p.inventory_accno_id, p.income_accno_id
                  FROM invoice i
		  JOIN parts p ON (p.id = i.parts_id)
                  WHERE i.trans_id = $form->{id}|;
      $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);
      while ($ref = $sth->fetchrow_hashref) {
	if ($ref->{inventory_accno_id} && $ref->{income_accno_id}) {
	  $updparts{$ref->{id}} = 1;
	}
      }
      $sth->finish;

      &reverse_invoice($dbh, $form);
    } else { 
      $query = qq|INSERT INTO ap (id) 
                  VALUES ($form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    } 
  }

  my $uid = localtime;
  $uid .= "$$";

  if (! $form->{id}) {

    $query = qq|INSERT INTO ap (invnumber, employee_id)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}'))|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM ap
                WHERE invnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;

  }

  my $amount;
  my $grossamount;
  my $allocated;
  my $invamount = 0;
  my $invnetamount = 0;

  if ($form->{currency} eq $form->{defaultcurrency}) {
    $form->{exchangerate} = 1;
  } else {
    $exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, 'sell');
  }
  
  $form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate});

  for my $i (1 .. $form->{rowcount}) {
    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
    
    if ($form->{"qty_$i"}) {
      
      $pth->execute($form->{"id_$i"});
      $ref = $pth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) {
	$form->{"${_}_$i"} = $ref->{$_};
      }
      $pth->finish;
      
      # project
      $project_id = 'NULL';
      if ($form->{"projectnumber_$i"} ne "") {
	($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
      }
 
      # undo discount formatting
      $form->{"discount_$i"} = $form->parse_amount($myconfig, $form->{"discount_$i"}) / 100;
      
      # keep entered selling price
      my $fxsellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});

      my ($dec) = ($fxsellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;
          
      # deduct discount
      $form->{"sellprice_$i"} = $fxsellprice - $form->round_amount($fxsellprice * $form->{"discount_$i"}, $decimalplaces);

      # linetotal
      my $fxlinetotal = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, 2);

      $amount = $fxlinetotal * $form->{exchangerate};
      my $linetotal = $form->round_amount($amount, 2);
      $fxdiff += $amount - $linetotal;

      @taxaccounts = Tax::init_taxes($form, $form->{"taxaccounts_$i"});

      $tax = Math::BigFloat->bzero();
      $fxtax = Math::BigFloat->bzero();
      
      if ($form->{taxincluded}) {
        $tax += $amount = Tax::calculate_taxes(\@taxaccounts, $form, 
	  $linetotal, 1);
	$form->{"sellprice_$i"} -= $amount / $form{"qty_$i"};
      } else {
        $tax += $amount = Tax::calculate_taxes(\@taxaccounts, $form,
	  $linetotal, 0);
	$fxtax += Tax::calculate_taxes(\@taxaccounts, $form, 
	  $fxlinetotal, 0);
      }
      
      for (@taxaccounts) {
	$form->{acc_trans}{$form->{id}}{$_->account}{amount} += $_->value;
      }

      $grossamount = $form->round_amount($linetotal, 2);

      if ($form->{taxincluded}) {
	$amount = $form->round_amount($tax, 2);
	$linetotal -= $form->round_amount($tax - $diff, 2);
	$diff = ($amount - $tax);
      }
      
      $amount = $form->round_amount($linetotal, 2);
      $allocated = 0;

      # adjust and round sellprice
      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} * $form->{exchangerate}, $decimalplaces);

      # save detail record in invoice table
      $query = qq|INSERT INTO invoice (description)
                  VALUES ('$uid')|;
      $dbh->do($query) || $form->dberror($query);

      $query = qq|SELECT id FROM invoice
                  WHERE description = '$uid'|;
      ($invoice_id) = $dbh->selectrow_array($query);

      $query = qq|UPDATE invoice SET
                  trans_id = $form->{id},
		  parts_id = $form->{"id_$i"},
		  description = |.$dbh->quote($form->{"description_$i"}).qq|,
		  qty = $form->{"qty_$i"} * -1,
		  sellprice = $form->{"sellprice_$i"},
		  fxsellprice = $fxsellprice,
		  discount = $form->{"discount_$i"},
		  allocated = $allocated,
		  unit = |.$dbh->quote($form->{"unit_$i"}).qq|,
		  deliverydate = |.$form->dbquote($form->{"deliverydate_$i"}, SQL_DATE).qq|,
		  project_id = $project_id,
		  serialnumber = |.$dbh->quote($form->{"serialnumber_$i"}).qq|,
		  notes = |.$dbh->quote($form->{"notes_$i"}).qq|
		  WHERE id = $invoice_id|;
      $dbh->do($query) || $form->dberror($query);
      

      if ($form->{"inventory_accno_id_$i"}) {

	# add purchase to inventory
	push @{ $form->{acc_trans}{lineitems} }, {
	  chart_id => $form->{"inventory_accno_id_$i"},
	  amount => $amount,
	  fxgrossamount => $fxlinetotal + $form->round_amount($fxtax, 2),
	  grossamount => $grossamount,
	  project_id => $project_id,
	  invoice_id => $invoice_id };
	
	
	$updparts{$form->{"id_$i"}} = 1;

	# update parts table
	$form->update_balance($dbh,
	                      "parts",
			      "onhand",
			      qq|id = $form->{"id_$i"}|,
			      $form->{"qty_$i"}) unless $form->{shipped};
			      
	
        # check if we sold the item
	$query = qq|SELECT i.id, i.qty, i.allocated, i.trans_id, i.project_id,
		    p.inventory_accno_id, p.expense_accno_id, a.transdate
		    FROM invoice i
		    JOIN parts p ON (p.id = i.parts_id)
		    JOIN ar a ON (a.id = i.trans_id)
	            WHERE i.parts_id = $form->{"id_$i"}
		    AND (i.qty + i.allocated) > 0
		    ORDER BY transdate|;
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

        my $totalqty = $form->{"qty_$i"};
	
	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
	  
	  my $qty = $ref->{qty} + $ref->{allocated};

	  if (($qty - $totalqty) > 0) {
	    $qty = $totalqty;
	  }

	  $linetotal = $form->round_amount($form->{"sellprice_$i"} * $qty, 2);
	  $ref->{project_id} ||= 'NULL';

	  # add entry for inventory, this one is for the sold item
	  if ($linetotal) {
	    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
			transdate, project_id, invoice_id)
			VALUES ($ref->{trans_id}, $ref->{inventory_accno_id},
			$linetotal, '$ref->{transdate}', $ref->{project_id},
			$invoice_id)|;
	    $dbh->do($query) || $form->dberror($query);

	    # add expense
	    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
			transdate, project_id, invoice_id)
			VALUES ($ref->{trans_id}, $ref->{expense_accno_id},
			|. ($linetotal * -1) .qq|, '$ref->{transdate}',
			$ref->{project_id}, $invoice_id)|;
	    $dbh->do($query) || $form->dberror($query);
	  }
      
	  # update allocated for sold item
	  $form->update_balance($dbh,
				"invoice",
				"allocated",
				qq|id = $ref->{id}|,
				$qty * -1);
	
	  $allocated += $qty;

	  last if (($totalqty -= $qty) <= 0);
	}

	$sth->finish;

      } else {
	
	# add purchase to expense
	push @{ $form->{acc_trans}{lineitems} }, {
	  chart_id => $form->{"expense_accno_id_$i"},
	  amount => $amount,
	  fxgrossamount => $fxlinetotal + $form->round_amount($fxtax, 2),
	  grossamount => $grossamount,
	  project_id => $project_id,
	  invoice_id => $invoice_id };
	
      }
    }
  }

  $form->{paid} = 0;
  for $i (1 .. $form->{paidaccounts}) {
    $form->{"paid_$i"} = $form->parse_amount($myconfig, $form->{"paid_$i"});
    $form->{paid} += $form->{"paid_$i"};
    $form->{datepaid} = $form->{"datepaid_$i"} if ($form->{"datepaid_$i"});
  }

  # add lineitems + tax
  $amount = 0;
  $grossamount = 0;
  $fxgrossamount = 0;
  for (@{ $form->{acc_trans}{lineitems} }) {
    $amount += $_->{amount};
    $grossamount += $_->{grossamount};
    $fxgrossamount += $_->{fxgrossamount};
  }
  $invnetamount = $amount;

  $amount = 0;
  for (split / /, $form->{taxaccounts}) {
    $amount += $form->{acc_trans}{$form->{id}}{$_}{amount} = $form->round_amount($form->{acc_trans}{$form->{id}}{$_}{amount}, 2);
    $form->{acc_trans}{$form->{id}}{$_}{amount} *= -1;
  }
  $invamount = $invnetamount + $amount;

  $diff = 0;
  if ($form->{taxincluded}) {
    $diff = $form->round_amount($grossamount - $invamount, 2);
    $invamount += $diff;
  }
  $fxdiff = $form->round_amount($fxdiff,2);
  $invnetamount += $fxdiff;
  $invamount += $fxdiff;

  if ($form->round_amount($form->{paid} - $fxgrossamount,2) == 0) {
    $form->{paid} = $invamount;
  } else {
    $form->{paid} = $form->round_amount($form->{paid} * $form->{exchangerate}, 2);
  }
 
  foreach $ref (sort { $b->{amount} <=> $a->{amount} } @ { $form->{acc_trans}{lineitems} }) {
    $amount = $ref->{amount} + $diff + $fxdiff;
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                transdate, project_id, invoice_id)
                VALUES ($form->{id}, $ref->{chart_id}, $amount * -1,
		'$form->{transdate}', $ref->{project_id}, $ref->{invoice_id})|;
    $dbh->do($query) || $form->dberror($query);
    $diff = 0;
    $fxdiff = 0;
  }

  $form->{payables} = $invamount;
  
  delete $form->{acc_trans}{lineitems};
  
  # update exchangerate
  if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
    $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, 0, $form->{exchangerate});
  }
  
  # record payable
  if ($form->{payables}) {
    ($accno) = split /--/, $form->{AP};

    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                transdate)
                VALUES ($form->{id},
		       (SELECT id FROM chart
		       WHERE accno = '$accno'),
                $form->{payables}, '$form->{transdate}')|;
    $dbh->do($query) || $form->dberror($query);
  }

  foreach my $trans_id (keys %{$form->{acc_trans}}) {
    foreach my $accno (keys %{ $form->{acc_trans}{$trans_id} }) {
      $amount = $form->round_amount($form->{acc_trans}{$trans_id}{$accno}{amount}, 2);
      if ($amount) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate)
	            VALUES ($trans_id, (SELECT id FROM chart
		                        WHERE accno = '$accno'),
                    $amount, '$form->{transdate}')|;
        $dbh->do($query) || $form->dberror($query);
      }
    }
  }

  # if there is no amount but a payment record payable
  if ($invamount == 0) {
    $form->{payables} = 1;
  }

  my $cleared = 0;
  
  # record payments and offsetting AP
  for my $i (1 .. $form->{paidaccounts}) {

    if ($form->{"paid_$i"}) {
      my ($accno) = split /--/, $form->{"AP_paid_$i"};
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
      $form->{datepaid} = $form->{"datepaid_$i"};

      $exchangerate = 0;

      if ($form->{currency} eq $form->{defaultcurrency}) {
	$form->{"exchangerate_$i"} = 1;
      } else {
	$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'sell');

	$form->{"exchangerate_$i"} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{"exchangerate_$i"});
      }
      

      # record AP
      $amount = ($form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, 2)) * -1;
      
      if ($form->{payables}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
		    transdate)
		    VALUES ($form->{id}, (SELECT id FROM chart
					WHERE accno = '$form->{AP}'),
		    $amount, '$form->{"datepaid_$i"}')|;
	$dbh->do($query) || $form->dberror($query);
      }

      if ($keepcleared) {
	$cleared = ($form->{"cleared_$i"}) ? 1 : 0;
      }
      
      # record payment
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                  source, memo, cleared)
                  VALUES ($form->{id}, (SELECT id FROM chart
		                      WHERE accno = '$accno'),
                  $form->{"paid_$i"}, '$form->{"datepaid_$i"}', |
		  .$dbh->quote($form->{"source_$i"}).qq|, |
		  .$dbh->quote($form->{"memo_$i"}).qq|, '$cleared')|;
      $dbh->do($query) || $form->dberror($query);

      # exchangerate difference
      $amount = $form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"} - $form->{"paid_$i"}, 2);
      
      if ($amount) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, source, fx_transaction, cleared)
	            VALUES ($form->{id}, (SELECT id FROM chart
		                        WHERE accno = '$accno'),
		    $amount, '$form->{"datepaid_$i"}', |
		    .$dbh->quote($form->{"source_$i"}).qq|, '1', '$cleared')|;
        $dbh->do($query) || $form->dberror($query);
      }
 
      # gain/loss
      $amount = $form->round_amount($form->round_amount($form->{"paid_$i"} * $form->{exchangerate},2) - $form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"},2), 2);
      
      if ($amount) {
	my $accno_id = ($amount > 0) ? $fxgain_accno_id : $fxloss_accno_id;
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate, fx_transaction, cleared)
	            VALUES ($form->{id}, $accno_id,
		    $amount, '$form->{"datepaid_$i"}', '1', '$cleared')|;
        $dbh->do($query) || $form->dberror($query);
      }
      
      # update exchange rate
      if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
	$form->update_exchangerate($dbh, $form->{currency}, $form->{"datepaid_$i"}, 0, $form->{"exchangerate_$i"});
      }
    }
  }

  # set values which could be empty
  $form->{taxincluded} *= 1;

  $form->{invnumber} = $form->update_defaults($myconfig, "vinumber", $dbh) unless $form->{invnumber};

  # save AP record
  $query = qq|UPDATE ap set
              invnumber = |.$dbh->quote($form->{invnumber}).qq|,
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      quonumber = |.$dbh->quote($form->{quonumber}).qq|,
              transdate = '$form->{transdate}',
              vendor_id = $form->{vendor_id},
              amount = $invamount,
              netamount = $invnetamount,
              paid = $form->{paid},
	      datepaid = |.$form->dbquote($form->{datepaid}, SQL_DATE).qq|,
	      duedate = |.$form->dbquote($form->{duedate}, SQL_DATE).qq|,
	      invoice = '1',
	      shippingpoint = |.$dbh->quote($form->{shippingpoint}).qq|,
	      shipvia = |.$dbh->quote($form->{shipvia}).qq|,
	      taxincluded = '$form->{taxincluded}',
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      intnotes = |.$dbh->quote($form->{intnotes}).qq|,
	      curr = '$form->{currency}',
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      language_code = '$form->{language_code}',
	      ponumber = |.$dbh->quote($form->{ponumber}).qq|
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # add shipto
  $form->{name} = $form->{vendor};
  $form->{name} =~ s/--$form->{vendor_id}//;
  $form->add_shipto($dbh, $form->{id});
  
  my %audittrail = ( tablename  => 'ap',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'posted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);
 
  my $rc = $dbh->commit;

  foreach $item (keys %updparts) {
    $query = qq|UPDATE parts SET
		avgcost = avgcost($item),
		lastcost = lastcost($item)
		WHERE id = $item|;
    $dbh->do($query) || $form->dberror($query);
    $dbh->commit;
  }
  
  $dbh->disconnect;
  $rc;
  
}



sub reverse_invoice {
  my ($dbh, $form) = @_;
  
  my $query = qq|SELECT id FROM ap
                 WHERE id = $form->{id}|;
  my ($id) = $dbh->selectrow_array($query);

  return unless $id;
  
  # reverse inventory items
  $query = qq|SELECT i.parts_id, p.inventory_accno_id, p.expense_accno_id,
              i.qty, i.allocated, i.sellprice, i.project_id
              FROM invoice i, parts p
	      WHERE i.parts_id = p.id
              AND i.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $netamount = 0;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $netamount += $form->round_amount($ref->{sellprice} * $ref->{qty} * -1, 2);

    if ($ref->{inventory_accno_id}) {
      # update onhand
      $form->update_balance($dbh,
                            "parts",
			    "onhand",
			    qq|id = $ref->{parts_id}|,
			    $ref->{qty});
      
      # if $ref->{allocated} > 0 than we sold that many items
      if ($ref->{allocated} > 0) {

	# get references for sold items
	$query = qq|SELECT i.id, i.trans_id, i.allocated, a.transdate
	            FROM invoice i, ar a
		    WHERE i.parts_id = $ref->{parts_id}
		    AND i.allocated < 0
		    AND i.trans_id = a.id
		    ORDER BY transdate DESC|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $pthref = $sth->fetchrow_hashref(NAME_lc)) {
	  my $qty = $ref->{allocated};
	  
	  if (($ref->{allocated} + $pthref->{allocated}) > 0) {
	    $qty = $pthref->{allocated} * -1;
	  }

	  my $amount = $form->round_amount($ref->{sellprice} * $qty, 2);

	  #adjust allocated
	  $form->update_balance($dbh,
				"invoice",
				"allocated",
				qq|id = $pthref->{id}|,
				$qty);

          # add reversal for sale
	  $ref->{project_id} *= 1;
          $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
		      transdate, project_id)
		      VALUES ($pthref->{trans_id}, $ref->{expense_accno_id},
		      $amount, '$form->{transdate}', $ref->{project_id})|;
	  $dbh->do($query) || $form->dberror($query);
	  
          $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, 
		      transdate, project_id)
		      VALUES ($pthref->{trans_id}, $ref->{inventory_accno_id},
		      $amount * -1, '$form->{transdate}', $ref->{project_id})|;
	  $dbh->do($query) || $form->dberror($query);
  
	  last if (($ref->{allocated} -= $qty) <= 0);
	}
	$sth->finish;
      }
    }
  }
  $sth->finish;
  
  # delete acc_trans
  $query = qq|DELETE FROM acc_trans
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete invoice entries
  $query = qq|DELETE FROM invoice
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|DELETE FROM shipto
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->commit;

} 



sub delete_invoice {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my %audittrail = ( tablename  => 'ap',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  my $query = qq|SELECT parts_id FROM invoice
                 WHERE trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $item;
  my %updparts = ();
  while (($item) = $sth->fetchrow_array) {
    $updparts{$item} = 1;
  }
  $sth->finish;
 
  &reverse_invoice($dbh, $form);
  
  # delete AP record
  $query = qq|DELETE FROM ap
              WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete spool files
  $query = qq|SELECT spoolfile FROM status
              WHERE trans_id = $form->{id}
	      AND spoolfile IS NOT NULL|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my ${LedgerSMB::Sysconfig::spool}file;
  my @spoolfiles = ();

  while ((${LedgerSMB::Sysconfig::spool}file) = $sth->fetchrow_array) {
    push @spoolfiles, ${LedgerSMB::Sysconfig::spool}file;
  }
  $sth->finish;
  
  # delete status entries
  $query = qq|DELETE FROM status
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  my $rc = $dbh->commit;

  if ($rc) {
    foreach $item (keys %updparts) {
      $query = qq|UPDATE parts SET
		  avgcost = avgcost($item),
		  lastcost = lastcost($item)
		  WHERE id = $item|;
      $dbh->do($query) || $form->dberror($query);
      $dbh->commit;
    }

    foreach ${LedgerSMB::Sysconfig::spool}file (@spoolfiles) {
      unlink "${LedgerSMB::Sysconfig::spool}/$spoolfile" if $spoolfile;
    }
  }
  
  $dbh->disconnect;

  $rc;
  
}



sub retrieve_invoice {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;

  if ($form->{id}) {
    # get default accounts and last invoice number
    $query = qq|SELECT (SELECT c.accno FROM chart c
                        WHERE d.inventory_accno_id = c.id) AS inventory_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.income_accno_id = c.id) AS income_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.expense_accno_id = c.id) AS expense_accno,
		       (SELECT c.accno FROM chart c
		        WHERE d.fxgain_accno_id = c.id) AS fxgain_accno,
		       (SELECT c.accno FROM chart c
		        WHERE d.fxloss_accno_id = c.id) AS fxloss_accno,
                d.curr AS currencies
	 	FROM defaults d|;
  } else {
    $query = qq|SELECT (SELECT c.accno FROM chart c
                        WHERE d.inventory_accno_id = c.id) AS inventory_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.income_accno_id = c.id) AS income_accno,
                       (SELECT c.accno FROM chart c
		        WHERE d.expense_accno_id = c.id) AS expense_accno,
		       (SELECT c.accno FROM chart c
		        WHERE d.fxgain_accno_id = c.id) AS fxgain_accno,
		       (SELECT c.accno FROM chart c
		        WHERE d.fxloss_accno_id = c.id) AS fxloss_accno,
                d.curr AS currencies,
		current_date AS transdate
	 	FROM defaults d|;
  }
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) {
    $form->{$_} = $ref->{$_};
  }
  $sth->finish;


  if ($form->{id}) {
    
    # retrieve invoice
    $query = qq|SELECT a.invnumber, a.transdate, a.duedate,
                a.ordnumber, a.quonumber, a.paid, a.taxincluded, a.notes,
		a.intnotes, a.curr AS currency, a.vendor_id, a.language_code,
		a.ponumber
		FROM ap a
		WHERE id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) {
      $form->{$_} = $ref->{$_};
    }
    $sth->finish;

    # get shipto
    $query = qq|SELECT * FROM shipto
                WHERE trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) {
      $form->{$_} = $ref->{$_};
    }
    $sth->finish;
    
    # retrieve individual items
    $query = qq|SELECT
		p.partnumber, i.description, i.qty, i.fxsellprice, i.sellprice,
		i.parts_id AS id, i.unit, p.bin, i.deliverydate,
		pr.projectnumber,
                i.project_id, i.serialnumber, i.discount, i.notes,
		pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		p.weight, p.onhand,
		p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		t.description AS partsgrouptranslation
		FROM invoice i
		JOIN parts p ON (i.parts_id = p.id)
		LEFT JOIN project pr ON (i.project_id = pr.id)
		LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		LEFT JOIN translation t ON (t.trans_id = p.partsgroup_id AND t.language_code = '$form->{language_code}')
		WHERE i.trans_id = $form->{id}
		ORDER BY i.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # exchangerate defaults
    &exchangerate_defaults($dbh, $form);

    # price matrix and vendor partnumber
    my $pmh = PriceMatrix::PriceMatrixQuery($dbh, $form);

    # tax rates for part
    $query = qq|SELECT c.accno
		FROM chart c
		JOIN partstax pt ON (pt.chart_id = c.id)
		WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query);

    my $ptref;

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

      my ($dec) = ($ref->{fxsellprice} =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;

      $tth->execute($ref->{id});
      $ref->{taxaccounts} = "";
      my $taxrate = 0;
      
      while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
        $ref->{taxaccounts} .= "$ptref->{accno} ";
        $taxrate += $form->{"$ptref->{accno}_rate"};
      }
      
      $tth->finish;
      chop $ref->{taxaccounts};

      # price matrix
      $ref->{sellprice} = $form->round_amount($ref->{fxsellprice} * $form->{$form->{currency}}, $decimalplaces);
      PriceMatrix::price_matrix($pmh, $ref, $decimalplaces, $form, $myconfig);

      $ref->{sellprice} = $ref->{fxsellprice};
      $ref->{qty} *= -1;

      $ref->{partsgroup} = $ref->{partsgrouptranslation} if $ref->{partsgrouptranslation};
      
      push @{ $form->{invoice_details} }, $ref;
      
    }
    
    $sth->finish;
    
  }
  
  
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;
  
}


sub retrieve_item {
  my ($self, $myconfig, $form) = @_;

  my $i = $form->{rowcount};
  my $null;
  my $var;
  
  # don't include assemblies or obsolete parts
  my $where = "WHERE p.assembly = '0' AND p.obsolete = '0'";
  
  if ($form->{"partnumber_$i"} ne "") {
    $var = $form->like(lc $form->{"partnumber_$i"});
    $where .= " AND lower(p.partnumber) LIKE '$var'";
  }
  
  if ($form->{"description_$i"} ne "") {
    $var = $form->like(lc $form->{"description_$i"});
    if ($form->{language_code} ne "") {
      $where .= " AND lower(t1.description) LIKE '$var'";
    } else {
      $where .= " AND lower(p.description) LIKE '$var'";
    }
  }

  if ($form->{"partsgroup_$i"} ne "") {
    ($null, $var) = split /--/, $form->{"partsgroup_$i"};
    $var *= 1;
    $where .= qq| AND p.partsgroup_id = $var|;
  }
  
  if ($form->{"description_$i"} ne "") {
    $where .= " ORDER BY 3";
  } else {
    $where .= " ORDER BY 2";
  }

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT p.id, p.partnumber, p.description,
		 pg.partsgroup, p.partsgroup_id,
                 p.lastcost AS sellprice, p.unit, p.bin, p.onhand, p.notes,
		 p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		 p.partnumber AS sku, p.weight,
		 t1.description AS translation,
		 t2.description AS grouptranslation
                 FROM parts p
		 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		 LEFT JOIN translation t1 ON (t1.trans_id = p.id AND t1.language_code = '$form->{language_code}')
		 LEFT JOIN translation t2 ON (t2.trans_id = p.partsgroup_id AND t2.language_code = '$form->{language_code}')
	         $where|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  # foreign currency
  &exchangerate_defaults($dbh, $form);

  # taxes
  $query = qq|SELECT c.accno
	      FROM chart c
	      JOIN partstax pt ON (pt.chart_id = c.id)
	      WHERE pt.parts_id = ?|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);

  # price matrix
  my $pmh = PriceMatrix::price_matrix_query($dbh, $form);

  my $ref;
  my $ptref;
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    my ($dec) = ($ref->{sellprice} =~ /\.(\d+)/);
    $dec = length $dec;
    my $decimalplaces = ($dec > 2) ? $dec : 2;

    # get taxes for part
    $tth->execute($ref->{id});

    $ref->{taxaccounts} = "";
    while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
      $ref->{taxaccounts} .= "$ptref->{accno} ";
    }
    $tth->finish;
    chop $ref->{taxaccounts};

    # get vendor price and partnumber
    PriceMatrix::price_matrix($pmh, $ref, $decimalplaces, $form, $myconfig);

    $ref->{description} = $ref->{translation} if $ref->{translation};
    $ref->{partsgroup} = $ref->{grouptranslation} if $ref->{grouptranslation};
    
    push @{ $form->{item_list} }, $ref;
    
  }
  
  $sth->finish;
  $dbh->disconnect;
  
}


sub exchangerate_defaults {
  my ($dbh, $form) = @_;

  my $var;
  
  # get default currencies
  my $query = qq|SELECT substr(curr,1,3), curr FROM defaults|;
  my $eth = $dbh->prepare($query) || $form->dberror($query);
  $eth->execute;
  ($form->{defaultcurrency}, $form->{currencies}) = $eth->fetchrow_array;
  $eth->finish;

  $query = qq|SELECT sell
              FROM exchangerate
	      WHERE curr = ?
	      AND transdate = ?|;
  my $eth1 = $dbh->prepare($query) || $form->dberror($query);

  $query = qq~SELECT max(transdate || ' ' || sell || ' ' || curr)
              FROM exchangerate
	      WHERE curr = ?~;
  my $eth2 = $dbh->prepare($query) || $form->dberror($query);

  # get exchange rates for transdate or max
  foreach $var (split /:/, substr($form->{currencies},4)) {
    $eth1->execute($var, $form->{transdate});
    ($form->{$var}) = $eth1->fetchrow_array;
    if (! $form->{$var} ) {
      $eth2->execute($var);

      ($form->{$var}) = $eth2->fetchrow_array;
      ($null, $form->{$var}) = split / /, $form->{$var};
      $form->{$var} = 1 unless $form->{$var};
      $eth2->finish;
    }
    $eth1->finish;
  }

  $form->{$form->{currency}} = $form->{exchangerate} if $form->{exchangerate};
  $form->{$form->{currency}} ||= 1;
  $form->{$form->{defaultcurrency}} = 1;
  
}


sub vendor_details {
  my ($self, $myconfig, $form) = @_;
      
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  # get rest for the vendor
  my $query = qq|SELECT vendornumber, name, address1, address2, city, state,
                 zipcode, country,
                 contact, phone as vendorphone, fax as vendorfax, vendornumber,
		 taxnumber AS vendortaxnumber, sic_code AS sic, iban, bic,
		 gifi_accno AS gifi, startdate, enddate
                 FROM vendor
                 WHERE id = $form->{vendor_id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) {
    $form->{$_} = $ref->{$_};
  }

  $sth->finish;
  $dbh->disconnect;

}


sub item_links {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT accno, description, link
	         FROM chart
	         WHERE link LIKE '%IC%'
		 ORDER BY accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    foreach my $key (split(/:/, $ref->{link})) {
      if ($key =~ /IC/) {
        push @{ $form->{IC_links}{$key} }, { accno => $ref->{accno},
                                       description => $ref->{description} };
      }
    }
  }

  $sth->finish;
}

1;

