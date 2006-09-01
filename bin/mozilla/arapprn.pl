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
#
# printing routines for ar, ap
#

# any custom scripts for this one
if (-f "$form->{path}/custom_arapprn.pl") {
    eval { require "$form->{path}/custom_arapprn.pl"; };
}
if (-f "$form->{path}/$form->{login}_arapprn.pl") {
    eval { require "$form->{path}/$form->{login}_arapprn.pl"; };
}


1;
# end of main


sub print {

  if ($form->{media} !~ /screen/) {
    $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(postscript|pdf)/;
    $old_form = new Form;
    for (keys %$form) { $old_form->{$_} = $form->{$_} }
  }
 
  if ($form->{formname} =~ /(check|receipt)/) {
    if ($form->{media} eq 'screen') {
      $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(postscript|pdf)/;
    }
  }

  if (! $form->{invnumber}) {
    $invfld = 'sinumber';
    $invfld = 'vinumber' if $form->{ARAP} eq 'AP';
    $form->{invnumber} = $form->update_defaults(\%myconfig, $invfld);
    if ($form->{media} eq 'screen') {
      if ($form->{media} eq 'screen') {
	&update;
	exit;
      }
    }
  }

  if ($form->{formname} =~ /(check|receipt)/) {
    if ($form->{media} ne 'screen') {
      for (qw(action header)) { delete $form->{$_} }
      $form->{invtotal} = $form->{oldinvtotal};
      
      foreach $key (keys %$form) {
	$form->{$key} =~ s/&/%26/g;
	$form->{previousform} .= qq|$key=$form->{$key}&|;
      }
      chop $form->{previousform};
      $form->{previousform} = $form->escape($form->{previousform}, 1);
    }

    if ($form->{paidaccounts} > 1) {
      if ($form->{"paid_$form->{paidaccounts}"}) {
	&update;
	exit;
      } elsif ($form->{paidaccounts} > 2) {
	# select payment
	&select_payment;
	exit;
      }
    } else {
      $form->error($locale->text('Nothing to print!'));
    }
    
  }

  &{ "print_$form->{formname}" }($old_form, 1);

}


sub print_check {
  my ($old_form, $i) = @_;
  
  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if ($form->{"paid_$i"}) {
    @a = ();
    
    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }

    push @a, "source_$i", "memo_$i";
    $form->format_string(@a);
  }

  $form->{amount} = $form->{"paid_$i"};

  if (($form->{formname} eq 'check' && $form->{vc} eq 'customer') ||
    ($form->{formname} eq 'receipt' && $form->{vc} eq 'vendor')) {
    $form->{amount} =~ s/-//g;
  }
    
  for (qw(datepaid source memo)) { $form->{$_} = $form->{"${_}_$i"} }

  &{ "$form->{vc}_details" };
  @a = qw(name address1 address2 city state zipcode country);
 
  foreach $item (qw(invnumber ordnumber)) {
    $temp{$item} = $form->{$item};
    delete $form->{$item};
    push(@{ $form->{$item} }, $temp{$item});
  }
  push(@{ $form->{invdate} }, $form->{transdate});
  push(@{ $form->{due} }, $form->format_amount(\%myconfig, $form->{oldinvtotal}, 2));
  push(@{ $form->{paid} }, $form->{"paid_$i"});

  use LedgerSMB::CP;
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode}); 
  $c->init;
  ($whole, $form->{decimal}) = split /\./, $form->parse_amount(\%myconfig, $form->{amount});

  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1);
  $form->{text_amount} = $c->num2text($whole);
  $form->{integer_amount} = $form->format_amount($myconfig, $whole);

  ($form->{employee}) = split /--/, $form->{employee};

  $form->{notes} =~ s/^\s+//g;
  push @a, "notes";

  for (qw(company address tel fax businessnumber)) { $form->{$_} = $myconfig{$_} }
  $form->{address} =~ s/\\n/\n/g;

  push @a, qw(company address tel fax businessnumber text_amount text_decimal);
  
  $form->format_string(@a);

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = ($form->{formname} eq 'transaction') ? lc $form->{ARAP} . "_$form->{formname}.html" : "$form->{formname}.html";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/html$/tex/;
  }

  if ($form->{media} !~ /(screen)/) {
    $form->{OUT} = "| $printer{$form->{media}}";
    
    if ($form->{printed} !~ /$form->{formname}/) {

      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename   => lc $form->{ARAP},
                    reference   => $form->{invnumber},
		    formname    => $form->{formname},
		    action      => 'printed',
		    id          => $form->{id} );
    
    %status = ();
    for (qw(printed audittrail)) { $status{$_} = $form->{$_} }
    
    $status{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);

  }

  $form->{fileid} = $invnumber;
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->parse_template(\%myconfig, $userspath);

  if ($form->{previousform}) {
  
    $previousform = $form->unescape($form->{previousform});

    for (keys %$form) { delete $form->{$_} }

    foreach $item (split /&/, $previousform) {
      ($key, $value) = split /=/, $item, 2;
      $value =~ s/%26/&/g;
      $form->{$key} = $value;
    }

    for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

    for (1 .. $form->{rowcount}) { $form->{"amount_$_"} = $form->parse_amount(\%myconfig, $form->{"amount_$_"}) }
    for (split / /, $form->{taxaccounts}) { $form->{"tax_$_"} = $form->parse_amount(\%myconfig, $form->{"tax_$_"}) }

    for $i (1 .. $form->{paidaccounts}) {
      for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    }

    for (qw(printed audittrail)) { $form->{$_} = $status{$_} }

    &{ "$display_form" };
    
  }

}


