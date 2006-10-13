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
# Account reconciliation module
#
#======================================================================

use LedgerSMB::RC;

1;
# end of main

# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')


sub reconciliation {
  
  RC->paymentaccounts(\%myconfig, \%$form);

  $selection = "";
  for (@{ $form->{PR} }) { $selection .= "<option>$_->{accno}--$_->{description}\n" }

  $form->{title} = $locale->text('Reconciliation');

  if ($form->{report}) {
    $form->{title} = $locale->text('Reconciliation Report');
    $cleared = qq|
        <input type=hidden name=report value=1>
        <tr>
	  <td align=right><input type=checkbox class=checkbox name=outstanding value=1 checked></td>
	  <td>|.$locale->text('Outstanding').qq|</td>
	  <td align=right><input type=checkbox class=checkbox name=cleared value=1></td>
	  <td>|.$locale->text('Cleared').qq|</td>
	</tr>
|;

  }

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

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right nowrap>|.$locale->text('Account').qq|</th>
	  <td colspan=3><select name=accno>$selection</select></td>
	</tr>
	<tr>
	  <th align=right>|.$locale->text('From').qq|</th>
	  <td colspan=3><input name=fromdate size=11 title="$myconfig{dateformat}"> <b>|.$locale->text('To').qq|</b> <input name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	$cleared
        <tr>
	  <td></td>
	  <td colspan=3><input type=radio style=radio name=summary value=1 checked> |.$locale->text('Summary').qq|
	  <input type=radio style=radio name=summary value=0> |.$locale->text('Detail').qq|</td>
	</tr>
	<tr>
	  <td></td>
	  <td colspan=3><input type=checkbox class=checkbox name=fx_transaction value=1 checked> |.$locale->text('Include Exchange Rate Difference').qq|</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input type=hidden name=nextsub value=get_payments>
|;

  $form->hide_form(qw(path login sessionid));

  print qq|
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">

</form>
|;

  if ($form->{lynx}) {
    require "bin/menu.pl";
    &menubar;
  }

  print qq|

</body>
</html>
|;

}


sub continue { &{ $form->{nextsub} } };

sub till_closing {
  $form->{callback} = "$form->{script}?path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

  @colheadings = qw(Source Actual Expected Error);
  my $curren = $pos_config{'curren'};

  $form->{title} = "Closing Till For $form->{login}";
  require "pos.conf.pl"; 
  RC->getposlines(\%myconfig, \%$form);
  $form->header;
  print qq|
<body>

<form method=post action=$form->{script}>
<input type=hidden name=path value=$form->{path}>
<input type=hidden name=login value=$form->{login}>
<input type=hidden name=sessionid value=$form->{sessionid}>

<input type=hidden name=callback value="$form->{callback}">
<input type=hidden name=sum value="|.$form->{sum} * -1 .qq|">
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
</table> 
<table width=100%>
|;

  print "<tr>";
  map {print "<td class=listheading>$_</td>";} @colheadings;
  print "</tr>";
  my $j;
  my $source;
  foreach $source (sort keys %pos_sources){
    $amount = 0;
    foreach $ref (@{$form->{TB}}){
      if ($ref->{source} eq $source){
        $amount = $ref->{amount} * -1;
        last;
      }
    }
    ++$j;
    $j = $j % 2;
    print qq|<tr class=listrow$j><td>|.$pos_sources{$source}.qq|</td>
             <td><input name="amount_$source">
             <input type=hidden name="expected_$source" 
		value="$amount"></td>
             <td>${curren}$amount</td>
             <td id="error_$source">&nbsp;</td></tr>|;
  }
  print qq|
<script type='text/javascript'>
 
function money_round(m){
  var r;
  r = Math.round(m * 100)/100;
  return r;
}

function custom_calc_total(){
  |;
  my $subgen = 'document.forms[0].sub_sub.value = ';
  foreach my $unit (@{$pos_config{'breakdown'}}) {
    # XXX Needs to take into account currencies that don't use 2 dp
    my $parsed = $form->parse_amount(\%pos_config, $unit);
    my $calcval = $parsed;
    $calcval = sprintf('%03d', $calcval * 100) if $calcval < 1;
    my $subval = 'sub_' . $calcval;
    $calcval = 'calc_' . $calcval;
    print qq|
  document.forms[0].${subval}.value = document.forms[0].${calcval}.value * $parsed;
    |;
    $subgen .= "document.forms[0].${subval}.value * 1 + ";
  }
  print $subgen . "0;";
  print qq|document.forms[0].sub_sub.value = 
           money_round(document.forms[0].sub_sub.value);
  document.forms[0].amount_cash.value = money_round(
	document.forms[0].sub_sub.value - $pos_config{till_cash});
  check_errors();
}
function check_errors(){
  var cumulative_error = 0;
  var source_error = 0;
  var err_cell;
  |;
  map {
    print "  source_error = money_round(
	document.forms[0].amount_$_.value - 
 	document.forms[0].expected_$_.value);
  cumulative_error = cumulative_error + source_error;
  err_cell = document.getElementById('error_$_');
  err_cell.innerHTML = '$curren' + source_error;\n"; 
  } (keys %pos_sources);
  print qq|
  alert('Cumulative Error: $curren' + money_round(cumulative_error));
}
</script>

