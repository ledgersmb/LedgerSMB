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

    RC->paymentaccounts( \%myconfig, \%$form );

    $selection = "";
    for ( @{ $form->{PR} } ) {
        $selection .= "<option>$_->{accno}--$_->{description}\n";
    }

    $form->{title} = $locale->text('Reconciliation');

    if ( $form->{report} ) {
        $form->{title} = $locale->text('Reconciliation Report');
        $cleared = qq|
        <input type=hidden name=report value=1>
        <tr>
	  <td align=right><input type=checkbox class=checkbox name=outstanding value=1 checked></td>
	  <td>| . $locale->text('Outstanding') . qq|</td>
	  <td align=right><input type=checkbox class=checkbox name=cleared value=1></td>
	  <td>| . $locale->text('Cleared') . qq|</td>
	</tr>
|;

    }

    if ( @{ $form->{all_years} } ) {

        # accounting years
        $form->{selectaccountingyear} = "<option>\n";
        for ( @{ $form->{all_years} } ) {
            $form->{selectaccountingyear} .= qq|<option>$_\n|;
        }
        $form->{selectaccountingmonth} = "<option>\n";
        for ( sort keys %{ $form->{all_month} } ) {
            $form->{selectaccountingmonth} .=
              qq|<option value=$_>|
              . $locale->text( $form->{all_month}{$_} ) . qq|\n|;
        }

        $selectfrom = qq|
        <tr>
	  <th align=right>| . $locale->text('Period') . qq|</th>
	  <td colspan=3>
	  <select name=month>$form->{selectaccountingmonth}</select>
	  <select name=year>$form->{selectaccountingyear}</select>
	  <input name=interval class=radio type=radio value=0 checked>&nbsp;|
          . $locale->text('Current') . qq|
	  <input name=interval class=radio type=radio value=1>&nbsp;|
          . $locale->text('Month') . qq|
	  <input name=interval class=radio type=radio value=3>&nbsp;|
          . $locale->text('Quarter') . qq|
	  <input name=interval class=radio type=radio value=12>&nbsp;|
          . $locale->text('Year') . qq|
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
	  <th align=right nowrap>| . $locale->text('Account') . qq|</th>
	  <td colspan=3><select name=accno>$selection</select></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('From') . qq|</th>
	  <td colspan=3><input class="date" name=fromdate size=11 title="$myconfig{dateformat}"> <b>|
      . $locale->text('To')
      . qq|</b> <input class="date" name=todate size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	$cleared
        <tr>
	  <td></td>
	  <td colspan=3><input type=radio style=radio name=summary value=1 checked> |
      . $locale->text('Summary') . qq|
	  <input type=radio style=radio name=summary value=0> |
      . $locale->text('Detail')
      . qq|</td>
	</tr>
	<tr>
	  <td></td>
	  <td colspan=3><input type=checkbox class=checkbox name=fx_transaction value=1 checked> |
      . $locale->text('Include Exchange Rate Difference')
      . qq|</td>
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
<button type="submit" class="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>

</form>
|;

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|

</body>
</html>
|;

}

sub continue { &{ $form->{nextsub} } }

