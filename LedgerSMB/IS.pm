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
#`
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
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


sub invoice_details {
  my ($self, $myconfig, $form) = @_;

  $form->{duedate} = $form->{transdate} unless ($form->{duedate});

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT date '$form->{duedate}' - date '$form->{transdate}'
                 AS terms, weightunit
		 FROM defaults|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  ($form->{terms}, $form->{weightunit}) = $sth->fetchrow_array;
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
  my $partsgroup;
  
  my %oid = ( 'Pg'	=> 'TRUE',
              'Oracle'	=> 'rowid',
	      'DB2'	=> '1=1'
	    );
  
  my @taxaccounts;
  my %taxaccounts;
  my $tax;
  my $taxrate;
  my $taxamount;
 
  my %translations;
  
  $query = qq|SELECT p.description, t.description
              FROM project p
	      LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
	      WHERE id = ?|;
  my $prh = $dbh->prepare($query) || $form->dberror($query);

  $query = qq|SELECT inventory_accno_id, income_accno_id,
              expense_accno_id, assembly, weight FROM parts
              WHERE id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);

  my $sortby;
  
  # sort items by project and partsgroup
  for $i (1 .. $form->{rowcount} - 1) {

    # account numbers
    $pth->execute($form->{"id_$i"});
    $ref = $pth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
    $pth->finish;

    $projectnumber_id = 0;
    $projectnumber = "";
    $form->{partsgroup} = "";
    $form->{projectnumber} = "";
    
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      
      $inventory_accno_id = ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) ? "1" : "";
      
      if ($form->{groupprojectnumber}) {
	($projectnumber, $projectnumber_id) = split /--/, $form->{"projectnumber_$i"};
      }
      if ($form->{grouppartsgroup}) {
	($form->{partsgroup}) = split /--/, $form->{"partsgroup_$i"};
      }
      
      if ($projectnumber_id && $form->{groupprojectnumber}) {
	if ($translation{$projectnumber_id}) {
	  $form->{projectnumber} = $translation{$projectnumber_id};
	} else {
	  # get project description
	  $prh->execute($projectnumber_id);
	  ($projectdescription, $translation) = $prh->fetchrow_array;
	  $prh->finish;
	  
	  $form->{projectnumber} = ($translation) ? "$projectnumber, $translation" : "$projectnumber, $projectdescription";

	  $translation{$projectnumber_id} = $form->{projectnumber};
	}
      }

      if ($form->{grouppartsgroup} && $form->{partsgroup}) {
	$form->{projectnumber} .= " / " if $projectnumber_id;
	$form->{projectnumber} .= $form->{partsgroup};
      }
      
      $form->format_string(projectnumber);

    }

    $sortby = qq|$projectnumber$form->{partsgroup}|;
    if ($form->{sortby} ne 'runningnumber') {
      for (qw(partnumber description bin)) {
	$sortby .= $form->{"${_}_$i"} if $form->{sortby} eq $_;
      }
    }

    push @sortlist, [ $i, qq|$projectnumber$form->{partsgroup}$inventory_accno_id|, $form->{projectnumber}, $projectnumber_id, $form->{partsgroup}, $sortby ];

  }

  # sort the whole thing by project and group
  @sortlist = sort { $a->[5] cmp $b->[5] } @sortlist;

  my $runningnumber = 1;
  my $sameitem = "";
  my $subtotal;
  my $k = scalar @sortlist;
  my $j = 0;

  foreach $item (@sortlist) {

    $i = $item->[0];
    $j++;

    # heading
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($item->[1] ne $sameitem) {
	$sameitem = $item->[1];
	
	$ok = 0;

	if ($form->{groupprojectnumber}) {
	  $ok = $form->{"projectnumber_$i"};
	}
	if ($form->{grouppartsgroup}) {
	  $ok = $form->{"partsgroup_$i"} unless $ok;
	}

	if ($ok) {
	  
	  if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
	    push(@{ $form->{part} }, "");
	    push(@{ $form->{service} }, NULL);
	  } else {
	    push(@{ $form->{part} }, NULL);
	    push(@{ $form->{service} }, "");
	  }
    
	  push(@{ $form->{description} }, $item->[2]);
	  for (qw(taxrates runningnumber number sku serialnumber bin qty ship unit deliverydate projectnumber sellprice listprice netprice discount discountrate linetotal weight itemnotes)) { push(@{ $form->{$_} }, "") }
	  push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
	}
      }
    }
      
    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
    
    if ($form->{"qty_$i"}) {

      $form->{totalqty} += $form->{"qty_$i"};
      $form->{totalship} += $form->{"qty_$i"};
      $form->{totalweight} += ($form->{"qty_$i"} * $form->{"weight_$i"});
      $form->{totalweightship} += ($form->{"qty_$i"} * $form->{"weight_$i"});

      # add number, description and qty to $form->{number}, ....
      push(@{ $form->{runningnumber} }, $runningnumber++);
      push(@{ $form->{number} }, $form->{"partnumber_$i"});
      push(@{ $form->{sku} }, $form->{"sku_$i"});
      push(@{ $form->{serialnumber} }, $form->{"serialnumber_$i"});
      push(@{ $form->{bin} }, $form->{"bin_$i"});
      push(@{ $form->{description} }, $form->{"description_$i"});
      push(@{ $form->{itemnotes} }, $form->{"notes_$i"});
      push(@{ $form->{qty} }, $form->format_amount($myconfig, $form->{"qty_$i"}));
      push(@{ $form->{ship} }, $form->format_amount($myconfig, $form->{"qty_$i"}));
      push(@{ $form->{unit} }, $form->{"unit_$i"});
      push(@{ $form->{deliverydate} }, $form->{"deliverydate_$i"});
      push(@{ $form->{projectnumber} }, $form->{"projectnumber_$i"});
      
      push(@{ $form->{sellprice} }, $form->{"sellprice_$i"});
      
      # listprice
      push(@{ $form->{listprice} }, $form->{"listprice_$i"});
      
      push(@{ $form->{weight} }, $form->format_amount($myconfig, $form->{"weight_$i"} * $form->{"qty_$i"}));

      my $sellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});
      my ($dec) = ($sellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;
      
      my $discount = $form->round_amount($sellprice * $form->parse_amount($myconfig, $form->{"discount_$i"})/100, $decimalplaces);
      
      # keep a netprice as well, (sellprice - discount)
      $form->{"netprice_$i"} = $sellprice - $discount;
      
      my $linetotal = $form->round_amount($form->{"qty_$i"} * $form->{"netprice_$i"}, 2);

      if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
	push(@{ $form->{part} }, $form->{"sku_$i"});
	push(@{ $form->{service} }, NULL);
	$form->{totalparts} += $linetotal;
      } else {
	push(@{ $form->{service} }, $form->{"sku_$i"});
	push(@{ $form->{part} }, NULL);
	$form->{totalservices} += $linetotal;
      }

      push(@{ $form->{netprice} }, ($form->{"netprice_$i"}) ? $form->format_amount($myconfig, $form->{"netprice_$i"}, $decimalplaces) : " ");
      
      $discount = ($discount) ? $form->format_amount($myconfig, $discount * -1, $decimalplaces) : " ";
      $linetotal = ($linetotal) ? $linetotal : " ";
      
      push(@{ $form->{discount} }, $discount);
      push(@{ $form->{discountrate} }, $form->format_amount($myconfig, $form->{"discount_$i"}));

      $form->{total} += $linetotal;

      # this is for the subtotals for grouping
      $subtotal += $linetotal;

      $form->{"linetotal_$i"} = $form->format_amount($myconfig, $linetotal, 2);
      push(@{ $form->{linetotal} }, $form->{"linetotal_$i"});
      
      @taxaccounts = Tax::init_taxes($form, $form->{"taxaccounts_$i"});
      
      my $ml = 1;
      my @taxrates = ();
      
      $tax = 0;
      
      if ($form->{taxincluded}) {
        $taxamount = Tax::calculate_taxes(\@taxaccounts, $form, $linetotal, 1);
        $taxbase = ($linetotal - $taxamount);
	$tax += Tax::extract_taxes(\@taxaccounts, $form, $linetotal);
      } else {
        $taxamount = Tax::calculate_taxes(\@taxaccounts, $form, $linetotal, 0);
	$tax += Tax::apply_taxes(\@taxaccounts, $form, $linetotal);
      }

      foreach $item (@taxaccounts) {
        push @taxrates, 100 * $item->rate;
	$taxaccounts{$item->account} += $item->value;
	if ($form->{taxincluded}) {
	  $taxbase{$item->account} += $taxbase;
	} else {
	  $taxbase{$item->account} += $linetotal;
	}
      }

      push(@{ $form->{lineitems} }, { amount => $linetotal, tax => $form->round_amount($tax, 2) });
      push(@{ $form->{taxrates} }, join ' ', sort { $a <=> $b } @taxrates);
      
      if ($form->{"assembly_$i"}) {
	$form->{stagger} = -1;
	&assembly_details($myconfig, $form, $dbh, $form->{"id_$i"}, $oid{$myconfig->{dbdriver}}, $form->{"qty_$i"});
      }

    }

    # add subtotal
    if ($form->{groupprojectnumber} || $form->{grouppartsgroup}) {
      if ($subtotal) {
	if ($j < $k) {
	  # look at next item
	  if ($sortlist[$j]->[1] ne $sameitem) {

	    if ($form->{"inventory_accno_id_$j"} || $form->{"assembly_$i"}) {
	      push(@{ $form->{part} }, "");
	      push(@{ $form->{service} }, NULL);
	    } else {
	      push(@{ $form->{service} }, "");
	      push(@{ $form->{part} }, NULL);
	    }

	    for (qw(taxrates runningnumber number sku serialnumber bin qty ship unit deliverydate projectnumber sellprice listprice netprice discount discountrate weight itemnotes)) { push(@{ $form->{$_} }, "") }
	    
	    push(@{ $form->{description} }, $form->{groupsubtotaldescription});
	    
	    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });

	    if ($form->{groupsubtotaldescription} ne "") {
	      push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, 2));
	    } else {
	      push(@{ $form->{linetotal} }, "");
	    }
	    $subtotal = 0;
	  }
	  
	} else {

	  # got last item
	  if ($form->{groupsubtotaldescription} ne "") {

	    if ($form->{"inventory_accno_id_$j"} || $form->{"assembly_$i"}) {
	      push(@{ $form->{part} }, "");
	      push(@{ $form->{service} }, NULL);
	    } else {
	      push(@{ $form->{service} }, "");
	      push(@{ $form->{part} }, NULL);
	    }

	    for (qw(taxrates runningnumber number sku serialnumber bin qty ship unit deliverydate projectnumber sellprice listprice netprice discount discountrate weight itemnotes)) { push(@{ $form->{$_} }, "") }

	    push(@{ $form->{description} }, $form->{groupsubtotaldescription});
	    push(@{ $form->{linetotal} }, $form->format_amount($myconfig, $subtotal, 2));
	    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
	  }
	}
      }
    }
  }

   
  $tax = 0;
  foreach my $item (sort keys %taxaccounts) {
    if ($form->round_amount($taxaccounts{$item}, 2)) {
      $tax += $taxamount = $form->round_amount($taxaccounts{$item}, 2);
      
      push(@{ $form->{taxbaseinclusive} }, $form->{"${item}_taxbaseinclusive"} = $form->format_amount($myconfig, $taxbase{$item} + $tax, 2));
      push(@{ $form->{taxbase} }, $form->{"${item}_taxbase"} = $form->format_amount($myconfig, $taxbase{$item}, 2));
      push(@{ $form->{tax} }, $form->{"${item}_tax"} = $form->format_amount($myconfig, $taxamount, 2));
      
      push(@{ $form->{taxdescription} }, $form->{"${item}_description"});
      
      $form->{"${item}_taxrate"} = $form->format_amount($myconfig, $form->{"${item}_rate"} * 100);
      push(@{ $form->{taxrate} }, $form->{"${item}_taxrate"});
      push(@{ $form->{taxnumber} }, $form->{"${item}_taxnumber"});
    }
  }
    
  # adjust taxes for lineitems
  my $total = 0;
  for (@{ $form->{lineitems} }) {
    $total += $_->{tax};
  }
  if ($form->round_amount($total,2) != $form->round_amount($tax,2)) {
    # get largest amount
    for (reverse sort { $a->{tax} <=> $b->{tax} } @{ $form->{lineitems} }) {
      $_->{tax} -= $total - $tax;
      last;
    }
  }
  $i = 1;
  for (@{ $form->{lineitems} }) {
    push(@{ $form->{linetax} }, $form->format_amount($myconfig, $_->{tax}, 2, ""));
  }
  
 
  for $i (1 .. $form->{paidaccounts}) {
    if ($form->{"paid_$i"}) {
      push(@{ $form->{payment} }, $form->{"paid_$i"});
      my ($accno, $description) = split /--/, $form->{"AR_paid_$i"};
      push(@{ $form->{paymentaccount} }, $description); 
      push(@{ $form->{paymentdate} }, $form->{"datepaid_$i"});
      push(@{ $form->{paymentsource} }, $form->{"source_$i"});
      push(@{ $form->{paymentmemo} }, $form->{"memo_$i"});

      $form->{paid} += $form->parse_amount($myconfig, $form->{"paid_$i"});
    }
  }

  for (qw(totalparts totalservices)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}, 2) }
  for (qw(totalqty totalship totalweight)) { $form->{$_} = $form->format_amount($myconfig, $form->{$_}) }
  $form->{subtotal} = $form->format_amount($myconfig, $form->{total}, 2);
  $form->{invtotal} = ($form->{taxincluded}) ? $form->{total} : $form->{total} + $tax;

  use LedgerSMB::CP;
  my $c;
  if ($form->{language_code} ne "") {
    $c = new CP $form->{language_code};
  } else {
    $c = new CP $myconfig->{countrycode};
  }
  $c->init;
  my $whole;
  ($whole, $form->{decimal}) = split /\./, $form->{invtotal};
  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $form->format_amount($myconfig, $whole);
 
  $form->format_string(qw(text_amount text_decimal));

  $form->{total} = $form->format_amount($myconfig, $form->{invtotal} - $form->{paid}, 2);
  $form->{invtotal} = $form->format_amount($myconfig, $form->{invtotal}, 2);

  $form->{paid} = $form->format_amount($myconfig, $form->{paid}, 2);

  $dbh->disconnect;
  
}


