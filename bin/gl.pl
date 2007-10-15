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
# Copyright (c) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
# Contributors:
#
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
#
# Contributors:
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
# Genereal Ledger
#
#======================================================================

use LedgerSMB::GL;
use LedgerSMB::PE;
use LedgerSMB::Template;

require "bin/arap.pl";

$form->{login} = 'test';
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

sub pos_adjust {
    $form->{rowcount} = 3;
    require "pos.conf.pl";
    $form->{accno_1} = $pos_config{'close_cash_accno'};
    $form->{accno_2} = $pos_config{'coa_prefix'};
    $form->{accno_3} = $pos_config{'coa_prefix'};
}

sub add_pos_adjust {
    $form->{pos_adjust} = 1;
    $form->{reference} =
      $locale->text("Adjusting Till: (till) Source: (source)");
    $form->{description} =
      $locale->text("Adjusting till due to data entry error.");
    $form->{callback} =
"$form->{script}?action=add_pos_adjust&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};
    &add;
}

sub add {

    $form->{title} = "Add";

    $form->{callback} =
"$form->{script}?action=add&transfer=$form->{transfer}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}"
      unless $form->{callback};

    &create_links;
    $form->{reference} = $form->update_defaults(\%myconfig, 'glnumber');
    $form->{rowcount} = ( $form->{transfer} ) ? 3 : 9;
    if ( $form->{pos_adjust} ) {
        &pos_adjust;
    }
    $form->{oldtransdate} = $form->{transdate};
    $form->{focus}        = "reference";

    # departments
    if ( @{ $form->{all_department} } ) {
        $form->{selectdepartment} = "<option>\n";

        for ( @{ $form->{all_department} } ) {
            $form->{selectdepartment} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }
    }

    &display_form(1);

}

sub edit {

    &create_links;

    $form->{locked} =
      ( $form->{revtrans} )
      ? '1'
      : ( $form->datetonum( \%myconfig, $form->{transdate} ) <=
          $form->datetonum( \%myconfig, $form->{closedto} ) );

    # readonly
    if ( !$form->{readonly} ) {
        $form->{readonly} = 1
          if $myconfig{acs} =~ /General Ledger--Add Transaction/;
    }

    $form->{title} = "Edit";

    $i = 1;
    foreach $ref ( @{ $form->{GL} } ) {
        $form->{"accno_$i"} = "$ref->{accno}--$ref->{description}";

        $form->{"projectnumber_$i"} =
          "$ref->{projectnumber}--$ref->{project_id}";
        for (qw(fx_transaction source memo)) { $form->{"${_}_$i"} = $ref->{$_} }

        if ( $ref->{amount} < 0 ) {
            $form->{totaldebit} -= $ref->{amount};
            $form->{"debit_$i"} = $ref->{amount} * -1;
        }
        else {
            $form->{totalcredit} += $ref->{amount};
            $form->{"credit_$i"} = $ref->{amount};
        }

        $i++;
    }

    $form->{rowcount} = $i;
    $form->{focus}    = "debit_$i";

    &form_header;
    &display_rows;
    &form_footer;

}

sub create_links {

    GL->transaction( \%myconfig, \%$form );

    for ( @{ $form->{all_accno} } ) {
        $form->{selectaccno} .= "<option>$_->{accno}--$_->{description}\n";
    }

    # projects
    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
        }
    }

    # departments
    if ( @{ $form->{all_department} } ) {
        $form->{department} = "$form->{department}--$form->{department_id}";
        $form->{selectdepartment} = "<option>\n";
        for ( @{ $form->{all_department} } ) {
            $form->{selectdepartment} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }
    }

}