sub till_closing {
    my %hiddens;
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
    RC->getposlines( \%myconfig, \%$form );

    $hiddens{path} = $form->{path};
    $hiddens{login} = $form->{login};
    $hiddens{sessionid} = $form->{sessionid};
    $hiddens{callback} = $form->{callback};
    $hiddens{sum} = "$form->{sum}" * -1;

    my $j;
    my $source;
    my @sources;
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
        push @sources, {i => $j,
            label => $pos_sources{$source},
            source => $source,
            currenamount => "${curren}${amount}",
            };
        $hiddens{"expected_$source"} = "$amount";
    }
    my @units;
    foreach my $unit ( @{ $pos_config{'breakdown'} } ) {

        # XXX Needs to take into account currencies that don't use 2 dp
        my $calcval = $form->parse_amount( \%pos_config, $unit );
        $calcval = sprintf( '%03d', $calcval * 100 ) if $calcval < 1;
        my $subval = 'sub_' . $calcval;
        my $unit_name = $calcval;
        $calcval = 'calc_' . $calcval;
        push @units, {
            unit => $unit,
            unit_name => "$unit_name",
            currenunit => "${curren}${unit}",
            quantity => {name => $calcval, value => $form->{$calcval}},
            value => {name => $subval, value => $form->{$subval}},
            };
    }
    my @buttons = ({
        name => 'calculate',
        value => 'Calculate',
        type => 'button',
        text => $locale->text('Calculate'),
        attributes => {onclick => 'custom_calc_total()'},
    }, {
        name => 'action',
        value => 'close_till',
        text => $locale->text('Close Till'),
    });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'rc-till-closing',
        );
    $template->render({
        form => $form,
        user => \%myconfig, 
        'pos' => \%pos_config, 
        hiddens => \%hiddens,
        columns => \@colheadings,
        sources => \@sources,
        units => \@units,
        buttons => \@buttons,
    });
}

sub close_till {
    use LedgerSMB::GL;
    require 'pos.conf.pl';
    RC->clear_till( \%myconfig, \%$form );
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
    $lines .= "Cumulative Error: $amount";
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
    my @cashlines = [ $locale->text("Cash Breakdown:") ];
    foreach my $unit ( @{ $pos_config{'breakdown'} } ) {

        # XXX Needs to take into account currencies that don't use 2 dp
        my $parsed = $form->parse_amount( \%pos_config, $unit );
        my $calcval = $parsed;
        $calcval = sprintf( '%03d', $calcval * 100 ) if $calcval < 1;
        my $subval = 'sub_' . $calcval;
        $calcval = 'calc_' . $calcval;
        push @cashlines, "$form->{$calcval} x $parseval = $form->{$subval}";
    }
    push @cashlines,
      $locale->text( "Total Cash in Drawer: [_1]", $form->{sub_sub} );
    push @cashlines,
      $locale->text( "Less Cash in Till At Start: [_1]", $form->{till_cash} );
    push @cashlines, "\n";
    $cash = join( "\n", @cashlines );
    $foot = $locale->text( "Cumulative Error: [_1]", $difference ) . "\n";
    $foot .=
      $locale->text( 'Reset Till By [_1]', $amount ) . "\n\n\n\n\n\n\n\n\n\n";
    open( PRN, "|-", ${LedgerSMB::Sysconfig::printer}{Printer} );
    print PRN $head;
    print PRN $lines;
    print PRN $cash;
    print PRN $cash;
    print PRN $foot;
    close PRN;

    if ( $difference > 0 ) {
        $message = $locale->text( "You are over by [_1]", $difference );
    }
    elsif ( $difference < 0 ) {
        $message = $locale->text( "You are under by [_1]", $difference * -1 );
    }
    else {
        $message =
          $local->text("Congratulations!  Your till is exactly balanced.");
    }
    $form->info($message);
}

sub get_payments {

    ( $form->{accno}, $form->{account} ) = split /--/, $form->{accno};
    if ( $form->{'pos'} ) {
        require "pos.conf.pl";
        $form->{fromdate} = $form->current_date( \%myconfig );
        unless ( $form->{source} ) {
            $form->{source} = ( sort keys(%pos_sources) )[0];
        }
        if ( $form->{source} eq 'cash' ) {
            $form->{summary} = "true";
        }
        else {
            $form->{summary} = "";
        }
        $form->{accno} = $pos_config{'coa_prefix'} . "." . $pos_config{'till'};
        $form->{account} = $form->{source};
    }

    RC->payment_transactions( \%myconfig, \%$form );

    $ml = ( $form->{category} eq 'A' ) ? -1 : 1;
    $form->{statementbalance} = $form->{endingbalance} * $ml;
    if ( !$form->{fx_transaction} ) {
        $form->{statementbalance} =
          ( $form->{endingbalance} - $form->{fx_endingbalance} ) * $ml;
    }

    $form->{statementbalance} =
      $form->format_amount( \%myconfig, $form->{statementbalance}, 2, 0 );

    &display_form;

}