sub assembly_details {
  my ($myconfig, $form, $dbh, $id, $oid, $qty) = @_;
  
  my $sm = "";
  my $spacer;
  
  $form->{stagger}++;
  if ($form->{format} eq 'html') {
    $spacer = "&nbsp;" x (3 * ($form->{stagger} - 1)) if $form->{stagger} > 1;
  }
  if ($form->{format} =~ /(postscript|pdf)/) {
    if ($form->{stagger} > 1) {
      $spacer = ($form->{stagger} - 1) * 3;
      $spacer = '\rule{'.$spacer.'mm}{0mm}';
    }
  }
  
  # get parts and push them onto the stack
  my $sortorder = "";

  if ($form->{grouppartsgroup}) {
    $sortorder = qq|ORDER BY pg.partsgroup|;
  }
  
  my $query = qq|SELECT p.partnumber, p.description, p.unit, a.qty,
	         pg.partsgroup, p.partnumber AS sku
	         FROM assembly a
	         JOIN parts p ON (a.parts_id = p.id)
	         LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
	         WHERE a.bom = '1'
	         AND a.id = '$id'
	         $sortorder|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    for (qw(partnumber description partsgroup)) {
      $form->{"a_$_"} = $ref->{$_};
      $form->format_string("a_$_");
    }

    if ($form->{grouppartsgroup} && $ref->{partsgroup} ne $sm) {
      for (qw(taxrates runningnumber number sku serialnumber unit qty ship bin deliverydate projectnumber sellprice listprice netprice discount discountrate linetotal weight itemnotes)) { push(@{ $form->{$_} }, "") }
      $sm = ($form->{"a_partsgroup"}) ? $form->{"a_partsgroup"} : "--";
      push(@{ $form->{description} }, "$spacer$sm");
      push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });
    }
    
    if ($form->{stagger}) {
      
      push(@{ $form->{description} }, $form->format_amount($myconfig, $ref->{qty} * $form->{"qty_$i"}) . qq| -- $form->{"a_partnumber"}, $form->{"a_description"}|);
      for (qw(taxrates runningnumber number sku serialnumber unit qty ship bin deliverydate projectnumber sellprice listprice netprice discount discountrate linetotal weight itemnotes)) { push(@{ $form->{$_} }, "") }
      
    } else {
      
      push(@{ $form->{description} }, qq|$form->{"a_description"}|);
      push(@{ $form->{number} }, $form->{"a_partnumber"});
      push(@{ $form->{sku} }, $form->{"a_partnumber"});

      for (qw(taxrates runningnumber ship serialnumber reqdate projectnumber sellprice listprice netprice discount discountrate linetotal weight itemnotes)) { push(@{ $form->{$_} }, "") }
      
    }

    push(@{ $form->{lineitems} }, { amount => 0, tax => 0 });

    push(@{ $form->{qty} }, $form->format_amount($myconfig, $ref->{qty} * $qty));
    
    for (qw(unit bin)) {
      $form->{"a_$_"} = $ref->{$_};
      $form->format_string("a_$_");
      push(@{ $form->{$_} }, $form->{"a_$_"});
    }

  }
  $sth->finish;

  $form->{stagger}--;
  
}


