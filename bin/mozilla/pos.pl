#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# POS
#
#=====================================================================


1;
# end


sub add {

  $form->{title} = $locale->text('Add POS Invoice');

  $form->{callback} = "$form->{script}?action=$form->{nextsub}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};
  
  &invoice_links;

  $form->{type} =  "pos_invoice";
  $form->{format} = "txt";
  $form->{media} = ($myconfig{printer}) ? $myconfig{printer} : "screen";
  $form->{rowcount} = 0;

  $form->{readonly} = ($myconfig{acs} =~ /POS--Sale/) ? 1 : 0;

  $ENV{REMOTE_ADDR} =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  $form->{till} = $4;

  $form->{partsgroup} = "";
  for (@{ $form->{all_partsgroup} }) { $form->{partsgroup} .= "$_->{partsgroup}--$_->{translation}\n"; }

  &display_form;

}


sub openinvoices {

  $ENV{REMOTE_ADDR} =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  $form->{till} = $4;
  
  $form->{sort} = 'transdate';

  for (qw(open l_invnumber l_transdate l_name l_amount l_curr l_till l_subtotal)) { $form->{$_} = 'Y'; }

  if ($myconfig{role} ne 'user') {
    $form->{l_employee} = 'Y';
  }

  $form->{title} = $locale->text('Open');
  transactions;
  
}


sub edit {

  $form->{title} = $locale->text('Edit POS Invoice');

  $form->{callback} = "$form->{script}?action=$form->{nextsub}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};
  
  &invoice_links;
  &prepare_invoice;

  $form->{type} =  "pos_invoice";
  $form->{format} = "txt";
  $form->{media} = ($myconfig{printer}) ? $myconfig{printer} : "screen";

  $form->{readonly} = ($myconfig{acs} =~ /POS--Sale/) ? 1 : 0;

  $form->{partsgroup} = "";
  for (@{ $form->{all_partsgroup} }) { $form->{partsgroup} .= "$_->{partsgroup}--$_->{translation}\n"; }
  
  &display_form;

}


