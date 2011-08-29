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
# Copyright (C) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
#
#  Contributors:
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
# module for Chart of Accounts, Income Statement and Balance Sheet
# search and edit transactions posted by the GL, AR and AP
#
#======================================================================

use LedgerSMB::CA;

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

sub chart_of_accounts {

    CA->all_accounts( \%myconfig, \%$form );

    @column_index = qw(accno gifi_accno description debit credit);

    $column_header{accno} =
      qq|<th class="listtop">| . $locale->text('Account') . qq|</th>\n|;
    $column_header{gifi_accno} =
      qq|<th class="listtop">| . $locale->text('GIFI') . qq|</th>\n|;
    $column_header{description} =
      qq|<th class="listtop">| . $locale->text('Description') . qq|</th>\n|;
    $column_header{debit} =
      qq|<th class="listtop">| . $locale->text('Debit') . qq|</th>\n|;
    $column_header{credit} =
      qq|<th class="listtop">| . $locale->text('Credit') . qq|</th>\n|;

    $form->{title} = $locale->text('Chart of Accounts');

    $colspan = $#column_index + 1;

    $form->header;

    print qq|
<body>
  
<table border="0" width="100%">
  <tr><th class="listtop" colspan="$colspan">$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr class="listheading">|;

    for (@column_index) { print $column_header{$_} }

    print qq|
  </tr>
|;

    foreach $ca ( @{ $form->{CA} } ) {

        $description      = $form->escape( $ca->{description} );
        $gifi_description = $form->escape( $ca->{gifi_description} );

        $href =
qq|$form->{script}?path=$form->{path}&action=list&accno=$ca->{accno}&login=$form->{login}&sessionid=$form->{sessionid}&description=$description&gifi_accno=$ca->{gifi_accno}&gifi_description=$gifi_description|;

        if ( $ca->{charttype} eq "H" ) {
            print qq|<tr class=listheading>|;
            for (qw(accno description)) {
                $column_data{$_} = qq|<th class="listheading">$ca->{$_}</th>|;
            }
            $column_data{gifi_accno} =
              qq|<th class="listheading">$ca->{gifi_accno}&nbsp;</th>|;
        }
        else {
            $i++;
            $i %= 2;
            print qq|<tr class="listrow$i">|;
            $column_data{accno} = qq|<td><a href="$href">$ca->{accno}</a></td>|;
            $column_data{gifi_accno} =
qq|<td><a href="$href&accounttype=gifi">$ca->{gifi_accno}</a>&nbsp;</td>|;
            $column_data{description} = "<td>$ca->{description}</td>";
        }

        $column_data{debit} =
            '<td align="right">'
          . $form->format_amount( \%myconfig, $ca->{debit}, 2, "&nbsp;" )
          . "</td>\n";
        $column_data{credit} =
            '<td align="right">'
          . $form->format_amount( \%myconfig, $ca->{credit}, 2, "&nbsp;" )
          . "</td>\n";

        $totaldebit  += $ca->{debit};
        $totalcredit += $ca->{credit};

        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
</tr>
|;
    }

    for (qw(accno gifi_accno description)) {
        $column_data{$_} = "<td>&nbsp;</td>";
    }

    $column_data{debit} =
      '<th align="right" class="listtotal">'
      . $form->format_amount( \%myconfig, $totaldebit, 2, 0 ) . "</th>";
    $column_data{credit} =
      '<th align="right" class="listtotal">'
      . $form->format_amount( \%myconfig, $totalcredit, 2, 0 ) . "</th>";

    print '<tr class="listtotal">';

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
</tr>
<tr>
  <td colspan="$colspan"><hr size="3" noshade></td>
</tr>
</table>

</body>
</html>
|;

}

