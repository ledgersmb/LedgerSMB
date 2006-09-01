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
# Payment module
#
#======================================================================


use LedgerSMB::CP;
use LedgerSMB::OP;
use LedgerSMB::IS;
use LedgerSMB::IR;

require "$form->{path}/arap.pl";

1;
# end of main


sub payment {

  if ($form->{type} eq 'receipt') {
    $form->{ARAP} = "AR";
    $form->{arap} = "ar";
    $form->{vc} = "customer";
    $form->{formname} = "receipt";
  }
  if ($form->{type} eq 'check') {
    $form->{ARAP} = "AP";
    $form->{arap} = "ap";
    $form->{vc} = "vendor";
    $form->{formname} = "check";
  }

  $form->{payment} = "payment";
  
  $form->{callback} = "$form->{script}?action=payment&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&all_vc=$form->{all_vc}&type=$form->{type}";
  
  # setup customer/vendor selection for open invoices
  if ($form->{all_vc}) {
    $form->all_vc(\%myconfig, $form->{vc}, $form->{ARAP}, undef, $form->{datepaid});
  } else {
    CP->get_openvc(\%myconfig, \%$form);
    if ($myconfig{vclimit} > 0) {
      $form->{"all_$form->{vc}"} = $form->{name_list};
    }
  }

  $form->{"select$form->{vc}"} = "";
  if (@{ $form->{"all_$form->{vc}"} }) {
    $form->{"$form->{vc}_id"} = $form->{"all_$form->{vc}"}->[0]->{id};
    for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
  }

  # departments
  if (@{ $form->{all_department} }) { 
    $form->{selectdepartment} = "<option>\n";
    $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department};

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
  }

  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "<option>\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| }
  }

  CP->paymentaccounts(\%myconfig, \%$form);

  $form->{selectaccount} = "";
  $form->{"select$form->{ARAP}"} = "";

  for (@{ $form->{PR}{"$form->{ARAP}_paid"} }) { $form->{selectaccount} .= "<option>$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{$form->{ARAP}} }) { $form->{"select$form->{ARAP}"} .= "<option>$_->{accno}--$_->{description}\n" }

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  $form->{selectcurrency} = "";
  for (@curr) { $form->{selectcurrency} .= "<option>$_\n" }

  $form->{currency} = $form->{defaultcurrency};
  $form->{oldcurrency} = $form->{currency};

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{forex} = $form->{exchangerate} = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid}, ($form->{vc} eq 'customer') ? "buy" : "sell");
  }

  $form->{olddatepaid} = $form->{datepaid};

  $form->{media} = $myconfig{printer};
  $form->{format} = "pdf" unless $myconfig{printer};

  &payment_header;
  &payment_footer;
  
}


sub payments {
  
  if ($form->{type} eq 'receipt') {
    $form->{ARAP} = "AR";
    $form->{arap} = "ar";
    $form->{vc} = "customer";
    $form->{formname} = "receipt";
  }
  if ($form->{type} eq 'check') {
    $form->{ARAP} = "AP";
    $form->{arap} = "ap";
    $form->{vc} = "vendor";
    $form->{formname} = "check";
  }
  
  $form->{payment} = "payments";

  $form->{callback} = "$form->{script}?action=$form->{action}";
  for (qw(path login sessionid type)) { $form->{callback} .= "&$_=$form->{$_}" }

  CP->paymentaccounts(\%myconfig, \%$form);
  
  if (@{ $form->{all_language} }) {
    $form->{selectlanguage} = "<option>\n";
    for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| }
  }
  
  # departments
  if (@{ $form->{all_department} }) { 
    $form->{selectdepartment} = "<option>\n";
    $form->{department} = "$form->{department}--$form->{department_id}" if $form->{department};

    for (@{ $form->{all_department} }) { $form->{selectdepartment} .= qq|<option value="$_->{description}--$_->{id}">$_->{description}\n| }
  }

  $form->{selectaccount} = "";
  $form->{"select$form->{ARAP}"} = "";

  for (@{ $form->{PR}{"$form->{ARAP}_paid"} }) { $form->{selectaccount} .= "<option>$_->{accno}--$_->{description}\n" }
  for (@{ $form->{PR}{$form->{ARAP}} }) { $form->{"select$form->{ARAP}"} .= "<option>$_->{accno}--$_->{description}\n" }

  # currencies
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  $form->{selectcurrency} = "";
  for (@curr) { $form->{selectcurrency} .= "<option>$_\n" }

  $form->{oldcurrency} = $form->{currency} = $form->{defaultcurrency};
  $form->{oldduedateto} = $form->{datepaid};

  $form->{media} = $myconfig{printer};
  $form->{format} = "pdf" unless $myconfig{printer};

  &payments_header;
  &invoices_due;
  &payments_footer;

}