sub form_header {

  # set option selected
  for (qw(AR currency)) {
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/option>\Q$form->{$_}\E/option selected>$form->{$_}/;
  }

  for (qw(customer department employee)) {
    $form->{"select$_"} = $form->unescape($form->{"select$_"});
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
  }
    
  $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

  $exchangerate = qq|<tr>|;
  $exchangerate .= qq|
                <th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td> | if $form->{defaultcurrency};
  $exchangerate .= qq|
                <input type=hidden name=selectcurrency value="$form->{selectcurrency}"> 
		<input type=hidden name=defaultcurrency value=$form->{defaultcurrency}>
|;
		
  if ($form->{defaultcurrency} && $form->{currency} ne $form->{defaultcurrency}) {
    if ($form->{forex}) {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchange Rate').qq|</th><td>$form->{exchangerate}<input type=hidden name=exchangerate value=$form->{exchangerate}></td>|;
    } else {
      $exchangerate .= qq|<th align=right>|.$locale->text('Exchange Rate').qq|</th><td><input name=exchangerate size=10 value=$form->{exchangerate}></td>|;
    }
  }
  $exchangerate .= qq|
<input type=hidden name=forex value=$form->{forex}>
</tr>
|;

  if ($form->{selectcustomer}) {
    $customer = qq|<select name=customer>$form->{selectcustomer}</select>
                   <input type=hidden name="selectcustomer" value="|.
		   $form->escape($form->{selectcustomer},1).qq|">|;
  } else {
    $customer = qq|<input name=customer value="$form->{customer}" size=35>|;
  }
  
  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td colspan=3><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|.
		$form->escape($form->{selectdepartment},1).qq|">
		</td>
	      </tr>
| if $form->{selectdepartment};

   $employee = qq|
	      <tr>
	        <th align=right nowrap>|.$locale->text('Salesperson').qq|</th>
		<td colspan=3><select name=employee>$form->{selectemployee}</select></td>
		<input type=hidden name=selectemployee value="|.
		$form->escape($form->{selectemployee},1).qq|">
	      </tr>
| if $form->{selectemployee};

  if ($form->{change} != $form->{oldchange}) {
    $form->{creditremaining} -= $form->{oldchange};
  }
  $n = ($form->{creditremaining} < 0) ? "0" : "1";

  if ($form->{business}) {
    $business = qq|
              <tr>
	        <th align=right nowrap>|.$locale->text('Business').qq|</th>
		<td>$form->{business}</td>
		<td width=10></td>
		<th align=right nowrap>|.$locale->text('Trade Discount').qq|</th>
		<td>|.$form->format_amount(\%myconfig, $form->{tradediscount} * 100).qq| %</td>
	      </tr>
|;
  }

  if ($form->{selectlanguage}) {
    if ($form->{language_code} ne $form->{oldlanguage_code}) {
      # rebuild partsgroup
      $form->get_partsgroup(\%myconfig, { language_code => $form->{language_code}, searchitems => 'nolabor'});
      $form->{partsgroup} = "";
      for (@{ $form->{all_partsgroup} }) { $form->{partsgroup} .= "$_->{partsgroup}--$_->{translation}\n"; }
      $form->{oldlanguage_code} = $form->{language_code};
    }

      
    $form->{"selectlanguage"} = $form->unescape($form->{"selectlanguage"});
    $form->{"selectlanguage"} =~ s/ selected//;
    $form->{"selectlanguage"} =~ s/(<option value="\Q$form->{language_code}\E")/$1 selected/; 
    $lang = qq|
	      <tr>
                <th align=right>|.$locale->text('Language').qq|</th>
		<td colspan=3><select name=language_code>$form->{selectlanguage}</select></td>
	      </tr>
    <input type=hidden name=oldlanguage_code value=$form->{oldlanguage_code}>
    <input type=hidden name=selectlanguage value="|.
    $form->escape($form->{selectlanguage},1).qq|">|;
  }

  $i = $form->{rowcount} + 1;
  $focus = "partnumber_$i";
  
  $form->header;
 
  print qq|
<body onLoad="document.forms[0].${focus}.focus()" />

<form method=post action="$form->{script}">
|;

  $form->hide_form(qw(id till type format printed title discount creditlimit creditremaining tradediscount business closedto locked oldtransdate customer_id oldcustomer));

  print qq|
<input type=hidden name=vc value="customer">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$form->{title}</font></th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Customer').qq|</th>
		<td colspan=3>$customer</td>
	      </tr>
	      <tr>
	        <td></td>
		<td colspan=3>
		  <table>
		    <tr>
		      <th align=right nowrap>|.$locale->text('Credit Limit').qq|</th>
		      <td>$form->{creditlimit}</td>
		      <td width=10></td>
		      <th align=right nowrap>|.$locale->text('Remaining').qq|</th>
		      <td class="plus$n">|.$form->format_amount(\%myconfig, $form->{creditremaining}, 0, "0").qq|</font></td>
		    </tr>
		    $business
		  </table>
		</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Record in').qq|</th>
		<td colspan=3><select name=AR>$form->{selectAR}</select></td>
		<input type=hidden name=selectAR value="$form->{selectAR}">
	      </tr>
	      $department
	    </table>
	  </td>
	  <td>
	    <table>
	      $employee
	      $exchangerate
	      $lang
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
    </td>
  </tr>
|;

  $form->hide_form(qw(taxaccounts duedate invnumber transdate selectcurrency defaultcurrency));

  for (split / /, $form->{taxaccounts}) {
    $form->hide_form("${_}_rate", "${_}_description", "${_}_taxnumber");
  }

}



