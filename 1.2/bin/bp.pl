#=====================================================================
# LedgerSMB Small Medium Business Accounting
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
# Copyright (c) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#======================================================================
#
# Batch printing
#
#======================================================================


use LedgerSMB::BP;

1;
# end of main


sub search {

# $locale->text('Sales Invoices')
# $locale->text('Packing Lists')
# $locale->text('Pick Lists')
# $locale->text('Sales Orders')
# $locale->text('Work Orders')
# $locale->text('Purchase Orders')
# $locale->text('Bin Lists')
# $locale->text('Quotations')
# $locale->text('RFQs')
# $locale->text('Time Cards')

  # setup customer/vendor selection
  BP->get_vc(\%myconfig, \%$form);
  
  if (@{ $form->{"all_$form->{vc}"} }) { 
    $name = "<option>\n";
    for (@{ $form->{"all_$form->{vc}"} }) { $name .= qq|<option value="$_->{name}--$_->{id}">$_->{name}\n| }
    $name = qq|<select name=$form->{vc}>$name</select>|;
  } else {
    $name = qq|<input name=$form->{vc} size=35>|;
  }

# $locale->text('Customer')
# $locale->text('Vendor')
# $locale->text('Employee')

  %label = ( invoice => { title => 'Sales Invoices', name => 'Customer' },
             packing_list => { title => 'Packing Lists', name => 'Customer' },
             pick_list => { title => 'Pick Lists', name => 'Customer' },
             sales_order => { title => 'Sales Orders', name => 'Customer' },
             work_order => { title => 'Work Orders', name => 'Customer' },
             purchase_order => { title => 'Purchase Orders', name => 'Vendor' },
             bin_list => { title => 'Bin Lists', name => 'Vendor' },
             sales_quotation => { title => 'Quotations', name => 'Customer' },
             request_quotation => { title => 'RFQs', name => 'Vendor' },
             timecard => { title => 'Time Cards', name => 'Employee' },
	     check => {title => 'Check', name => 'Vendor'},
	   );

  $label{invoice}{invnumber} = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Invoice Number').qq|</th>
	  <td colspan=3><input name=invnumber size=20></td>
	</tr>
|;
  $label{invoice}{ordnumber} = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Order Number').qq|</th>
	  <td colspan=3><input name=ordnumber size=20></td>
	</tr>
|;
  $label{sales_quotation}{quonumber} = qq|
	<tr>
	  <th align=right nowrap>|.$locale->text('Quotation Number').qq|</th>
	  <td colspan=3><input name=quonumber size=20></td>
	</tr>
|;

  $label{packing_list}{invnumber} = $label{invoice}{invnumber};
  $label{packing_list}{ordnumber} = $label{invoice}{ordnumber};
  $label{pick_list}{invnumber} = $label{invoice}{invnumber};
  $label{pick_list}{ordnumber} = $label{invoice}{ordnumber};
  $label{sales_order}{ordnumber} = $label{invoice}{ordnumber};
  $label{work_order}{ordnumber} = $label{invoice}{ordnumber};
  $label{purchase_order}{ordnumber} = $label{invoice}{ordnumber};
  $label{bin_list}{ordnumber} = $label{invoice}{ordnumber};
  $label{request_quotation}{quonumber} = $label{sales_quotation}{quonumber};
  
  # do one call to text
  $form->{title} = $locale->text('Print')." ".$locale->text($label{$form->{type}}{title});

  # accounting years
  if (@{ $form->{all_years} }) {
    # accounting years
    $form->{selectaccountingyear} = "<option>\n";
    for (@{ $form->{all_years} }) { $form->{selectaccountingyear} .= qq|<option>$_\n| }
    $form->{selectaccountingmonth} = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $form->{selectaccountingmonth} .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

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
|;

  $form->hide_form(qw(vc type title));

  print qq|
<table width=100%>
  <tr><th class=listtop>$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>|.$locale->text($label{$form->{type}}{name}).qq|</th>
	  <td colspan=3>$name</td>
	</tr>
	$account
	$label{$form->{type}}{invnumber}
	$label{$form->{type}}{ordnumber}
	$label{$form->{type}}{quonumber}
	<tr>
	  <th align=right nowrap>|.$locale->text('From').qq|</th>
	  <td><input name=transdatefrom size=11 title="$myconfig{dateformat}"></td>
	  <th align=right>|.$locale->text('To').qq|</th>
	  <td><input name=transdateto size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=sort value=transdate>
<input type=hidden name=nextsub value=list_spool>

<br>
<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>
|;

  $form->hide_form(qw(path login sessionid));
  
  print qq|

</form>

</body>
</html>
|;

}



sub remove {
  
  $selected = 0;
  
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      $selected = 1;
      last;
    }
  }

  $form->error($locale->text('Nothing selected!')) unless $selected;
 
  $form->{title} = $locale->text('Confirm!');
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>
|;

  for (qw(action header)) { delete $form->{$_} }
  
  foreach $key (keys %$form) {
    print qq|<input type=hidden name=$key value="$form->{$key}">\n|;
  }

  print qq|