sub payments_header {

  if ($form->{type} eq 'receipt') {
    $form->{title} = $locale->text('Receipts');
  }
  if ($form->{type} eq 'check') {
    $form->{title} = $locale->text('Payments');
  }

 
  for ("department") {
    $form->{"select$_"} = $form->unescape($form->{"select$_"});
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
  }
 
  for ("account", "currency", "$form->{ARAP}") {
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/option>\Q$form->{$_}\E/option selected>$form->{$_}/;
  }

  if ($form->{defaultcurrency}) {
     $exchangerate = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td>
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=oldcurrency value=$form->{oldcurrency}>
	      </tr>
|;
  }
 
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

    if ($form->{forex}) {
      $exchangerate .= qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
		<td colspan=3><input type=hidden name=exchangerate size=10 value=$form->{exchangerate}>$form->{exchangerate}</td>
	      </tr>
|;
    } else {
      $exchangerate .= qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
		<td colspan=3><input name=exchangerate size=10 value=$form->{exchangerate}></td>
	      </tr>
|;
    }
  }
 
  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|.$form->escape($form->{selectdepartment},1).qq|">
	      </td>
	    </tr>
| if $form->{selectdepartment};


  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(defaultcurrency closedto vc type formname arap ARAP title oldduedatefrom oldduedateto payment olddepartment));

  print qq|
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
	        <th align=right>|.$locale->text('Due Date').qq|&nbsp;|.$locale->text('From').qq|</th>
		<td><input name=duedatefrom value="$form->{duedatefrom}" title="$myconfig{dateformat}" size=11></td>
	        <th align=right>|.$locale->text('To').qq|</th>
		<td><input name=duedateto value="$form->{duedateto}" title="$myconfig{dateformat}" size=11></td>
	      </tr>
	    </table>
	  </td>
	  </td>
	  <td align=right>
	    <table>
	      $department
	      <tr>
	        <th align=right nowrap>|.$locale->text($form->{ARAP}).qq|</th>
		<td colspan=3><select name=$form->{ARAP}>$form->{"select$form->{ARAP}"}</select>
		</td>
		<input type=hidden name="select$form->{ARAP}" value="$form->{"select$form->{ARAP}"}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Account').qq|</th>
		<td colspan=3><select name=account>$form->{selectaccount}</select>
		<input type=hidden name=selectaccount value="$form->{selectaccount}">
		</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Date').qq|</th>
		<td><input name=datepaid value="$form->{datepaid}" title="$myconfig{dateformat}" size=11></td>
	      </tr>
	      $exchangerate
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
|;

}


sub invoices_due {

  @column_index = qw(name invnumber transdate amount due checked paid memo source);
  push @column_index, "language" if $form->{selectlanguage};
  
  $colspan = $#column_index + 1;

  $invoice = $locale->text('Invoices');
  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);
  
  print qq|
  <input type=hidden name=column_index value="id @column_index">
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class=listheading colspan=$colspan>$invoice</th>
	</tr>
|;

  $column_data{name} = qq|<th nowrap>$vclabel</th>|;
  $column_data{invnumber} = qq|<th nowrap>|.$locale->text('Invoice')."</th>";
  $column_data{transdate} = qq|<th nowrap>|.$locale->text('Date')."</th>";
  $column_data{amount} = qq|<th nowrap>|.$locale->text('Amount')."</th>";
  $column_data{due} = qq|<th nowrap>|.$locale->text('Amount Due')."</th>";
  $column_data{paid} = qq|<th nowrap>|.$locale->text('Amount')."</th>";
  $column_data{checked} = qq|<th nowrap>|.$locale->text('Select')."</th>";
  $column_data{memo} = qq|<th nowrap>|.$locale->text('Memo')."</th>";
  $column_data{source} = qq|<th nowrap>|.$locale->text('Source')."</th>";
  $column_data{language} = qq|<th nowrap>|.$locale->text('Language')."</th>";
  
  print qq|
        <tr>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
