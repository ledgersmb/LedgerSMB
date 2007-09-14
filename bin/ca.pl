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
use LedgerSMB::Template;

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

    $column_header{accno} = $locale->text('Account');
    $column_header{gifi_accno} = $locale->text('GIFI');
    $column_header{description} = $locale->text('Description');
    $column_header{debit} = $locale->text('Debit');
    $column_header{credit} = $locale->text('Credit');

    $form->{title} = $locale->text('Chart of Accounts');
    $form->{callback} = 
      qq|$form->{script}?path=$form->{path}&action=chart_of_accounts&login=$form->{login}&sessionid=$form->{sessionid}|;

    my @rows;
    my $totaldebit = 0;
    my $totalcredit = 0;
    foreach my $ca ( @{ $form->{CA} } ) {
        my %column_data;

        my $description      = $form->escape( $ca->{description} );
        my $gifi_description = $form->escape( $ca->{gifi_description} );

        my $href =
qq|$form->{script}?path=$form->{path}&action=list&accno=$ca->{accno}&login=$form->{login}&sessionid=$form->{sessionid}&description=$description&gifi_accno=$ca->{gifi_accno}&gifi_description=$gifi_description|;

        if ( $ca->{charttype} eq "H" ) {
            $column_data{heading} = 'H';
            for (qw(accno description)) {
                $column_data{$_} = $ca->{$_};
            }
            $column_data{gifi_accno} = $ca->{gifi_accno};
        }
        else {
            $i++;
            $i %= 2;
            $column_data{i} = $i;
            $column_data{accno} = {
                text => $ca->{accno},
                href => $href};
            $column_data{gifi_accno} = {
                text => $ca->{gifi_accno},
                href => "$href&accounttype=gifi"};
            $column_data{description} = $ca->{description};
        }

        $column_data{debit} =
          $form->format_amount( \%myconfig, $ca->{debit}, 2, " " );
        $column_data{credit} =
          $form->format_amount( \%myconfig, $ca->{credit}, 2, " " );

        $totaldebit  += $ca->{debit};
        $totalcredit += $ca->{credit};

	push @rows, \%column_data;
    }

    for (qw(accno gifi_accno description)) {
        $column_data{$_} = " ";
    }

    $column_data{debit} = $form->format_amount( \%myconfig, $totaldebit, 2, 0 );
    $column_data{credit} = $form->format_amount(\%myconfig, $totalcredit, 2, 0);

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'csv_chart_of_accounts',
        text => $locale->text('CSV Report'),
        type => 'submit',
        class => 'submit',
    };

    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale,
        path => 'UI',
        template => 'am-list-accounts',
        format => ($form->{action} =~ /^csv/)? 'CSV': 'HTML');
    $template->render({
        form => \%$form,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
	totals => \%column_data,
        rows => \@rows,
    });
}