sub form_footer {

  $form->{invtotal} = $form->{invsubtotal};

  $form->{taxincluded} = ($form->{taxincluded}) ? "checked" : "";

  $taxincluded = "";
  if ($form->{taxaccounts}) {
    $taxincluded = qq|
              <tr height="5"></tr>
	      <tr>
	        <td align=right>
		<input name=taxincluded class=checkbox type=checkbox value=1 $form->{taxincluded}></td><th align=left>|.$locale->text('Tax Included').qq|</th>
	      </tr>
|;
  }
  
  if (!$form->{taxincluded}) {
    
    for (split / /, $form->{taxaccounts}) {
      if ($form->{"${_}_base"}) {
	$form->{"${_}_total"} = $form->round_amount($form->{"${_}_base"} * $form->{"${_}_rate"}, 2);
	$form->{invtotal} += $form->{"${_}_total"};
	$form->{"${_}_total"} = $form->format_amount(\%myconfig, $form->{"${_}_total"}, 2, 0);
	
	$tax .= qq|
	      <tr>
		<th align=right>$form->{"${_}_description"}</th>
		<td align=right>$form->{"${_}_total"}</td>
	      </tr>
|;
      }
    }

    $form->{invsubtotal} = $form->format_amount(\%myconfig, $form->{invsubtotal}, 2, 0);

    $subtotal = qq|
	      <tr>
		<th align=right>|.$locale->text('Subtotal').qq|</th>
		<td align=right>$form->{invsubtotal}</td>
	      </tr>
|;
  }

  @column_index = qw(paid source memo AR_paid);

  $column_data{paid} = "<th>".$locale->text('Amount')."</th>";
  $column_data{source} = "<th>".$locale->text('Source')."</th>";
  $column_data{memo} = "<th>".$locale->text('Memo')."</th>";
  $column_data{AR_paid} = "<th>&nbsp;</th>";
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr valign=top>
	  <td>
	    <table>
	      <tr>
|;

  for (@column_index) { print "$column_data{$_}\n"; }
  
  print qq|
	      </tr>
|;

  $totalpaid = 0;
  
  $form->{paidaccounts}++ if ($form->{"paid_$form->{paidaccounts}"});
  for $i (1 .. $form->{paidaccounts}) {
  
    $form->{"selectAR_paid_$i"} = $form->{selectAR_paid};
    $form->{"selectAR_paid_$i"} =~ s/option>\Q$form->{"AR_paid_$i"}\E/option selected>$form->{"AR_paid_$i"}/;
  
  # format amounts
    $totalpaid += $form->{"paid_$i"};
    $form->{"paid_$i"} = $form->format_amount(\%myconfig, $form->{"paid_$i"}, 2);
    $form->{"exchangerate_$i"} = $form->format_amount(\%myconfig, $form->{"exchangerate_$i"});


    $column_data{paid} = qq|<td><input name="paid_$i" size=11 value=$form->{"paid_$i"}></td>|;
    $column_data{source} = qq|<td><input name="source_$i" size=10 value="$form->{"source_$i"}"></td>|;
    $column_data{memo} = qq|<td><input name="memo_$i" size=10 value="$form->{"memo_$i"}"></td>|;
    $column_data{AR_paid} = qq|<td><select name="AR_paid_$i">$form->{"selectAR_paid_$i"}</select></td>|;

    print qq|
	      <tr>
|;
    for (@column_index) { print "$column_data{$_}\n"; }
  
    print qq|
	      </tr>
|;

    $form->hide_form("cleared_$i", "exchangerate_$i", "forex_$i");

  }
  
  $form->{change} = 0;
  if ($totalpaid > $form->{invtotal}) {
    $form->{change} = $totalpaid - $form->{invtotal};
  }
  $form->{oldchange} = $form->{change};
  $form->{change} = $form->format_amount(\%myconfig, $form->{change}, 2, 0);
  $form->{totalpaid} = $form->format_amount(\%myconfig, $totalpaid, 2);
 
  $form->{oldinvtotal} = $form->{invtotal};
  $form->{invtotal} = $form->format_amount(\%myconfig, $form->{invtotal}, 2, 0);
 
  print qq|
	      <tr>
		<th align=right>|.$locale->text('Change').qq|</th>
		<th>$form->{change}</th>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $subtotal
	      $tax
	      <tr>
		<th align=right>|.$locale->text('Total').qq|</th>
		<td align=right>$form->{invtotal}</td>
	      </tr>
	      $taxincluded
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
 
<input type=hidden name=oldtotalpaid value=$totalpaid>
<input type=hidden name=datepaid value=$form->{transdate}>

<tr>
  <td>
|;

  $form->hide_form(qw(paidaccounts selectAR_paid oldinvtotal change oldchange invtotal));
  
  &print_options;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $transdate = $form->datetonum(\%myconfig, $form->{transdate});
  $closedto = $form->datetonum(\%myconfig, $form->{closedto});

# type=submit $locale->text('Update')
# type=submit $locale->text('Print')
# type=submit $locale->text('Post')
# type=submit $locale->text('Print and Post')
# type=submit $locale->text('Delete')

  if (! $form->{readonly}) {
    %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	       'Print' => { ndx => 2, key => 'P', value => $locale->text('Print') },
	       'Post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
	       'Print and Post' => { ndx => 4, key => 'R', value => $locale->text('Print and Post') },
	       'Delete' => { ndx => 5, key => 'D', value => $locale->text('Delete') },
	      );
   
    if ($transdate > $closedto) {

      if (! $form->{id}) {
	delete $button{'Delete'};
      }

      delete $button{'Print and Post'} unless $latex;
    } else {
      for ('Print', 'Post', 'Print and Post', 'Delete') { delete $button{$_} }
    }
      
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

    print qq|<p>
    <input type=text size=1 value="B" accesskey="B" title="[Alt-B]">\n|;
  
    if ($form->{partsgroup}) {
      $form->{partsgroup} =~ s/\r//g;
      $form->{partsgroup} = $form->quote($form->{partsgroup});

      $spc = ($form->{path} =~ /lynx/) ? "." : " ";
      print qq|
<input type=hidden name=nextsub value=lookup_partsgroup>
<input type=hidden name=partsgroup value="$form->{partsgroup}">|;

      foreach $item (split /\n/, $form->{partsgroup}) {
	($partsgroup, $translation) = split /--/, $item;
	$item = ($translation) ? $translation : $partsgroup;
	print qq| <input class=submit type=submit name=action value="$spc$item">\n| if $item;
      }
    }
  }

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }
  
  $form->hide_form(qw(rowcount callback path login sessionid));
  
  print qq|