sub project_description {
  my ($self, $dbh, $id) = @_;

  my $query = qq|SELECT description
                 FROM project
		 WHERE id = $id|;
  ($_) = $dbh->selectrow_array($query);

  $_;

}


sub customer_details {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  # get rest for the customer
  my $query = qq|SELECT customernumber, name, address1, address2, city,
                 state, zipcode, country,
	         contact, phone as customerphone, fax as customerfax,
		 taxnumber AS customertaxnumber, sic_code AS sic, iban, bic,
		 startdate, enddate
	         FROM customer
	         WHERE id = $form->{customer_id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }

  $sth->finish;
  $dbh->disconnect;

}


sub post_invoice {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database, turn off autocommit
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  my $null;
  my $project_id;
  my $exchangerate = 0;
  my $keepcleared = 0;
  
  %$form->{acc_trans} = ();

  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  }
  
  ($null, $form->{department_id}) = split(/--/, $form->{department});
  $form->{department_id} *= 1;

  $query = qq|SELECT fxgain_accno_id, fxloss_accno_id
              FROM defaults|;
  my ($fxgain_accno_id, $fxloss_accno_id) = $dbh->selectrow_array($query);

  $query = qq|SELECT p.assembly, p.inventory_accno_id,
              p.income_accno_id, p.expense_accno_id, p.project_id
	      FROM parts p
	      WHERE p.id = ?|;
  my $pth = $dbh->prepare($query) || $form->dberror($query);
  
  if ($form->{id}) {
    $keepcleared = 1;
    $query = qq|SELECT id FROM ar
                WHERE id = $form->{id}|;

    if ($dbh->selectrow_array($query)) {
      &reverse_invoice($dbh, $form);
    } else {
      $query = qq|INSERT INTO ar (id)
                  VALUES ($form->{id})|;
      $dbh->do($query) || $form->dberror($query);
    }
    
  }
  
  my $uid = localtime;
  $uid .= "$$";
 
  if (! $form->{id}) {
   
    $query = qq|INSERT INTO ar (invnumber, employee_id)
                VALUES ('$uid', $form->{employee_id})|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM ar
                WHERE invnumber = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;

    @queries = $form->run_custom_queries('ar', 'INSERT');
  }


  if ($form->{currency} eq $form->{defaultcurrency}) {
    $form->{exchangerate} = 1;
  } else {
    $exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, 'buy');
  }

  $form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate});

  my $i;
  my $item;
  my $allocated = 0;
  my $taxrate;
  my $tax;
  my $fxtax;
  my @taxaccounts;
  my $amount;
  my $grossamount;
  my $invamount = 0;
  my $invnetamount = 0;
  my $diff = 0;
  my $ml;
  my $invoice_id;
  my $ndx;

  foreach $i (1 .. $form->{rowcount}) {
    $form->{"qty_$i"} = $form->parse_amount($myconfig, $form->{"qty_$i"});
    
    if ($form->{"qty_$i"}) {
      
      $pth->execute($form->{"id_$i"});
      $ref = $pth->fetchrow_hashref(NAME_lc);
      for (keys %$ref) { $form->{"${_}_$i"} = $ref->{$_} }
      $pth->finish;

      # project
      $project_id = 'NULL';
      if ($form->{"projectnumber_$i"}) {
	($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
      }
      $project_id = $form->{"project_id_$i"} if $form->{"project_id_$i"};

      # keep entered selling price
      my $fxsellprice = $form->parse_amount($myconfig, $form->{"sellprice_$i"});

      my ($dec) = ($fxsellprice =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;
      
      # undo discount formatting
      $form->{"discount_$i"} = $form->parse_amount($myconfig, $form->{"discount_$i"})/100;
     
      # deduct discount
      $form->{"sellprice_$i"} = $fxsellprice - $form->round_amount($fxsellprice * $form->{"discount_$i"}, $decimalplaces);
      
      # linetotal
      my $fxlinetotal = $form->round_amount($form->{"sellprice_$i"} * $form->{"qty_$i"}, 2);

      $amount = $fxlinetotal * $form->{exchangerate};
      my $linetotal = $form->round_amount($amount, 2);
      $fxdiff += $amount - $linetotal;
      
      @taxaccounts = Tax::init_taxes($form, $form->{"taxaccounts_$i"});
      $ml = 1;
      $tax = 0;
      $fxtax = 0;
      
      if ($form->{taxincluded}) {
        $tax += $amount = Tax::calculate_taxes(\@taxaccounts, $form,
		$linetotal, 1);
	$form->{"sellprice_$i"} -= $amount / $form->{"qty_$i"};
	$fxtax += Tax::calculate_taxes(\@taxaccounts, $form, $linetotal, 1);
      } else {
        $tax += $amount = Tax::calculate_taxes(\@taxaccounts, $form,
		$linetotal, 0);
	$fxtax += Tax::calculate_taxes(\@taxaccounts, $form, $linetotal, 0);
      }

      $grossamount = $form->round_amount($linetotal, 2);
      
      if ($form->{taxincluded}) {
	$amount = $form->round_amount($tax, 2);
	$linetotal -= $form->round_amount($tax - $diff, 2);
	$diff = ($amount - $tax);
      }
      
      # add linetotal to income
      $amount = $form->round_amount($linetotal, 2);

      push @{ $form->{acc_trans}{lineitems} }, {
        chart_id => $form->{"income_accno_id_$i"},
	amount => $amount,
	fxgrossamount => $fxlinetotal + $fxtax,
	grossamount => $grossamount,
	project_id => $project_id };
      $ndx = $#{@{$form->{acc_trans}{lineitems}}};

      $form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"} * $form->{exchangerate}, $decimalplaces);
  
      if ($form->{"inventory_accno_id_$i"} || $form->{"assembly_$i"}) {
	
        if ($form->{"assembly_$i"}) {
          # do not update if assembly consists of all services
	  $query = qq|SELECT sum(p.inventory_accno_id), p.assembly
	              FROM parts p
		      JOIN assembly a ON (a.parts_id = p.id)
		      WHERE a.id = $form->{"id_$i"}
		      GROUP BY p.assembly|;
          $sth = $dbh->prepare($query);
	  $sth->execute || $form->dberror($query);
	  my ($inv, $assembly) = $sth->fetchrow_array;
	  $sth->finish;
		      
          if ($inv || $assembly) {
	    $form->update_balance($dbh,
				  "parts",
				  "onhand",
				  qq|id = $form->{"id_$i"}|,
				  $form->{"qty_$i"} * -1) unless $form->{shipped};
	  }

	  &process_assembly($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id);
	} else {
	  $form->update_balance($dbh,
	                        "parts",
				"onhand",
				qq|id = $form->{"id_$i"}|,
				$form->{"qty_$i"} * -1) unless $form->{shipped};
				
	  $allocated = &cogs($dbh, $form, $form->{"id_$i"}, $form->{"qty_$i"}, $project_id);
	}
      }

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
		  qty = $form->{"qty_$i"},
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

      # add invoice_id
      $form->{acc_trans}{lineitems}[$ndx]->{invoice_id} = $invoice_id;
      
    }
  }

  $form->{paid} = 0;
  for $i (1 .. $form->{paidaccounts}) {
    $form->{"paid_$i"} = $form->parse_amount($myconfig, $form->{"paid_$i"});
    $form->{paid} += $form->{"paid_$i"};
    $form->{datepaid} = $form->{"datepaid_$i"} if ($form->{"paid_$i"});
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
    $amount += 
      $form->{acc_trans}{$form->{id}}{$_}{amount} = 
      $form->round_amount($form->{acc_trans}{$form->{id}}{$_}{amount}, 2); 
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
		VALUES ($form->{id}, $ref->{chart_id}, $amount,
	      '$form->{transdate}', $ref->{project_id}, $ref->{invoice_id})|;
    $dbh->do($query) || $form->dberror($query);
    $diff = 0;
    $fxdiff = 0;
  }
  
  $form->{receivables} = $invamount * -1;
 
  delete $form->{acc_trans}{lineitems};
  
  # update exchangerate
  if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
    $form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $form->{exchangerate}, 0);
  }

  # record receivable
  if ($form->{receivables}) {
    ($accno) = split /--/, $form->{AR};

    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
                transdate)
                VALUES ($form->{id},
		       (SELECT id FROM chart
		        WHERE accno = '$accno'),
                $form->{receivables}, '$form->{transdate}')|;
    $dbh->do($query) || $form->dberror($query);
  }

  foreach my $trans_id (keys %{$form->{acc_trans}}) {
    foreach my $accno (keys %{$form->{acc_trans}{$trans_id}}) {
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

  
  # if there is no amount but a payment record receivable
  if ($invamount == 0) {
    $form->{receivables} = 1;
  }
  
  my $cleared = 0;
  
  # record payments and offsetting AR
  for $i (1 .. $form->{paidaccounts}) {
    
    if ($form->{"paid_$i"}) {
      my ($accno) = split /--/, $form->{"AR_paid_$i"};
      $form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});
      $form->{datepaid} = $form->{"datepaid_$i"};
      
      $exchangerate = 0;
      
      if ($form->{currency} eq $form->{defaultcurrency}) {
	$form->{"exchangerate_$i"} = 1;
      } else {
	$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{"datepaid_$i"}, 'buy');
	
	$form->{"exchangerate_$i"} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{"exchangerate_$i"});
      }
      
 
      # record AR
      $amount = $form->round_amount($form->{"paid_$i"} * $form->{exchangerate}, 2);

      if ($form->{receivables}) {
	$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
	            transdate)
		    VALUES ($form->{id}, (SELECT id FROM chart
					WHERE accno = '$form->{AR}'),
		    $amount, '$form->{"datepaid_$i"}')|;
	$dbh->do($query) || $form->dberror($query);
      }

      # record payment
      $amount = $form->{"paid_$i"} * -1;
      if ($keepcleared) {
	$cleared = ($form->{"cleared_$i"}) ? 1 : 0;
      }
      
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
                  source, memo, cleared)
                  VALUES ($form->{id}, (SELECT id FROM chart
		                      WHERE accno = '$accno'),
		  $amount, '$form->{"datepaid_$i"}', |
		  .$dbh->quote($form->{"source_$i"}).qq|, |
		  .$dbh->quote($form->{"memo_$i"}).qq|, '$cleared')|;
      $dbh->do($query) || $form->dberror($query);

      # exchangerate difference
      $amount = $form->round_amount(($form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"} - $form->{"paid_$i"}, 2)) * -1, 2);

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
      $amount = $form->round_amount(($form->round_amount($form->{"paid_$i"} * $form->{exchangerate},2) - $form->round_amount($form->{"paid_$i"} * $form->{"exchangerate_$i"},2)) * -1, 2);

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
	$form->update_exchangerate($dbh, $form->{currency}, $form->{"datepaid_$i"}, $form->{"exchangerate_$i"}, 0);
      }
    }
  }

  # set values which could be empty to 0
  $form->{terms} *= 1;
  $form->{taxincluded} *= 1;

  # if this is from a till
  my $till = ($form->{till}) ? qq|'$form->{till}'| : "NULL";

  $form->{invnumber} = $form->update_defaults($myconfig, "sinumber", $dbh) unless $form->{invnumber};

  # save AR record
  $query = qq|UPDATE ar set
              invnumber = |.$dbh->quote($form->{invnumber}).qq|,
	      ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
	      quonumber = |.$dbh->quote($form->{quonumber}).qq|,
              transdate = '$form->{transdate}',
              customer_id = $form->{customer_id},
              amount = $invamount,
              netamount = $invnetamount,
              paid = $form->{paid},
	      datepaid = |.$form->dbquote($form->{datepaid}, SQL_DATE).qq|,
	      duedate = |.$form->dbquote($form->{duedate}, SQL_DATE).qq|,
	      invoice = '1',
	      shippingpoint = |.$dbh->quote($form->{shippingpoint}).qq|,
	      shipvia = |.$dbh->quote($form->{shipvia}).qq|,
	      terms = $form->{terms},
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      intnotes = |.$dbh->quote($form->{intnotes}).qq|,
	      taxincluded = '$form->{taxincluded}',
	      curr = '$form->{currency}',
	      department_id = $form->{department_id},
	      employee_id = $form->{employee_id},
	      till = $till,
	      language_code = '$form->{language_code}',
	      ponumber = |.$dbh->quote($form->{ponumber}).qq|
              WHERE id = $form->{id}
             |;
  $dbh->do($query) || $form->dberror($query);

  # add shipto
  $form->{name} = $form->{customer};
  $form->{name} =~ s/--$form->{customer_id}//;
  $form->add_shipto($dbh, $form->{id});

  # save printed, emailed and queued
  $form->save_status($dbh);
  
  my %audittrail = ( tablename  => 'ar',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'posted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);

  my $rc = $dbh->commit;

  $dbh->disconnect;

  $rc;
  
}