sub print_receipt {
  my ($old_form, $i) = @_;
  
  &print_check($old_form, $i);

}


sub print_transaction {
  my ($old_form) = @_;
 
  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";
 

  &{ "$form->{vc}_details" };
  @a = qw(name address1 address2 city state zipcode country);
  
  
  $form->{invtotal} = 0;
  foreach $i (1 .. $form->{rowcount} - 1) {
    ($form->{tempaccno}, $form->{tempaccount}) = split /--/, $form->{"$form->{ARAP}_amount_$i"};
    ($form->{tempprojectnumber}) = split /--/, $form->{"projectnumber_$i"};
    $form->{tempdescription} = $form->{"description_$i"};
    
    $form->format_string(qw(tempaccno tempaccount tempprojectnumber tempdescription));
    
    push(@{ $form->{accno} }, $form->{tempaccno});
    push(@{ $form->{account} }, $form->{tempaccount});
    push(@{ $form->{description} }, $form->{tempdescription});
    push(@{ $form->{projectnumber} }, $form->{tempprojectnumber});

    push(@{ $form->{amount} }, $form->{"amount_$i"});

    $form->{subtotal} += $form->parse_amount(\%myconfig, $form->{"amount_$i"});
    
  }

  foreach $accno (split / /, $form->{taxaccounts}) {
    if ($form->{"tax_$accno"}) {
      $form->format_string("${accno}_description");

      $tax += $form->parse_amount(\%myconfig, $form->{"tax_$accno"});

      $form->{"${accno}_tax"} = $form->{"tax_$accno"};
      push(@{ $form->{tax} }, $form->{"tax_$accno"});
      
      push(@{ $form->{taxdescription} }, $form->{"${accno}_description"});

      $form->{"${accno}_taxrate"} = $form->format_amount($myconfig, $form->{"${accno}_rate"} * 100);
      push(@{ $form->{taxrate} }, $form->{"${accno}_taxrate"});
      
      push(@{ $form->{taxnumber} }, $form->{"${accno}_taxnumber"});
    }
  }
    
  $tax = 0 if $form->{taxincluded};

  push @a, $form->{ARAP};
  $form->format_string(@a);

  $form->{paid} = 0;
  for $i (1 .. $form->{paidaccounts} - 1) {

    if ($form->{"paid_$i"}) {
    @a = ();
    $form->{paid} += $form->parse_amount(\%myconfig, $form->{"paid_$i"});
    
    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }

    push @a, "$form->{ARAP}_paid_$i", "source_$i", "memo_$i";
    $form->format_string(@a);
    
    ($accno, $account) = split /--/, $form->{"$form->{ARAP}_paid_$i"};
    
    push(@{ $form->{payment} }, $form->{"paid_$i"});
    push(@{ $form->{paymentdate} }, $form->{"datepaid_$i"});
    push(@{ $form->{paymentaccount} }, $account);
    push(@{ $form->{paymentsource} }, $form->{"source_$i"});
    push(@{ $form->{paymentmemo} }, $form->{"memo_$i"});
    }
    
  }

  $form->{invtotal} = $form->{subtotal} + $tax;
  $form->{total} = $form->{invtotal} - $form->{paid};
  
  use LedgerSMB::CP;
  $c = CP->new(($form->{language_code}) ? $form->{language_code} : $myconfig{countrycode}); 
  $c->init;
  ($whole, $form->{decimal}) = split /\./, $form->{invtotal};

  $form->{decimal} .= "00";
  $form->{decimal} = substr($form->{decimal}, 0, 2);
  $form->{text_decimal} = $c->num2text($form->{decimal} * 1); 
  $form->{text_amount} = $c->num2text($whole); 
  $form->{integer_amount} = $form->format_amount($myconfig, $whole);

  for (qw(invtotal subtotal paid total)) { $form->{$_} = $form->format_amount(\%myconfig, $form->{$_}, 2) }
  
  ($form->{employee}) = split /--/, $form->{employee};

  if (exists $form->{longformat}) {
    for (qw(duedate transdate)) { $form->{$_} = $locale->date(\%myconfig, $form->{$_}, $form->{longformat}) }
  }

  $form->{notes} =~ s/^\s+//g;
  
  @a = ("invnumber", "transdate", "duedate", "notes");

  for (qw(company address tel fax businessnumber)) { $form->{$_} = $myconfig{$_} }
  $form->{address} =~ s/\\n/\n/g;

  push @a, qw(company address tel fax businessnumber text_amount text_decimal);
  
  $form->format_string(@a);

  $form->{invdate} = $form->{transdate};

  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = ($form->{formname} eq 'transaction') ? lc $form->{ARAP} . "_$form->{formname}.html" : "$form->{formname}.html";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/html$/tex/;
  }

  if ($form->{media} !~ /(screen)/) {
    $form->{OUT} = "| $printer{$form->{media}}";
    
    if ($form->{printed} !~ /$form->{formname}/) {

      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    $old_form->{printed} = $form->{printed} if %$old_form;
    
    %audittrail = ( tablename   => lc $form->{ARAP},
                    reference   => $form->{"invnumber"},
		    formname    => $form->{formname},
		    action      => 'printed',
		    id          => $form->{id} );
    
    $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail) if %$old_form;

  }

  $form->{fileid} = $form->{invnumber};
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->parse_template(\%myconfig, $userspath);

  if (%$old_form) {
    $old_form->{invnumber} = $form->{invnumber};
    $old_form->{invtotal} = $form->{invtotal};

    for (keys %$form) { delete $form->{$_} }
    for (keys %$old_form) { $form->{$_} = $old_form->{$_} }

    if (! $form->{printandpost}) {
      for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

      for (1 .. $form->{rowcount}) { $form->{"amount_$_"} = $form->parse_amount(\%myconfig, $form->{"amount_$_"}) }
      for (split / /, $form->{taxaccounts}) { $form->{"tax_$_"} = $form->parse_amount(\%myconfig, $form->{"tax_$_"}) }

      for $i (1 .. $form->{paidaccounts}) {
	for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
      }
    }
    
    &{ "$display_form" };

  }

}