</form>

</body>
</html>
|;

}


sub post {

  $form->isblank("customer", $locale->text('Customer missing!'));

  # if oldcustomer ne customer redo form
  $customer = $form->{customer};
  $customer =~ s/--.*//g;
  $customer .= "--$form->{customer_id}";
  if ($customer ne $form->{oldcustomer}) {
    &update;
    exit;
  }
  
  &validate_items;

  $form->isblank("exchangerate", $locale->text('Exchange rate missing!')) if ($form->{currency} ne $form->{defaultcurrency});
  
  $paid = 0;
  for (1 .. $form->{paidaccounts}) { $paid += $form->parse_amount(\%myconfig, $form->{"paid_$_"}); }
  delete $form->{datepaid} unless $paid;
  
  $total = $form->parse_amount(\%myconfig, $form->{invtotal});
  
  # deduct change from first payment
  $form->{"paid_1"} = $form->format_amount(\%myconfig, $form->parse_amount(\%myconfig, $form->{"paid_1"}) - ($paid - $total), 2) if $paid > $total;
  
  ($form->{AR}) = split /--/, $form->{AR};

  if (IS->post_invoice(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Posted!'));
  } else {
    $form->error($locale->text('Cannot post transaction!'));
  }
  
}


sub display_row {
  my $numrows = shift;

  @column_index = qw(partnumber description partsgroup qty unit sellprice discount linetotal);
    
  $form->{invsubtotal} = 0;

  for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0; }
  
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Price').qq|</th>|;
  $column_data{linetotal} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading nowrap>%</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}"; };

  print qq|
        </tr>
