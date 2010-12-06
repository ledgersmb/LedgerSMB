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
    my %hiddens;

    @column_index = qw(accno gifi_accno description debit credit);

    my $column_names = {
        accno => 'Account',
        gifi_accno => 'GIFI',
        description => 'Description',
        debit => 'Debit',
        credit => 'Credit'
    };

    $form->{title} = $locale->text('Chart of Accounts');
    $form->{callback} = 
      qq|$form->{script}?path=$form->{path}&action=chart_of_accounts&login=$form->{login}&sessionid=$form->{sessionid}|;
    $hiddens{callback} = $form->{callback};
    $hiddens{path} = $form->{path};
    $hiddens{action} = 'chart_of_accounts';
    $hiddens{login} = $form->{login};
    $hiddens{sessionid} = $form->{sessionid};

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
            $column_data{class} = 'heading';
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
        template => 'form-dynatable',
        format => ($form->{action} =~ /^csv/)? 'CSV': 'HTML');
        
    my $column_heading = $template->column_heading($column_names);
    
    $template->render({
        form => \%$form,
        buttons => \@buttons,
        hiddens => \%hiddens,
        columns => \@column_index,
        heading => $column_heading,
        totals => \%column_data,
        rows => \@rows,
        row_alignment => {'credit' => 'right', 'debit' => 'right'},
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
        push @{$selectdepartment->{options}}, {
	    value => '',
	    text => ''
	};
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
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig,
        locale => $locale,
        template => 'ca-list-selector');
    $template->render({
        form => $form,
	includes => \@includes,
	selectmonth => $selectmonth,
	selectyear => $selectyear,
	selectdepartment => $selectdepartment,
	intervals => $intervals,
    });
}

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