sub vendor_details { IR->vendor_details(\%myconfig, \%$form) };
sub customer_details { IS->customer_details(\%myconfig, \%$form) };


sub select_payment {

  @column_index = ("ndx", "datepaid", "source", "memo", "paid", "$form->{ARAP}_paid");

  # list payments with radio button on a form
  $form->header;

  $title = $locale->text('Select payment');

  $column_data{ndx} = qq|<th width=1%>&nbsp;</th>|;
  $column_data{datepaid} = qq|<th>|.$locale->text('Date').qq|</th>|;
  $column_data{source} = qq|<th>|.$locale->text('Source').qq|</th>|;
  $column_data{memo} = qq|<th>|.$locale->text('Memo').qq|</th>|;
  $column_data{paid} = qq|<th>|.$locale->text('Amount').qq|</th>|;
  $column_data{"$form->{ARAP}_paid"} = qq|<th>|.$locale->text('Account').qq|</th>|;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
	</tr>
|;

  $checked = "checked";
  foreach $i (1 .. $form->{paidaccounts} - 1) {

    for (@column_index) { $column_data{$_} = qq|<td>$form->{"${_}_$i"}</td>| }

    $paid = $form->{"paid_$i"};
    $ok = 1;

    $column_data{ndx} = qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
    $column_data{paid} = qq|<td align=right>$paid</td>|;

    $checked = "";
    
    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

  }
  
  print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  for (qw(action nextsub)) { delete $form->{$_} }

  $form->hide_form;
  
  print qq|

<br>
<input type=hidden name=nextsub value=payment_selected>
|;

  if ($ok) {
    print qq|
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;
  }

  print qq|
</form>

</body>
</html>
|;
  
}