|;

  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate = ($exchangerate) ? $exchangerate : 1;
  
  for $i (1 .. $numrows) {
    # undo formatting
    for (qw(qty discount sellprice)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}); }

    ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
    $dec = length $dec;
    $decimalplaces = ($dec > 2) ? $dec : 2;

    if (($form->{"qty_$i"} != $form->{"oldqty_$i"}) || ($form->{currency} ne $form->{oldcurrency})) {
      # check for a pricematrix
      @a = split / /, $form->{"pricematrix_$i"};
      if (scalar @a) {
	foreach $item (@a) {
	  ($q, $p) = split /:/, $item;
	  if (($p * 1) && ($form->{"qty_$i"} >= ($q * 1))) {
	    ($dec) = ($p =~ /\.(\d+)/);
	    $dec = length $dec;
	    $decimalplaces = ($dec > 2) ? $dec : 2;
	    $form->{"sellprice_$i"} = $form->round_amount($p / $exchangerate, $decimalplaces);
	  }
	}
      }
    }
    
    if ($i < $numrows) {
      $column_data{discount} = qq|<td align=right><input name="discount_$i" size=3 value=|.$form->format_amount(\%myconfig, $form->{"discount_$i"}).qq|></td>|;
    } else {
      $column_data{discount} = qq|<td></td>|;
    }
    
    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, 2);

    for (qw(partnumber sku description partsgroup unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}); }
    
    $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=20 value="$form->{"partnumber_$i"}" accesskey="$i" title="[Alt-$i]"></td>|;

    if (($rows = $form->numtextrows($form->{"description_$i"}, 40, 6)) > 1) {
      $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=46 wrap=soft>$form->{"description_$i"}</textarea></td>|;
    } else {
      $column_data{description} = qq|<td><input name="description_$i" size=48 value="$form->{"description_$i"}"></td>|;
    }

    $column_data{qty} = qq|<td align=right><input name="qty_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|></td>|;
    $column_data{unit} = qq|<td>$form->{"unit_$i"}</td>|;
    $column_data{sellprice} = qq|<td align=right><input name="sellprice_$i" size=9 value=|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces).qq|></td>|;
    $column_data{linetotal} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, 2).qq|</td>|;
    
    print qq|
        <tr valign=top>|;

    for (@column_index) { print "\n$column_data{$_}"; }
  
    print qq|
        </tr>
|;

    $form->{"oldqty_$i"} = $form->{"qty_$i"};

    for (qw(id listprice lastcost taxaccounts pricematrix oldqty sku partsgroup unit inventory_accno_id income_accno_id expense_accno_id)) { $form->hide_form("${_}_$i") }
      
    for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $linetotal; }
  
    $form->{invsubtotal} += $linetotal;
  }

  print qq|
      </table>
    </td>
  </tr>

<input type=hidden name=oldcurrency value=$form->{currency}>

|;

}


sub print {
  
  if (!$form->{invnumber}) {
    $form->{invnumber} = $form->update_defaults(\%myconfig, "sinumber");
    if ($form->{media} eq 'screen') {
      &update;
      exit;
    }
  }

  $old_form = new Form;
  for (keys %$form) { $old_form->{$_} = $form->{$_}; }
  
  for (qw(employee department)) { $form->{$_} =~ s/--.*//g; }
  $form->{invdate} = $form->{transdate};
  $form->{dateprinted} = scalar localtime;

  &print_form($old_form);

}


sub print_form {
  my $old_form = shift;
  
  # if oldcustomer ne customer redo form
  $customer = $form->{customer};
  $customer =~ s/--.*//g;
  $customer .= "--$form->{customer_id}";
  if ($customer ne $form->{oldcustomer}) {
    &update;
    exit;
  }

  &validate_items;

  &{ "$form->{vc}_details" };

  @a = ();
  for (1 .. $form->{rowcount}) { push @a, ("partnumber_$_", "description_$_"); }
  for (split / /, $form->{taxaccounts}) { push @a, "${_}_description"; }
  $form->format_string(@a);

  # format payment dates
  for (1 .. $form->{paidaccounts}) { $form->{"datepaid_$_"} = $locale->date(\%myconfig, $form->{"datepaid_$_"}); }
  
  IS->invoice_details(\%myconfig, \%$form);

  if ($form->parse_amount(\%myconfig, $form->{total}) <= 0) {
    $form->{total} = 0;
  } else {
    $form->{change} = 0;
  }

  for (qw(company address tel fax businessnumber)) { $form->{$_} = $myconfig{$_}; }
  $form->{username} = $myconfig{name};

  $form->{address} =~ s/\\n/\n/g;
  push @a, qw(company address tel fax businessnumber username);
  $form->format_string(@a);

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = "$form->{type}.$form->{format}";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }
  
  if ($form->{media} ne 'screen') {
    $form->{OUT} = "| $printer{$form->{media}}";
  }

  $form->{discount} = $form->format_amount(\%myconfig, $form->{discount} * 100);
  
  $form->{rowcount}--;
  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>";
  delete $form->{stylesheet};
  
  $form->parse_template(\%myconfig, $userspath);

  if ($form->{printed} !~ /$form->{formname}/) {
    $form->{printed} .= " $form->{formname}";
    $form->{printed} =~ s/^ //;
    
    $form->update_status(\%myconfig);
  }
  $old_form->{printed} = $form->{printed};
  
  # if we got back here restore the previous form
  if ($form->{media} ne 'screen') {
    # restore and display form
    for (keys %$old_form) { $form->{$_} = $old_form->{$_}; }
    $form->{exchangerate} = $form->parse_amount(\%myconfig, $form->{exchangerate});

    for $i (1 .. $form->{paidaccounts}) {
      for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}); }
    }

    delete $form->{pre};

    if (! $form->{printandpost}) {
      $form->{rowcount}--;
      &display_form;
    }
  }

}