|;

  $form->{selectlanguage} = $form->unescape($form->{selectlanguage});

  for $i (1 .. $form->{rowcount}) {

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    $totalamount += $form->{"amount_$i"};
    $totaldue += $form->{"due_$i"};
    $totalpaid += $form->{"paid_$i"};

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, 2) }

    $column_data{invnumber} = qq|<td>$form->{"invnumber_$i"}</td>
      <input type=hidden name="invnumber_$i" value="$form->{"invnumber_$i"}">
      <input type=hidden name="id_$i" value=$form->{"id_$i"}>|;
    $column_data{transdate} = qq|<td>$form->{"transdate_$i"}</td>
      <input type=hidden name="transdate_$i" value=$form->{"transdate_$i"}>|;
    $column_data{amount} = qq|<td align=right>$form->{"amount_$i"}</td>
      <input type=hidden name="amount_$i" value=$form->{"amount_$i"}>|;
    $column_data{due} = qq|<td align=right>$form->{"due_$i"}</td>
      <input type=hidden name="due_$i" value=$form->{"due_$i"}>|;

    $column_data{paid} = qq|<td align=right><input name="paid_$i" size=10 value=$form->{"paid_$i"}></td>|;

    if ($same_id eq $form->{"$form->{vc}_id_$i"}) {
      for (qw(name memo source language)) { $column_data{$_} = qq|<td>&nbsp;</td>| }
    } else {
      $column_data{name} = qq|<td>$form->{"name_$i"}</td>|;
      $column_data{memo} = qq|<td align=right><input name="memo_$i" size=10 value="$form->{"memo_$i"}"></td>|;
      $column_data{source} = qq|<td align=right><input name="source_$i" size=10 value="$form->{"source_$i"}"></td>|;

      if ($form->{selectlanguage}) {
	$selectlanguage = $form->{selectlanguage};
	$selectlanguage =~ s/(<option value="\Q$form->{"language_code_$i"}\E")/$1 selected/;
	$column_data{language} = qq|<td><select name="language_code_$i">$selectlanguage</select></td>|;
      }

    }
    
    $column_data{name} .= qq|
      <input type=hidden name="name_$i" value="$form->{"name_$i"}">
      <input type=hidden name="$form->{vc}_id_$i" value="$form->{"$form->{vc}_id_$i"}">|;

    $form->{"checked_$i"} = ($form->{"checked_$i"}) ? "checked" : "";
    $column_data{checked} = qq|<td align=center><input name="checked_$i" type=checkbox class=checkbox $form->{"checked_$i"}></td>|;

    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    print qq|
        </tr>
|;

    $same_id = $form->{"$form->{vc}_id_$i"};
    
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{amount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalamount, 2, "&nbsp;").qq|</th>|;
  $column_data{due} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totaldue, 2, "&nbsp;").qq|</th>|;
  $column_data{paid} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalpaid, 2, "&nbsp;").qq|</th>|;

  print qq|
        <tr class=listtotal>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
      </table>
    </td>
  </tr>
<input type=hidden name=selectlanguage value="|.$form->escape($form->{selectlanguage},1).qq|">
|;

}


sub payments_footer {
  
  $form->{DF}{$form->{format}} = "selected";

  $transdate = $form->datetonum(\%myconfig, $form->{datepaid});
  $closedto = $form->datetonum(\%myconfig, $form->{closedto});
  
  if ($latex) {
   
    $media = qq|<select name=media>
          <option value=screen>|.$locale->text('Screen');

    if (%printer) {
      for (sort keys %printer) { $media .= qq| 
          <option value="$_">$_| }
    }
  
    $media .= qq|</select>|;
    $format = qq|<select name=format>
            <option value=postscript $form->{DF}{postscript}>|.$locale->text('Postscript').qq|
	    <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF').qq|</select>|;
  }

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

# type=submit $locale->text('Update')
# type=submit $locale->text('Post')
# type=submit $locale->text('Print') 
# type=submit $locale->text('Select all') 

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	     'Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
             'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	     'Post' => { ndx => 4, key => 'O', value => $locale->text('Post') },
	    ); 

  if (! $latex) {
    delete $button{'Print'};
  }

  if ($transdate <= $closedto) {
    for ('Post', 'Print') { delete $button{$_} }
    $media = $format = "";
  }
  
  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  print qq|
  $format
  $media
|;

  $form->hide_form(qw(callback rowcount path login sessionid));
 
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


sub select_all {

  for (1 .. $form->{rowcount}) { $form->{"checked_$_"} = 1 }
  &{"update_$form->{payment}"}
  
}


sub update {
  my ($new_name_selected) = @_;

  &{"update_$form->{payment}"};
  
}


sub update_payments {

  if ($form->{ARAP} eq 'AR') {
    $buysell = "buy";
  } else {
    $buysell = "sell";
  }

  if (($form->{oldduedatefrom} ne $form->{duedatefrom}) || ($form->{oldduedateto} ne $form->{duedateto}) || ($form->{department} ne $form->{olddepartment})) {
    CP->get_openinvoices(\%myconfig, \%$form);
    $form->{redo} = 1;
  }

  if ($form->{currency} ne $form->{oldcurrency}) {
    $form->{oldcurrency} = $form->{currency};
    if (!$form->{redo}) {
      CP->get_openinvoices(\%myconfig, \%$form);
      $form->{redo} = 1;
    }
  }

  for (qw(duedatefrom duedateto department)) { $form->{"old$_"} = $form->{$_} }
  
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid}, $buysell)));

  if ($form->{redo}) {
    $form->{rowcount} = 0;

    $i = 0;
    foreach $ref (@{ $form->{PR} }) {
      $i++;
      for (qw(id name invnumber transdate)) { $form->{"${_}_$i"} = $ref->{$_} }
      $form->{"$form->{vc}_id_$i"} = $ref->{"$form->{vc}_id"};
      $ref->{exchangerate} = 1 unless $ref->{exchangerate};
      $form->{"amount_$i"} = $ref->{amount} / $ref->{exchangerate};
      $form->{"due_$i"} = ($ref->{amount} - $ref->{paid}) / $ref->{exchangerate};
      $form->{"checked_$i"} = "";
      $form->{"paid_$i"} = "";

      # need to format
      for (qw(amount due)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, 2) }
    }
    
    $form->{rowcount} = $i;
  }

  $form->{amount} = $form->parse_amount(\%myconfig, $form->{amount});

  # recalculate
  $amount = 0;
  for $i (1 .. $form->{rowcount}) {

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }

    if ($form->{"checked_$i"}) {
      # calculate paid_$i
      if (!$form->{"paid_$i"}) {
	$form->{"paid_$i"} = $form->{"due_$i"};
      }
      
      $amount += $form->{"paid_$i"};
      $form->{redo} = 1;
    } else {
      $form->{"paid_$i"} = "";
    }

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, 2) }
  }

  $form->{amount} += ($amount - $form->{oldamount}) if $form->{redo};

  &payments_header;
  &invoices_due;
  &payments_footer;
  
}