sub process_assembly {
  my ($dbh, $form, $id, $totalqty, $project_id) = @_;

  my $query = qq|SELECT a.parts_id, a.qty, p.assembly,
                 p.partnumber, p.description, p.unit,
                 p.inventory_accno_id, p.income_accno_id,
		 p.expense_accno_id
                 FROM assembly a
		 JOIN parts p ON (a.parts_id = p.id)
		 WHERE a.id = $id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $allocated;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    $allocated = 0;
    
    $ref->{inventory_accno_id} *= 1;
    $ref->{expense_accno_id} *= 1;

    # multiply by number of assemblies
    $ref->{qty} *= $totalqty;
    
    if ($ref->{assembly}) {
      &process_assembly($dbh, $form, $ref->{parts_id}, $ref->{qty}, $project_id);
      next;
    } else {
      if ($ref->{inventory_accno_id}) {
	$allocated = &cogs($dbh, $form, $ref->{parts_id}, $ref->{qty}, $project_id);
      }
    }

    # save detail record for individual assembly item in invoice table
    $query = qq|INSERT INTO invoice (trans_id, description, parts_id, qty,
                sellprice, fxsellprice, allocated, assemblyitem, unit)
		VALUES
		($form->{id}, |
		.$dbh->quote($ref->{description}).qq|,
		$ref->{parts_id}, $ref->{qty}, 0, 0, $allocated, 't', |
		.$dbh->quote($ref->{unit}).qq|)|;
    $dbh->do($query) || $form->dberror($query);
	 
  }

  $sth->finish;

}


