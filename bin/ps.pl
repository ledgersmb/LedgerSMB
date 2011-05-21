######################################################################
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
# Copyright (c) 1999 - 2005
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
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
#
#######################################################################
#
# point of sale script
#
#######################################################################

use LedgerSMB::AA;
use LedgerSMB::IS;
use LedgerSMB::RP;

require "bin/ar.pl";
require "bin/is.pl";
require "bin/rp.pl";
require "bin/pos.pl";
require "pos.conf.pl";

# customizations
if ( -f "bin/custom/pos.pl" ) {
    eval { require "bin/custom/pos.pl"; };
}
if ( -f "bin/custom/$form->{login}_pos.pl" ) {
    eval { require "bin/custom/$form->{login}_pos.pl"; };
}

# Necessary for Partsgroup lookups
if ( $form->{action} =~ s/^\s// ) {
    $form->{my_partsgroup} = $form->{action};
    $form->{action}        = "lookup_partsgroup";
}

sub till_closing {
    $form->{callback} =
"$form->{script}?path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    # $locale->text("Source");
    # $locale->text("Actual");
    # $locale->text("Expected");
    # $locale->text("Error");
    @colheadings = qw(Source Actual Expected Error);
    my $curren = $pos_config{'curren'};

    $form->{title} = $locale->text( "Closing Till For [_1]", $form->{login} );
    require "pos.conf.pl";
    IS->getposlines( \%myconfig, \%$form );
    $form->header;
    print qq|
<body>

<form method="post" action="$form->{script}">
<input type="hidden" name="path" value="$form->{path}">
<input type="hidden" name="login" value="$form->{login}">
<input type="hidden" name="sessionid" value="$form->{sessionid}">

<input type="hidden" name="callback" value="$form->{callback}">
<input type="hidden" name="sum" value="| . $form->{sum} * -1 . qq|">
<table width="100%">
  <tr>
    <th class="listtop">$form->{title}</th>
  </tr>
</table> 
<table width="100%">
|;

    print "<tr>";
    map { print '<td class="listheading">' . $locale->text($_) . "</td>"; }
      @colheadings;
    print "</tr>";
    my $j;
    my $source;
    foreach $source ( sort keys %pos_sources ) {
        $amount = 0;
        foreach $ref ( @{ $form->{TB} } ) {
            if ( $ref->{memo} eq $source ) {
                $amount = $ref->{amount} * -1;
                last;
            }
        }
        ++$j;
        $j = $j % 2;
        print qq|<tr class="listrow$j"><td>| . $pos_sources{$source} . qq|</td>
             <td><input name="amount_$source">
             <input type="hidden" name="expected_$source" 
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
    my $subgen  = 'document.forms[0].sub_sub.value = ';
    my $toround = '';
    foreach my $unit ( @{ $pos_config{'breakdown'} } ) {

        # XXX Needs to take into account currencies that don't use 2 dp
        my $parsed = $form->parse_amount( \%pos_config, $unit );
        my $calcval = $parsed;
        $calcval = sprintf( '%03d', $calcval * 100 ) if $calcval < 1;
        my $subval = 'sub_' . $calcval;
        $calcval = 'calc_' . $calcval;
        print qq|
  document.forms[0].${subval}.value = document.forms[0].${calcval}.value * $parsed;
    |;
        $subgen  .= "document.forms[0].${subval}.value * 1 + ";
        $toround .= qq|
    	document.forms[0].${subval}.value = 
    	money_round(document.forms[0].${subval}.value); |;
    }
    print $subgen . "0;";
    print $toround;
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
    } ( keys %pos_sources );
    print qq|
  alert('|
      . $locale->text('Cumulative Error:')
      . qq| $curren' + money_round(cumulative_error));
}
</script>

<table>
<col><col><col>|;
    foreach my $unit ( @{ $pos_config{'breakdown'} } ) {

        # XXX Needs to take into account currencies that don't use 2 dp
        my $calcval = $form->parse_amount( \%pos_config, $unit );
        $calcval = sprintf( '%03d', $calcval * 100 ) if $calcval < 1;
        my $subval = 'sub_' . $calcval;
        $calcval = 'calc_' . $calcval;
        print qq|<tr>
      <td><input type="text" name="$calcval" value="$form->{$calcval}"></td>
      <th>X ${curren}${unit} = </th>
      <td><input type="text" name="$subval" value="$form->{$subval}"></td>
    </tr>|;
    }
    print qq|<tr>
    <td>&nbsp;</td>
    <th>| . $locale->text("Subtotal") . qq|:</th>
    <td><input type="text" name="sub_sub" value="$form->{sub_sub}"></td>
  </tr>
  </table>
<input type="button" name="calculate" class="submit" onClick="custom_calc_total()" 
   value='| . $locale->text('Calculate') . qq|'>
|;
    print qq|</table><button type="submit" name="action" value="close_till">|
      . $locale->text("Close Till")
      . qq|</button>|;
    print qq|
</form>

</body>
</html>
|;
}


