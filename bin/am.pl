#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
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
# Copyright (c) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# administration
#
#======================================================================


use LedgerSMB::AM;
use LedgerSMB::CA;
use LedgerSMB::Form;
use LedgerSMB::User;
use LedgerSMB::RP;
use LedgerSMB::GL;


1;
# end of main



sub add { &{ "add_$form->{type}" } };
sub edit { &{ "edit_$form->{type}" } };
sub save { &{ "save_$form->{type}" } };
sub delete { &{ "delete_$form->{type}" } };


sub save_as_new {

  delete $form->{id};

  &save;

}


sub add_account {
  
  $form->{title} = "Add";
  $form->{charttype} = "A";
  
  $form->{callback} = "$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &account_header;
  &form_footer;
  
}


sub edit_account {
  
  $form->{title} = "Edit";
  
  $form->{accno} =~ s/\\'/'/g;
  $form->{accno} =~ s/\\\\/\\/g;
 
  AM->get_account(\%myconfig, \%$form);
  
  foreach my $item (split(/:/, $form->{link})) {
    $form->{$item} = "checked";
  }

  &account_header;
  &form_footer;

}


sub account_header {

  $form->{title} = $locale->text("$form->{title} Account");
  
  $checked{$form->{charttype}} = "checked";
  $checked{contra} = "checked" if $form->{contra};
  $checked{"$form->{category}_"} = "checked";
  
  for (qw(accno description)) { $form->{$_} = $form->quote($form->{$_}) }

# this is for our parser only!
# type=submit $locale->text('Add Account')
# type=submit $locale->text('Edit Account')

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=account>

<input type=hidden name=inventory_accno_id value=$form->{inventory_accno_id}>
<input type=hidden name=income_accno_id value=$form->{income_accno_id}>
<input type=hidden name=expense_accno_id value=$form->{expense_accno_id}>
<input type=hidden name=fxgain_accno_id values=$form->{fxgain_accno_id}>
<input type=hidden name=fxloss_accno_id values=$form->{fxloss_accno_id}>

<table border=0 width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr valign=top>
    <td>
      <table>
	<tr>
	  <th align="right">|.$locale->text('Account Number').qq|</th>
	  <td><input name=accno size=20 value="$form->{accno}"></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Description').qq|</th>
	  <td><input name=description size=40 value="$form->{description}"></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Account Type').qq|</th>
	  <td>
	    <table>
	      <tr valign=top>
		<td><input name=category type=radio class=radio value=A $checked{A_}>&nbsp;|.$locale->text('Asset').qq|\n<br>
		<input name=category type=radio class=radio value=L $checked{L_}>&nbsp;|.$locale->text('Liability').qq|\n<br>
		<input name=category type=radio class=radio value=Q $checked{Q_}>&nbsp;|.$locale->text('Equity').qq|\n<br>
		<input name=category type=radio class=radio value=I $checked{I_}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=category type=radio class=radio value=E $checked{E_}>&nbsp;|.$locale->text('Expense')
		.qq|</td>
		<td>
		<input name=contra class=checkbox type=checkbox value=1 $checked{contra}>&nbsp;|.$locale->text('Contra').qq|
		</td>
		<td>
		<input name=charttype type=radio class=radio value="H" $checked{H}>&nbsp;|.$locale->text('Heading').qq|<br>
		<input name=charttype type=radio class=radio value="A" $checked{A}>&nbsp;|.$locale->text('Account')
		.qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
|;


if ($form->{charttype} eq "A") {
  print qq|
	<tr>
	  <td colspan=2>
	    <table>
	      <tr>
		<th align=left>|.$locale->text('Is this a summary account to record').qq|</th>
		<td>
		<input name=AR class=checkbox type=checkbox value=AR $form->{AR}>&nbsp;|.$locale->text('AR')
		.qq|&nbsp;<input name=AP class=checkbox type=checkbox value=AP $form->{AP}>&nbsp;|.$locale->text('AP')
		.qq|&nbsp;<input name=IC class=checkbox type=checkbox value=IC $form->{IC}>&nbsp;|.$locale->text('Inventory')
		.qq|</td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <th colspan=2>|.$locale->text('Include in drop-down menus').qq|</th>
	</tr>
	<tr valign=top>
	  <td colspan=2>
	    <table width=100%>
	      <tr>
		<th align=left>|.$locale->text('Receivables').qq|</th>
		<th align=left>|.$locale->text('Payables').qq|</th>
		<th align=left>|.$locale->text('Tracking Items').qq|</th>
		<th align=left>|.$locale->text('Non-tracking Items').qq|</th>
	      </tr>
	      <tr>
		<td>
		<input name=AR_amount class=checkbox type=checkbox value=AR_amount $form->{AR_amount}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=AR_paid class=checkbox type=checkbox value=AR_paid $form->{AR_paid}>&nbsp;|.$locale->text('Payment').qq|\n<br>
		<input name=AR_tax class=checkbox type=checkbox value=AR_tax $form->{AR_tax}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
		<td>
		<input name=AP_amount class=checkbox type=checkbox value=AP_amount $form->{AP_amount}>&nbsp;|.$locale->text('Expense/Asset').qq|\n<br>
		<input name=AP_paid class=checkbox type=checkbox value=AP_paid $form->{AP_paid}>&nbsp;|.$locale->text('Payment').qq|\n<br>
		<input name=AP_tax class=checkbox type=checkbox value=AP_tax $form->{AP_tax}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
		<td>
		<input name=IC_sale class=checkbox type=checkbox value=IC_sale $form->{IC_sale}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=IC_cogs class=checkbox type=checkbox value=IC_cogs $form->{IC_cogs}>&nbsp;|.$locale->text('COGS').qq|\n<br>
		<input name=IC_taxpart class=checkbox type=checkbox value=IC_taxpart $form->{IC_taxpart}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
		<td>
		<input name=IC_income class=checkbox type=checkbox value=IC_income $form->{IC_income}>&nbsp;|.$locale->text('Income').qq|\n<br>
		<input name=IC_expense class=checkbox type=checkbox value=IC_expense $form->{IC_expense}>&nbsp;|.$locale->text('Expense').qq|\n<br>
		<input name=IC_taxservice class=checkbox type=checkbox value=IC_taxservice $form->{IC_taxservice}>&nbsp;|.$locale->text('Tax') .qq|
		</td>
	      </tr>
	    </table>
	  </td>  
	</tr>  
	<tr>
	</tr>
|;
}

print qq|
        <tr>
	  <th align="right">|.$locale->text('GIFI').qq|</th>
	  <td><input name=gifi_accno size=9 value=$form->{gifi_accno}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub form_footer {

  $form->hide_form(qw(callback path login sessionid));

# type=submit $locale->text('Save')
# type=submit $locale->text('Save as new')
# type=submit $locale->text('Delete')

  %button = ();
  
  if ($form->{id}) {
    $button{'Save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };
    $button{'Save as new'} = { ndx => 7, key => 'N', value => $locale->text('Save as new') };
    
    if ($form->{orphaned}) {
      $button{'Delete'} = { ndx => 16, key => 'D', value => $locale->text('Delete') };
    }
  } else {
    $button{'Save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };
  }

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }
	      
  print qq|
</form>

</body>
</html>
|;

}

  
sub save_account {

  $form->isblank("accno", $locale->text('Account Number missing!'));
  $form->isblank("category", $locale->text('Account Type missing!'));
  
  # check for conflicting accounts
  if ($form->{AR} || $form->{AP} || $form->{IC}) {
    $a = "";
    for (qw(AR AP IC)) { $a .= $form->{$_} }
    $form->error($locale->text('Cannot set account for more than one of AR, AP or IC')) if length $a > 2;

    for (qw(AR_amount AR_tax AR_paid AP_amount AP_tax AP_paid IC_taxpart IC_taxservice IC_sale IC_cogs IC_income IC_expense)) { $form->error("$form->{AR}$form->{AP}$form->{IC} ". $locale->text('account cannot be set to any other type of account')) if $form->{$_} }
  }

  foreach $item ("AR", "AP") {
    $i = 0;
    for ("${item}_amount", "${item}_paid", "${item}_tax") { $i++ if $form->{$_} }
    $form->error($locale->text('Cannot set multiple options for')." $item") if $i > 1;
  }
  
  if (AM->save_account(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Account saved!'));
  } else {
    $form->error($locale->text('Cannot save account!'));
  }

}


sub list_account {

  CA->all_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('Chart of Accounts');
  
  # construct callback
  $callback = "$form->{script}?action=list_account&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  @column_index = qw(accno gifi_accno description debit credit link);

  $column_header{accno} = qq|<th class=listtop>|.$locale->text('Account').qq|</a></th>|;
  $column_header{gifi_accno} = qq|<th class=listtop>|.$locale->text('GIFI').qq|</a></th>|;
  $column_header{description} = qq|<th class=listtop>|.$locale->text('Description').qq|</a></th>|;
  $column_header{debit} = qq|<th class=listtop>|.$locale->text('Debit').qq|</a></th>|;
  $column_header{credit} = qq|<th class=listtop>|.$locale->text('Credit').qq|</a></th>|;
  $column_header{link} = qq|<th class=listtop>|.$locale->text('Link').qq|</a></th>|;


  $form->header;
  $colspan = $#column_index + 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
</tr>
|;

  # escape callback
  $callback = $form->escape($callback);
  
  foreach $ca (@{ $form->{CA} }) {
    
    $ca->{debit} = "&nbsp;";
    $ca->{credit} = "&nbsp;";

    if ($ca->{amount} > 0) {
      $ca->{credit} = $form->format_amount(\%myconfig, $ca->{amount}, 2, "&nbsp;");
    }
    if ($ca->{amount} < 0) {
      $ca->{debit} = $form->format_amount(\%myconfig, -$ca->{amount}, 2, "&nbsp;");
    }

    $ca->{link} =~ s/:/<br>/og;

    $gifi_accno = $form->escape($ca->{gifi_accno});
    
    if ($ca->{charttype} eq "H") {
      print qq|<tr class="listheading">|;

      $column_data{accno} = qq|<th><a class="listheading" href="$form->{script}?action=edit_account&id=$ca->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback">$ca->{accno}</a></th>|;
      $column_data{gifi_accno} = qq|<th class="listheading"><a href="$form->{script}?action=edit_gifi&accno=$gifi_accno&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback">$ca->{gifi_accno}</a>&nbsp;</th>|;
      $column_data{description} = qq|<th class="listheading">$ca->{description}&nbsp;</th>|;
      $column_data{debit} = qq|<th>&nbsp;</th>|;
      $column_data{credit} = qq| <th>&nbsp;</th>|;
      $column_data{link} = qq|<th>&nbsp;</th>|;

    } else {
      $i++; $i %= 2;
      print qq|
<tr valign=top class="listrow$i">|;
      $column_data{accno} = qq|<td><a href="$form->{script}?action=edit_account&id=$ca->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback">$ca->{accno}</a></td>|;
      $column_data{gifi_accno} = qq|<td><a href="$form->{script}?action=edit_gifi&accno=$gifi_accno&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback">$ca->{gifi_accno}</a>&nbsp;</td>|;
      $column_data{description} = qq|<td>$ca->{description}&nbsp;</td>|;
      $column_data{debit} = qq|<td align="right">$ca->{debit}</td>|;
      $column_data{credit} = qq|<td align="right">$ca->{credit}</td>|;
      $column_data{link} = qq|<td>$ca->{link}&nbsp;</td>|;
      
    }

    for (@column_index) { print "$column_data{$_}\n" }
    
    print "</tr>\n";
  }
  
  print qq|
  <tr><td colspan="$colspan"><hr size="3" noshade /></td></tr>
</table>

</body>
</html>
|;

}


sub delete_account {

  $form->{title} = $locale->text('Delete Account');

  foreach $id (qw(inventory_accno_id income_accno_id expense_accno_id fxgain_accno_id fxloss_accno_id)) {
    if ($form->{id} == $form->{$id}) {
      $form->error($locale->text('Cannot delete default account!'));
    }
  }

  if (AM->delete_account(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Account deleted!'));
  } else {
    $form->error($locale->text('Cannot delete account!'));
  }

}


sub list_gifi {

  @{ $form->{fields} } = qw(accno description);
  $form->{table} = "gifi";
  
  AM->gifi_accounts(\%myconfig, \%$form);

  $form->{title} = $locale->text('GIFI');
  
  # construct callback
  $callback = "$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  @column_index = qw(accno description);

  $column_header{accno} = qq|<th class="listheading">|.$locale->text('GIFI').qq|</a></th>|;
  $column_header{description} = qq|<th class="listheading">|.$locale->text('Description').qq|</a></th>|;


  $form->header;
  $colspan = $#column_index + 1;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop colspan=$colspan>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }
  
  print qq|
</tr>
|;

  # escape callback
  $callback = $form->escape($callback);
  
  foreach $ca (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
<tr valign=top class=listrow$i>|;
    
    $accno = $form->escape($ca->{accno});
    $column_data{accno} = qq|<td><a href=$form->{script}?action=edit_gifi&coa=1&accno=$accno&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ca->{accno}</td>|;
    $column_data{description} = qq|<td>$ca->{description}&nbsp;</td>|;
    
    for (@column_index) { print "$column_data{$_}\n" }
    
    print "</tr>\n";
  }
  
  print qq|
  <tr>
    <td colspan=$colspan><hr size=3 noshade></td>
  </tr>
</table>

</body>
</html>
|;

}


sub add_gifi {
  $form->{title} = "Add";
  
  # construct callback
  $form->{callback} = "$form->{script}?action=list_gifi&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->{coa} = 1;
  
  &gifi_header;
  &gifi_footer;
  
}


sub edit_gifi {
  
  $form->{title} = "Edit";
  
  AM->get_gifi(\%myconfig, \%$form);

  $form->error($locale->text('Account does not exist!')) unless $form->{accno};
  
  &gifi_header;
  &gifi_footer;
  
}


sub gifi_header {

  $form->{title} = $locale->text("$form->{title} GIFI");
  
# $locale->text('Add GIFI')
# $locale->text('Edit GIFI')

  for (qw(accno description)) { $form->{$_} = $form->quote($form->{$_}) }

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value="$form->{accno}">
<input type=hidden name=type value=gifi>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">|.$locale->text('GIFI').qq|</th>
	  <td><input name=accno size=20 value="$form->{accno}"></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Description').qq|</th>
	  <td><input name=description size=60 value="$form->{description}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub gifi_footer {

  $form->hide_form(qw(callback path login sessionid));
  
# type=submit $locale->text('Save')
# type=submit $locale->text('Copy to COA')
# type=submit $locale->text('Delete')

  %button = ();
  
  $button{'Save'} = { ndx => 3, key => 'S', value => $locale->text('Save') };
  
  if ($form->{accno}) {
    if ($form->{orphaned}) {
      $button{'Delete'} = { ndx => 16, key => 'D', value => $locale->text('Delete') };
    }
  }
    
  if ($form->{coa}) {
    $button{'Copy to COA'} = { ndx => 7, key => 'C', value => $locale->text('Copy to COA') };
  }

  for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub save_gifi {

  $form->isblank("accno", $locale->text('GIFI missing!'));
  AM->save_gifi(\%myconfig, \%$form);
  $form->redirect($locale->text('GIFI saved!'));

}


sub copy_to_coa {

  $form->isblank("accno", $locale->text('GIFI missing!'));

  AM->save_gifi(\%myconfig, \%$form);

  delete $form->{id};
  $form->{gifi_accno} = $form->{accno};
  
  $form->{title} = "Add";
  $form->{charttype} = "A";
  
  &account_header;
  &form_footer;
  
}


sub delete_gifi {

  AM->delete_gifi(\%myconfig, \%$form);
  $form->redirect($locale->text('GIFI deleted!'));

}


sub add_department {

  $form->{title} = "Add";
  $form->{role} = "P";
  
  $form->{callback} = "$form->{script}?action=add_department&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &department_header;
  &form_footer;

}


sub edit_department {

  $form->{title} = "Edit";

  AM->get_department(\%myconfig, \%$form);

  &department_header;
  &form_footer;

}


sub list_department {

  AM->departments(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_department&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Departments');

  @column_index = qw(description cost profit);

  $column_header{description} = qq|<th width=90%><a class="listheading" href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_header{cost} = qq|<th class="listheading" nowrap>|.$locale->text('Cost Center').qq|</th>|;
  $column_header{profit} = qq|<th class="listheading" nowrap>|.$locale->text('Profit Center').qq|</th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $costcenter = ($ref->{role} eq "C") ? "*" : "&nbsp;";
   $profitcenter = ($ref->{role} eq "P") ? "*" : "&nbsp;";
   
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_department&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;
   $column_data{cost} = qq|<td align=center>$costcenter</td>|;
   $column_data{profit} = qq|<td align=center>$profitcenter</td>|;

   for (@column_index) { print "$column_data{$_}\n" }

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

<br>
<form method=post action=$form->{script}>
|;

  $form->{type} = "department";
  
  $form->hide_form(qw(type callback path login sessionid));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Department').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>
  
  </body>
  </html> 
|;
  
}


sub department_header {

  $form->{title} = $locale->text("$form->{title} Department");

# $locale->text('Add Department')
# $locale->text('Edit Department')

  $form->{description} = $form->quote($form->{description});

  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="$form->{description}">|;
  }

  $costcenter = "checked" if $form->{role} eq "C";
  $profitcenter = "checked" if $form->{role} eq "P";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=department>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">|.$locale->text('Description').qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td></td>
    <td><input type=radio style=radio name=role value="C" $costcenter> |.$locale->text('Cost Center').qq|
        <input type=radio style=radio name=role value="P" $profitcenter> |.$locale->text('Profit Center').qq|
    </td>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_department {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_department(\%myconfig, \%$form);
  $form->redirect($locale->text('Department saved!'));

}


sub delete_department {

  AM->delete_department(\%myconfig, \%$form);
  $form->redirect($locale->text('Department deleted!'));

}


sub add_business {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_business&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &business_header;
  &form_footer;

}


sub edit_business {

  $form->{title} = "Edit";

  AM->get_business(\%myconfig, \%$form);

  &business_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_business {

  AM->business(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_business&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Type of Business');

  @column_index = qw(description discount);

  $column_header{description} = qq|<th width=90%><a class="listheading" href=$href>|.$locale->text('Description').qq|</a></th>|;
  $column_header{discount} = qq|<th class="listheading">|.$locale->text('Discount').qq| %</th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $discount = $form->format_amount(\%myconfig, $ref->{discount} * 100, 2, "&nbsp");
   
   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_business&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;
   $column_data{discount} = qq|<td align="right">$discount</td>|;
   
   for (@column_index) { print "$column_data{$_}\n" }

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

<br>
<form method=post action=$form->{script}>
|;

  $form->{type} = "business";
  
  $form->hide_form(qw(type callback path login sessionid));

  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Business').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  
  </form>
  
  </body>
  </html> 
|;
  
}


sub business_header {

  $form->{title} = $locale->text("$form->{title} Business");

# $locale->text('Add Business')
# $locale->text('Edit Business')

  $form->{description} = $form->quote($form->{description});
  $form->{discount} = $form->format_amount(\%myconfig, $form->{discount} * 100);

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=business>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">|.$locale->text('Type of Business').qq|</th>
	  <td><input name=description size=30 value="$form->{description}"></td>
	<tr>
	<tr>
	  <th align="right">|.$locale->text('Discount').qq| %</th>
	  <td><input name=discount size=5 value=$form->{discount}></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_business {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_business(\%myconfig, \%$form);
  $form->redirect($locale->text('Business saved!'));

}


sub delete_business {

  AM->delete_business(\%myconfig, \%$form);
  $form->redirect($locale->text('Business deleted!'));

}



sub add_sic {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_sic&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &sic_header;
  &form_footer;

}


sub edit_sic {

  $form->{title} = "Edit";

  $form->{code} =~ s/\\'/'/g;
  $form->{code} =~ s/\\\\/\\/g;
  
  AM->get_sic(\%myconfig, \%$form);
  $form->{id} = $form->{code};

  &sic_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_sic {

  AM->sic(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_sic&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Standard Industrial Codes');

  @column_index = $form->sort_columns(qw(code description));

  $column_header{code} = qq|<th><a class="listheading" href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_header{description} = qq|<th><a class="listheading" href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    if ($ref->{sictype} eq 'H') {
      print qq|
        <tr valign=top class="listheading">
|;
      $column_data{code} = qq|<th><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</th>|;
      $column_data{description} = qq|<th>$ref->{description}</th>|;
     
    } else {
      print qq|
        <tr valign=top class=listrow$i>
|;

      $column_data{code} = qq|<td><a href=$form->{script}?action=edit_sic&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</td>|;
      $column_data{description} = qq|<td>$ref->{description}</td>|;

   }
    
   for (@column_index) { print "$column_data{$_}\n" }

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

<br>
<form method=post action=$form->{script}>
|;

  $form->{type} = "sic";
  
  $form->hide_form(qw(type callback path login sessionid));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add SIC').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>
  
  </body>
  </html> 
|;
  
}


sub sic_header {

  $form->{title} = $locale->text("$form->{title} SIC");

# $locale->text('Add SIC')
# $locale->text('Edit SIC')

  for (qw(code description)) { $form->{$_} = $form->quote($form->{$_}) }

  $checked = ($form->{sictype} eq 'H') ? "checked" : "";

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=sic>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">|.$locale->text('Code').qq|</th>
    <td><input name=code size=10 value="$form->{code}"></td>
  <tr>
  <tr>
    <td></td>
    <th align=left><input name=sictype class=checkbox type=checkbox value="H" $checked> |.$locale->text('Heading').qq|</th>
  <tr>
  <tr>
    <th align="right">|.$locale->text('Description').qq|</th>
    <td><input name=description size=60 value="$form->{description}"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_sic {

  $form->isblank("code", $locale->text('Code missing!'));
  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_sic(\%myconfig, \%$form);
  $form->redirect($locale->text('SIC saved!'));

}


sub delete_sic {

  AM->delete_sic(\%myconfig, \%$form);
  $form->redirect($locale->text('SIC deleted!'));

}


sub add_language {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_language&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &language_header;
  &form_footer;

}


sub edit_language {

  $form->{title} = "Edit";

  $form->{code} =~ s/\\'/'/g;
  $form->{code} =~ s/\\\\/\\/g;
  
  AM->get_language(\%myconfig, \%$form);
  $form->{id} = $form->{code};

  &language_header;

  $form->{orphaned} = 1;
  &form_footer;

}


sub list_language {

  AM->language(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_language&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Languages');

  @column_index = $form->sort_columns(qw(code description));

  $column_header{code} = qq|<th><a class="listheading" href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_header{description} = qq|<th><a class="listheading" href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;

    print qq|
        <tr valign=top class=listrow$i>
|;

    $column_data{code} = qq|<td><a href=$form->{script}?action=edit_language&code=$ref->{code}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{code}</td>|;
    $column_data{description} = qq|<td>$ref->{description}</td>|;
    
   for (@column_index) { print "$column_data{$_}\n" }

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

<br>
<form method=post action=$form->{script}>
|;

  $form->{type} = "language";

  $form->hide_form(qw(type callback path login sessionid));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Language').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>
  
  </body>
  </html> 
|;
  
}


sub language_header {

  $form->{title} = $locale->text("$form->{title} Language");

# $locale->text('Add Language')
# $locale->text('Edit Language')

  for (qw(code description)) { $form->{$_} = $form->quote($form->{$_}) }

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=language>
<input type=hidden name=id value="$form->{code}">

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">|.$locale->text('Code').qq|</th>
    <td><input name=code size=10 value="$form->{code}"></td>
  <tr>
  <tr>
    <th align="right">|.$locale->text('Description').qq|</th>
    <td><input name=description size=60 value="$form->{description}"></td>
  </tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_language {

  $form->isblank("code", $locale->text('Code missing!'));
  $form->isblank("description", $locale->text('Description missing!'));

  $form->{code} =~ s/(\.\.|\*)//g;
  
  AM->save_language(\%myconfig, \%$form);

  if (! -d "$myconfig{templates}/$form->{code}") {
      
    umask(002);
    
    if (mkdir "$myconfig{templates}/$form->{code}", oct("771")) {
      
      umask(007);

      opendir TEMPLATEDIR, "$myconfig{templates}" or $form->error("$myconfig{templates} : $!");
      @templates = grep !/^(\.|\.\.)/, readdir TEMPLATEDIR;
      closedir TEMPLATEDIR;

      foreach $file (@templates) {
	if (-f "$myconfig{templates}/$file") {
	  open(TEMP, "$myconfig{templates}/$file") or $form->error("$myconfig{templates}/$file : $!");

	  open(NEW, ">$myconfig{templates}/$form->{code}/$file") or $form->error("$myconfig{templates}/$form->{code}/$file : $!");

	  while ($line = <TEMP>) {
	    print NEW $line;
	  }
	  close(TEMP);
	  close(NEW);
	}
      }
    } else {
      $form->error("${templates}/$form->{code} : $!");
    }
  }
    
  $form->redirect($locale->text('Language saved!'));

}


sub delete_language {

  $form->{title} = $locale->text('Confirm!');

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  for (qw(action nextsub)) { delete $form->{$_} }
  
  $form->hide_form;

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Deleting a language will also delete the templates for the language').qq| $form->{invnumber}</h4>

<input type=hidden name=action value=continue>
<input type=hidden name=nextsub value=yes_delete_language>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">
</form>

</body>
</html>
|;

}


sub yes_delete_language {
  
  AM->delete_language(\%myconfig, \%$form);

  # delete templates
  $dir = "$myconfig{templates}/$form->{code}";
  if (-d $dir) {
    unlink <$dir/*>;
    rmdir "$myconfig{templates}/$form->{code}";
  }
  $form->redirect($locale->text('Language deleted!'));

}


sub display_stylesheet {
  
  $form->{file} = "css/$myconfig{stylesheet}";
  &display_form;
  
}


sub list_templates {

  AM->language(\%myconfig, \%$form);
  
  if (! @{ $form->{ALL} }) {
    &display_form;
    exit;
  }

  unshift @{ $form->{ALL} }, { code => '.', description => $locale->text('Default Template') };
  
  $href = "$form->{script}?action=list_templates&direction=$form->{direction}&oldsort=$form->{oldsort}&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $form->sort_order();

  $form->{callback} = "$form->{script}?action=list_templates&direction=$form->{direction}&oldsort=$form->{oldsort}&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
  
  $callback = $form->escape($form->{callback});

  chomp $myconfig{templates};
  $form->{file} =~ s/$myconfig{templates}//;
  $form->{file} =~ s/\///;
  $form->{title} = $form->{file};

  @column_index = $form->sort_columns(qw(code description));

  $column_header{code} = qq|<th><a class="listheading" href=$href&sort=code>|.$locale->text('Code').qq|</a></th>|;
  $column_header{description} = qq|<th><a class="listheading" href=$href&sort=description>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;

    print qq|
        <tr valign=top class=listrow$i>
|;

    $column_data{code} = qq|<td><a href=$form->{script}?action=display_form&file=$myconfig{templates}/$ref->{code}/$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&code=$ref->{code}&callback=$callback>$ref->{code}</td>|;
    $column_data{description} = qq|<td>$ref->{description}</td>|;
    
   for (@column_index) { print "$column_data{$_}\n" }

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

<br>
<form method=post action=$form->{script}>

<input name=callback type=hidden value="$form->{callback}">

<input type=hidden name=type value=language>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>
|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>
  
  </body>
  </html> 
|;
  
}


sub display_form {

  $form->{file} =~ s/^(.:)*?\/|\.\.\///g; 
  $form->{file} =~ s/^\/*//g;
  $form->{file} =~ s/$userspath//;
  $form->{file} =~ s/$memberfile//;

  $form->error("$!: $form->{file}") unless -f $form->{file};

  AM->load_template(\%myconfig, \%$form);

  $form->{title} = $form->{file};

  $form->{body} =~ s/<%include (.*?)%>/<a href=$form->{script}\?action=display_form&file=$myconfig{templates}\/$form->{code}\/$1&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}>$1<\/a>/g;

  # if it is anything but html
  if ($form->{file} !~ /\.html$/) {
    $form->{body} = "<pre>\n$form->{body}\n</pre>";
  }
    
  $form->header;

  print qq|
<body>

$form->{body}

<form method=post action=$form->{script}>
|;

  $form->{type} = "template";

  $form->hide_form(qw(file type path login sessionid));
  
  print qq|
<input name=action type=submit class=submit value="|.$locale->text('Edit').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub edit_template {

  AM->load_template(\%myconfig, \%$form);

  $form->{title} = $locale->text('Edit Template');
  # convert &nbsp to &amp;nbsp;
  $form->{body} =~ s/&nbsp;/&amp;nbsp;/gi;
  

  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input name=file type=hidden value=$form->{file}>
<input name=type type=hidden value=template>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input name=callback type=hidden value="$form->{script}?action=display_form&file=$form->{file}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}">

<textarea name=body rows=25 cols=70>
$form->{body}
</textarea>

<br>
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print q|
  </form>


</body>
</html>
|;

}


sub save_template {

  AM->save_template(\%myconfig, \%$form);
  $form->redirect($locale->text('Template saved!'));
  
}


sub defaults {
  
  # get defaults for account numbers and last numbers
  AM->defaultaccounts(\%myconfig, \%$form);

  foreach $key (keys %{ $form->{accno} }) {
    foreach $accno (sort keys %{ $form->{accno}{$key} }) {
      $form->{account}{$key} .= "<option>$accno--$form->{accno}{$key}{$accno}{description}\n";
      $form->{accno}{$form->{accno}{$key}{$accno}{id}} = $accno;
    }
  }

  for (qw(IC IC_inventory IC_income IC_expense FX_gain FX_loss)) { $form->{account}{$_} =~ s/>$form->{accno}{$form->{defaults}{$_}}/ selected>$form->{accno}{$form->{defaults}{$_}}/ }

  for (qw(accno defaults)) { delete $form->{$_} }
  
  $form->{title} = $locale->text('System Defaults');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=defaults>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">|.$locale->text('Business Number').qq|</th>
	  <td><input name=businessnumber size=25 value="$form->{businessnumber}"></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Weight Unit').qq|</th>
	  <td><input name=weightunit size=5 value="$form->{weightunit}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <th class="listheading">|.$locale->text('Last Numbers & Default Accounts').qq|</th>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Inventory').qq|</th>
	  <td><select name=IC>$form->{account}{IC}</select></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Income').qq|</th>
	  <td><select name=IC_income>$form->{account}{IC_income}</select></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Expense').qq|</th>
	  <td><select name=IC_expense>$form->{account}{IC_expense}</select></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Foreign Exchange Gain').qq|</th>
	  <td><select name=FX_gain>$form->{account}{FX_gain}</select></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Foreign Exchange Loss').qq|</th>
	  <td><select name=FX_loss>$form->{account}{FX_loss}</select></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <th align=left>|.$locale->text('Enter up to 3 letters separated by a colon (i.e CAD:USD:EUR) for your native and foreign currencies').qq|</th>
  </tr>
  <tr>
    <td>
    <input name=curr size=40 value="$form->{curr}">
    </td>
  </tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right" nowrap>|.$locale->text('GL Reference Number').qq|</th>
	  <td><input name=glnumber size=40 value="$form->{glnumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Sales Invoice/AR Transaction Number').qq|</th>
	  <td><input name=sinumber size=40 value="$form->{sinumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Sales Order Number').qq|</th>
	  <td><input name=sonumber size=40 value="$form->{sonumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Vendor Invoice/AP Transaction Number').qq|</th>
	  <td><input name=vinumber size=40 value="$form->{vinumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Purchase Order Number').qq|</th>
	  <td><input name=ponumber size=40 value="$form->{ponumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Sales Quotation Number').qq|</th>
	  <td><input name=sqnumber size=40 value="$form->{sqnumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('RFQ Number').qq|</th>
	  <td><input name=rfqnumber size=40 value="$form->{rfqnumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Part Number').qq|</th>
	  <td><input name=partnumber size=40 value="$form->{partnumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Job/Project Number').qq|</th>
	  <td><input name=projectnumber size=40 value="$form->{projectnumber}"></td>
        </tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Employee Number').qq|</th>
	  <td><input name=employeenumber size=40 value="$form->{employeenumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Customer Number').qq|</th>
	  <td><input name=customernumber size=40 value="$form->{customernumber}"></td>
	</tr>
	<tr>
	  <th align="right" nowrap>|.$locale->text('Vendor Number').qq|</th>
	  <td><input name=vendornumber size=40 value="$form->{vendornumber}"></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(path login sessionid));
  
  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub taxes {
  
  # get tax account numbers
  AM->taxes(\%myconfig, \%$form);

  $i = 0;
  foreach $ref (@{ $form->{taxrates} }) {
    $i++;
    $form->{"taxrate_$i"} = $form->format_amount(\%myconfig, $ref->{rate});
    $form->{"taxdescription_$i"} = $ref->{description};
    
    for (qw(taxnumber validto pass taxmodulename)) { 
      $form->{"${_}_$i"} = $ref->{$_};
    }
    $form->{taxaccounts} .= "$ref->{id}_$i ";
  }
  chop $form->{taxaccounts};
  
  &display_taxes;

}


sub display_taxes {
  
  $form->{title} = $locale->text('Taxes');
  
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=type value=taxes>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th></th>
	  <th>|.$locale->text('Rate').qq| (%)</th>
	  <th>|.$locale->text('Number').qq|</th>
	  <th>|.$locale->text('Valid To').qq|</th>
	  <th>|.$locale->text('Ordering').qq|</th>
	  <th>|.$locale->text('Tax Rules').qq|</th>
	</tr>
|;

  for (split(/ /, $form->{taxaccounts})) {
    
    ($null, $i) = split /_/, $_;
    
    $form->{"taxrate_$i"} = $form->format_amount(\%myconfig, $form->{"taxrate_$i"});
    
    $form->hide_form("taxdescription_$i");
    
    print qq|
	<tr>
	  <th align="right">|;
	  
    if ($form->{"taxdescription_$i"} eq $sametax) {
      print "";
    } else {
      print qq|$form->{"taxdescription_$i"}|;
    }
    
    print qq|</th>
	  <td><input name="taxrate_$i" size=6 value=$form->{"taxrate_$i"}></td>
	  <td><input name="taxnumber_$i" value="$form->{"taxnumber_$i"}"></td>
	  <td><input name="validto_$i" size=11 value="$form->{"validto_$i"}" title="$myconfig{dateformat}"></td>
	  <td><input name="pass_$i" size=6 value="$form->{"pass_$i"}"></td>
	  <td><select name="taxmodule_id_$i" size=1>|;
    foreach my $taxmodule (sort keys %$form) {
      next if ($taxmodule !~ /^taxmodule_/);
      next if ($taxmodule =~ /^taxmodule_id_/);
      my $modulenum = $taxmodule;
      $modulenum =~ s/^taxmodule_//;
      print '<option label="'.$form->{$taxmodule}.'" value="'.$modulenum . '"';
      print " SELECTED " if $form->{$taxmodule} eq $form->{"taxmodulename_$i"};
      print " />\n";
    }
    print qq|</select></td>
	</tr> |;
    $sametax = $form->{"taxdescription_$i"};
    
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

  $form->hide_form(qw(taxaccounts path login sessionid));
  foreach my $taxmodule (sort keys %$form) {
    next if ($taxmodule !~ /^taxmodule_/);
    next if ($taxmodule =~ /^taxmodule_id_/);
    $form->hide_form("$taxmodule");
  }

  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Update').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub update {

  @a = split / /, $form->{taxaccounts};
  $ndx = $#a + 1;
  
  foreach $item (@a) {
    ($accno, $i) = split /_/, $item;
    push @t, $accno;
    $form->{"taxmodulename_$i"} = $form->{"taxmodule_".$form->{"taxmodule_id_$i"}};

    if ($form->{"validto_$i"}) {
      $j = $i + 1;
      if ($form->{"taxdescription_$i"} ne $form->{"taxdescription_$j"}) {
	#insert line
	for ($j = $ndx + 1; $j > $i; $j--) {
	  $k = $j - 1;
	  for (qw(taxrate taxdescription taxnumber validto)) { $form->{"${_}_$j"} = $form->{"${_}_$k"} }
	}
	$ndx++;
	$k = $i + 1;
	for (qw(taxdescription taxnumber)) { $form->{"${_}_$k"} = $form->{"${_}_$i"} }
	for (qw(taxrate validto)) { $form->{"${_}_$k"} = "" }
	push @t, $accno;
      }
    } else {
      # remove line
      $j = $i + 1;
      if ($form->{"taxdescription_$i"} eq $form->{"taxdescription_$j"}) {
	  for ($j = $i + 1; $j <= $ndx; $j++) {
	    $k = $j + 1;
	    for (qw(taxrate taxdescription taxnumber validto)) { $form->{"${_}_$j"} = $form->{"${_}_$k"} }
	  }
	  $ndx--;
	  splice @t, $i-1, 1;
	}
    }
	
  }

  $i = 1;
  $form->{taxaccounts} = "";
  for (@t) {
    $form->{taxaccounts} .= "${_}_$i ";
    $i++;
  }
  chop $form->{taxaccounts};

  &display_taxes;
  
}



sub config {

  foreach $item (qw(mm-dd-yy mm/dd/yy dd-mm-yy dd/mm/yy dd.mm.yy yyyy-mm-dd)) {
    $dateformat .= ($item eq $myconfig{dateformat}) ? "<option selected>$item\n" : "<option>$item\n";
  }

  my @formats = qw(1,000.00 1000.00 1.000,00 1000,00 1'000.00);
  push @formats, '1 000.00';
  foreach $item (@formats) {
    $numberformat .= ($item eq $myconfig{numberformat}) ? "<option selected>$item\n" : "<option>$item\n";
  }

  for (qw(name company address signature)) { $myconfig{$_} = $form->quote($myconfig{$_}) }
  for (qw(address signature)) { $myconfig{$_} =~ s/\\n/\n/g }

  %countrycodes = User->country_codes;
  $countrycodes = '';
  
  foreach $key (sort { $countrycodes{$a} cmp $countrycodes{$b} } keys %countrycodes) {
    $countrycodes .= ($myconfig{countrycode} eq $key) ? "<option selected value=$key>$countrycodes{$key}\n" : "<option value=$key>$countrycodes{$key}\n";
  }
  $countrycodes = qq|<option value="">English\n$countrycodes|;

  opendir CSS, "css/.";
  @all = grep /.*\.css$/, readdir CSS;
  closedir CSS;

  foreach $item (@all) {
    if ($item eq $myconfig{stylesheet}) {
      $selectstylesheet .= qq|<option selected>$item\n|;
    } else {
      $selectstylesheet .= qq|<option>$item\n|;
    }
  }
  $selectstylesheet .= "<option>\n";
  
  if (%printer && $latex) {
    $selectprinter = "<option>\n";
    foreach $item (sort keys %printer) {
      if ($myconfig{printer} eq $item) {
	$selectprinter .= qq|<option value="$item" selected>$item\n|;
      } else {
	$selectprinter .= qq|<option value="$item">$item\n|;
      }
    }

    $printer = qq|
	      <tr>
		<th align="right">|.$locale->text('Printer').qq|</th>
		<td><select name=printer>$selectprinter</select></td>
	      </tr>
|;
  }
  
  $form->{title} = $locale->text('Edit Preferences for').qq| $form->{login}|;
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=old_password value=$myconfig{password}>
<input type=hidden name=type value=preferences>
<input type=hidden name=role value=$myconfig{role}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align="right">|.$locale->text('Name').qq|</th>
		<td><input name=name size=20 value="$myconfig{name}"></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('E-mail').qq|</th>
		<td><input name=email size=35 value="$myconfig{email}"></td>
	      </tr>
	      <tr valign=top>
		<th align="right">|.$locale->text('Signature').qq|</th>
		<td><textarea name=signature rows=3 cols=35>$myconfig{signature}</textarea></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Phone').qq|</th>
		<td><input name=tel size=14 value="$myconfig{tel}"></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Fax').qq|</th>
		<td><input name=fax size=14 value="$myconfig{fax}"></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Company').qq|</th>
		<td><input name=company size=35 value="$myconfig{company}"></td>
	      </tr>
	      <tr valign=top>
		<th align="right">|.$locale->text('Address').qq|</th>
		<td><textarea name=address rows=4 cols=35>$myconfig{address}</textarea></td>
	      </tr>
	    </table>
	  </td>
	  <td>
	    <table>
	      <tr>
		<th align="right">|.$locale->text('Password').qq|</th>
		<td><input type=password name=new_password size=10 value=$myconfig{password}></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Confirm').qq|</th>
		<td><input type=password name=confirm_password size=10></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Date Format').qq|</th>
		<td><select name=dateformat>$dateformat</select></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Number Format').qq|</th>
		<td><select name=numberformat>$numberformat</select></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Dropdown Limit').qq|</th>
		<td><input name=vclimit size=10 value="$myconfig{vclimit}"></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Menu Width').qq|</th>
		<td><input name=menuwidth size=10 value="$myconfig{menuwidth}"></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Language').qq|</th>
		<td><select name=countrycode>$countrycodes</select></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Session Timeout').qq|</th>
		<td><input name=timeout size=10 value="$myconfig{timeout}"></td>
	      </tr>
	      <tr>
		<th align="right">|.$locale->text('Stylesheet').qq|</th>
		<td><select name=usestylesheet>$selectstylesheet</select></td>
	      </tr>
	      $printer
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(path login sessionid));
  
  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Save').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>

</body>
</html>
|;

}


sub save_defaults {

  if (AM->save_defaults(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Defaults saved!'));
  } else {
    $form->error($locale->text('Cannot save defaults!'));
  }

}


sub save_taxes {

  if (AM->save_taxes(\%myconfig, \%$form)) {
    $form->redirect($locale->text('Taxes saved!'));
  } else {
    $form->error($locale->text('Cannot save taxes!'));
  }

}


sub save_preferences {

  $form->{stylesheet} = $form->{usestylesheet};

  if ($form->{new_password} ne $form->{old_password}) {
    $form->error($locale->text('Password does not match!')) if $form->{new_password} ne $form->{confirm_password};
  }

  if (AM->save_preferences(\%myconfig, \%$form, $memberfile, $userspath)) {
    $form->redirect($locale->text('Preferences saved!'));
  } else {
    $form->error($locale->text('Cannot save preferences!'));
  }

}


sub backup {

  if ($form->{media} eq 'email') {
    $form->error($locale->text('No email address for')." $myconfig{name}") unless ($myconfig{email});
    
    $form->{OUT} = "$sendmail";

  }

  $SIG{INT} = 'IGNORE';
  AM->backup(\%myconfig, \%$form, $userspath, $gzip);

  if ($form->{media} eq 'email') {
    $form->redirect($locale->text('Backup sent to').qq| $myconfig{email}|);
  }

}



sub audit_control {

  $form->{title} = $locale->text('Audit Control');

  AM->closedto(\%myconfig, \%$form);
  
  if ($form->{revtrans}) {
    $checked{revtransY} = "checked";
  } else {
    $checked{revtransN} = "checked";
  }
  
  if ($form->{audittrail}) {
    $checked{audittrailY} = "checked";
  } else {
    $checked{audittrailN} = "checked";
  }
 
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">|.$locale->text('Enforce transaction reversal for all dates').qq|</th>
	  <td><input name=revtrans class=radio type=radio value="1" $checked{revtransY}> |.$locale->text('Yes').qq| <input name=revtrans class=radio type=radio value="0" $checked{revtransN}> |.$locale->text('No').qq|</td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Close Books up to').qq|</th>
	  <td><input name=closedto size=11 title="$myconfig{dateformat}" value=$form->{closedto}></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Activate Audit trail').qq|</th>
	  <td><input name=audittrail class=radio type=radio value="1" $checked{audittrailY}> |.$locale->text('Yes').qq| <input name=audittrail class=radio type=radio value="0" $checked{audittrailN}> |.$locale->text('No').qq|</td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Remove Audit trail up to').qq|</th>
	  <td><input name=removeaudittrail size=11 title="$myconfig{dateformat}"></td>
	</tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input type=hidden name=nextsub value=doclose>
<input type=hidden name=action value=continue>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">

</form>

</body>
</html>
|;

}


sub doclose {

  AM->closebooks(\%myconfig, \%$form);
  
  if ($form->{revtrans}) {
    $msg = $locale->text('Transaction reversal enforced for all dates');
  } else {
    
    if ($form->{closedto}) {
      $msg = $locale->text('Transaction reversal enforced up to')
      ." ".$locale->date(\%myconfig, $form->{closedto}, 1);
    } else {
      $msg = $locale->text('Books are open');
    }
  }

  $msg .= "<p>";
  if ($form->{audittrail}) {
    $msg .= $locale->text('Audit trail enabled');
  } else {
    $msg .= $locale->text('Audit trail disabled');
  }

  $msg .= "<p>";
  if ($form->{removeaudittrail}) {
    $msg .= $locale->text('Audit trail removed up to')
    ." ".$locale->date(\%myconfig, $form->{removeaudittrail}, 1);
  }
    
  $form->redirect($msg);
  
}


sub add_warehouse {

  $form->{title} = "Add";
  
  $form->{callback} = "$form->{script}?action=add_warehouse&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}" unless $form->{callback};

  &warehouse_header;
  &form_footer;

}


sub edit_warehouse {

  $form->{title} = "Edit";

  AM->get_warehouse(\%myconfig, \%$form);

  &warehouse_header;
  &form_footer;

}


sub list_warehouse {

  AM->warehouses(\%myconfig, \%$form);

  $href = "$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->sort_order();
  
  $form->{callback} = "$form->{script}?action=list_warehouse&direction=$form->{direction}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  $callback = $form->escape($form->{callback});
  
  $form->{title} = $locale->text('Warehouses');

  @column_index = qw(description);

  $column_header{description} = qq|<th width=100%><a class="listheading" href=$href>|.$locale->text('Description').qq|</a></th>|;

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print qq|
        </tr>
|;

  foreach $ref (@{ $form->{ALL} }) {
    
    $i++; $i %= 2;
    
    print qq|
        <tr valign=top class=listrow$i>
|;

   $column_data{description} = qq|<td><a href=$form->{script}?action=edit_warehouse&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback>$ref->{description}</td>|;

   for (@column_index) { print "$column_data{$_}\n" }

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

<br>
<form method=post action=$form->{script}>
|;

  $form->{type} = "warehouse";

  $form->hide_form(qw(type callback path login sessionid));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Add Warehouse').qq|">|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|
  </form>
  
  </body>
  </html> 
|;
  
}



sub warehouse_header {

  $form->{title} = $locale->text("$form->{title} Warehouse");

# $locale->text('Add Warehouse')
# $locale->text('Edit Warehouse')

  $form->{description} = $form->quote($form->{description});

  if (($rows = $form->numtextrows($form->{description}, 60)) > 1) {
    $description = qq|<textarea name="description" rows=$rows cols=60 wrap=soft>$form->{description}</textarea>|;
  } else {
    $description = qq|<input name=description size=60 value="$form->{description}">|;
  }

  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=id value=$form->{id}>
<input type=hidden name=type value=warehouse>

<table width=100%>
  <tr>
    <th class=listtop colspan=2>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <th align="right">|.$locale->text('Description').qq|</th>
    <td>$description</td>
  </tr>
  <tr>
    <td colspan=2><hr size=3 noshade></td>
  </tr>
</table>
|;

}


sub save_warehouse {

  $form->isblank("description", $locale->text('Description missing!'));
  AM->save_warehouse(\%myconfig, \%$form);
  $form->redirect($locale->text('Warehouse saved!'));

}


sub delete_warehouse {

  AM->delete_warehouse(\%myconfig, \%$form);
  $form->redirect($locale->text('Warehouse deleted!'));

}


sub yearend {

  AM->earningsaccounts(\%myconfig, \%$form);
  $chart = "";
  for (@{ $form->{chart} }) { $chart .= "<option>$_->{accno}--$_->{description}" }
  
  $form->{title} = $locale->text('Yearend');
  $form->header;
  
  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=decimalplaces value=2>
<input type=hidden name=l_accno value=Y>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align="right">|.$locale->text('Yearend').qq|</th>
	  <td><input name=todate size=11 title="$myconfig{dateformat}" value=$todate></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Reference').qq|</th>
	  <td><input name=reference size=20 value="|.$locale->text('Yearend').qq|"></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Description').qq|</th>
	  <td><textarea name=description rows=3 cols=50 wrap=soft></textarea></td>
	</tr>
	<tr>
	  <th align="right">|.$locale->text('Retained Earnings').qq|</th>
	  <td><select name=accno>$chart</select></td>
	</tr>
	<tr>
          <th align="right">|.$locale->text('Method').qq|</th>
          <td><input name=method class=radio type=radio value=accrual checked>&nbsp;|.$locale->text('Accrual').qq|&nbsp;<input name=method class=radio type=radio value=cash>&nbsp;|.$locale->text('Cash').qq|</td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<input type=hidden name=nextsub value=generate_yearend>
|;

  $form->hide_form(qw(path login sessionid));
  
  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

}


sub generate_yearend {

  $form->isblank("todate", $locale->text('Yearend date missing!'));

  RP->yearend_statement(\%myconfig, \%$form);
  
  $form->{transdate} = $form->{todate};

  $earnings = 0;
  
  $form->{rowcount} = 1;
  foreach $key (keys %{ $form->{I} }) {
    if ($form->{I}{$key}{charttype} eq "A") {
      $form->{"debit_$form->{rowcount}"} = $form->{I}{$key}{this};
      $earnings += $form->{I}{$key}{this};
      $form->{"accno_$form->{rowcount}"} = $key;
      $form->{rowcount}++;
      $ok = 1;
    }
  }

  foreach $key (keys %{ $form->{E} }) {
    if ($form->{E}{$key}{charttype} eq "A") {
      $form->{"credit_$form->{rowcount}"} = $form->{E}{$key}{this} * -1;
      $earnings += $form->{E}{$key}{this};
      $form->{"accno_$form->{rowcount}"} = $key;
      $form->{rowcount}++;
      $ok = 1;
    }
  }
  if ($earnings > 0) {
    $form->{"credit_$form->{rowcount}"} = $earnings;
    $form->{"accno_$form->{rowcount}"} = $form->{accno}
  } else {
    $form->{"debit_$form->{rowcount}"} = $earnings * -1;
    $form->{"accno_$form->{rowcount}"} = $form->{accno}
  }
  
  if ($ok) {
    if (AM->post_yearend(\%myconfig, \%$form)) {
      $form->redirect($locale->text('Yearend posted!'));
    } else {
      $form->error($locale->text('Yearend posting failed!'));
    }
  } else {
    $form->error('Nothing to do!');
  }
  
}



sub company_logo {
  
  $myconfig{address} =~ s/\\n/<br>/g;
  $myconfig{dbhost} = $locale->text('localhost') unless $myconfig{dbhost};

  $form->{stylesheet} = $myconfig{stylesheet};

  $form->{title} = $locale->text('About');
  
  # create the logo screen
  $form->header;

  print qq|
<body>

<pre>

</pre>
<center>
<a href="http://www.ledgersmb.org/" target="_blank"><img src="ledger-smb.png" width="200" height="100" border="0" alt="LedgerSMB Logo" /></a>
<h1 class="login">|.$locale->text('Version').qq| $form->{version}</h1>

<p>
|.$locale->text('Licensed to').qq|
<p>
<b>
$myconfig{company}
<br>$myconfig{address}
</b>

<p>
<table border=0>
  <tr>
    <th align="right">|.$locale->text('User').qq|</th>
    <td>$myconfig{name}</td>
  </tr>
  <tr>
    <th align="right">|.$locale->text('Dataset').qq|</th>
    <td>$myconfig{dbname}</td>
  </tr>
  <tr>
    <th align="right">|.$locale->text('Database Host').qq|</th>
    <td>$myconfig{dbhost}</td>
  </tr>
</table>

</center>

</body>
</html>
|;

}


sub recurring_transactions {

# $locale->text('Day')
# $locale->text('Days')
# $locale->text('Month')
# $locale->text('Months')
# $locale->text('Week')
# $locale->text('Weeks')
# $locale->text('Year')
# $locale->text('Years')

  $form->{stylesheet} = $myconfig{stylesheet};

  $form->{title} = $locale->text('Recurring Transactions');

  $column_header{id} = "";

  AM->recurring_transactions(\%myconfig, \%$form);

  $href = "$form->{script}?action=recurring_transactions";
  for (qw(direction oldsort path login sessionid)) { $href .= qq|&$_=$form->{$_}| }
  
  $form->sort_order();
  
  # create the logo screen
  $form->header;

  @column_index = qw(ndx reference description);
  
  push @column_index, qw(nextdate enddate id amount curr repeat howmany recurringemail recurringprint);

  $column_header{reference} = qq|<th><a class="listheading" href="$href&sort=reference">|.$locale->text('Reference').q|</a></th>|;
  $column_header{ndx} = q|<th class="listheading">&nbsp;</th>|;
  $column_header{id} = q|<th class="listheading">|.$locale->text('ID').q|</th>|;
  $column_header{description} = q|<th class="listheading">|.$locale->text('Description').q|</th>|;
  $column_header{nextdate} = qq|<th><a class="listheading" href="$href&sort=nextdate">|.$locale->text('Next').q|</a></th>|;
  $column_header{enddate} = qq|<th><a class="listheading" href="$href&sort=enddate">|.$locale->text('Ends').q|</a></th>|;
  $column_header{amount} = q|<th class="listheading">|.$locale->text('Amount').q|</th>|;
  $column_header{curr} = q|<th class="listheading">&nbsp;</th>|;
  $column_header{repeat} = q|<th class="listheading">|.$locale->text('Every').q|</th>|;
  $column_header{howmany} = q|<th class="listheading">|.$locale->text('Times').q|</th>|;
  $column_header{recurringemail} = q|<th class="listheading">|.$locale->text('E-mail').q|</th>|;
  $column_header{recurringprint} = q|<th class="listheading">|.$locale->text('Print').q|</th>|;

print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr class="listheading">
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
        </tr>
|;

  $i = 1;
  $colspan = $#column_index + 1;

  %tr = ( ar => $locale->text('AR'),
          ap => $locale->text('AP'),
	  gl => $locale->text('GL'),
	  so => $locale->text('Sales Orders'),
	  po => $locale->text('Purchase Orders'),
	);

  %f = &formnames;
	  
  foreach $transaction (sort keys %{ $form->{transactions} }) {
    print qq|
        <tr>
	  <th class="listheading" colspan=$colspan>$tr{$transaction}</th>
	</tr>
|;
    
    foreach $ref (@{ $form->{transactions}{$transaction} }) {

      for (@column_index) { $column_data{$_} = "<td nowrap>$ref->{$_}</td>" }

      if ($ref->{repeat} > 1) {
	$unit = $locale->text(ucfirst $ref->{unit});
	$repeat = "$ref->{repeat} $unit";
      } else {
	chop $ref->{unit};
	$unit = $locale->text(ucfirst $ref->{unit});
	$repeat = $unit;
      }

      $column_data{ndx} = qq|<td></td>|;
      
      if (!$ref->{expired}) {
	if ($ref->{overdue} <= 0) {
	  $k++;
	  $column_data{ndx} = qq|<td nowrap><input name="ndx_$k" class=checkbox type=checkbox value=$ref->{id} checked></td>|;
	}
      }
      
      $reference = ($ref->{reference}) ? $ref->{reference} : $locale->text('Next Number');
      $column_data{reference} = qq|<td nowrap><a href=$form->{script}?action=edit_recurring&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&module=$ref->{module}&invoice=$ref->{invoice}&transaction=$ref->{transaction}&recurringnextdate=$ref->{nextdate}>$reference</a></td>|;

      $module = "$ref->{module}.pl";
      $type = "";
      if ($ref->{module} eq 'ar') {
	$module = "is.pl" if $ref->{invoice};
	$ref->{amount} /= $ref->{exchangerate};
      }
      if ($ref->{module} eq 'ap') {
	$module = "ir.pl" if $ref->{invoice};
	$ref->{amount} /= $ref->{exchangerate};
      }
      if ($ref->{module} eq 'oe') {
	$type = ($ref->{vc} eq 'customer') ? "sales_order" : "purchase_order";
      }

      $column_data{id} = qq|<td><a href="$module?action=edit&id=$ref->{id}&vc=$ref->{vc}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$type&readonly=1">$ref->{id}</a></td>|;
      
      $column_data{repeat} = qq|<td align="right" nowrap>$repeat</td>|;
      $column_data{howmany} = qq|<td align="right" nowrap>|.$form->format_amount(\%myconfig, $ref->{howmany})."</td>";
      $column_data{amount} = qq|<td align="right" nowrap>|.$form->format_amount(\%myconfig, $ref->{amount}, 2)."</td>";
      
      $column_data{recurringemail} = "<td nowrap>";
      @f = split /:/, $ref->{recurringemail};
      for (0 .. $#f) { $column_data{recurringemail} .= "$f{$f[$_]}<br>" }
      $column_data{recurringemail} .= "</td>";
      
      $column_data{recurringprint} = "<td nowrap>";
      @f = split /:/, $ref->{recurringprint};
      for (0 .. $#f) { $column_data{recurringprint} .= "$f{$f[$_]}<br>" }
      $column_data{recurringprint} .= "</td>";

      $j++; $j %= 2;
      print qq|
      <tr class=listrow$j>
|;

      for (@column_index) { print "\n$column_data{$_}" }

      print qq|
      </tr>
|;
    }
  }

  print qq|
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$k>
|;

  $form->hide_form(qw(path login sessionid));

  print qq|
<input class=submit type=submit name=action value="|.$locale->text('Process Transactions').qq|">| if $k;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }
  
  print qq|
</form>
  
</body>
</html>
|;

}


sub edit_recurring {

  %links = ( ar => 'create_links',
             ap => 'create_links',
	     gl => 'create_links',
	     is => 'invoice_links',
	     ir => 'invoice_links',
	     oe => 'order_links',
	   );
  %prepare = ( is => 'prepare_invoice',
               ir => 'prepare_invoice',
	       oe => 'prepare_order',
             );

  $form->{callback} = "$form->{script}?action=recurring_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";
 
  $form->{type} = "transaction";
  
  if ($form->{module} eq 'ar') {
    if ($form->{invoice}) {
      $form->{type} = "invoice";
      $form->{module} = "is";
    }
  }
  if ($form->{module} eq 'ap') {
    if ($form->{invoice}) {
      $form->{type} = "invoice";
      $form->{module} = "ir";
    }
  }
  
  if ($form->{module} eq 'oe') {
    %tr = ( so => sales_order,
            po => purchase_order,
	  );
	    
    $form->{type} = $tr{$form->{transaction}};
  }

  $form->{script} = "$form->{module}.pl";
  do "bin/$form->{script}";

  &{ $links{$form->{module}} };
  
  # return if transaction doesn't exist
  $form->redirect unless $form->{recurring};
 
  if ($prepare{$form->{module}}) {
    &{ $prepare{$form->{module}} };
  }
  
  $form->{selectformat} = qq|<option value="html">html\n|;
  if ($latex) {
    $form->{selectformat} .= qq|
            <option value="postscript">|.$locale->text('Postscript').qq|
	    <option value="pdf">|.$locale->text('PDF');
  }

  &schedule;
    
}


sub process_transactions {

  # save variables
  my $pt = new Form;
  for (keys %$form) { $pt->{$_} = $form->{$_} }

  my $defaultprinter;
  while (my ($key, $value) = each %printer) {
    if ($value =~ /lpr/) {
      $defaultprinter = $key;
      last;
    }
  }

  $myconfig{vclimit} = 0;
  %f = &formnames;
  
  for (my $i = 1; $i <= $pt->{lastndx}; $i++) {
    if ($pt->{"ndx_$i"}) {
      $id = $pt->{"ndx_$i"};
      
      # process transaction
      AM->recurring_details(\%myconfig, \%$pt, $id);

      $header = $form->{header};
      # reset $form
      for (keys %$form) { delete $form->{$_}; }
      for (qw(login path sessionid stylesheet timeout)) { $form->{$_} = $pt->{$_}; }
      $form->{id} = $id;
      $form->{header} = $header;

      # post, print, email
      if ($pt->{arid} || $pt->{apid} || $pt->{oeid}) {
	if ($pt->{arid} || $pt->{apid}) {
	  if ($pt->{arid}) {
	    $form->{script} = ($pt->{invoice}) ? "is.pl" : "ar.pl";
	    $form->{ARAP} = "AR";
	    $form->{module} = "ar";
	    $invfld = "sinumber";
	  } else {
	    $form->{script} = ($pt->{invoice}) ? "ir.pl" : "ap.pl";
	    $form->{ARAP} = "AP";
	    $form->{module} = "ap";
	    $invfld = "vinumber";
	  }
	  do "bin/$form->{script}";

          if ($pt->{invoice}) {
	    &invoice_links;
	    &prepare_invoice;
	    
	    for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }

	  } else {
	    &create_links;

            $form->{type} = "transaction";
            for (1 .. $form->{rowcount} - 1) { $form->{"amount_$_"} = $form->format_amount(\%myconfig, $form->{"amount_$_"}, 2) }
	    for (1 .. $form->{paidaccounts}) { $form->{"paid_$_"} = $form->format_amount(\%myconfig, $form->{"paid_$_"}, 2) }

	  }
	  
	  delete $form->{"$form->{ARAP}_links"};
	  for (qw(acc_trans invoice_details)) { delete $form->{$_} }
	  for (qw(department employee language month partsgroup project years)) { delete $form->{"all_$_"} }
	  
	  $form->{invnumber} = $pt->{reference};
	  $form->{transdate} = $pt->{nextdate};

          # tax accounts
          $form->all_taxaccounts(\%myconfig, undef, $form->{transdate});
	  
	  # calculate duedate
	  $form->{duedate} = $form->add_date(\%myconfig, $form->{transdate}, $pt->{overdue}, "days");

	  if ($pt->{payment}) {
	    # calculate date paid
	    for ($j = 1; $j <= $form->{paidaccounts}; $j++) {
	      $form->{"datepaid_$j"} = $form->add_date(\%myconfig, $form->{transdate}, $pt->{paid}, "days");

	      ($form->{"$form->{ARAP}_paid_$j"}) = split /--/, $form->{"$form->{ARAP}_paid_$j"};
	      delete $form->{"cleared_$j"};
	    }
	    
	    $form->{paidaccounts}++;
	  } else {
	    $form->{paidaccounts} = -1;
	  }

	  for (qw(id recurring intnotes printed emailed queued)) { delete $form->{$_} }

	  ($form->{$form->{ARAP}}) = split /--/, $form->{$form->{ARAP}};

	  $form->{invnumber} = $form->update_defaults(\%myconfig, "$invfld") unless $form->{invnumber};
	  $form->{reference} = $form->{invnumber};
	  for (qw(invnumber reference)) { $form->{$_} = $form->unquote($form->{$_}) }

          if ($pt->{invoice}) {
	    if ($pt->{arid}) {
	      $form->info("\n".$locale->text('Posting')." ".$locale->text('Sales Invoice')." $form->{invnumber}");
	      $ok = IS->post_invoice(\%myconfig, \%$form);
	    } else {
	      $form->info("\n".$locale->text('Posting')." ".$locale->text('Vendor Invoice')." $form->{invnumber}");
	      $ok = IR->post_invoice(\%myconfig, \%$form);
	    }
	  } else {
	    if ($pt->{arid}) {
	      $form->info("\n".$locale->text('Posting')." ".$locale->text('Transaction')." $form->{invnumber}");
	    } else {
	      $form->info("\n".$locale->text('Posting')." ".$locale->text('Transaction')." $form->{invnumber}");
	    }

	    $ok = AA->post_transaction(\%myconfig, \%$form);
	    
	  }
	  $form->info(" ..... ".$locale->text('done'));
	  
	  # print form
	  if ($latex && $ok) {
	    $ok = &print_recurring(\%$pt, $defaultprinter);
	  }
	  
	  &email_recurring(\%$pt) if $ok;
	  
	} else {

	  # order
	  $form->{script} = "oe.pl";
	  $form->{module} = "oe";

	  $ordnumber = "ordnumber";
	  if ($pt->{customer_id}) {
	    $form->{vc} = "customer";
	    $form->{type} = "sales_order";
	    $ordfld = "sonumber";
	    $flabel = $locale->text('Sales Order');
	  } else {
	    $form->{vc} = "vendor";
	    $form->{type} = "purchase_order";
	    $ordfld = "ponumber";
	    $flabel = $locale->text('Purchase Order');
	  }
	  require "bin/$form->{script}";

	  &order_links;
	  &prepare_order;

	  for (keys %$form) { $form->{$_} = $form->unquote($form->{$_}) }
	  
	  $form->{$ordnumber} = $pt->{reference};
	  $form->{transdate} = $pt->{nextdate};
	  
	  # calculate reqdate
	  $form->{reqdate} = $form->add_date(\%myconfig, $form->{transdate}, $pt->{req}, "days") if $form->{reqdate};

	  for (qw(id recurring intnotes printed emailed queued)) { delete $form->{$_} }
	  for (1 .. $form->{rowcount}) { delete $form->{"orderitems_id_$_"} }

	  $form->{$ordnumber} = $form->update_defaults(\%myconfig, "$ordfld") unless $form->{$ordnumber};
	  $form->{reference} = $form->{$ordnumber};
	  for ("$ordnumber", "reference") { $form->{$_} = $form->unquote($form->{$_}) }
	  $form->{closed} = 0;

	  $form->info("\n".$locale->text('Saving')." ".$flabel." $form->{$ordnumber}");
	  if ($ok = OE->save(\%myconfig, \%$form)) {
	    $form->info(" ..... ".$locale->text('done'));
	  } else {
	    $form->info(" ..... ".$locale->text('failed'));
	  }

	  # print form
	  if ($latex && $ok) {
	    &print_recurring(\%$pt, $defaultprinter);
	  }

	  &email_recurring(\%$pt);

	}

      } else {
	# GL transaction
	GL->transaction(\%myconfig, \%$form);
	
	$form->{reference} = $pt->{reference};
	$form->{transdate} = $pt->{nextdate};

	$j = 1;
	foreach $ref (@{ $form->{GL} }) {
	  $form->{"accno_$j"} = "$ref->{accno}--$ref->{description}";

	  $form->{"projectnumber_$j"} = "$ref->{projectnumber}--$ref->{project_id}" if $ref->{project_id};
	  $form->{"fx_transaction_$j"} = $ref->{fx_transaction};

	  if ($ref->{amount} < 0) {
	    $form->{"debit_$j"} = $ref->{amount} * -1;
	  } else {
	    $form->{"credit_$j"} = $ref->{amount};
	  }

	  $j++;
	}
	
	$form->{rowcount} = $j;

	for (qw(id recurring)) { delete $form->{$_} }
	$form->info("\n".$locale->text('Posting')." ".$locale->text('GL Transaction')." $form->{reference}");
	$ok = GL->post_transaction(\%myconfig, \%$form);
	$form->info(" ..... ".$locale->text('done'));
	
      }

      AM->update_recurring(\%myconfig, \%$pt, $id) if $ok;

    }
  }

  $form->{callback} = "am.pl?action=recurring_transactions&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&header=$form->{header}";
  $form->redirect;

}


sub print_recurring {
  my ($pt, $defaultprinter) = @_;

  my %f = &formnames;
  my $ok = 1;
  
  if ($pt->{recurringprint}) {
    @f = split /:/, $pt->{recurringprint};
    for ($j = 0; $j <= $#f; $j += 3) {
      $media = $f[$j+2];
      $media ||= $myconfig->{printer} if $printer{$myconfig->{printer}};
      $media ||= $defaultprinter;
      
      $form->info("\n".$locale->text('Printing')." ".$locale->text($f{$f[$j]})." $form->{reference}");

      @a = ("perl", "$form->{script}", "action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=$media&vc=$form->{vc}&ARAP=$form->{ARAP}");

      $ok = !(system(@a));
      
      if ($ok) {
	$form->info(" ..... ".$locale->text('done'));
      } else {
	$form->info(" ..... ".$locale->text('failed'));
	last;
      }
    }
  }

  $ok;
  
}


sub email_recurring {
  my ($pt) = @_;

  my %f = &formnames;
  my $ok = 1;
  
  if ($pt->{recurringemail}) {

    @f = split /:/, $pt->{recurringemail};
    for ($j = 0; $j <= $#f; $j += 2) {
      
      $form->info("\n".$locale->text('Sending')." ".$locale->text($f{$f[$j]})." $form->{reference}");

      # no email, bail out
      if (!$form->{email}) {
	$form->info(" ..... ".$locale->text('E-mail address missing!'));
	last;
      }
      
      $message = $form->escape($pt->{message},1);
      
      @a = ("perl", "$form->{script}", "action=reprint&module=$form->{module}&type=$form->{type}&login=$form->{login}&path=$form->{path}&sessionid=$form->{sessionid}&id=$form->{id}&formname=$f[$j]&format=$f[$j+1]&media=email&vc=$form->{vc}&ARAP=$form->{ARAP}&message=$message");

      $ok = !(system(@a));
      
      if ($ok) {
	$form->info(" ..... ".$locale->text('done'));
      } else {
	$form->info(" ..... ".$locale->text('failed'));
	last;
      }
    }
  }

  $ok;
  
}



sub formnames {
  
# $locale->text('Transaction')
# $locale->text('Invoice')
# $locale->text('Credit Invoice')
# $locale->text('Debit Invoice')
# $locale->text('Packing List')
# $locale->text('Pick List')
# $locale->text('Sales Order')
# $locale->text('Work Order')
# $locale->text('Purchase Order')
# $locale->text('Bin List')
 
  my %f = ( transaction => 'Transaction',
		invoice => 'Invoice',
	 credit_invoice => 'Credit Invoice',
	  debit_invoice => 'Debit Invoice',
	   packing_list => 'Packing List',
	      pick_list => 'Pick List',
	    sales_order => 'Sales Order',
	     work_order => 'Work Order',
	 purchase_order => 'Purchase Order',
               bin_list => 'Bin List',
          );        

  %f;

}


sub continue { &{ $form->{nextsub} } };