<table>
<col><col><col>|;
  foreach my $unit (@{$pos_config{'breakdown'}}) {
    # XXX Needs to take into account currencies that don't use 2 dp
    my $calcval = $form->parse_amount(\%pos_config, $unit);
    $calcval = sprintf('%03d', $calcval * 100) if $calcval < 1;
    my $subval = 'sub_' . $calcval;
    $calcval = 'calc_' . $calcval;
    print qq|<tr>
      <td><input type=text name=$calcval value="$form->{$calcval}"></td>
      <th>X ${curren}${unit} = </th>
      <td><input type=text name=$subval value="$form->{$subval}"></td>
    </tr>|;
  }
  print qq|<tr>
    <td>&nbsp;</td>
    <th>Subtotal:</th>
    <td><input type=text name=sub_sub value="$form->{sub_sub}"></td>
  </tr>
  </table>
<input type=button name=calculate class=submit onClick="custom_calc_total()" 
   value='Calculate'>
|;
  print qq|</table><input type=submit name=action value="|.
		$locale->text("close_till").qq|">|;
  print qq|
</form>

</body>
</html>
|;
}


sub close_till {
  use LedgerSMB::GL;
  require 'pos.conf.pl';
  RC->clear_till(\%myconfig, \%$form);
  my $amount = 0;
  my $expected = 0;
  my $difference = 0;
  my $lines = '';
  $form->{rowcount} = 2;
  foreach $key (keys %pos_sources){
     $amount = 0;
     $expected = 0;
     $amount = $form->parse_amount(\%myconfig, $form->{"amount_$key"});
     $expected = $form->parse_amount(\%myconfig, $form->{"expected_$key"});
     $gl_entry = "Closing Till $pos_config{till} source = $key";
     $accno1 = $pos_config{till_accno};
     if (${$pos_config{'source_accno_override'}{$key}}){
       $accno2 = ${$pos_config{'source_accno_override'}{$key}};
     } else {
       $accno2 = $pos_config{'close_cash_accno'};
     }
     $form->{reference} = $gl_entry;
     $form->{accno_1} = $accno1;
     $form->{credit_1} = $amount;
     $form->{accno_2} = $accno2;
     $form->{debit_2} = $amount;
     $form->{transdate} = $form->current_date(\%myconfig);
     GL->post_transaction(\%myconfig, \%$form);
     delete $form->{id};
     $error = $amount - $expected;
     $difference += $error;
     $lines .= "Source: $key, Amount: $amount\nExpected: $expected.  Error= $error\n\n";
  }
  $gl_entry = "Closing Till: $pos_config{till} Over/Under";
  $amount = $difference * -1;
  $form->{reference} = $gl_entry;
  $form->{accno_1} = $accno1;
  $form->{credit_1} = $amount;
  $form->{accno_2} = $pos_config{coa_prefix};
  $form->{debit_2} = $amount;
  $form->{transdate} = $form->current_date(\%myconfig);
  GL->post_transaction(\%myconfig, \%$form);
  delete $form->{id};
  $lines .= "Cumulative Error: $amount";
  $form->{accno} = $form->{accno_1};
  RC->getbalance(\%myconfig, \%$form); 
  $amount = $form->{balance} * -1;
  $gl_entry = "Resetting Till: $pos_config{till}";
  $form->{reference} = $gl_entry;
  $form->{accno_1} = $accno1;
  $form->{credit_1} = $amount;
  $form->{accno_2} = $pos_config{coa_prefix};
  $form->{debit_2} = $amount;
  $form->{transdate} = $form->current_date(\%myconfig);
  GL->post_transaction(\%myconfig, \%$form);
  delete $form->{id};

  $head = "Closing Till $pos_config{till} for $form->{login}\n".
	"Date: $form->{transdate}\n\n\n";
  my @cashlines = [$locale->text("Cash Breakdown:")];
  foreach my $unit (@{$pos_config{'breakdown'}}) {
    # XXX Needs to take into account currencies that don't use 2 dp
    my $parsed = $form->parse_amount(\%pos_config, $unit);
    my $calcval = $parsed;
    $calcval = sprintf('%03d', $calcval * 100) if $calcval < 1;
    my $subval = 'sub_' . $calcval;
    $calcval = 'calc_' . $calcval;
    push @cashlines, "$form->{$calcval} x $parseval = $form->{$subval}";
  }
  push @cashlines, $locale->text("Total Cash in Drawer:") . $form->{sub_sub};
  push @cashlines, $locale->text("Less Cash in Till At Start:") . 
  	$form->{till_cash};
  push @cashlines, "\n";
  $cash = join ("\n", @cashlines);
  $foot = $locale->text("Cumulative Error: ")."$difference\n";
  $foot .= $locale->text('Reset Till By ')."$amount\n\n\n\n\n\n\n\n\n\n";
  open (PRN, "|-",  $printer{Printer});
  print PRN $head;
  print PRN $lines;
  print PRN $cash;
  print PRN $cash;
  print PRN $foot;
  close PRN;
  if ($difference > 0){
    $message = $locale->text("You are over by ").$difference;
  } elsif ($difference < 0){
    $message = $locale->text("You are under by ").$difference * -1;
  }
  else {
    $message = $local->text("Congratulations!  Your till is exactly balanced.");
  }
  $form->info($message);
}