sub payment_selected {

  &{ "print_$form->{formname}" }($form->{oldform}, $form->{ndx});

}


sub print_options {

  if ($form->{selectlanguage}) {
    $form->{"selectlanguage"} = $form->unescape($form->{"selectlanguage"});
    $form->{"selectlanguage"} =~ s/ selected//;
    $form->{"selectlanguage"} =~ s/(<option value="\Q$form->{language_code}\E")/$1 selected/;
    $lang = qq|<select name=language_code>$form->{selectlanguage}</select>
    <input type=hidden name=selectlanguage value="|.
    $form->escape($form->{selectlanguage},1).qq|">|;
  }
  
  $form->{selectformname} = $form->unescape($form->{selectformname});
  $form->{selectformname} =~ s/ selected//;
  $form->{selectformname} =~ s/(<option value="\Q$form->{formname}\E")/$1 selected/;
  
  $type = qq|<select name=formname>$form->{selectformname}</select>
  <input type=hidden name=selectformname value="|.$form->escape($form->{selectformname},1).qq|">|;

  $media = qq|<select name=media>
          <option value="screen">|.$locale->text('Screen');

  $form->{selectformat} = qq|<option value="html">html\n|;
  
  if (%printer && $latex) {
    for (sort keys %printer) { $media .= qq| 
          <option value="$_">$_| }
  }

  if ($latex) {
    $form->{selectformat} .= qq|
            <option value="postscript">|.$locale->text('Postscript').qq|
	    <option value="pdf">|.$locale->text('PDF');
  }

  $format = qq|<select name=format>$form->{selectformat}</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
  $format .= qq|
  <input type=hidden name=selectformat value="|.$form->escape($form->{selectformat},1).qq|">|;
  $media .= qq|</select>|;
  $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;

  print qq|
  <table width=100%>
    <tr>
      <td>$type</td>
      <td>$lang</td>
      <td>$format</td>
      <td>$media</td>
      <td align=right width=90%>
  |;

  if ($form->{printed} =~ /$form->{formname}/) {
    print $locale->text('Printed').qq|<br>|;
  }

  if ($form->{recurring}) {
    print $locale->text('Scheduled');
  }

  print qq|
      </td>
    </tr>
  </table>
|;

}


sub print_and_post {

  $form->error($locale->text('Select postscript or PDF!')) if $form->{format} !~ /(postscript|pdf)/;
  $form->error($locale->text('Select a Printer!')) if $form->{media} eq 'screen';

  $form->{printandpost} = 1;
  $form->{display_form} = "post";
  &print;

}