sub update_payment {

  if ($form->{vc} eq 'customer') {
    $buysell = "buy";
  } else {
    $buysell = "sell";
  }

  $department = $form->{department};

  # get customer/vendor
  &check_openvc;
  $form->{department} = $department;

  if ($form->{datepaid} ne $form->{olddatepaid}) {
    $form->{olddatepaid} = $form->{datepaid};
    $form->{oldall_vc} = !$form->{oldall_vc} if $form->{all_vc};
  }

  if ($form->{department} ne $form->{olddepartment}) {
    $form->{olddepartment} = $form->{department};
    $form->{redo} = 1;
  }
  
  # if we switched to all_vc
  if ($form->{all_vc} ne $form->{oldall_vc}) {

    if ($form->{"select$form->{vc}"}) {
      $form->{redo} = ($form->{"old$name"} ne $form->{$name});
    } else {
      $form->{redo} = ($form->{"old$name"} ne qq|$form->{$name}--$form->{"${name}_id"}|);
    }

    $form->{"select$form->{vc}"} = "";

    if ($form->{all_vc}) {
      $form->all_vc(\%myconfig, $form->{vc}, $form->{ARAP}, undef, $form->{datepaid});
      
      if (@{ $form->{"all_$form->{vc}"} }) {
	for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
      }
      
    } else {
      if (($myconfig{vclimit} * 1) > 0) {
	$form->{$form->{vc}} = "";
      }
      
      CP->get_openvc(\%myconfig, \%$form);

      if (($myconfig{vclimit} * 1) > 0) {
	$form->{"all_$form->{vc}"} = $form->{name_list};
      }

      if (@{ $form->{"all_$form->{vc}"} }) {
	$newvc = qq|$form->{"all_$form->{vc}"}[0]->{name}--$form->{"all_$form->{vc}"}[0]->{id}|;
	for (@{ $form->{"all_$form->{vc}"} }) { $form->{"select$form->{vc}"} .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }


	# if the name is not the same
	if ($form->{"select$form->{vc}"} !~ /$form->{$form->{vc}}/) {
	  $form->{$form->{vc}} = $newvc;
	  &check_openvc;
	}
      }
    }

    if (@{ $form->{all_language} }) {
      $form->{selectlanguage} = "<option>\n";
      for (@{ $form->{all_language} }) { $form->{selectlanguage} .= qq|<option value="$_->{code}">$_->{description}\n| }
    }

  }

  if ($new_name_selected || $form->{redo}) {
    CP->get_openinvoices(\%myconfig, \%$form);
    ($newvc) = split /--/, $form->{$form->{vc}};
    $form->{"old$form->{vc}"} = qq|$newvc--$form->{"$form->{vc}_id"}|;;
    $form->{redo} = 1;
  }

  if ($form->{currency} ne $form->{oldcurrency}) {
    $form->{oldcurrency} = $form->{currency};
    if (!$form->{redo}) {
      CP->get_openinvoices(\%myconfig, \%$form);
      $form->{redo} = 1;
    }
  }
  
  
  $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{datepaid}, $buysell)));

  if ($form->{redo}) {
    $form->{rowcount} = 0;

    $i = 0;
    foreach $ref (@{ $form->{PR} }) {
      $i++;
      $form->{"id_$i"} = $ref->{id};
      $form->{"invnumber_$i"} = $ref->{invnumber};
      $form->{"transdate_$i"} = $ref->{transdate};
      $ref->{exchangerate} = 1 unless $ref->{exchangerate};
      $form->{"amount_$i"} = $ref->{amount} / $ref->{exchangerate};
      $form->{"due_$i"} = ($ref->{amount} - $ref->{paid}) / $ref->{exchangerate};
      $form->{"checked_$i"} = "";
      $form->{"paid_$i"} = "";

      # need to format
      for (qw(amount due)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, 2) }
    }
    $form->{rowcount} = $i;
  }

  $form->{amount} = $form->parse_amount(\%myconfig, $form->{amount});

  # recalculate
  $amount = 0;
  for $i (1 .. $form->{rowcount}) {

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }

    if ($form->{"checked_$i"}) {
      # calculate paid_$i
      if (!$form->{"paid_$i"}) {
	$form->{"paid_$i"} = $form->{"due_$i"};
      }
      
      $amount += $form->{"paid_$i"};
      $form->{redo} = 1;
    } else {
      $form->{"paid_$i"} = "";
    }

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, 2) }
  }

  $form->{amount} += ($amount - $form->{oldamount}) if $form->{redo};

  &payment_header;
  &list_invoices;
  &payment_footer;
  
}