sub display_form {
    my %hiddens;
    my @buttons;

    my @column_index;
    if ( $form->{report} ) {
        @column_index = qw(transdate source name cleared debit credit);
    }
    else {
        @column_index = qw(transdate source name cleared debit credit balance);
    }

    my %column_header;
    $column_header{cleared} = $locale->text('R');
    $column_header{source} = $locale->text('Source');
    $column_header{name} = $locale->text('Description');
    $column_header{transdate} = $locale->text('Date');
    $column_header{debit} = $locale->text('Debit');
    $column_header{credit} = $locale->text('Credit');
    $column_header{balance} = $locale->text('Balance');

    my @options;
    if ( $form->{fromdate} ) {
        push @options,
            $locale->text('From [_1]',
            $locale->date( \%myconfig, $form->{fromdate}, 1 ));
    }
    if ( $form->{todate} ) {
        push @options,
            $locale->text('To [_1]',
            $locale->date( \%myconfig, $form->{todate}, 1 ));
    }

    $form->{title} = "$form->{accno}--$form->{account}";

    $hiddens{source} = $form->{source};
    $hiddens{cumulative_error} = $form->{cumulative_error};

    my $ml = ( $form->{category} eq 'A' ) ? -1 : 1;
    $form->{beginningbalance} *= $ml;
    $form->{fx_balance}       *= $ml;

    if ( !$form->{fx_transaction} ) {
        $form->{beginningbalance} -= $form->{fx_balance};
    }
    my $balance = $form->{beginningbalance};

    my $i = 0;
    my $j = 0;
    my @rows;

    if ( !$form->{report} ) {
        my %column_data;
        for (qw(cleared transdate source debit credit)) {
            $column_data{$_} = ' ';
        }
        $column_data{name} = $locale->text('Beginning Balance');
        $column_data{balance} = $form->format_amount(\%myconfig, $balance, 2, 0);
        $column_data{i} = $j;
        push @rows, \%column_data;
    }

    foreach my $ref ( @{ $form->{PR} } ) {

        $i++;

        if ( !$form->{fx_transaction} ) {
            next if $ref->{fx_transaction};
        }

        my %column_data;
        my $checked = ( $ref->{cleared} ) ? "checked" : undef;

        my %temp = ();
        if ( !$ref->{fx_transaction} ) {
            for (qw(name source transdate)) { $temp{$_} = $ref->{$_} }
        }

        $column_data{name}{delimiter} = "|";
        for ( @{ $temp{name} } ) { $column_data{name}{text} .= "$_|" }

        $column_data{source} = $temp{source};

        $column_data{debit}  = ' ';
        $column_data{credit} = ' ';

        $balance += $ref->{amount} * $ml;

        $hiddens{"id_$i"} = $ref->{id};
        if ( $ref->{amount} < 0 ) {
            $totaldebits += $ref->{amount} * -1;
            $column_data{debit} = 
                $form->format_amount(\%myconfig, $ref->{amount} * -1, 2, ' ');
        } else {
            $totalcredits += $ref->{amount};
            $column_data{credit} =
                $form->format_amount(\%myconfig, $ref->{amount}, 2, ' ');
        }

        $column_data{balance} = $form->format_amount(\%myconfig, $balance, 2, 0);

        if ( $ref->{fx_transaction} ) {
            $column_data{cleared} =
              ($clearfx) ? '*': ' ';
            $cleared += $ref->{amount} * $ml if $clearfx;
        } else {
            if ( $form->{report} ) {
                if ( $ref->{cleared} ) {
                    $column_data{cleared} = '*';
                    $clearfx = 1;
                } else {
                    $column_data{cleared} = ' ';
                    $clearfx = 0;
                }
            } else {
                if ( $ref->{oldcleared} ) {
                    $cleared += $ref->{amount} * $ml;
                    $clearfx = 1;
                    $hiddens{"cleared_$i"} = $ref->{cleared};
                    $hiddens{"oldcleared_$i"} = $ref->{oldcleared};
                    $hiddens{"source_$i"} = $ref->{source};
                    $hiddens{"amount_$i"} = $ref->{amount};
                    $column_data{cleared} = '*';
                } else {
                    $cleared += $ref->{amount} * $ml if $checked;
                    $clearfx = ($checked) ? 1 : 0;
                    $hiddens{"source_$i"} = $ref->{source};
                    $hiddens{"amount_$i"} = $ref->{amount};
                    $column_data{cleared} = {input => {
                        type => 'checkbox',
                        value => 1,
                        name => "cleared_$i",
                        $checked => $checked,
                        }};
                }
            }
        }

        $hiddens{"transdate_$i"} = $ref->{transdate};
        $column_data{transdate} = $temp{transdate};

        $j++;
        $j %= 2;
        $column_data{i} = $j;

        push @rows, \%column_data;
    }
    $form->{rowcount} = $i;

    # print totals
    my %column_data;
    for (@column_index) { $column_data{$_} = ' ' }

    $column_data{debit} =
        $form->format_amount( \%myconfig, $totaldebits, 2, ' ' );
    $column_data{credit} =
        $form->format_amount( \%myconfig, $totalcredits, 2, ' ' );

    $form->{statementbalance} =
      $form->parse_amount( \%myconfig, $form->{statementbalance} );
    $difference =
      $form->format_amount( \%myconfig,
        $form->{beginningbalance} + $cleared - $form->{statementbalance},
        2, 0 );
    if ( $form->{source} ) {
        $difference = 0;
    }
    $form->{statementbalance} =
      $form->format_amount( \%myconfig, $form->{statementbalance}, 2, 0 );

    if ( $form->{'pos'} ) {
        push @buttons, {
            name => 'action',
            value => 'close_next',
            text => $locale->text('Close Next')
            };
    } else {
        push @buttons, {
            name => 'action',
            value => 'done',
            text => $locale->text('Done')
            };
    }

    $hiddens{difference} = $difference;
    if ( $form->{'pos'} ) {
        $hiddens{'pos'} = 'true';
    }

    if (! $form->{report} ) {
        $hiddens{$_} = $form->{$_} foreach
            qw(fx_transaction summary rowcount accno account fromdate todate path login sessionid);

        unshift @buttons, {
            name => 'action',
            value => 'select_all',
            text => $locale->text('Select all'),
            };
        unshift @buttons, {
            name => 'action',
            value => 'update',
            text => $locale->text('Update'),
            };
    }

##SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'rc-display-form',
        );
    $template->render({
        form => $form,
        hiddens => \%hiddens,
        options => \@options,
        rows => \@rows,
        totals => \%column_data,
        columns => \@column_index,
        heading => \%column_header,
        buttons => \@buttons,
    });
}

sub update {
    $form->{null2} = $form->{null};

    RC->payment_transactions( \%myconfig, \%$form );

    $i = 0;
    foreach $ref ( @{ $form->{PR} } ) {
        $i++;
        $ref->{cleared} = ( $form->{"cleared_$i"} ) ? 1 : 0;
    }

    &display_form;

}

sub select_all {

    RC->payment_transactions( \%myconfig, \%$form );

    for ( @{ $form->{PR} } ) { $_->{cleared} = 1 }

    &display_form;

}

sub done {

    $form->{callback} =
"$form->{script}?path=$form->{path}&action=reconciliation&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->error( $locale->text('Out of balance!') )
      if ( $form->{difference} *= 1 );

    RC->reconcile( \%myconfig, \%$form );
    $form->redirect;

}