sub cogs {
  my ($dbh, $form, $id, $totalqty, $project_id) = @_;

  my $query = qq|SELECT i.id, i.trans_id, i.qty, i.allocated, i.sellprice,
                 i.fxsellprice, p.inventory_accno_id, p.expense_accno_id
		 FROM invoice i, parts p
		 WHERE i.parts_id = p.id
		 AND i.parts_id = $id
		 AND (i.qty + i.allocated) < 0
		 ORDER BY trans_id|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $allocated = 0;
  my $qty;
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    if (($qty = (($ref->{qty} * -1) - $ref->{allocated})) > $totalqty) {
      $qty = $totalqty;
    }
    
    $form->update_balance($dbh,
			  "invoice",
			  "allocated",
			  qq|id = $ref->{id}|,
			  $qty);

    # total expenses and inventory
    # sellprice is the cost of the item
    my $linetotal = $form->round_amount($ref->{sellprice} * $qty, 2);

    # add expense
    push @{ $form->{acc_trans}{lineitems} }, {
      chart_id => $ref->{expense_accno_id},
      amount => $linetotal * -1,
      project_id => $project_id,
      invoice_id => $ref->{id} };

    # deduct inventory
    push @{ $form->{acc_trans}{lineitems} }, {
      chart_id => $ref->{inventory_accno_id},
      amount => $linetotal,
      project_id => $project_id,
      invoice_id => $ref->{id} };

    # add allocated
    $allocated += -$qty;
    
    last if (($totalqty -= $qty) <= 0);
  }

  $sth->finish;

  $allocated;
  
}