sub payment_header {

  $vclabel = ucfirst $form->{vc};
  $vclabel = $locale->text($vclabel);
  
  if ($form->{type} eq 'receipt') {
    $form->{title} = $locale->text('Receipt');
  }
  if ($form->{type} eq 'check') {
    $form->{title} = $locale->text('Payment');
  }


# $locale->text('Customer')
# $locale->text('Vendor')

  if ($form->{$form->{vc}} eq "") {
    for (qw(address1 address2 city zipcode state country)) { $form->{$_} = "" }
  }
  
  for ("$form->{vc}", "department") {
    $form->{"select$_"} = $form->unescape($form->{"select$_"});
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/(<option value="\Q$form->{$_}\E")/$1 selected/;
  }
  
  for ("account", "currency", "$form->{ARAP}") {
    $form->{"select$_"} =~ s/ selected//;
    $form->{"select$_"} =~ s/option>\Q$form->{$_}\E/option selected>$form->{$_}/;
  }

  if ($form->{defaultcurrency}) {
    $exchangerate = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Currency').qq|</th>
		<td><select name=currency>$form->{selectcurrency}</select></td>
		<input type=hidden name=selectcurrency value="$form->{selectcurrency}">
		<input type=hidden name=oldcurrency value=$form->{oldcurrency}>
	      </tr>
|;
  }

  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $form->format_amount(\%myconfig, $form->{exchangerate});

    if ($form->{forex}) {
      $exchangerate .= qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
		<td colspan=3><input type=hidden name=exchangerate size=10 value=$form->{exchangerate}>$form->{exchangerate}</td>
	      </tr>
|;
    } else {
      $exchangerate .= qq|
 	      <tr>
		<th align=right nowrap>|.$locale->text('Exchange Rate').qq|</th>
		<td colspan=3><input name=exchangerate size=10 value=$form->{exchangerate}></td>
	      </tr>
|;
    }
  }

  $vc = ($form->{"select$form->{vc}"}) ? qq|<select name=$form->{vc}>$form->{"select$form->{vc}"}\n</select>| : qq|<input name=$form->{vc} size=35 value="$form->{$form->{vc}}">|;

  if ($form->{all_vc}) {
    $allvc = "checked";
  } else {
    $allvc = "";
  }
  
# $locale->text('AR')
# $locale->text('AP')

  $department = qq|
              <tr>
	        <th align="right" nowrap>|.$locale->text('Department').qq|</th>
		<td><select name=department>$form->{selectdepartment}</select>
		<input type=hidden name=selectdepartment value="|.$form->escape($form->{selectdepartment},1).qq|">
	      </td>
	    </tr>