sub close_till {
    use LedgerSMB::GL;
    require 'pos.conf.pl';
    IS->clear_till( \%myconfig, \%$form );
    my $amount     = 0;
    my $expected   = 0;
    my $difference = 0;
    my $lines      = '';
    $form->{rowcount} = 2;

    foreach $key ( keys %pos_sources ) {
        $amount   = 0;
        $expected = 0;
        $amount   = $form->parse_amount( \%myconfig, $form->{"amount_$key"} );
        $expected = $form->parse_amount( \%myconfig, $form->{"expected_$key"} );
        $gl_entry = "Closing Till $pos_config{till} source = $key";
        $accno1   = $pos_config{till_accno};
        if ( ${ $pos_config{'source_accno_override'}{$key} } ) {
            $accno2 = ${ $pos_config{'source_accno_override'}{$key} };
        }
        else {
            $accno2 = $pos_config{'close_cash_accno'};
        }
        $form->{reference} = $gl_entry;
        $form->{accno_1}   = $accno1;
        $form->{credit_1}  = $amount;
        $form->{accno_2}   = $accno2;
        $form->{debit_2}   = $amount;
        $form->{transdate} = $form->current_date( \%myconfig );
        GL->post_transaction( \%myconfig, \%$form );
        delete $form->{id};
        $error = $amount - $expected;
        $difference += $error;
        $lines .=
"Source: $key, Amount: $amount\nExpected: $expected.  Error= $error\n\n";
    }
    $gl_entry          = "Closing Till: $pos_config{till} Over/Under";
    $amount            = $difference * -1;
    $form->{reference} = $gl_entry;
    $form->{accno_1}   = $accno1;
    $form->{credit_1}  = $amount;
    $form->{accno_2}   = $pos_config{coa_prefix};
    $form->{debit_2}   = $amount;
    $form->{transdate} = $form->current_date( \%myconfig );
    GL->post_transaction( \%myconfig, \%$form );
    delete $form->{id};
    $lines .= "Cumulative Error: $amount\n\n";
    $form->{accno} = $form->{accno_1};
    RC->getbalance( \%myconfig, \%$form );
    $amount            = $form->{balance} * -1;
    $gl_entry          = "Resetting Till: $pos_config{till}";
    $form->{reference} = $gl_entry;
    $form->{accno_1}   = $accno1;
    $form->{credit_1}  = $amount;
    $form->{accno_2}   = $pos_config{coa_prefix};
    $form->{debit_2}   = $amount;
    $form->{transdate} = $form->current_date( \%myconfig );
    GL->post_transaction( \%myconfig, \%$form );
    delete $form->{id};

    $head =
        "Closing Till $pos_config{till} for $form->{login}\n"
      . "Date: $form->{transdate}\n\n\n";
    my @cashlines = ( $locale->text("Cash Breakdown:") );
    foreach my $unit ( @{ $pos_config{'breakdown'} } ) {

        # XXX Needs to take into account currencies that don't use 2 dp
        my $parsed = $form->parse_amount( \%pos_config, $unit );
        my $calcval = $parsed;
        $calcval = sprintf( '%03d', $calcval * 100 ) if $calcval < 1;
        my $subval = 'sub_' . $calcval;
        $calcval = 'calc_' . $calcval;
        push @cashlines, "$form->{$calcval} x $parsed = $form->{$subval}";
    }
    push @cashlines,
      $locale->text( "Total Cash in Drawer: [_1]", $form->{sub_sub} );
    push @cashlines,
      $locale->text( "Less Cash in Till At Start: [_1]", $pos_config{till_cash} );
    push @cashlines, "\n";
    $cash = join( "\n", @cashlines );
    $foot = $locale->text( "Cumulative Error: [_1]", $difference ) . "\n";
    $foot .=
      $locale->text( 'Reset Till By [_1]', $amount ) . "\n\n\n\n\n\n\n\n\n\n";
    open( PRN, "|-", ${LedgerSMB::Sysconfig::printer}{Printer} );

    print PRN $head;
    print PRN $lines;
    print PRN $cash;
    print PRN $foot;
    close PRN;

    if ( $difference < 0 ) {
        $message = $locale->text( "You are over by [_1]", $difference );
    }
    elsif ( $difference > 0 ) {
        $message = $locale->text( "You are under by [_1]", $difference * -1 );
    }
    else {
        $message =
          $locale->text("Congratulations!  Your till is exactly balanced.");
    }
    $form->info($message);
}

1;

# end
