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
#  Contributors: Antonio Gallardo <agssa@ibw.com.ni>
#                Benjamin Lee <benjaminlee@consultant.com>
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
# module for preparing Income Statement and Balance Sheet
#
#======================================================================

package lsmb_legacy;
use Error qw(:try);

require "bin/arap.pl";

use LedgerSMB::Template;
use LedgerSMB::PE;
use LedgerSMB::RP;
use LedgerSMB::Company_Config;

1;

# end of main

=item init_company_config

Sets $form->{company} and $form->{address} for income statement and balance 
statement

=cut

sub init_company_config {
   my ($form) = @_;
   $cconfig = LedgerSMB::Company_Config->new();
   $cconfig->merge($form);
   $cconfig->initialize;
   $form->{company} = $LedgerSMB::Company_Config::settings->{company_name};
   $form->{address} = $LedgerSMB::Company_Config::settings->{company_address};
}



sub report {
    my %hiddens;
    my %report = (
        balance_sheet    => { title => 'Balance Sheet' },
        income_statement => { title => 'Income Statement' },
        receipts             => { title => 'Receipts', vc => 'customer' },
        payments             => { title => 'Payments' },
        projects             => { title => 'Project Transactions' },
        inv_activity         => { title => 'Inventory Activity' },
    );

    $form->{title} = $locale->text( $report{ $form->{report} }->{title} );

    my $gifi = 1;

    # get departments
    if ( ref $form->{all_department} eq 'ARRAY' ) {
        $form->{selectdepartment} = {
            name => 'department',
            options => [{value => '', text => ''}],
            };
       push @{$form->{selectdepartment}{options}}, {
           value => "$_->{description}--$_->{id}",
           text => $_->{description},
           } foreach @{$form->{all_department}};
    }

    if (ref $form->{all_years} eq 'ARRAY') {

        # accounting years
        $form->{selectaccountingyear} = {
            name => 'fromyear',
            options => [{text => '', value => ''}],
            };
        push @{$form->{selectaccountingyear}{options}}, {
            text => $_,
            value => $_,
            } foreach ( @{ $form->{all_years} } );

        $form->{selectaccountingmonth} = {
            name => 'frommonth',
            options => [{text => '', value => ''}],
            };
        push @{$form->{selectaccountingmonth}{options}}, {
            text => $locale->text( $form->{all_month}{$_} ),
            value => $_,
            } foreach ( sort keys %{ $form->{all_month} } );
    }

    # get projects
    if (ref $form->{all_project} eq 'ARRAY') {
        $form->{selectproject} = {
            name => 'projectnumber',
            options => [{text => '', value => ''}],
            };
        push @{$form->{selectproject}{options}}, {
            text => $_->{projectnumber},
            value => "$_->{projectnumber}--$_->{id}",
            } foreach ( @{ $form->{all_project} } );
    }

    $hiddens{title} = $form->{title};

    my $subform;
    if ( $form->{report} eq "projects" ) {
        $hiddens{nextsub} = 'generate_projects';
        $subform = 'projects';
    } elsif ( $form->{report} eq "inv_activity" ) {
        $gifi = 0;
        $hiddens{nextsub} = 'generate_inv_activity';
        $subform = 'generate_inv_activity';
    } elsif ( $form->{report} eq "balance_sheet" ) {
        $hiddens{nextsub} = 'generate_balance_sheet';
        $subform = 'generate_balance_sheet';
    }

    #$form->{login} = 'test';TODO meaning?
    $hiddens{$_} = $form->{$_} foreach qw(path login sessionid);
    $form->{yearend_options} = [
         {id => 'all',  label => $locale->text('All') }, 
         {id => 'last', label => $locale->text('Last Only') }, 
         {id => 'none', label => $locale->text('None') }, 
    ];
    $form->{ignore_yearend} = 'none';

##SC: Temporary commenting
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }
    my @buttons = ({
        name => 'action',
        value => 'continue',
        text => $locale->text('Continue'),
        });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'rp-search',
        );
    $template->render({
        user => \%myconfig,
        form => $form,
        subform => $subform,
        hiddens => \%hiddens,
        options => \@options,
        buttons => \@buttons,
        gifi => $gifi,
    });

}

sub continue { &{ $form->{nextsub} } }

sub generate_balance_sheet {
    init_company_config($form);
    RP->balance_sheet( \%myconfig, \%$form );

    $form->{asofdate} = $form->current_date( \%myconfig )
      unless $form->{asofdate};
    $form->{period} =
      $locale->date( \%myconfig, $form->current_date( \%myconfig ), 1 );

    ( $form->{department} ) = split /--/, $form->{department};

    # define Current Earnings account
    push(
        @{ $form->{equity_account} }, {
            current_earnings => 1,
            text => $locale->text('Current Earnings')
            },
    );

    $form->{this_period} = $locale->date( \%myconfig, $form->{asofdate}, 0 );
    $form->{last_period} =
      $locale->date( \%myconfig, $form->{compareasofdate}, 0 );

    # setup company variables for the form
    for (qw(nativecurr login)) {
        $form->{$_} = $myconfig{$_};
    }
    ##SC: The escaped form will be converted in-template
    $form->{address} =~ s/\\n/<br>/g;

    $form->{templates} = $myconfig{templates};

    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale, 
        template => 'balance_sheet',
        format => $form->{format}? uc $form->{format}: 'HTML',
        no_auto_output => 1,
        );
    try {
        $template->render($form);
        $template->output(%{$form});
    }
    catch Error::Simple with {
        my $E = shift;
        $form->error( $E->stacktrace );
    };
}