| if $form->{selectdepartment};

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  $form->hide_form(qw(defaultcurrency closedto vc type ARAP arap title formname payment olddepartment));

  print qq|

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
	        <td align=right>
		<input name=all_vc type=checkbox class=checkbox value=Y $allvc>
		<input type=hidden name="oldall_vc" value="$form->{all_vc}"></td>
		<th align=left>|.$locale->text('All').qq|</th>
	      </tr>
	      <tr>
		<th align=right>$vclabel</th>
		<td>$vc</td>
                <input type=hidden name="select$form->{vc}" value="|.$form->escape($form->{"select$form->{vc}"},1).qq|">
                <input type=hidden name="$form->{vc}_id" value=$form->{"$form->{vc}_id"}>
		<input type=hidden name="old$form->{vc}" value="$form->{"old$form->{vc}"}">
	      </tr>
	      <tr valign=top>
		<th align=right nowrap>|.$locale->text('Address').qq|</th>
		<td colspan=2>
		  <table>
		    <tr>
		      <td>$form->{address1}</td>
		    </tr>
		    <tr>
		      <td>$form->{address2}</td>
		    </tr>
		      <td>$form->{city}</td>
		    </tr>
		    </tr>
		      <td>$form->{state}</td>
		    </tr>
		    </tr>
		      <td>$form->{zipcode}</td>
		    </tr>
		    <tr>
		      <td>$form->{country}</td>
		    </tr>
		  </table>
		</td>
		<input type=hidden name=address1 value="$form->{address1}">
		<input type=hidden name=address2 value="$form->{address2}">
		<input type=hidden name=city value="$form->{city}">
		<input type=hidden name=state value="$form->{state}">
		<input type=hidden name=zipcode value="$form->{zipcode}">
		<input type=hidden name=country value="$form->{country}">
	      </tr>
	      <tr>
		<th align=right>|.$locale->text('Memo').qq|</th>
		<td colspan=2><input name="memo" size=30 value="$form->{memo}"></td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      $department
	      <tr>
	        <th align=right nowrap>|.$locale->text($form->{ARAP}).qq|</th>
		<td colspan=3><select name=$form->{ARAP}>$form->{"select$form->{ARAP}"}</select>
		</td>
		<input type=hidden name="select$form->{ARAP}" value="$form->{"select$form->{ARAP}"}">
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Account').qq|</th>
		<td colspan=3><select name=account>$form->{selectaccount}</select>
		<input type=hidden name=selectaccount value="$form->{selectaccount}">
		</td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Date').qq|</th>
		<td><input name=datepaid value="$form->{datepaid}" title="$myconfig{dateformat}" size=11></td>
		<input type=hidden name=olddatepaid value=$form->{olddatepaid}>
	      </tr>
	      $exchangerate
	      <tr>
		<th align=right nowrap>|.$locale->text('Source').qq|</th>
		<td colspan=3><input name=source value="$form->{source}" size=10></td>
	      </tr>
	      <tr>
		<th align=right nowrap>|.$locale->text('Amount').qq|</th>
		<td colspan=3><input name=amount size=10 value=|.$form->format_amount(\%myconfig, $form->{amount}, 2).qq|></td>
		<input type=hidden name=oldamount value=$form->{amount}>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
|;

}


sub list_invoices {

  @column_index = qw(invnumber transdate amount due checked paid);
  
  $colspan = $#column_index + 1;

  $invoice = $locale->text('Invoices');
  
  print qq|
  <input type=hidden name=column_index value="id @column_index">
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th class=listheading colspan=$colspan>$invoice</th>
	</tr>
|;

  $column_data{invnumber} = qq|<th nowrap>|.$locale->text('Invoice')."</th>";
  $column_data{transdate} = qq|<th nowrap>|.$locale->text('Date')."</th>";
  $column_data{amount} = qq|<th nowrap>|.$locale->text('Amount')."</th>";
  $column_data{due} = qq|<th nowrap>|.$locale->text('Amount Due')."</th>";
  $column_data{paid} = qq|<th nowrap>|.$locale->text('Amount')."</th>";
  $column_data{checked} = qq|<th nowrap>|.$locale->text('Select')."</th>";
  
  print qq|
        <tr>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
|;

  for $i (1 .. $form->{rowcount}) {

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    $totalamount += $form->{"amount_$i"};
    $totaldue += $form->{"due_$i"};
    $totalpaid += $form->{"paid_$i"};

    for (qw(amount due paid)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, 2) }

    $column_data{invnumber} = qq|<td>$form->{"invnumber_$i"}</td>
      <input type=hidden name="invnumber_$i" value="$form->{"invnumber_$i"}">
      <input type=hidden name="id_$i" value=$form->{"id_$i"}>|;
    $column_data{transdate} = qq|<td width=15%>$form->{"transdate_$i"}</td>
      <input type=hidden name="transdate_$i" value=$form->{"transdate_$i"}>|;
    $column_data{amount} = qq|<td align=right width=15%>$form->{"amount_$i"}</td>
      <input type=hidden name="amount_$i" value=$form->{"amount_$i"}>|;
    $column_data{due} = qq|<td align=right width=15%>$form->{"due_$i"}</td>
      <input type=hidden name="due_$i" value=$form->{"due_$i"}>|;

    $column_data{paid} = qq|<td align=right width=15%><input name="paid_$i" size=10 value=$form->{"paid_$i"}></td>|;

    $form->{"checked_$i"} = ($form->{"checked_$i"}) ? "checked" : "";
    $column_data{checked} = qq|<td align=center width=10%><input name="checked_$i" type=checkbox class=checkbox $form->{"checked_$i"}></td>|;

    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    print qq|
        </tr>
|;
  }

  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{amount} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalamount, 2, "&nbsp;").qq|</th>|;
  $column_data{due} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totaldue, 2, "&nbsp;").qq|</th>|;
  $column_data{paid} = qq|<th class=listtotal align=right>|.$form->format_amount(\%myconfig, $totalpaid, 2, "&nbsp;").qq|</th>|;

  print qq|
        <tr class=listtotal>
|;
  for (@column_index) { print "$column_data{$_}\n" }
  print qq|
        </tr>
      </table>
    </td>
  </tr>
|;

}