<h2 class=confirm>$form->{title}</h2>

<h4>|.$locale->text('Are you sure you want to remove the marked entries from the queue?').qq|</h4>

<button name="action" class="submit" type="submit" value="yes">|.$locale->text('Yes').qq|</button>
</form>

</body>
</html>
|;

}



sub yes {

  $form->info($locale->text('Removing marked entries from queue ...'));
  $form->{callback} .= "&header=1" if $form->{callback};

  if (BP->delete_spool(\%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool})) {
    $form->redirect($locale->text('Removed spoolfiles!'));
  } else {
    $form->error($locale->text('Cannot remove files!'));
  }

}


sub print {

  if ($form->{callback}) {
    for (1 .. $form->{rowcount}) { $form->{callback} .= "&checked_$_=1" if $form->{"checked_$_"} }
    $form->{callback} .= "&header=1";
  }

  for $i (1 .. $form->{rowcount}) {
    if ($form->{"checked_$i"}) {
      $form->{OUT} = ${LedgerSMB::Sysconfig::printer}{$form->{media}};
      $form->{printmode} = '|-';
      $form->info($locale->text('Printing')." ...");

      if (BP->print_spool(\%myconfig, \%$form, ${LedgerSMB::Sysconfig::spool})) {
	print $locale->text('done');
	$form->redirect($locale->text('Marked entries printed!'));
      }
      exit;
    }
  }

  $form->error('Nothing selected!');

}