sub list {

    $form->{title} = $locale->text('List Transactions');
    if ( $form->{accounttype} eq 'gifi' ) {
        $form->{title} .= " - "
          . $locale->text('GIFI')
          . " $form->{gifi_accno} - $form->{gifi_description}";
    }
    else {
        $form->{title} .= " - "
          . $locale->text('Account')
          . " $form->{accno} - $form->{description}";
    }

    # get departments
    $form->all_departments( \%myconfig );
    if ( @{ $form->{all_department} } ) {
        $form->{selectdepartment} = "<option>\n";

        for ( @{ $form->{all_department} } ) {
            $form->{selectdepartment} .=
qq|<option value="$_->{description}--$_->{id}">$_->{description}\n|;
        }
    }

    $department = qq|
        <tr>
	  <th align="right" nowrap>| . $locale->text('Department') . qq|</th>
	  <td colspan="3"><select name="department">$form->{selectdepartment}</select></td>
	</tr>
| if $form->{selectdepartment};

    if ( @{ $form->{all_years} } ) {

        # accounting years
        $form->{selectaccountingyear} = "<option>\n";
        for ( @{ $form->{all_years} } ) {
            $form->{selectaccountingyear} .= qq|<option>$_\n|;
        }
        $form->{selectaccountingmonth} = "<option>\n";
        for ( sort keys %{ $form->{all_month} } ) {
            $form->{selectaccountingmonth} .=
              qq|<option value="$_">|
              . $locale->text( $form->{all_month}{$_} ) . qq|\n|;
        }

        $selectfrom = qq|
        <tr>
	<th align="right">| . $locale->text('Period') . qq|</th>
	<td colspan="3">
	<select name="month">$form->{selectaccountingmonth}</select>
	<select name="year">$form->{selectaccountingyear}</select>
	<input name="interval" class="radio" type="radio" value="0" checked>&nbsp;|
          . $locale->text('Current') . qq|
	<input name="interval" class="radio" type="radio" value="1">&nbsp;|
          . $locale->text('Month') . qq|
	<input name="interval" class="radio" type="radio" value="3">&nbsp;|
          . $locale->text('Quarter') . qq|
	<input name="interval" class="radio" type="radio" value="12">&nbsp;|
          . $locale->text('Year') . qq|
	</td>
      </tr>
|;
    }

    $form->header;

    print qq|
<body>

<form method="post" action="$form->{script}">

<input type="hidden" name="accno" value="$form->{accno}">
<input type="hidden" name="description" value="$form->{description}">

<input type="hidden" name="sort" value="transdate">
<input type="hidden" name="oldsort" value="transdate">

<input type="hidden" name="accounttype" value="$form->{accounttype}">
<input type="hidden" name="gifi_accno" value="$form->{gifi_accno}">
<input type="hidden" name="gifi_description" value="$form->{gifi_description}">

<table border="0" width="100%">
  <tr><th class="listtop">$form->{title}</th></tr>
  <tr height="5"></tr>
  <tr valign="top">
    <td>
      <table>
        $department
	<tr>
	  <th align="right">| . $locale->text('From') . qq|</th>
	  <td><input name="fromdate" size="11" title="$myconfig{dateformat}"></td>
	  <th align="right">| . $locale->text('To') . qq|</th>
	  <td><input name="todate" size="11" title="$myconfig{dateformat}"></td>
	</tr>
	$selectfrom
	<tr>
	  <th align="right">| . $locale->text('Include in Report') . qq|</th>
	  <td colspan="3">
	  <input name="l_accno" class="checkbox" type="checkbox" value="Y">&nbsp;|
      . $locale->text('AR/AP') . qq|
	  <input name="l_subtotal" class="checkbox" type="checkbox" value="Y">&nbsp;|
      . $locale->text('Subtotal') . qq|
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  <tr><td><hr size="3" noshade></td></tr>
</table>

<input type="hidden" name="login" value="$form->{login}">
<input type="hidden" name="path" value="$form->{path}">
<input type="hidden" name="sessionid" value="$form->{sessionid}">

<br><button class="submit" type="submit" name="action" value="list_transactions">|
      . $locale->text('List Transactions')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub list_transactions {

    CA->all_transactions( \%myconfig, \%$form );

    $department    = $form->escape( $form->{department} );
    $projectnumber = $form->escape( $form->{projectnumber} );
    $title         = $form->escape( $form->{title} );

    # construct href
    $href =
"$form->{script}?action=list_transactions&department=$department&projectnumber=$projectnumber&title=$title";
    for (
        qw(path oldsort accno login sessionid fromdate todate accounttype gifi_accno l_heading l_subtotal l_accno)
      )
    {
        $href .= "&$_=$form->{$_}";
    }

    $drilldown = $href;
    $drilldown .= "&sort=$form->{sort}";

    $href .= "&direction=$form->{direction}";

    $form->sort_order();

    $drilldown .= "&direction=$form->{direction}";

    $form->{prevreport} = $href unless $form->{prevreport};
    $href      .= "&prevreport=" . $form->escape( $form->{prevreport} );
    $drilldown .= "&prevreport=" . $form->escape( $form->{prevreport} );

    # figure out which column comes first
    $column_header{transdate} =
        qq|<th><a class="listheading" href="$href&sort=transdate">|
      . $locale->text('Date')
      . qq|</a></th>|;
    $column_header{reference} =
        qq|<th><a class="listheading" href="$href&sort=reference">|
      . $locale->text('Reference')
      . qq|</a></th>|;
    $column_header{description} =
        qq|<th><a class="listheadine" href="$href&sort=description">|
      . $locale->text('Description')
      . qq|</a></th>|;
    $column_header{cleared} =
      qq|<th class="listheading">| . $locale->text('R') . qq|</th>|;
    $column_header{source} =
      qq|<th class="listheading">| . $locale->text('Source') . qq|</th>|;
    $column_header{debit} =
      qq|<th class="listheading">| . $locale->text('Debit') . qq|</th>|;
    $column_header{credit} =
      qq|<th class="listheading">| . $locale->text('Credit') . qq|</th>|;
    $column_header{balance} =
      qq|<th class="listheading">| . $locale->text('Balance') . qq|</th>|;
    $column_header{accno} =
      qq|<th class="listheading">| . $locale->text('AR/AP') . qq|</th>|;

    @columns = qw(transdate reference description debit credit);
    if ( $form->{link} =~ /_paid/ ) {
        @columns =
          qw(transdate reference description source cleared debit credit);
    }
    push @columns, "accno" if $form->{l_accno};
    @column_index = $form->sort_columns(@columns);

    if ( $form->{accounttype} eq 'gifi' ) {
        for (qw(accno description)) { $form->{$_} = $form->{"gifi_$_"} }
    }
    if ( $form->{accno} ) {
        push @column_index, "balance";
    }

    $form->{title} =
      ( $form->{accounttype} eq 'gifi' )
      ? $locale->text('GIFI')
      : $locale->text('Account');

    $form->{title} .= " $form->{accno} - $form->{description}";

    if ( $form->{department} ) {
        ($department) = split /--/, $form->{department};
        $options = $locale->text('Department') . " : $department<br>";
    }
    if ( $form->{projectnumber} ) {
        ($projectnumber) = split /--/, $form->{projectnumber};
        $options .= $locale->text('Project Number') . " : $projectnumber<br>";
    }

    if ( $form->{fromdate} || $form->{todate} ) {

        if ( $form->{fromdate} ) {
            $fromdate = $locale->date( \%myconfig, $form->{fromdate}, 1 );
        }
        if ( $form->{todate} ) {
            $todate = $locale->date( \%myconfig, $form->{todate}, 1 );
        }

        $form->{period} = "$fromdate - $todate";
    }
    else {
        $form->{period} =
          $locale->date( \%myconfig, $form->current_date( \%myconfig ), 1 );
    }

    $form->{period} = qq|<a href="$form->{prevreport}">$form->{period}</a>|
      if $form->{prevreport};

    $options .= $form->{period};

    # construct callback
    $department         = $form->escape( $form->{department},    1 );
    $projectnumber      = $form->escape( $form->{projectnumber}, 1 );
    $title              = $form->escape( $form->{title},         1 );
    $form->{prevreport} = $form->escape( $form->{prevreport},    1 );

    $form->{callback} =
"$form->{script}?action=list_transactions&department=$department&projectnumber=$projectnumber&title=$title";
    for (
        qw(path direction oldsort accno login sessionid fromdate todate accounttype gifi_accno l_heading l_subtotal l_accno prevreport)
      )
    {
        $form->{callback} .= "&$_=$form->{$_}";
    }

    $form->header;

    print qq|
<body>

<table width="100%">
  <tr>
    <th class="listtop">$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$options</td>
  </tr>
  <tr>
    <td>
      <table width="100%">
       <tr class="listheading">
|;

    for (@column_index) { print "$column_header{$_}\n" }

    print qq|
       </tr>
|;

    # add sort to callback
    $form->{callback} =
      $form->escape( $form->{callback} . "&sort=$form->{sort}" );

    if ( @{ $form->{CA} } ) {
        $sameitem = $form->{CA}->[0]->{ $form->{sort} };
    }

    $ml = ( $form->{category} =~ /(A|E)/ ) ? -1 : 1;
    $ml *= -1 if $form->{contra};

    if ( $form->{accno} && $form->{balance} ) {

        for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

        $column_data{balance} =
            '<td align="right">'
          . $form->format_amount( \%myconfig, $form->{balance} * $ml, 2, 0 )
          . "</td>";

        $i++;
        $i %= 2;

        print qq|
        <tr class="listrow$i">
|;
        for (@column_index) { print "$column_data{$_}\n" }
        print qq|
       </tr>
|;

    }

    foreach $ca ( @{ $form->{CA} } ) {

        if ( $form->{l_subtotal} eq 'Y' ) {
            if ( $sameitem ne $ca->{ $form->{sort} } ) {
                &ca_subtotal;
            }
        }

        # construct link to source
        $href =
"<a href=$ca->{module}.pl?path=$form->{path}&action=edit&id=$ca->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}>$ca->{reference}</a>";

        $column_data{debit} =
            '<td align="right">'
          . $form->format_amount( \%myconfig, $ca->{debit}, 2, "&nbsp;" )
          . "</td>";
        $column_data{credit} =
            '<td align="right">'
          . $form->format_amount( \%myconfig, $ca->{credit}, 2, "&nbsp;" )
          . "</td>";

        $form->{balance} += $ca->{amount};
        $column_data{balance} =
            '<td align="right">'
          . $form->format_amount( \%myconfig, $form->{balance} * $ml, 2, 0 )
          . "</td>";

        $subtotaldebit  += $ca->{debit};
        $subtotalcredit += $ca->{credit};

        $totaldebit  += $ca->{debit};
        $totalcredit += $ca->{credit};

        $column_data{transdate}   = qq|<td>$ca->{transdate}</td>|;
        $column_data{reference}   = qq|<td>$href</td>|;
        $column_data{description} = qq|<td>$ca->{description}&nbsp;</td>|;

        $column_data{cleared} =
          ( $ca->{cleared} ) ? qq|<td>*</td>| : qq|<td>&nbsp;</td>|;
        $column_data{source} = qq|<td>$ca->{source}&nbsp;</td>|;

        $column_data{accno} = qq|<td>|;
        for ( @{ $ca->{accno} } ) {
            $column_data{accno} .= qq|<a href="$drilldown&accno=$_">$_</a> |;
        }
        $column_data{accno} .= qq|&nbsp;</td>|;

        if ( $ca->{id} != $sameid ) {
            $i++;
            $i %= 2;
        }
        $sameid = $ca->{id};

        print qq|
        <tr class="listrow$i">
|;

        for (@column_index) { print "$column_data{$_}\n" }

        print qq|
        </tr>
|;

    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        &ca_subtotal;
    }

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{debit} =
      qq|<th align="right" class="listtotal">|
      . $form->format_amount( \%myconfig, $totaldebit, 2, "&nbsp;" ) . "</th>";
    $column_data{credit} =
      qq|<th align="right" class="listtotal">|
      . $form->format_amount( \%myconfig, $totalcredit, 2, "&nbsp;" ) . "</th>";
    $column_data{balance} =
      qq|<th align="right" class="listtotal">|
      . $form->format_amount( \%myconfig, $form->{balance} * $ml, 2, 0 )
      . "</th>";

    print qq|
	<tr class="listtotal">
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size="3" noshade></td>
  </tr>
</table>

</body>
</html>
|;

}

sub ca_subtotal {

    for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }

    $column_data{debit} =
        qq|<th align="right" class="listsubtotal">|
      . $form->format_amount( \%myconfig, $subtotaldebit, 2, "&nbsp;" )
      . "</th>";
    $column_data{credit} =
        qq|<th align="right" class="listsubtotal">|
      . $form->format_amount( \%myconfig, $subtotalcredit, 2, "&nbsp;" )
      . "</th>";

    $subtotaldebit  = 0;
    $subtotalcredit = 0;

    $sameitem = $ca->{ $form->{sort} };

    print qq|
      <tr class="listsubtotal">
|;

    for (@column_index) { print "$column_data{$_}\n" }

    print qq|
      </tr>
|;

}