sub csv_chart_of_accounts { &chart_of_accounts }

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
    my $selectdepartment;
    if ( @{ $form->{all_department} } ) {
        $selectdepartment = {name => 'department', options => []};
        for ( @{ $form->{all_department} } ) {
            push @{$selectdepartment->{options}}, {
                value => "$_->{description}--$_->{id}",
                text => $_->{description}};
        }
    }

    my $selectmonth;
    my $selectyear;
    my $interval;
    if ( @{ $form->{all_years} } ) {

        # accounting years
        $selectyear = {name => 'year', options => []};
        for ( @{ $form->{all_years} } ) {
            push @{$selectyear->{options}}, {value => $_, text => $_};
        }
        
        $selectmonth = {name => 'month', options => []};
        for ( sort keys %{ $form->{all_month} } ) {
            push @{$selectmonth->{options}}, {value => $_,
                text => $locale->text($form->{all_month}{$_})};
        }
        $intervals = [
            {type => 'radio', name => 'interval', value => '0',
              checked => 'checked', text => $locale->text('Current')},
            {type => 'radio', name => 'interval', value => '1',
              text => $locale->text('Month')},
            {type => 'radio', name => 'interval', value => '3', 
              text => $locale->text('Quarter')},
            {type => 'radio', name => 'interval', value => '12', 
              text => $locale->text('Year')}];
    }

    my @includes = ({
        type => 'checkbox',
        name => 'l_accno',
        value => 'Y',
        text => $locale->text('AR/AP'),
    },{
        type => 'checkbox',
        name => 'l_subtotal',
        value => 'Y',
        text => $locale->text('Subtotal'),
    });
    $form->{sort} ||= ''; #SC: blah.  Find out why this breaks when undef
    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale,
        path => 'UI',
        template => 'ca-list-selector',
        format => 'HTML');
    $template->render({
        form => $form,
	includes => \@includes,
	selectmonth => $selectmonth,
	selectyear => $selectyear,
	selectdepartment => $selectdepartment,
	intervals => $intervals,
    });
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
    $column_header{transdate} = {
        text => $locale->text('Date'),
        href => "$href&sort=transdate"};
    $column_header{reference} = {
        text => $locale->text('Reference'),
        href => "$href&sort=reference"};
    $column_header{description} = {
        text => $locale->text('Description'),
        href => "$href&sort=description"};
    $column_header{cleared} = $locale->text('R');
    $column_header{source} = $locale->text('Source');
    $column_header{debit} = $locale->text('Debit');
    $column_header{credit} = $locale->text('Credit');
    $column_header{balance} = $locale->text('Balance');
    $column_header{accno} = $locale->text('AR/AP');

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

    my @options;
    if ( $form->{department} ) {
        ($department) = split /--/, $form->{department};
        push @options, $locale->text('Department') . " : $department";
    }
    if ( $form->{projectnumber} ) {
        ($projectnumber) = split /--/, $form->{projectnumber};
        push @options, $locale->text('Project Number') . " : $projectnumber";
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

    if ($form->{prevreport}) {
        push @options, {text => $form->{period}, href=> $form->{prevreport}};
        $form->{period} = "<a href=$form->{prevreport}>$form->{period}</a>";
    }


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

    # add sort to callback
    $form->{callback} =
      $form->escape( $form->{callback} . "&sort=$form->{sort}" );

    my @rows;
    if ( @{ $form->{CA} } ) {
        $sameitem = $form->{CA}->[0]->{ $form->{sort} };
    }

    $ml = ( $form->{category} =~ /(A|E)/ ) ? -1 : 1;
    $ml *= -1 if $form->{contra};

    if ( $form->{accno} && $form->{balance} ) {
        my %column_data;

        for (@column_index) { $column_data{$_} = " " }

        $column_data{balance} =
          $form->format_amount( \%myconfig, $form->{balance} * $ml, 2, 0 );

        $i++;
        $i %= 2;

        $column_data{i} = $i;
        push @rows, \%column_data;

    }

    foreach my $ca ( @{ $form->{CA} } ) {
        my %column_data;

        if ( $form->{l_subtotal} eq 'Y' ) {
            if ( $sameitem ne $ca->{ $form->{sort} } ) {
                push @rows, &ca_subtotal;
            }
        }

        $column_data{debit} =
          $form->format_amount( \%myconfig, $ca->{debit}, 2, " " );
        $column_data{credit} =
          $form->format_amount( \%myconfig, $ca->{credit}, 2, " " );

        $form->{balance} += $ca->{amount};
        $column_data{balance} =
          $form->format_amount( \%myconfig, $form->{balance} * $ml, 2, 0 );

        $subtotaldebit  += $ca->{debit};
        $subtotalcredit += $ca->{credit};

        $totaldebit  += $ca->{debit};
        $totalcredit += $ca->{credit};

        $column_data{transdate}   = $ca->{transdate};
        $column_data{reference}   = {
            text => $ca->{reference},
            href => "$ca->{module}.pl?path=$form->{path}&action=edit&id=$ca->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}"};

        $column_data{description} = $ca->{description};

        $column_data{cleared} =
          ( $ca->{cleared} ) ? "*" : " ";
        $column_data{source} = $ca->{source};

        $column_data{accno} = [];
        for ( @{ $ca->{accno} } ) {
            push @{$column_data{accno}}, {text => $_, href=> "$drilldown&accno=$_>"};
        }

        if ( $ca->{id} != $sameid ) {
            $i++;
            $i %= 2;
        }
        $sameid = $ca->{id};

        $column_data{i} = $i;
        push @rows, \%column_data;

    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        push @rows, &ca_subtotal;
    }

    for (@column_index) { $column_data{$_} = " " }

    $column_data{debit} =
      $form->format_amount( \%myconfig, $totaldebit, 2, " " );
    $column_data{credit} =
      $form->format_amount( \%myconfig, $totalcredit, 2, " " );
    $column_data{balance} =
      $form->format_amount( \%myconfig, $form->{balance} * $ml, 2, 0 );

    my @buttons;
    push @buttons, {
        name => 'action',
        value => 'csv_list_transactions',
        text => $locale->text('CSV Report'),
        type => 'submit',
        class => 'submit',
    };

    $form->{callback} = $form->unescape($form->{callback});
    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale,
        path => 'UI',
        template => 'ca-list-transactions',
        format => ($form->{action} =~ /^csv/)? 'CSV': 'HTML');
    $template->render({
        form => \%$form,
        options => \@options,
        buttons => \@buttons,
        columns => \@column_index,
        heading => \%column_header,
	totals => \%column_data,
        rows => \@rows,
    });
}

sub csv_list_transactions { &list_transactions }

sub ca_subtotal {

    my %column_data;
    for (@column_index) { $column_data{$_} = " " }

    $column_data{debit} =
      $form->format_amount( \%myconfig, $subtotaldebit, 2, " " );
    $column_data{credit} =
      $form->format_amount( \%myconfig, $subtotalcredit, 2, " " );

    $subtotaldebit  = 0;
    $subtotalcredit = 0;

    $sameitem = $ca->{ $form->{sort} };
    $column_data{is_subtotal} = 1;

    return \%column_data;
}