sub list_spool {

  $form->{$form->{vc}} = $form->unescape($form->{$form->{vc}});
  ($form->{$form->{vc}}, $form->{"$form->{vc}_id"}) = split(/--/, $form->{$form->{vc}});

  BP->get_spoolfiles(\%myconfig, \%$form);

  $title = $form->escape($form->{title});
  $href = "$form->{script}?action=list_spool&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&vc=$form->{vc}&type=$form->{type}&title=$title";
 
  $form->sort_order();
  
  $title = $form->escape($form->{title},1);
  $callback = "$form->{script}?action=list_spool&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&vc=$form->{vc}&type=$form->{type}&title=$title";

  if ($form->{$form->{vc}}) {
    $callback .= "&$form->{vc}=".$form->escape($form->{$form->{vc}},1);
    $href .= "&$form->{vc}=".$form->escape($form->{$form->{vc}});
    $option = ($form->{vc} eq 'customer') ? $locale->text('Customer') : $locale->text('Vendor');
    $option .= " : $form->{$form->{vc}}";
  }
  if ($form->{account}) {
    $callback .= "&account=".$form->escape($form->{account},1);
    $href .= "&account=".$form->escape($form->{account});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Account')." : $form->{account}";
  }
  if ($form->{invnumber}) {
    $callback .= "&invnumber=".$form->escape($form->{invnumber},1);
    $href .= "&invnumber=".$form->escape($form->{invnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Invoice Number')." : $form->{invnumber}";
  }
  if ($form->{ordnumber}) {
    $callback .= "&ordnumber=".$form->escape($form->{ordnumber},1);
    $href .= "&ordnumber=".$form->escape($form->{ordnumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Order Number')." : $form->{ordnumber}";
  }
  if ($form->{quonumber}) {
    $callback .= "&quonumber=".$form->escape($form->{quonumber},1);
    $href .= "&quonumber=".$form->escape($form->{quonumber});
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('Quotation Number')." : $form->{quonumber}";
  }
 
  if ($form->{transdatefrom}) {
    $callback .= "&transdatefrom=$form->{transdatefrom}";
    $href .= "&transdatefrom=$form->{transdatefrom}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{transdatefrom}, 1);
  }
  if ($form->{transdateto}) {
    $callback .= "&transdateto=$form->{transdateto}";
    $href .= "&transdateto=$form->{transdateto}";
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{transdateto}, 1);
  }

  $name = ucfirst $form->{vc};
  
  @columns = qw(transdate);
  if ($form->{type} =~ /(invoice)/) {
    push @columns, "invnumber";
  }
  if ($form->{type} =~ /(packing|pick)_list/) {
    push @columns, "invnumber";
  }
  if ($form->{type} =~ /_(order|list)$/) {
    push @columns, "ordnumber";
  }
  if ($form->{type} =~ /_quotation$/) {
    push @columns, "quonumber";
  }
  if ($form->{type} eq 'timecard') {
    push @columns, "id";
  }


  push @columns, (name, spoolfile);
  @column_index = $form->sort_columns(@columns);
  unshift @column_index, "checked";

  $column_header{checked} = "<th class=listheading>&nbsp;</th>";
  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Date')."</a></th>";
  $column_header{invnumber} = "<th><a class=listheading href=$href&sort=invnumber>".$locale->text('Invoice')."</a></th>";
  $column_header{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Order')."</a></th>";
  $column_header{quonumber} = "<th><a class=listheading href=$href&sort=quonumber>".$locale->text('Quotation')."</a></th>";
  $column_header{name} = "<th><a class=listheading href=$href&sort=name>".$locale->text($name)."</a></th>";
  $column_header{id} = "<th><a class=listheading href=$href&sort=id>".$locale->text('ID')."</a></th>";
  $column_header{spoolfile} = "<th class=listheading>".$locale->text('Spoolfile')."</th>";


  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "\n$column_header{$_}" }

  print qq|
	</tr>
|;


  # add sort and escape callback, this one we use for the add sub
  $form->{callback} = $callback .= "&sort=$form->{sort}";

  # escape callback for href
  $callback = $form->escape($callback);
  
  $i = 0;
  
  foreach $ref (@{ $form->{SPOOL} }) {

    $i++;
   
    $form->{"checked_$i"} = "checked" if $form->{"checked_$i"};
    
    # this is for audittrail
    $form->{module} = $ref->{module};
    
    if ($ref->{invoice}) {
      $ref->{module} = ($ref->{module} eq 'ar') ? "is" : "ir";
    }
    $module = "$ref->{module}.pl";
    
    $column_data{transdate} = "<td>$ref->{transdate}&nbsp;</td>";

    if (${LedgerSMB::Sysconfig::spool} eq $ref->{spoolfile}) {
      $column_data{checked} = qq|<td></td>|;
    } else {
      $column_data{checked} = qq|<td><input name=checked_$i type=checkbox class=checkbox $form->{"checked_$i"} $form->{"checked_$i"}></td>|;
    }
    
    for (qw(id invnumber ordnumber quonumber)) { $column_data{$_} = qq|<td>$ref->{$_}</td>| }
    
    if ($ref->{module} eq 'oe') {
      $column_data{invnumber} = qq|<td>&nbsp</td>|;
      $column_data{ordnumber} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback>$ref->{ordnumber}</a></td>
      <input type=hidden name="reference_$i" value="$ref->{ordnumber}">|;
      
      $column_data{quonumber} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback>$ref->{quonumber}</a></td>
    <input type=hidden name="reference_$i" value="$ref->{quonumber}">|;
 
    } elsif ($ref->{module} eq 'jc') {
      $column_data{id} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback>$ref->{id}</a></td>
    <input type=hidden name="reference_$i" value="$ref->{id}">|;
    } else {
      $column_data{invnumber} = qq|<td><a href=$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&type=$form->{type}&callback=$callback>$ref->{invnumber}</a></td>
    <input type=hidden name="reference_$i" value="$ref->{invnumber}">|;
    }
    
   
    $column_data{name} = "<td>$ref->{name}</td>";
    $column_data{spoolfile} = qq|<td><a href=${LedgerSMB::Sysconfig::spool}/$ref->{spoolfile}>$ref->{spoolfile}</a></td>

|;

    ${LedgerSMB::Sysconfig::spool} = $ref->{spoolfile};
    
    $j++; $j %= 2;
    print "
        <tr class=listrow$j>
";

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
<input type=hidden name="id_$i" value=$ref->{id}>
<input type=hidden name="spoolfile_$i" value=$ref->{spoolfile}>

        </tr>
|;

  }

  print qq|
<input type=hidden name=rowcount value=$i>

      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

  $form->hide_form(qw(callback title vc type sort module account path login sessionid));
    
  if (%{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex}) {
    foreach $key (sort keys %{LedgerSMB::Sysconfig::printer}) {
      print qq|
<input name=media type=radio class=radio value="$key" |;
      print qq|checked| if $key eq $myconfig{printer};
      print qq|>$key|;
    }

    print qq|<p>\n|;
    
# type=submit $locale->text('Select all')
# type=submit $locale->text('Print')
# type=submit $locale->text('Remove')

    %button = ('select_all' => { ndx => 2, key => 'A', value => $locale->text('Select all') },
               'print' => { ndx => 3, key => 'P', value => $locale->text('Print') },
	       'remove' => { ndx => 4, key => 'R', value => $locale->text('Remove') },
	      );
	       
    for (sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button) { $form->print_button(\%button, $_) }
    
  }

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


sub select_all {

  for (1 .. $form->{rowcount}) { $form->{"checked_$_"} = 1 }
  &list_spool;
  
}


sub continue { &{ $form->{nextsub} } };