sub get_payments {

  ($form->{accno}, $form->{account}) = split /--/, $form->{accno};
  if ($form->{'pos'}){
    require "pos.conf.pl";
    $form->{fromdate} = $form->current_date(\%myconfig);
    unless ($form->{source}){
      $form->{source} = (sort keys(%pos_sources))[0];
    }
    if ($form->{source} eq 'cash'){
      $form->{summary} = "true";
    } else {
      $form->{summary} = "";
    }
    $form->{accno} = $pos_config{'coa_prefix'} . "." . $pos_config{'till'};   
    $form->{account} = $form->{source};
  }

  RC->payment_transactions(\%myconfig, \%$form);
  
  $ml = ($form->{category} eq 'A') ? -1 : 1;
  $form->{statementbalance} = $form->{endingbalance} * $ml;
  if (! $form->{fx_transaction}) {
    $form->{statementbalance} = ($form->{endingbalance} - $form->{fx_endingbalance}) * $ml;
  }
  
  $form->{statementbalance} = $form->format_amount(\%myconfig, $form->{statementbalance}, 2, 0);
  
  &display_form;

}


sub display_form {
  
  if ($form->{report}) {
    @column_index = qw(transdate source name cleared debit credit);
  } else {
    @column_index = qw(transdate source name cleared debit credit balance);
  }
  
  $column_header{cleared} = qq|<th>|.$locale->text('R').qq|</th>|;
  $column_header{source} = "<th class=listheading>".$locale->text('Source')."</a></th>";
  $column_header{name} = "<th class=listheading>".$locale->text('Description')."</a></th>";
  $column_header{transdate} = "<th class=listheading>".$locale->text('Date')."</a></th>";

  $column_header{debit} = "<th class=listheading>".$locale->text('Debit')."</a></th>";
  $column_header{credit} = "<th class=listheading>".$locale->text('Credit')."</a></th>";
  $column_header{balance} = "<th class=listheading>".$locale->text('Balance')."</a></th>";

  if ($form->{fromdate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('From')."&nbsp;".$locale->date(\%myconfig, $form->{fromdate}, 1);
  }
  if ($form->{todate}) {
    $option .= "\n<br>" if ($option);
    $option .= $locale->text('To')."&nbsp;".$locale->date(\%myconfig, $form->{todate}, 1);
  }

  $form->{title} = "$form->{accno}--$form->{account}";
  
  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=source value="$form->{source}">
<input type=hidden name=cumulative_error value="$form->{cumulative_error}">
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

  $ml = ($form->{category} eq 'A') ? -1 : 1;
  $form->{beginningbalance} *= $ml;
  $form->{fx_balance} *= $ml;
  
  if (! $form->{fx_transaction}) {
    $form->{beginningbalance} -= $form->{fx_balance};
  }
  $balance = $form->{beginningbalance};
  
  $i = 0;
  $j = 0;
  
  for (qw(cleared transdate source debit credit)) { $column_data{$_} = "<td>&nbsp;</td>" }

  if (! $form->{report}) {
    $column_data{name} = qq|<td>|.$locale->text('Beginning Balance').qq|</td>|;
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $balance, 2, 0)."</td>";
    print qq|
	<tr class=listrow$j>
|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
	</tr>
|;
  }


  foreach $ref (@{ $form->{PR} }) {

    $i++;

    if (! $form->{fx_transaction}) {
      next if $ref->{fx_transaction};
    }

    $checked = ($ref->{cleared}) ? "checked" : "";
    
    %temp = ();
    if (!$ref->{fx_transaction}) {
      for (qw(name source transdate)) { $temp{$_} = $ref->{$_} }
    }
      
    $column_data{name} = "<td>";
    for (@{ $temp{name} }) { $column_data{name} .= "$_<br>" }
    $column_data{name} .= "</td>";
    $column_data{source} = qq|<td>$temp{source}&nbsp;</td>
    <input type=hidden name="id_$i" value=$ref->{id}>|;
    
    $column_data{debit} = "<td>&nbsp;</td>";
    $column_data{credit} = "<td>&nbsp;</td>";
    
    $balance += $ref->{amount} * $ml;

    if ($ref->{amount} < 0) {
      
      $totaldebits += $ref->{amount} * -1;

      $column_data{debit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount} * -1, 2, "&nbsp;")."</td>";
      
    } else {
      
      $totalcredits += $ref->{amount};

      $column_data{credit} = "<td align=right>".$form->format_amount(\%myconfig, $ref->{amount}, 2, "&nbsp;")."</td>";
      
    }
    
    $column_data{balance} = "<td align=right>".$form->format_amount(\%myconfig, $balance, 2, 0)."</td>";

    if ($ref->{fx_transaction}) {

      $column_data{cleared} = ($clearfx) ? qq|<td align=center>*</td>| : qq|<td>&nbsp;</td>|;
      $cleared += $ref->{amount} * $ml if $clearfx;
      
    } else {
      
      if ($form->{report}) {
	
	if ($ref->{cleared}) {
	  $column_data{cleared} = qq|<td align=center>*</td>|;
	  $clearfx = 1;
	} else {
	  $column_data{cleared} = qq|<td>&nbsp;</td>|;
	  $clearfx = 0;
	}
	
      } else {

	if ($ref->{oldcleared}) {
	  $cleared += $ref->{amount} * $ml;
	  $clearfx = 1;
	  $column_data{cleared} = qq|<td align=center>*</td>
	  <input type=hidden name="cleared_$i" value=$ref->{cleared}>
	  <input type=hidden name="oldcleared_$i" value=$ref->{oldcleared}>
	  <input type=hidden name="source_$i" value="$ref->{source}">
          <input type=hidden name="amount_$1" value="$ref->{amount}">|;
	} else {
	  $cleared += $ref->{amount} * $ml if $checked;
	  $clearfx = ($checked) ? 1 : 0;
	  $column_data{cleared} = qq|<td align=center><input name="cleared_$i" type=checkbox class=checkbox value=1 $checked>
	  <input type=hidden name="source_$i" value="$ref->{source}">
          <input type=hidden name="amount_$i" value="$ref->{amount}">
          </td>|;
	}
	
      }
    }
    
    $column_data{transdate} = qq|<td>$temp{transdate}&nbsp;</td>
    <input type=hidden name="transdate_$i" value=$ref->{transdate}>|;

    $j++; $j %= 2;
    print qq|
	<tr class=listrow$j>
|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

  }

  $form->{rowcount} = $i;
  
  # print totals
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

  $column_data{debit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totaldebits, 2, "&nbsp;")."</th>";
  $column_data{credit} = "<th class=listtotal align=right>".$form->format_amount(\%myconfig, $totalcredits, 2, "&nbsp;")."</th>";
   
  print qq|
	<tr class=listtotal>