sub payment_footer {

  $form->{DF}{$form->{format}} = "selected";

  $transdate = $form->datetonum(\%myconfig, $form->{datepaid});
  $closedto = $form->datetonum(\%myconfig, $form->{closedto});

  if ($latex) {
    if ($form->{selectlanguage}) {
      $form->{"selectlanguage"} = $form->unescape($form->{"selectlanguage"});
      $form->{"selectlanguage"} =~ s/ selected//;
      $form->{"selectlanguage"} =~ s/(<option value="\Q$form->{language_code}\E")/$1 selected/;
      $lang = qq|<select name=language_code>$form->{selectlanguage}</select>
      <input type=hidden name=selectlanguage value="|.
      $form->escape($form->{selectlanguage},1).qq|">|;
    }
    
    $media = qq|<select name=media>
          <option value=screen>|.$locale->text('Screen');

    if (%printer) {
      for (sort keys %printer) { $media .= qq| 
          <option value="$_">$_| }
    }
  
    $media .= qq|</select>|;
    $format = qq|<select name=format>
            <option value=postscript $form->{DF}{postscript}>|.$locale->text('Postscript').qq|
	    <option value=pdf $form->{DF}{pdf}>|.$locale->text('PDF').qq|</select>|;
  }

  print qq|
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  %button = ('Update' => { ndx => 1, key => 'U', value => $locale->text('Update') },
	     'Select all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
             'Print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	     'Post' => { ndx => 4, key => 'O', value => $locale->text('Post') },
	    ); 

  if (! $latex) {
    delete $button{'Print'};
  }

  if ($transdate <= $closedto) {
    for ('Post', 'Print') { delete $button{$_} }
    $media = $format = "";
  }

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
  
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  print qq|
  $lang
  $format
  $media
|;

  $form->hide_form(qw(callback rowcount path login sessionid));
 
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


sub post { &{"post_$form->{payment}"} }


sub post_payments {
  
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->error($locale->text('Exchange rate missing!')) unless $form->{exchangerate};
  }

  if (CP->post_payments(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Payments posted!'));
  } else {
    $form->error($locale->text('Posting failed!'));
  }

}


sub post_payment {
  
  &check_form;
  
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->error($locale->text('Exchange rate missing!')) unless $form->{exchangerate};
  }

  $msg1 = "$form->{title} posted!";
  $msg2 = "Cannot post $form->{title}!";

# $locale->text('Payment posted!')
# $locale->text('Receipt posted!')
# $locale->text('Cannot post Payment!')
# $locale->text('Cannot post Receipt!')


  $form->{amount} = $form->format_amount(\%myconfig, $form->{amount}, 2);

  $source = $form->{source};
  $source =~ s/(\d+)/$1 + 1/e;
  
  if ($form->{callback}) {
    $form->{callback} .= "&source=$source";
  }
  
  if (CP->post_payment(\%myconfig, \%$form)) {
    $form->redirect($locale->text($msg1));
  } else {
    $form->error($locale->text($msg2));
  }

}


sub print {
  
  &{ "print_$form->{payment}" };
  &update if $form->{media} ne 'screen';
  
}


sub print_payments {

  $form->error($locale->text('Select postscript or PDF!')) if ($form->{format} !~ /(postscript|pdf)/);
  
  $SIG{INT} = 'IGNORE';

  for (qw(company address)) { $form->{$_} = $myconfig{$_} }
  $form->{address} =~ s/\\n/\n/g;

  %oldform = ();
  for (keys %$form) { $oldform{$_} = $form->{$_} };
  
  @a = qw(name company address text_amount text_decimal address1 address2 city state zipcode country memo);
  for (@a) { $temp{$_} = $form->{$_} }

  $form->format_string(@a);

  $ok = 0;
  $j = 0;
  $temp{rowcount} = $form->{rowcount};
  
  for $i (1 .. $temp{rowcount}) {

    if ($form->{"$form->{vc}_id_$i"} ne $form->{"$form->{vc}_id"}) {

      $form->{rowcount} = $j;
      for (1 .. $j) { $form->{"id_$_"} = $temp{"id_$_"} }
      &print_form if $ok;

      $ok = 0;
      $j = 0;
      $form->{amount} = 0;
      for (qw(invnumber invdate due paid)) { @{ $form->{$_} } = () }
      for (qw(language_code source memo)) { $form->{$_} = $form->{"${_}_$i"} }

    }

    if ($form->{"checked_$i"}) {
      $j++;
      $ok = 1;
      $temp{"id_$j"} = $form->{"id_$i"};
      $form->{"invdate_$i"} = $form->{"transdate_$i"};
      for (qw(invnumber invdate due paid)) { push @{ $form->{$_} }, $form->{"${_}_$i"} }
      $form->{amount} += $form->parse_amount(\%myconfig, $form->{"paid_$i"});
      $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
    }
    
  }

  $form->{rowcount} = $j;
  for (1 .. $j) { $form->{"id_$_"} = $temp{"id_$_"} }

  &print_form if $ok;

  for (keys %oldform) { $form->{$_} = $oldform{$_} }

}