sub csv_generate_projects { &generate_projects }
sub xls_generate_projects { &generate_projects }
sub ods_generate_projects { &generate_projects }

sub list_accounts {

    $title = $form->escape( $form->{title} );
    my %hiddens = (
        path => $form->{path},
        sessionid => $form->{sessionid},
        login => $form->{login},
        accounttype => $form->{accounttype},
        fromdate => $form->{fromdate},
        todate => $form->{todate},
        l_heading => $form->{l_heading},
        l_subtotal => $form->{l_subtotal},
        all_accounts => $form->{all_accounts},
        department => $form->{department},
        projectnumber => $form->{projectnumber},
        project_id => $form->{project_id},
        ignore_yearend => $form->{ignore_yearend},
    );

    my @options;
    if ( $form->{department} ) {
        ($department) = split /--/, $form->{department};
        push @options, $locale->text('Department: [_1]', $department);
        $department = $form->escape( $form->{department} );
    }
    if ( $form->{projectnumber} ) {
        ($projectnumber, $project_id) = split /--/, $form->{projectnumber};
        push @options, $locale->text('Project Number: [_1]', $projectnumber);
        $projectnumber = $form->escape( $form->{projectnumber} );
    }

    # if there are any dates
    if ( $form->{fromdate} || $form->{todate} ) {

        if ( $form->{fromdate} ) {
            $fromdate = $locale->date( \%myconfig, $form->{fromdate}, 1 );
        }
        if ( $form->{todate} ) {
            $todate = $locale->date( \%myconfig, $form->{todate}, 1 );
        }

        $form->{period} = "$fromdate - $todate";
    } else {
        $form->{period} =
          $locale->date( \%myconfig, $form->current_date( \%myconfig ), 1 );

    }
    push @options, $form->{period};

    my @column_index = qw(accno description begbalance debit credit endbalance);

    my $column_names = {
        accno => 'Account',
        description => 'Description',
        debit => 'Debit',
        credit => 'Credit',
        begbalance => 'Balance',
        endbalance => 'Balance'
    };

    if ( $form->{accounttype} eq 'gifi' ) {
        $column_names->{accno} = 'GIFI';
    }

    # sort the whole thing by account numbers and display
    my @rows;
    foreach $ref ( sort { $a->{accno} cmp $b->{accno} } @{ $form->{TB} } ) {

        my %column_data;
        my $description = $form->escape( $ref->{description} );

	# gl.pl requires datefrom instead of fromdate, etc.  We will get this
	# consistent.... eventually....  --CT
        my $href =
qq|gl.pl?path=$form->{path}&action=generate_report&accounttype=$form->{accounttype}&datefrom=$form->{fromdate}&dateto=$form->{todate}&sort=transdate&l_heading=$form->{l_heading}&l_subtotal=$form->{l_subtotal}&l_balance=Y&department=$department&projectnumber=$projectnumber&project_id=$project_id&title=$title&nextsub=$form->{nextsub}&prevreport=$form->{callback}&category=X&l_reference=Y&l_transdate=Y&l_description=Y&l_debit=Y&l_credit=Y|;

        if ( $form->{accounttype} eq 'gifi' ) {
            $href .= "&gifi_accno=$ref->{accno}&gifi_description=$description";
            $na = $locale->text('N/A');
            if ( !$ref->{accno} ) {
                for (qw(accno description)) { $ref->{$_} = $na }
            }
        }
        else {
            $href .= "&accno=$ref->{accno}";
        }

        $ml = ( $ref->{category} =~ /(A|E)/ ) ? -1 : 1;
        $ml *= -1 if $ref->{contra};

        $debit = $form->format_amount( \%myconfig, $ref->{debit}, 2, " " );
        $credit =
          $form->format_amount( \%myconfig, $ref->{credit}, 2, " " );
        $begbalance =
          $form->format_amount( \%myconfig, $ref->{balance} * $ml, 2,
            " " );
        $endbalance =
          $form->format_amount( \%myconfig,
            ( $ref->{balance} + $ref->{amount} ) * $ml, 2, " " );
        if ( ($ref->{charttype} eq "H") && $subtotal && $form->{l_subtotal} ) {
            my %column_data;
            if ($subtotal) {

                for (qw(accno begbalance endbalance)) {
                    $column_data{$_} = " ";
                }

                $subtotalbegbalance =
                  $form->format_amount( \%myconfig, $subtotalbegbalance, 2,
                    " " );
                $subtotalendbalance =
                  $form->format_amount( \%myconfig, $subtotalendbalance, 2,
                    " " );
                $subtotaldebit =
                  $form->format_amount( \%myconfig, $subtotaldebit, 2,
                    " " );
                $subtotalcredit =
                  $form->format_amount( \%myconfig, $subtotalcredit, 2,
                    " " );

                $column_data{description} = $subtotaldescription;
                $column_data{begbalance} = $subtotalbegbalance;
                $column_data{endbalance} = $subtotalendbalance;
                $column_data{debit} = $subtotaldebit;
                $column_data{credit} = $subtotalcredit;
                $column_data{class} = 'subtotal';

                push @rows, \%column_data;
            }
        }

        if ( $ref->{charttype} eq "H" ) {
            $subtotal            = 1;
            $subtotaldescription = $ref->{description};
            $subtotaldebit       = $ref->{debit};
            $subtotalcredit      = $ref->{credit};
            $subtotalbegbalance  = 0;
            $subtotalendbalance  = 0;

            if ( $form->{l_heading} ) {
                if ( !$form->{all_accounts} and
                    ( $subtotaldebit + $subtotalcredit ) == 0 ) {
                    $subtotal = 0;
                    next;
                }
            } else {
                $subtotal = 0;
                if ( $form->{all_accounts} || ( $form->{l_subtotal} &&
                        ( ( $subtotaldebit + $subtotalcredit ) != 0 ) )) {
                    $subtotal = 1;
                }
                next;
            }

            for (qw(accno debit credit begbalance endbalance)) {
                $column_data{$_} = " ";
            }
            $column_data{description} = $ref->{description};
            $column_data{class} = 'heading';
        }

        if ( $ref->{charttype} eq "A" ) {
            $column_data{accno} = {text => $ref->{accno}, href => $href};
            $column_data{description} = $ref->{description};
            $column_data{debit}       = $debit;
            $column_data{credit}      = $credit;
            $column_data{begbalance}  = $begbalance;
            $column_data{endbalance}  = $endbalance;

            $totaldebit  += $ref->{debit};
            $totalcredit += $ref->{credit};

            $cml = ( $ref->{contra} ) ? -1 : 1;

            $subtotalbegbalance += $ref->{balance} * $ml * $cml;
            $subtotalendbalance +=
              ( $ref->{balance} + $ref->{amount} ) * $ml * $cml;

        }

        if ( $ref->{charttype} eq "H" ) {
            $column_data{class} = 'heading';
        }
        if ( $ref->{charttype} eq "A" ) {
            $i++;
            $i %= 2;
            $column_data{i} = $i;
        }

        push @rows, \%column_data;
    }

    # print last subtotal
    if ( $subtotal && $form->{l_subtotal} ) {
        my %column_data;
        for (qw(accno begbalance endbalance)) {
            $column_data{$_} = " ";
        }
        $subtotalbegbalance =
          $form->format_amount( \%myconfig, $subtotalbegbalance, 2, " " );
        $subtotalendbalance =
          $form->format_amount( \%myconfig, $subtotalendbalance, 2, " " );
        $subtotaldebit =
          $form->format_amount( \%myconfig, $subtotaldebit, 2, " " );
        $subtotalcredit =
          $form->format_amount( \%myconfig, $subtotalcredit, 2, " " );
        $column_data{description} = $subtotaldescription;
        $column_data{begbalance} = $subtotalbegbalance;
        $column_data{endbalance} = $subtotalendbalance;
        $column_data{debit} = $subtotaldebit;
        $column_data{credit} = $subtotalcredit;
        $column_data{class} = 'subtotal';

        push @rows, \%column_data;
    }

    my %column_data;

    $totaldebit = $form->format_amount( \%myconfig, $totaldebit, 2, " " );
    $totalcredit =
      $form->format_amount( \%myconfig, $totalcredit, 2, " " );

    for (qw(accno description begbalance endbalance)) {
        $column_data{$_} = "";
    }

    $column_data{debit} = $totaldebit;
    $column_data{credit} = $totalcredit;


    my %can_load;
    $can_load{CSV} = 1;
    $can_load{ODS} =  eval { require OpenOffice::OODoc };

    my @buttons;
    for my $type (qw(CSV ODS)) {
        push @buttons, {
            name => 'action',
            value => lc "${type}_$form->{nextsub}",
            text => $locale->text("[_1] Report", $type),
            type => 'submit',
            class => 'submit',
            disabled => $can_load{$type} ? "" : "disabled",
        };
    }
    my $format;
    if ($form->{action} eq 'continue') {
	$format = 'HTML';
    } else {
        $format = uc substr $form->{action}, 0, 3;
    	push @column_index, 'class';
        $column_header{class} = 'rowtype';
    }
    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-dynatable',
        path => 'UI',
        format => $format,
        );
    
    my $column_heading = $template->column_heading($column_names);    
    
    $template->render({
        form => $form,
        hiddens => \%hiddens,
        buttons => \@buttons,
        options => \@options,
        columns => \@column_index,
        heading => $column_heading,
        rows => \@rows,
        totals => \%column_data,
        row_alignment => {
            'credit' => 'right',
            'debit' => 'right',
            'begbalance' => 'right',
            'endbalance' => 'right'
            },
    });
}

1;