|;

  for (@column_index) { print "\n$column_data{$_}" }
 
  $form->{statementbalance} = $form->parse_amount(\%myconfig, $form->{statementbalance});
  $difference = $form->format_amount(\%myconfig, $form->{beginningbalance} + $cleared - $form->{statementbalance}, 2, 0);
  if ($form->{source}){
    $difference = 0;
  }
  $form->{statementbalance} = $form->format_amount(\%myconfig, $form->{statementbalance}, 2, 0);

  print qq|
	</tr>
      </table>
    </td>
  </tr>
|;

  if ($form->{'pos'}){
     $close_next = qq|<input type=submit class=submit name=action 
       value="|.$locale->text('close_next').qq|">|;
     $done = "";
  }
  else {
     $close_next = "";
     $done = qq|<input type=submit class=submit name=action
       value="|.$locale->text('Done').qq|">|;
  }
  if ($form->{'pos'}){
    $difference = qq|
              <tr>
                 <th align=right><select name=over_under>
                     <option value=under>|.$locale->text('Under').qq|</option>
                     <option value=over>|.$locale->text('Over').qq|</option>
                   </select><input type=hidden name=pos value='true'>
                 </th>
		<td width=10%></td>
		<td align=right><input name=null size=11 
                    value='|.$form->{null2}.qq|'></td>
		<input type=hidden name=difference 
                     value=$difference>
                
    |;
    if ($form->{'over_under'}){
      $o_u = $form->{'over_under'};
      $difference =~ s/(value=$o_u)/SELECTED $1/g;
    }
  } else {
    $difference = qq|
	      <tr>
		<th align=right nowrap>|.$locale->text('Difference').qq|</th>
                <td width=10%></td>
		<td align=right><input name=null size=11 value=$difference></td>
		<input type=hidden name=difference value=$difference>
	      </tr>|;
  }
   
 
  if ($form->{report}) {

    print qq|
    </tr>
  </table>
|;

  } else {
    
    print qq|
   
  <tr>
    <td>
      <table width=100%>
        <tr>
	  <td align=right>
	    <table>
	      <tr>
		<th align=right nowrap>|.$locale->text('Statement Balance').qq|</th>
		<td width=10%></td>
		<td align=right><input name=statementbalance size=11 value=$form->{statementbalance}></td>
	      </tr>
		$difference
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

  $form->hide_form(qw(fx_transaction summary rowcount accno account fromdate todate path login sessionid));
  
  print qq|
<br>
<input type=submit class=submit name=action value="|.$locale->text('Update').qq|">
<input type=submit class=submit name=action value="|.$locale->text('Select all').qq|">
    $done
    $close_next |;
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


sub update {
  $form->{null2} = $form->{null};
  
  RC->payment_transactions(\%myconfig, \%$form);

  $i = 0;
  foreach $ref (@{ $form->{PR} }) {
    $i++;
    $ref->{cleared} = ($form->{"cleared_$i"}) ? 1 : 0;
  }

  &display_form;
  
}


sub select_all {
  
  RC->payment_transactions(\%myconfig, \%$form);

  for (@{ $form->{PR} }) { $_->{cleared} = 1 }

  &display_form;
  
}


sub done {

  $form->{callback} = "$form->{script}?path=$form->{path}&action=reconciliation&login=$form->{login}&sessionid=$form->{sessionid}";

  $form->error($locale->text('Out of balance!')) if ($form->{difference} *= 1);

  RC->reconcile(\%myconfig, \%$form);
  $form->redirect;
  
}