sub reverse_invoice {
  my ($dbh, $form) = @_;
  
  my $query = qq|SELECT id FROM ar
                 WHERE id = $form->{id}|;
  my ($id) = $dbh->selectrow_array($query);

  return unless $id;

  # reverse inventory items
  my $query = qq|SELECT i.id, i.parts_id, i.qty, i.assemblyitem, p.assembly,
		 p.inventory_accno_id
                 FROM invoice i
		 JOIN parts p ON (i.parts_id = p.id)
		 WHERE i.trans_id = $form->{id}|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    if ($ref->{inventory_accno_id} || $ref->{assembly}) {

      # if the invoice item is not an assemblyitem adjust parts onhand
      if (!$ref->{assemblyitem}) {
        # adjust onhand in parts table
	$form->update_balance($dbh,
	                      "parts",
			      "onhand",
			      qq|id = $ref->{parts_id}|,
			      $ref->{qty});
      }

      # loop if it is an assembly
      next if ($ref->{assembly});
      
      # de-allocated purchases
      $query = qq|SELECT id, trans_id, allocated
                  FROM invoice
		  WHERE parts_id = $ref->{parts_id}
		  AND allocated > 0
		  ORDER BY trans_id DESC|;
      my $sth = $dbh->prepare($query);
      $sth->execute || $form->dberror($query);

      while (my $inhref = $sth->fetchrow_hashref(NAME_lc)) {
	$qty = $ref->{qty};
	if (($ref->{qty} - $inhref->{allocated}) > 0) {
	  $qty = $inhref->{allocated};
	}
	
	# update invoice
	$form->update_balance($dbh,
			      "invoice",
			      "allocated",
			      qq|id = $inhref->{id}|,
			      $qty * -1);

        last if (($ref->{qty} -= $qty) <= 0);
      }
      $sth->finish;
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
  my ($self, $myconfig, $form, ${LedgerSMB::Sysconfig::spool}) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  &reverse_invoice($dbh, $form);
  
  my %audittrail = ( tablename  => 'ar',
                     reference  => $form->{invnumber},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);
     
  # delete AR record
  my $query = qq|DELETE FROM ar
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
    $query = qq|SELECT d.curr AS currencies
		FROM defaults d|;
  } else {
    $query = qq|SELECT d.curr AS currencies, current_date AS transdate
                FROM defaults d|;
  }
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref = $sth->fetchrow_hashref(NAME_lc);
  for (keys %$ref) { $form->{$_} = $ref->{$_} }
  $sth->finish;

  
  if ($form->{id}) {
    
    # retrieve invoice
    $query = qq|SELECT a.invnumber, a.ordnumber, a.quonumber,
                a.transdate, a.paid,
                a.shippingpoint, a.shipvia, a.terms, a.notes, a.intnotes,
		a.duedate, a.taxincluded, a.curr AS currency,
		a.employee_id, e.name AS employee, a.till, a.customer_id,
		a.language_code, a.ponumber
		FROM ar a
	        LEFT JOIN employee e ON (e.id = a.employee_id)
		WHERE a.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # get shipto
    $query = qq|SELECT * FROM shipto
                WHERE trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # retrieve individual items
    $query = qq|SELECT i.description, i.qty, i.fxsellprice, i.sellprice,
		i.discount, i.parts_id AS id, i.unit, i.deliverydate,
		i.project_id, pr.projectnumber, i.serialnumber, i.notes,
		p.partnumber, p.assembly, p.bin,
		pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		p.listprice, p.lastcost, p.weight, p.onhand,
		p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		t.description AS partsgrouptranslation
		FROM invoice i
	        JOIN parts p ON (i.parts_id = p.id)
	        LEFT JOIN project pr ON (i.project_id = pr.id)
	        LEFT JOIN partsgroup pg ON (p.partsgroup_id = pg.id)
		LEFT JOIN translation t ON (t.trans_id = p.partsgroup_id AND t.language_code = '$form->{language_code}')
		WHERE i.trans_id = $form->{id}
		AND NOT i.assemblyitem = '1'
		ORDER BY i.id|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # foreign currency
    &exchangerate_defaults($dbh, $form);

    # query for price matrix
    my $pmh = PriceMatrix::price_matrix_query($dbh, $form);
    
    # taxes
    $query = qq|SELECT c.accno
		FROM chart c
		JOIN partstax pt ON (pt.chart_id = c.id)
		WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);
   
    my $taxrate;
    my $ptref;
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

      my ($dec) = ($ref->{fxsellprice} =~ /\.(\d+)/);
      $dec = length $dec;
      my $decimalplaces = ($dec > 2) ? $dec : 2;

      $tth->execute($ref->{id});

      $ref->{taxaccounts} = "";
      $taxrate = 0;
      
      while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
	$ref->{taxaccounts} .= "$ptref->{accno} ";
	$taxrate += $form->{"$ptref->{accno}_rate"};
      }
      $tth->finish;
      chop $ref->{taxaccounts};

      # price matrix
      $ref->{sellprice} = ($ref->{fxsellprice} * $form->{$form->{currency}});
      PriceMatrix::price_matrix($pmh, $ref, $form->{transdate}, $decimalplaces, $form, $myconfig);
      $ref->{sellprice} = $ref->{fxsellprice};

      $ref->{partsgroup} = $ref->{partsgrouptranslation} if $ref->{partsgrouptranslation};
      
      push @{ $form->{invoice_details} }, $ref;
    }
    $sth->finish;

  }

  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  @queries = $form->run_custom_queries('ar', 'SELECT');
  $form->{dbh}->commit;
  $rc;

}