sub print_and_post {

  $form->error($locale->text('Select a Printer!')) if ($form->{media} eq 'screen');
  $form->{printandpost} = 1;
  &print;
  &post;

}
  
sub lookup_partsgroup {

  $form->{action} =~ s/\r//;
  $form->{action} = substr($form->{action}, 1);

  if ($form->{language_code}) {
    # get english
    foreach $item (split /\n/, $form->{partsgroup}) {
      if ($item =~ /$form->{action}/) {
	($partsgroup, $translation) = split /--/, $item;
	$form->{action} = $partsgroup;
	last;
      }
    }
  }
  
  $form->{"partsgroup_$form->{rowcount}"} = $form->{action};
 
  &update;

}



sub print_options {

  $form->{PD}{$form->{type}} = "checked";
  
  print qq|
<input type=hidden name=format value=$form->{format}>
<input type=hidden name=formname value=$form->{type}>

<table width=100%>
  <tr>
|;

 
  $media = qq|
    <td><input class=radio type=radio name=media value="screen"></td>
    <td>|.$locale->text('Screen').qq|</td>|;

  if (%printer) {
    for (keys %printer) {
      $media .= qq|
    <td><input class=radio type=radio name=media value="$_"></td>
    <td nowrap>$_</td>
|;
    }
  }

  $media =~ s/(value="\Q$form->{media}\E")/$1 checked/;

  print qq|
  $media
  
  <td width=99%>&nbsp;</td>|;
  
  if ($form->{printed} =~ /$form->{type}/) {
    print qq|
    <th>\||.$locale->text('Printed').qq|\|</th>|;
  }
  
  print qq|
  </tr>
</table>
|;

}


sub receipts {

  $form->{title} = $locale->text('Receipts');

  $form->{db} = 'ar';
  RP->paymentaccounts(\%myconfig, \%$form);
  
  $paymentaccounts = "";
  for (@{ $form->{PR} } ) { $paymentaccounts .= "$_->{accno} "; }

  if (@{ $form->{all_years} }) {
    # accounting years
    $form->{selectaccountingyear} = "<option>\n";
    for (@{ $form->{all_years} }) { $form->{selectaccountingyear} .= qq|<option>$_\n|; }
    $form->{selectaccountingmonth} = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $form->{selectaccountingmonth} .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n|; }

    $selectfrom = qq|
        <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td colspan=3>
	<select name=month>$form->{selectaccountingmonth}</select>
	<select name=year>$form->{selectaccountingyear}</select>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	</td>
      </tr>
|;
  }

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=title value="$form->{title}">
<input type=hidden name=paymentaccounts value="$paymentaccounts">

<input type=hidden name=till value=1>
<input type=hidden name=subtotal value=1>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
      
        <input type=hidden name=nextsub value=list_payments>
	
        <tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td><input name=fromdate size=11 title="$myconfig{dateformat}" value=$form->{fromdate}></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	  <input type=hidden name=sort value=transdate>
	  <input type=hidden name=db value=$form->{db}>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  if ($form->{menubar}) {
    require "$form->{path}/menu.pl";
    &menubar;
  }

  print qq|
 
</form>

</body>
</html>
|;

}