sub print_form {
       
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode});
  $c->init;

  ($whole, $form->{decimal}) = split /\./, $form->{amount};
  $form->{amount} = $form->format_amount(\%myconfig, $form->{amount}, 2);
  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $form->format_amount($myconfig, $whole);

  $datepaid = $form->datetonum(\%myconfig, $form->{datepaid});
  ($form->{yyyy}, $form->{mm}, $form->{dd}) = $datepaid =~ /(....)(..)(..)/;
  
  &{ "$form->{vc}_details" };

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = "$form->{formname}.tex";

  if ($form->{media} ne 'screen') {
    $form->{OUT} = "| $printer{$form->{media}}";
  }

  $form->parse_template(\%myconfig, $userspath);

}


sub print_payment {
 
  &check_form;
  
  for (qw(company address)) { $form->{$_} = $myconfig{$_} }
  $form->{address} =~ s/\\n/\n/g;

  @a = qw(name company address text_amount text_decimal address1 address2 city state zipcode country memo);

  %temp = ();
  for (@a) { $temp{$_} = $form->{$_} }

  $form->format_string(@a);

  &print_form;
  
  for (keys %temp) { $form->{$_} = $temp{$_} }

}


sub customer_details { IS->customer_details(\%myconfig, \%$form) };
sub vendor_details { IR->vendor_details(\%myconfig, \%$form) };
  

sub check_form {
  
  &check_openvc;

  if ($form->{currency} ne $form->{oldcurrency}) {
    &update;
    exit;
  }
  
  $form->error($locale->text('Date missing!')) unless $form->{datepaid};

  $closedto = $form->datetonum(\%myconfig, $form->{closedto});
  $datepaid = $form->datetonum(\%myconfig, $form->{datepaid});
  
  $form->error($locale->text('Cannot post payment for a closed period!')) if ($datepaid <= $closedto);

  # this is just to format the year
  $form->{datepaid} = $locale->date(\%myconfig, $form->{datepaid});
  
  $amount = $form->parse_amount(\%myconfig, $form->{amount});
  $form->{amount} = $amount;
  
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"paid_$i"}) {
      $amount -= $form->parse_amount(\%myconfig, $form->{"paid_$i"});
      
      push(@{ $form->{paid} }, $form->{"paid_$i"});
      push(@{ $form->{due} }, $form->{"due_$i"});
      push(@{ $form->{invnumber} }, $form->{"invnumber_$i"});
      push(@{ $form->{invdate} }, $form->{"transdate_$i"});
    }
  }

  if ($form->round_amount($amount, 2) != 0) {
    push(@{ $form->{paid} }, $form->format_amount(\%myconfig, $amount, 2));
    push(@{ $form->{due} }, $form->format_amount(\%myconfig, 0, "0"));
    push(@{ $form->{invnumber} }, ($form->{ARAP} eq 'AR') ? $locale->text('Deposit') : $locale->text('Prepayment'));
    push(@{ $form->{invdate} }, $form->{datepaid});
  }
   
}


sub check_openvc {

  $name = $form->{vc};
  ($new_name, $new_id) = split /--/, $form->{$name};
  
  if ($form->{all_vc}) {
    if ($form->{"select$name"}) {
      $ok = ($form->{"old$name"} ne $form->{$name});
    } else {
      $ok = ($form->{"old$name"} ne qq|$form->{$name}--$form->{"${name}_id"}|);
    }

    if ($ok) {
      $form->{redo} = 1;
      if ($form->{"select$name"}) {
	$form->{"${name}_id"} = $new_id;
	AA->get_name(\%myconfig, \%$form);
	$form->{$name} = $form->{"old$name"} = "$new_name--$new_id";
      } else {
	&check_name($form->{vc});
      }
    }
    
  } else {
    
    # if we use a selection
    if ($form->{"select$name"}) {
      if ($form->{"old$name"} ne $form->{$name}) {

	$form->{"${name}_id"} = $new_id;
	AA->get_name(\%myconfig, \%$form);

	$form->{$name} = $form->{"old$name"} = "$new_name--$new_id";
        $form->{redo} = 1;
      }
    } else {

      # check name, combine name and id
      if ($form->{"old$name"} ne qq|$form->{$name}--$form->{"${name}_id"}|) {

	# return one name or a list of names in $form->{name_list}
	if (($rv = CP->get_openvc(\%myconfig, \%$form)) > 1) {
	  $form->{redo} = 1;
	  &select_name($name);
	  exit;
	}

	if ($rv == 1) {
	  # we got one name
	  $form->{"${name}_id"} = $form->{name_list}[0]->{id};
	  $form->{$name} = $form->{name_list}[0]->{name};
	  $form->{"old$name"} = qq|$form->{$name}--$form->{"${name}_id"}|;

	  AA->get_name(\%myconfig, \%$form);

	} else {
	  # nothing open
	  $form->error($locale->text('Nothing open!'));
	}
	
	$form->{redo} = 1;
      }
    }
  }

}