sub retrieve_item {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $i = $form->{rowcount};
  my $null;
  my $var;

  my $where = "WHERE p.obsolete = '0' AND NOT p.income_accno_id IS NULL";

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
    if ($var == 0) {
      # search by partsgroup, this is for the POS
      $where .= qq| AND pg.partsgroup = '$form->{"partsgroup_$i"}'|;
    } else {
      $where .= qq| AND p.partsgroup_id = $var|;
    }
  }

  if ($form->{"description_$i"} ne "") {
    $where .= " ORDER BY 3";
  } else {
    $where .= " ORDER BY 2";
  }
  
  my $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
                 p.listprice, p.lastcost,
		 p.unit, p.assembly, p.bin, p.onhand, p.notes,
		 p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		 pg.partsgroup, p.partsgroup_id, p.partnumber AS sku,
		 p.weight,
		 t1.description AS translation,
		 t2.description AS grouptranslation
                 FROM parts p
		 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		 LEFT JOIN translation t1 ON (t1.trans_id = p.id AND t1.language_code = '$form->{language_code}')
		 LEFT JOIN translation t2 ON (t2.trans_id = p.partsgroup_id AND t2.language_code = '$form->{language_code}')
	         $where|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $ref;
  my $ptref;

  # setup exchange rates
  &exchangerate_defaults($dbh, $form);
  
  # taxes
  $query = qq|SELECT c.accno
	      FROM chart c
	      JOIN partstax pt ON (c.id = pt.chart_id)
	      WHERE pt.parts_id = ?|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);


  # price matrix
  my $pmh = PriceMatrix::price_matrix_query($dbh, $form);

  my $transdate = $form->datetonum($myconfig, $form->{transdate});
  
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

    # get matrix
    PriceMatrix::price_matrix($pmh, $ref, $transdate, $decimalplaces, $form, $myconfig);

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

  $query = qq|SELECT buy
              FROM exchangerate
	      WHERE curr = ?
	      AND transdate = ?|;
  my $eth1 = $dbh->prepare($query) || $form->dberror($query);

  $query = qq~SELECT max(transdate || ' ' || buy || ' ' || curr)
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


1;