sub search {

    $form->{title} = $locale->text('General Ledger Reports');

    $colspan = 5;
    $form->all_departments( \%myconfig );

    # departments
    if ( @{ $form->{all_department} } ) {
        $form->{selectdepartment} = "<option>\n";
        for ( @{ $form->{all_department} } ) {
            $form->{selectdepartment} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }

        $l_department =
          qq|<input name="l_department" class=checkbox type=checkbox value=Y> |
          . $locale->text('Department');

        $department = qq|
  	<tr>
	  <th align=right nowrap>| . $locale->text('Department') . qq|</th>
	  <td colspan=$colspan><select name=department>$form->{selectdepartment}</select></td>
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
	<td colspan=$colspan>
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

    @a = ();
    push @a, qq|<input name="l_id" class=checkbox type=checkbox value=Y> |
      . $locale->text('ID');
    push @a,
qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Date');
    push @a,
qq|<input name="l_reference" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Reference');
    push @a,
qq|<input name="l_description" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Description');
    push @a, qq|<input name="l_notes" class=checkbox type=checkbox value=Y> |
      . $locale->text('Notes');
    push @a, $l_department if $l_department;
    push @a,
      qq|<input name="l_debit" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Debit');
    push @a,
      qq|<input name="l_credit" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Credit');
    push @a,
      qq|<input name="l_source" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Source');
    push @a, qq|<input name="l_memo" class=checkbox type=checkbox value=Y> |
      . $locale->text('Memo');
    push @a,
      qq|<input name="l_accno" class=checkbox type=checkbox value=Y checked> |
      . $locale->text('Account');
    push @a,
      qq|<input name="l_gifi_accno" class=checkbox type=checkbox value=Y> |
      . $locale->text('GIFI');

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=sort value=transdate>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>| . $locale->text('Reference') . qq|</th>
	  <td><input name=reference size=20></td>

	  </tr>
	  <tr>
	  <th align=right>| . $locale->text('Source') . qq|</th>
	  <td><input name=source size=20></td>
	  <th align=right>| . $locale->text('Memo') . qq|</th>
	  <td><input name=memo size=20></td>
	</tr>
	$department
	<tr>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td colspan=$colspan><input name=description size=60></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Notes') . qq|</th>
	  <td colspan=$colspan><input name=notes size=60></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('From') . qq|</th>
	  <td><input class="date" name=datefrom size=11 title="$myconfig{dateformat}"></td>
	  <th align=right>| . $locale->text('To') . qq|</th>
	  <td><input class="date" name=dateto size=11 title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	<tr>
	  <th align=right>| . $locale->text('Amount') . qq| >=</th>
	  <td><input name=amountfrom size=11></td>
	  <th align=right>| . $locale->text('Amount') . qq| <=</th>
	  <td><input name=amountto size=11></td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Include in Report') . qq|</th>
	  <td colspan=$colspan>
	    <table>
	      <tr>
		<td>
		  <input name="category" class=radio type=radio value=X checked>&nbsp;|
      . $locale->text('All') . qq|
		  <input name="category" class=radio type=radio value=A>&nbsp;|
      . $locale->text('Asset') . qq|
		  <input name="category" class=radio type=radio value=L>&nbsp;|
      . $locale->text('Liability') . qq|
		  <input name="category" class=radio type=radio value=Q>&nbsp;|
      . $locale->text('Equity') . qq|
		  <input name="category" class=radio type=radio value=I>&nbsp;|
      . $locale->text('Income') . qq|
		  <input name="category" class=radio type=radio value=E>&nbsp;|
      . $locale->text('Expense') . qq|
		</td>
	      </tr>
	      <tr>
		<table>
|;

    while (@a) {
        print qq|<tr>\n|;
        for ( 1 .. 5 ) {
            print qq|<td nowrap>| . shift @a;
            print qq|</td>\n|;
        }
        print qq|</tr>\n|;
    }

    print qq|
		  <tr>
		    <td nowrap><input name="l_subtotal" class=checkbox type=checkbox value=Y> |
      . $locale->text('Subtotal')
      . qq|</td>
		  </tr>
		</table>
	      </tr>
	    </table>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=generate_report>
|;

    $form->hide_form(qw(path login sessionid));

    print qq|
<br>
<button class="submit" type="submit" name="action" value="continue">|
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

sub generate_report {

    $form->{sort} = "transdate" unless $form->{sort};
    $form->{amountfrom} = $form->parse_amount(\%myconfig, $form->{amountfrom});
    $form->{amountto} = $form->parse_amount(\%myconfig, $form->{amountto});

    GL->all_transactions( \%myconfig, \%$form );

    $href =
"$form->{script}?action=generate_report&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->sort_order();

    $callback =
"$form->{script}?action=generate_report&direction=$form->{direction}&oldsort=$form->{oldsort}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    my %hiddens = (
        'action' => 'generate_report',
        'direction' => $form->{direction},
        'oldsort' => $form->{oldsort},
        'path' => $form->{path},
        'login' => $form->{login},
        'sessionid' => $form->{sessionid},
        );
    %acctype = (
        'A' => $locale->text('Asset'),
        'L' => $locale->text('Liability'),
        'Q' => $locale->text('Equity'),
        'I' => $locale->text('Income'),
        'E' => $locale->text('Expense'),
    );
    my @options;

    $form->{title} = $locale->text('General Ledger');

    $ml = ( $form->{category} =~ /(A|E)/ ) ? -1 : 1;

    unless ( $form->{category} eq 'X' ) {
        $form->{title} .=
          " : " . $locale->text( $acctype{ $form->{category} } );
    }
    if ( $form->{accno} ) {
        $href .= "&accno=" . $form->escape( $form->{accno} );
        $callback .= "&accno=" . $form->escape( $form->{accno}, 1 );
        $hiddens{accno} = $form->{accno};
        push @options, $locale->text('Account')
          . " : $form->{accno} $form->{account_description}";
    }
    if ( $form->{gifi_accno} ) {
        $href     .= "&gifi_accno=" . $form->escape( $form->{gifi_accno} );
        $callback .= "&gifi_accno=" . $form->escape( $form->{gifi_accno}, 1 );
        $hiddens{gifi_accno} = $form->{gifi_accno};
        push @options, $locale->text('GIFI')
          . " : $form->{gifi_accno} $form->{gifi_account_description}";
    }
    if ( $form->{source} ) {
        $href     .= "&source=" . $form->escape( $form->{source} );
        $callback .= "&source=" . $form->escape( $form->{source}, 1 );
        $hiddens{source} = $form->{source};
        push @options, $locale->text('Source') . " : $form->{source}";
    }
    if ( $form->{memo} ) {
        $href     .= "&memo=" . $form->escape( $form->{memo} );
        $callback .= "&memo=" . $form->escape( $form->{memo}, 1 );
        $hiddens{memo} = $form->{memo};
        push @options, $locale->text('Memo') . " : $form->{memo}";
    }
    if ( $form->{reference} ) {
        $href     .= "&reference=" . $form->escape( $form->{reference} );
        $callback .= "&reference=" . $form->escape( $form->{reference}, 1 );
        $hiddens{reference} = $form->{reference};
        push @options, $locale->text('Reference') . " : $form->{reference}";
    }
    if ( $form->{department} ) {
        $href .= "&department=" . $form->escape( $form->{department} );
        $callback .= "&department=" . $form->escape( $form->{department}, 1 );
        $hiddens{department} = $form->{department};
        ($department) = split /--/, $form->{department};
        push @options, $locale->text('Department') . " : $department";
    }

    if ( $form->{description} ) {
        $href     .= "&description=" . $form->escape( $form->{description} );
        $callback .= "&description=" . $form->escape( $form->{description}, 1 );
        $hiddens{description} = $form->{description};
        push @options, $locale->text('Description') . " : $form->{description}";
    }
    if ( $form->{notes} ) {
        $href     .= "&notes=" . $form->escape( $form->{notes} );
        $callback .= "&notes=" . $form->escape( $form->{notes}, 1 );
        $hiddens{notes} = $form->{notes};
        push @options, $locale->text('Notes') . " : $form->{notes}";
    }

    if ( $form->{datefrom} ) {
        $href     .= "&datefrom=$form->{datefrom}";
        $callback .= "&datefrom=$form->{datefrom}";
        $hiddens{datefrom} = $form->{datefrom};
        push @options, $locale->text('From') . " "
          . $locale->date( \%myconfig, $form->{datefrom}, 1 );
    }
    if ( $form->{dateto} ) {
        $href     .= "&dateto=$form->{dateto}";
        $callback .= "&dateto=$form->{dateto}";
        $hiddens{dateto} = $form->{dateto};
        my $option = $locale->text('To') . " "
          . $locale->date( \%myconfig, $form->{dateto}, 1 );
        if ( $form->{datefrom} ) {
            $options[$#options] .= " $option";
        }
        else {
            push @options, $option;
        }
    }

    if ( $form->{amountfrom} ) {
        $href     .= "&amountfrom=$form->{amountfrom}";
        $callback .= "&amountfrom=$form->{amountfrom}";
        $hiddens{amountfrom} = $form->{amountfrom};
        push @options, $locale->text('Amount') . " >= "
          . $form->format_amount( \%myconfig, $form->{amountfrom}, 2 );
    }
    if ( $form->{amountto} ) {
        $href     .= "&amountto=$form->{amountto}";
        $callback .= "&amountto=$form->{amountto}";
        $hiddens{amountto} = $form->{amountto};
        my $option .= $form->format_amount( \%myconfig, $form->{amountto}, 2 );
        if ( $form->{amountfrom} ) {
            $options[$#options] .= " <= $option";
        }
        else {
            push @options, $locale->text('Amount') . " <= $option";
        }
    }

    @columns =
      $form->sort_columns(
        qw(transdate id reference description notes source memo debit credit accno gifi_accno department)
      );
    pop @columns if $form->{department};

    if ( $form->{link} =~ /_paid/ ) {
        @columns =
          $form->sort_columns(
            qw(transdate id reference description notes source memo cleared debit credit accno gifi_accno)
          );
        $form->{l_cleared} = "Y";
    }

    if ( $form->{accno} || $form->{gifi_accno} ) {
        @columns = grep !/(accno|gifi_accno)/, @columns;
        push @columns, "balance";
        $form->{l_balance} = "Y";
    }

    foreach $item (@columns) {
        if ( $form->{"l_$item"} eq "Y" ) {
            push @column_index, $item;

            # add column to href and callback
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
            $hiddens{"l_$item"} = 'Y';
        }
    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        $callback .= "&l_subtotal=Y";
        $href     .= "&l_subtotal=Y";
        $hiddens{l_subtotal} = 'Y';
    }

    $callback .= "&category=$form->{category}";
    $href     .= "&category=$form->{category}";
    $hiddens{category} = $form->{category};

    $column_header{id} =
        {text => $locale->text('ID'), href=> "$href&sort=id"};
    $column_header{transdate} =
        {text => $locale->text('Date'), href=> "$href&sort=transdate"};
    $column_header{reference} =
        {text => $locale->text('Reference'), href=> "$href&sort=reference"};
    $column_header{source} =
        {text => $locale->text('Source'), href=> "$href&sort=source"};
    $column_header{memo} =
        {text => $locale->text('Memo'), href=> "$href&sort=memo"};
    $column_header{description} =
        {text => $locale->text('Description'), href=> "$href&sort=description"};
    $column_header{department} =
        {text => $locale->text('Department'), href=> "$href&sort=department"};
    $column_header{notes} = $locale->text('Notes');
    $column_header{debit} = $locale->text('Debit');
    $column_header{credit} = $locale->text('Credit');
    $column_header{accno} =
        {text => $locale->text('Account'), href=> "$href&sort=accno"};
    $column_header{gifi_accno} =
        {text => $locale->text('GIFI'), href=> "$href&sort=gifi_accno"};
    $column_header{balance} = $locale->text('Balance');
    $column_header{cleared} = $locale->text('R');

    # add sort to callback
    $form->{callback} = "$callback&sort=$form->{sort}";
    $callback = $form->escape( $form->{callback} );
    $hiddens{sort} = $form->{sort};
    $hiddens{callback} = $form->{callback};

    $cml = 1;

    # initial item for subtotals
    if ( @{ $form->{GL} } ) {
        $sameitem = $form->{GL}->[0]->{ $form->{sort} };
        $cml = -1 if $form->{contra};
    }

    my @rows;
    if ( ( $form->{accno} || $form->{gifi_accno} ) && $form->{balance} ) {
        my %column_data;

        for (@column_index) { $column_data{$_} = " " }
        $column_data{balance} = 
            $form->format_amount( \%myconfig, $form->{balance} * $ml * $cml,
            2, 0 );

	$column_data{i} = 1;
        push @rows, \%column_data;
    }

    # reverse href
    $direction = ( $form->{direction} eq 'ASC' ) ? "ASC" : "DESC";
    $form->sort_order();
    $href =~ s/direction=$form->{direction}/direction=$direction/;

    my $i = 0;
    foreach $ref ( @{ $form->{GL} } ) {
        my %column_data;

        # if item ne sort print subtotal
        if ( $form->{l_subtotal} eq 'Y' ) {
            if ( $sameitem ne $ref->{ $form->{sort} } ) {
                push @rows, &gl_subtotal_tt();
            }
        }

        $form->{balance} += $ref->{amount};

        $subtotaldebit  += $ref->{debit};
        $subtotalcredit += $ref->{credit};

        $totaldebit  += $ref->{debit};
        $totalcredit += $ref->{credit};

        $ref->{debit} =
          $form->format_amount( \%myconfig, $ref->{debit}, 2, " " );
        $ref->{credit} =
          $form->format_amount( \%myconfig, $ref->{credit}, 2, " " );

        for (qw(id transdate)) { $column_data{$_} = "$ref->{$_}" }

        $column_data{reference} =
            {href => "$ref->{module}.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback",
            text => $ref->{reference}};

        #$ref->{notes} =~ s/\r?\n/<br>/g;
        for (qw(description source memo notes department)) {
            $column_data{$_} = "$ref->{$_} ";
        }

        $column_data{debit}  = "$ref->{debit}";
        $column_data{credit} = "$ref->{credit}";

        $column_data{accno} =
            {href => "$href&accno=$ref->{accno}&callback=$callback",
            text => "$ref->{accno} $ref->{accname}"};
        $column_data{gifi_accno} =
            {href => "$href&gifi_accno=$ref->{gifi_accno}&callback=$callback",
            text => $ref->{gifi_accno}};
        $column_data{balance} = $form->format_amount( \%myconfig, $form->{balance} * $ml * $cml,
            2, 0 );
        $column_data{cleared} =
          ( $ref->{cleared} ) ? "*" : " ";

        if ( $ref->{id} != $sameid ) {
            $i++;
            $i %= 2;
        }
	$column_data{'i'} = $i;
        push @rows, \%column_data;

        $sameid = $ref->{id};
    }

    push @rows, &gl_subtotal_tt() if ( $form->{l_subtotal} eq 'Y' );

    for (@column_index) { $column_data{$_} = " " }

    $column_data{debit} = $form->format_amount( \%myconfig, $totaldebit, 2, " " );
    $column_data{credit} = $form->format_amount( \%myconfig, $totalcredit, 2, " " );
    $column_data{balance} = $form->format_amount( \%myconfig, $form->{balance} * $ml * $cml, 2, 0 );

    $i = 1;
    my %button;
    if ( $myconfig{acs} !~ /General Ledger--General Ledger/ ) {
        $button{'General Ledger--Add Transaction'} = {
            name => 'action',
            value => 'gl_transaction',
            text => $locale->text('GL Transaction'),
            type => 'submit',
            class => 'submit',
            order => $i++};
    }
    if ( $myconfig{acs} !~ /AR--AR/ ) {
        $button{'AR--Add Transaction'} = {
            name => 'action',
            value => 'ar_transaction',
            text => $locale->text('AR Transaction'),
            type => 'submit',
            class => 'submit',
            order => $i++};
        $button{'AR--Sales Invoice'} = {
            name => 'action',
            value => 'sales_invoice_',
            text => $locale->text('Sales Invoice'),
            type => 'submit',
            class => 'submit',
            order => $i++};
    }
    if ( $myconfig{acs} !~ /AP--AP/ ) {
        $button{'AP--Add Transaction'} = {
            name => 'action',
            value => 'ap_transaction',
            text => $locale->text('AP Transaction'),
            type => 'submit',
            class => 'submit',
            order => $i++};
        $button{'AP--Vendor Invoice'} = {
            name => 'action',
            value => 'vendor_invoice_',
            text => $locale->text('Vendor Invoice'),
            type => 'submit',
            class => 'submit',
            order => $i++};
    }

    foreach $item ( split /;/, $myconfig{acs} ) {
        delete $button{$item};
    }

    my @buttons;
    foreach my $item ( sort { $a->{order} <=> $b->{order} } %button ) {
        push @buttons, $item if ref $item;
    }
    push @buttons, {
        name => 'action',
        value => 'csv_gl_report',
        text => $locale->text('CSV Report'),
        type => 'submit',
        class => 'submit',
    };

##SC: Taking this out for now...
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my %row_alignment = (
        'balance' => 'right',
        'debit' => 'right',
        'credit' => 'right'
        );
    my $template;
    my $format = uc substr($form->{action}, 0, 3);
    my $template = LedgerSMB::Template->new(
        user => \%myconfig,
        locale => $locale,
        path => 'UI',
        template => 'form-dynatable',
        format => ($format ne 'CSV')? 'HTML': 'CSV');
    $template->render({
        form => \%$form,
        buttons => \@buttons,
        hiddens => \%hiddens,
        options => \@options,
        columns => \@column_index,
        heading => \%column_header,
        rows => \@rows,
        row_alignment => \%row_alignment,
        totals => \%column_data,
    });

}

sub csv_gl_report { &generate_report }

sub gl_subtotal_tt {

    my %column_data;
    $subtotaldebit =
      $form->format_amount( \%myconfig, $subtotaldebit, 2, " " );
    $subtotalcredit =
      $form->format_amount( \%myconfig, $subtotalcredit, 2, " " );

    for (@column_index) { $column_data{$_} = " " }
    $column_data{class} = 'subtotal';

    $column_data{debit} = $subtotaldebit;
    $column_data{credit} = $subtotalcredit;

    $subtotaldebit  = 0;
    $subtotalcredit = 0;

    $sameitem = $ref->{ $form->{sort} };

    return \%column_data;
}

sub gl_subtotal {

    $subtotaldebit =
      $form->format_amount( \%myconfig, $subtotaldebit, 2, "&nbsp;" );
    $subtotalcredit =
      $form->format_amount( \%myconfig, $subtotalcredit, 2, "&nbsp;" );

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{debit} =
      "<th align=right class=listsubtotal>$subtotaldebit</td>";
    $column_data{credit} =
      "<th align=right class=listsubtotal>$subtotalcredit</td>";

    print "<tr class=listsubtotal>";
    for (@column_index) { print "$column_data{$_}\n" }
    print "</tr>";

    $subtotaldebit  = 0;
    $subtotalcredit = 0;

    $sameitem = $ref->{ $form->{sort} };

}

sub update {

    if ( $form->{transdate} ne $form->{oldtransdate} ) {
        if ( $form->{selectprojectnumber} ) {
            $form->all_projects( \%myconfig, undef, $form->{transdate} );
            if ( @{ $form->{all_project} } ) {
                $form->{selectprojectnumber} = "<option>\n";
                for ( @{ $form->{all_project} } ) {
                    $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
                }
                $form->{selectprojectnumber} =
                  $form->escape( $form->{selectprojectnumber}, 1 );
            }
        }
        $form->{oldtransdate} = $form->{transdate};
    }

    @a     = ();
    $count = 0;
    @flds  = qw(accno debit credit projectnumber fx_transaction source memo);

    for $i ( 1 .. $form->{rowcount} ) {
        unless ( ( $form->{"debit_$i"} eq "" )
            && ( $form->{"credit_$i"} eq "" ) )
        {
            for (qw(debit credit)) {
                $form->{"${_}_$i"} =
                  $form->parse_amount( \%myconfig, $form->{"${_}_$i"} );
            }

            push @a, {};
            $j = $#a;

            for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
            $count++;
        }
    }

    for $i ( 1 .. $count ) {
        $j = $i - 1;
        for (@flds) { $form->{"${_}_$i"} = $a[$j]->{$_} }
    }

    for $i ( $count + 1 .. $form->{rowcount} ) {
        for (@flds) { delete $form->{"${_}_$i"} }
    }

    $form->{rowcount} = $count + 1;

    &display_form;

}

sub display_form {
    my ($init) = @_;

    &form_header;
    &display_rows($init);
    &form_footer;

}

sub display_rows {
    my ($init) = @_;

    $form->{selectprojectnumber} =
      $form->unescape( $form->{selectprojectnumber} )
      if $form->{selectprojectnumber};

    $form->{totaldebit}  = 0;
    $form->{totalcredit} = 0;

    for $i ( 1 .. $form->{rowcount} ) {

        $source = qq|
    <td><input name="source_$i" size=10 value="$form->{"source_$i"}"></td>|;
        $memo = qq|
    <td><input name="memo_$i" value="$form->{"memo_$i"}"></td>|;

        if ($init) {
            $accno = qq|
      <td><select name="accno_$i">$form->{selectaccno}</select></td>|;

            if ( $form->{selectprojectnumber} ) {
                $project = qq|
    <td><select name="projectnumber_$i">$form->{selectprojectnumber}</select></td>|;
            }

            if ( $form->{transfer} ) {
                $fx_transaction = qq|
        <td><input name="fx_transaction_$i" class=checkbox type=checkbox value=1></td>
    |;
            }

        }
        else {

            $form->{totaldebit}  += $form->{"debit_$i"};
            $form->{totalcredit} += $form->{"credit_$i"};

            for (qw(debit credit)) {
                $form->{"${_}_$i"} =
                  ( $form->{"${_}_$i"} )
                  ? $form->format_amount( \%myconfig, $form->{"${_}_$i"}, 2 )
                  : "";
            }

            if ( $i < $form->{rowcount} ) {

                $accno = qq|<td>$form->{"accno_$i"}</td>|;

                if ( $form->{selectprojectnumber} ) {
                    $form->{"projectnumber_$i"} = ""
                      if $form->{selectprojectnumber} !~
                      /$form->{"projectnumber_$i"}/;

                    $project = $form->{"projectnumber_$i"};
                    $project =~ s/--.*//;
                    $project = qq|<td>$project</td>|;
                }

                if ( $form->{transfer} ) {
                    $checked = ( $form->{"fx_transaction_$i"} ) ? "1" : "";
                    $x = ($checked) ? "x" : "";
                    $fx_transaction = qq|
      <td><input type=hidden name="fx_transaction_$i" value="$checked">$x</td>
    |;
                }

                $form->hide_form( "accno_$i", "projectnumber_$i" );

            }
            else {

                $accno = qq|
      <td><select name="accno_$i">$form->{selectaccno}</select></td>|;

                if ( $form->{selectprojectnumber} ) {
                    $project = qq|
      <td><select name="projectnumber_$i">$form->{selectprojectnumber}</select></td>|;
                }

                if ( $form->{transfer} ) {
                    $fx_transaction = qq|
      <td><input name="fx_transaction_$i" class=checkbox type=checkbox value=1></td>
    |;
                }
            }
        }

        print qq|<tr valign=top>
    $accno
    $fx_transaction
    <td><input name="debit_$i" size=12 value="$form->{"debit_$i"}" accesskey=$i></td>
    <td><input name="credit_$i" size=12 value=$form->{"credit_$i"}></td>
    $source
    $memo
    $project
  </tr>

  |;
    }

    $form->hide_form(qw(rowcount selectaccno pos_adjust));

    print qq|
<input type=hidden name=selectprojectnumber value="|
      . $form->escape( $form->{selectprojectnumber}, 1 ) . qq|">|;

}

sub form_header {

    $title = $form->{title};
    if ( $form->{transfer} ) {
        $form->{title} = $locale->text("$title Cash Transfer Transaction");
    }
    else {
        $form->{title} = $locale->text("$title General Ledger Transaction");
    }

    # $locale->text('Add Cash Transfer Transaction')
    # $locale->text('Edit Cash Transfer Transaction')
    # $locale->text('Add General Ledger Transaction')
    # $locale->text('Edit General Ledger Transaction')

    $form->{selectdepartment} = $form->unescape( $form->{selectdepartment} );
    $form->{selectdepartment} =~ s/ selected//;
    $form->{selectdepartment} =~
      s/(<option value="\Q$form->{department}\E")/$1 selected/;

    for (qw(reference description notes)) {
        $form->{$_} = $form->quote( $form->{$_} );
    }

    if ( ( $rows = $form->numtextrows( $form->{description}, 50 ) ) > 1 ) {
        $description =
qq|<textarea name=description rows=$rows cols=50 wrap=soft>$form->{description}</textarea>|;
    }
    else {
        $description =
          qq|<input name=description size=50 value="$form->{description}">|;
    }

    if ( ( $rows = $form->numtextrows( $form->{notes}, 50 ) ) > 1 ) {
        $notes =
qq|<textarea name=notes rows=$rows cols=50 wrap=soft>$form->{notes}</textarea>|;
    }
    else {
        $notes = qq|<input name=notes size=50 value="$form->{notes}">|;
    }

    $department = qq|
        <tr>
	  <th align=right nowrap>| . $locale->text('Department') . qq|</th>
	  <td><select name=department>$form->{selectdepartment}</select></td>
	  <input type=hidden name=selectdepartment value="|
      . $form->escape( $form->{selectdepartment}, 1 ) . qq|">
	</tr>
| if $form->{selectdepartment};

    $project = qq| 
	  <th class=listheading>| . $locale->text('Project') . qq|</th>
| if $form->{selectprojectnumber};

    if ( $form->{transfer} ) {
        $fx_transaction = qq|
	  <th class=listheading>| . $locale->text('FX') . qq|</th>
|;
    }

    $focus = ( $form->{focus} ) ? $form->{focus} : "debit_$form->{rowcount}";

    $form->header;

    print qq|
<body onload="document.forms[0].${focus}.focus()" />

<form method=post action=$form->{script}>
|;

    $form->hide_form(
        qw(id transfer selectaccno closedto locked oldtransdate recurring));

    print qq|
<input type=hidden name=title value="$title">

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <th align=right>| . $locale->text('Reference') . qq|</th>
	  <td><input name=reference size=20 value="$form->{reference}"></td>
	  <th align=right>| . $locale->text('Date') . qq|</th>
	  <td><input class="date" name=transdate size=11 title="$myconfig{dateformat}" value=$form->{transdate}></td>
	</tr>
	$department
	<tr>
	  <th align=right>| . $locale->text('Description') . qq|</th>
	  <td colspan=3>$description</td>
	</tr>
	<tr>
	  <th align=right>| . $locale->text('Notes') . qq|</th>
	  <td colspan=3>$notes</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
	  <th class=listheading>| . $locale->text('Account') . qq|</th>
	  $fx_transaction
	  <th class=listheading>| . $locale->text('Debit') . qq|</th>
	  <th class=listheading>| . $locale->text('Credit') . qq|</th>
	  <th class=listheading>| . $locale->text('Source') . qq|</th>
	  <th class=listheading>| . $locale->text('Memo') . qq|</th>
	  $project
	</tr>
|;

}

sub form_footer {

    for (qw(totaldebit totalcredit)) {
        $form->{$_} =
          $form->format_amount( \%myconfig, $form->{$_}, 2, "&nbsp;" );
    }

    $project = qq|
	  <th>&nbsp;</th>
| if $form->{selectprojectnumber};

    if ( $form->{transfer} ) {
        $fx_transaction = qq|
	  <th>&nbsp;</th>
|;
    }

    print qq|
        <tr class=listtotal>
	  <th>&nbsp;</th>
	  $fx_transaction
	  <th class=listtotal align=right>$form->{totaldebit}</th>
	  <th class=listtotal align=right>$form->{totalcredit}</th>
	  <th>&nbsp;</th>
	  <th>&nbsp;</th>
	  $project
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>
|;

    $form->hide_form(qw(path login sessionid callback));

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    # type=submit $locale->text('Update')
    # type=submit $locale->text('Post')
    # type=submit $locale->text('Schedule')
    # type=submit $locale->text('Post as new')
    # type=submit $locale->text('Delete')

    if ( !$form->{readonly} ) {

        %button = (
            'update' =>
              { ndx => 1, key => 'U', value => $locale->text('Update') },
            'post' => { ndx => 3, key => 'O', value => $locale->text('Post') },
            'post_as_new' =>
              { ndx => 6, key => 'N', value => $locale->text('Post as new') },
            'schedule' =>
              { ndx => 7, key => 'H', value => $locale->text('Schedule') },
            'delete' =>
              { ndx => 8, key => 'D', value => $locale->text('Delete') },
        );

        %a = ();

        if ( $form->{id} ) {
            for ( 'update', 'post_as_new', 'schedule' ) { $a{$_} = 1 }

            if ( !$form->{locked} ) {
                if ( $transdate > $closedto ) {
                    for ( 'post', 'delete' ) { $a{$_} = 1 }
                }
            }

        }
        else {
            if ( $transdate > $closedto ) {
                for ( "update", "post", "schedule" ) { $a{$_} = 1 }
            }
        }

        for ( keys %button ) { delete $button{$_} if !$a{$_} }
        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            $form->print_button( \%button, $_ );
        }

    }

    if ( $form->{recurring} ) {
        print qq|<div align=right>| . $locale->text('Scheduled') . qq|</div>|;
    }

    if ( $form->{lynx} ) {
        require "bin/menu.pl";
        &menubar;
    }

    print qq|
  </form>

</body>
</html>
|;

}

sub delete {

    my %hiddens;
    delete $form->{action};
    foreach (keys %$form) {
        $hiddens{$_} = $form->{$_} unless ref $form->{$_};
    }

    $form->{title} = $locale->text('Confirm!');
    my $query = $locale->text(
        'Are you sure you want to delete Transaction [_1]',
        $form->{reference} )

    my @buttons = ({
        name => 'action',
        value => 'delete_transaction',
        text => $locale->text('Yes'),
        });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-confirmation',
        );
    $template->render({
        form => $form,
        query => $query,
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub delete_transaction {

    if ( GL->delete_transaction( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Transaction deleted!') );
    }
    else {
        $form->error( $locale->text('Cannot delete transaction!') );
    }

}

sub post {

    $form->isblank( "transdate", $locale->text('Transaction Date missing!') );

    $transdate = $form->datetonum( \%myconfig, $form->{transdate} );
    $closedto  = $form->datetonum( \%myconfig, $form->{closedto} );

    $form->error(
        $locale->text('Cannot post transaction for a closed period!') )
      if ( $transdate <= $closedto );

    # add up debits and credits
    for $i ( 1 .. $form->{rowcount} ) {
        $dr = $form->parse_amount( \%myconfig, $form->{"debit_$i"} );
        $cr = $form->parse_amount( \%myconfig, $form->{"credit_$i"} );

        if ( $dr && $cr ) {
            $form->error(
                $locale->text(
'Cannot post transaction with a debit and credit entry for the same account!'
                )
            );
        }
        $debit  += $dr;
        $credit += $cr;
    }

    if ( $form->round_amount( $debit, 2 ) != $form->round_amount( $credit, 2 ) )
    {
        $form->error( $locale->text('Out of balance transaction!') );
    }

    if ( !$form->{repost} ) {
        if ( $form->{id} ) {
            &repost;
            exit;
        }
    }

    if ( GL->post_transaction( \%myconfig, \%$form ) ) {
        $form->redirect( $locale->text('Transaction posted!') );
    }
    else {
        $form->error( $locale->text('Cannot post transaction!') );
    }

}

