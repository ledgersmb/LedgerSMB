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

use Error qw(:try);

require "bin/arap.pl";

use LedgerSMB::Template;
use LedgerSMB::PE;
use LedgerSMB::RP;

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

# $locale->text('Balance Sheet')
# $locale->text('Income Statement')
# $locale->text('Trial Balance')
# $locale->text('AR Aging')
# $locale->text('AP Aging')
# $locale->text('Tax collected')
# $locale->text('Tax paid')
# $locale->text('Receipts')
# $locale->text('Payments')
# $locale->text('Project Transactions')
# $locale->text('Non-taxable Sales')
# $locale->text('Non-taxable Purchases')

sub report {

    my %hiddens;
    my %report = (
        balance_sheet    => { title => 'Balance Sheet' },
        income_statement => { title => 'Income Statement' },
        trial_balance    => { title => 'Trial Balance' },
        ar_aging         => { title => 'AR Aging', vc => 'customer' },
        ap_aging         => { title => 'AP Aging', vc => 'vendor' },
        tax_collected    => { title => 'Tax collected', vc => 'customer' },
        tax_paid         => { title => 'Tax paid' },
        nontaxable_sales => { title => 'Non-taxable Sales', vc => 'customer' },
        nontaxable_purchases => { title => 'Non-taxable Purchases' },
        receipts             => { title => 'Receipts', vc => 'customer' },
        payments             => { title => 'Payments' },
        projects             => { title => 'Project Transactions' },
        inv_activity         => { title => 'Inventory Activity' },
    );

    $form->{title} = $locale->text( $report{ $form->{report} }->{title} );

    my $gifi = 1;

    # get departments
    $form->all_departments(\%myconfig, undef, $report{$form->{report}}->{vc});
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
    $form->all_projects( \%myconfig );
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
    } elsif ( $form->{report} eq "income_statement" ) {
        $hiddens{nextsub} = 'generate_income_statement';
        $subform = 'generate_income_statement';
    } elsif ( $form->{report} eq "balance_sheet" ) {
        $hiddens{nextsub} = 'generate_balance_sheet';
        $subform = 'generate_balance_sheet';
    } elsif ( $form->{report} eq "trial_balance" ) {
        $hiddens{nextsub} = 'generate_trial_balance';
        $subform = 'generate_trial_balance';
    } elsif ( $form->{report} =~ /^tax_/ ) {
        $gifi = 0;

        $form->{db} = ( $form->{report} =~ /_collected/ ) ? "ar" : "ap";

        RP->get_taxaccounts( \%myconfig, \%$form );

        $hiddens{nextsub} = 'generate_tax_report';
        $hiddens{db} = $form->{db};
        $hiddens{sort} = 'transdate';
        $subform = 'generate_tax_report';

        my $checked = "checked";
        $form->{taxaccountlist} = [];
        foreach $ref ( @{ $form->{taxaccounts} } ) {
            push @{$form->{taxaccountlist}}, {
                name => 'accno',
                type => 'radio',
                value => $ref->{accno},
                label => $ref->{description},
                $checked => $checked,
                };
            $hiddens{"$ref->{accno}_description"} = $ref->{description};
            $hiddens{"$ref->{accno}_rate"} = $ref->{rate};
            $checked = undef;
        }
        if (ref $form->{gifi_taxaccounts} eq 'ARRAY') {
            $form->{gifitaxaccountlist} = [];
            foreach $ref ( @{ $form->{gifi_taxaccounts} } ) {
                push @{$form->{taxaccountlist}}, {
                    name => 'accno',
                    type => 'radio',
                    value => "gifi_$ref->{accno}",
                    label => $ref->{description},
                    };
                $hiddens{"gifi_$ref->{accno}_description"} = $ref->{description};
                $hiddens{"gifi_$ref->{accno}_rate"} = $ref->{rate};
            }
        }
    } elsif ( $form->{report} =~ /^nontaxable_/ ) {
        $gifi = 0;

        $form->{db} = ( $form->{report} =~ /_sales/ ) ? "ar" : "ap";
        $hiddens{nextsub} = 'generate_tax_report';
        $hiddens{db} = $form->{db};
        $hiddens{sort} = 'transdate';
        $hiddens{report} = $form->{report};
        $subform = 'generate_tax_report';
    } elsif (   ( $form->{report} eq "ar_aging" )
        || ( $form->{report} eq "ap_aging" ) ) {
        $gifi = 0;
        $subform = 'aging';

        if ( $form->{report} eq 'ar_aging' ) {
            $label = $locale->text('Customer');
            $form->{vc} = 'customer';
            $form->{uvc} = 'Customer';
        }
        else {
            $label = $locale->text('Vendor');
            $form->{vc} = 'vendor';
            $form->{uvc} = 'Vendor';
        }

	$vc = {name => $form->{vc}, size => 35};
	$form->{vci} = {type => 'input', input => $vc};

        $hiddens{type} = 'statement';
        $hiddens{format} = 'ps' if $myconfig{printer};
	$hiddens{media} = $myconfig{printer};
        
	my $nextsub = "generate_$form->{report}";
	$hiddens{nextsub} = $nextsub;
	$hiddens{action} = $nextsub;
    } elsif ( $form->{report} =~ /(receipts|payments)$/ ) {
        $gifi = 0;
        $subform = 'payments';

        $form->{db} = ( $form->{report} =~ /payments$/ ) ? "ap" : "ar";

        RP->paymentaccounts( \%myconfig, \%$form );

        my $paymentaccounts = '';
        $form->{paymentaccounts} = {
            name => 'account',
            options => [{text => '', value => ''}],
            };
        foreach $ref ( @{ $form->{PR} } ) {
            $paymentaccounts .= "$ref->{accno} ";
            push @{$form->{paymentaccounts}{options}}, {
                text => "$ref->{accno}--$ref->{description}",
                value => "$ref->{accno}--$ref->{description}",
                };
        }

        chop $paymentaccounts;

        $hiddens{nextsub} = 'list_payments';
        $hiddens{paymentaccounts} = $paymentaccounts;
        $hiddens{db} = $form->{db};
        $hiddens{sort} = 'transdate';

    }

    $form->{login} = 'test';
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

sub generate_inv_activity {
    
    my %hiddens;
    my @options;
    my $title = $form->{title};

    RP->inventory_activity( \%myconfig, \%$form );

    #  if ($form->{department}) {
    #    ($department) = split /--/, $form->{department};
    #    $options = $locale->text('Department')." : $department<br>";
    #    $department = $form->escape($form->{department});
    #  }
##  if ($form->{projectnumber}) {
    #    ($projectnumber) = split /--/, $form->{projectnumber};
    #    $options .= $locale->text('Project Number')." : $projectnumber<br>";
    #    $projectnumber = $form->escape($form->{projectnumber});
    #  }

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

    my @column_index = qw(partnumber description sold revenue received expense);

    my $href =
qq|rp.pl?path=$form->{path}&action=continue&accounttype=$form->{accounttype}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&l_heading=$form->{l_heading}&l_subtotal=$form->{l_subtotal}&department=$department&projectnumber=$projectnumber&project_id=$form->{project_id}&title=$title&nextsub=$form->{nextsub}|;

    my $column_names = {
        partnumber => 'Part Number',
        description => 'Description',
        sold => 'Sold',
        revenue => 'Revenue',
        received => 'Received',
        expense => 'Expense'
        };
    my @sort_columns = @column_index;
    my $sort_href = "$href&sort_col";

    if ( $form->{sort_col} eq 'qty' || $form->{sort_col} eq 'revenue' ) {
        $form->{sort_type} = 'numeric';
    }
    my $i    = 0;
    my $cols = "l_transdate=Y&l_name=Y&l_invnumber=Y&summary=1";
    my $dates =
"transdatefrom=$form->{fromdate}&transdateto=$form->{todate}&year=$form->{fromyear}&month=$form->{frommonth}&interval=$form->{interval}";
    my $base =
      "path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}";

    $form->{callback} = "rp.pl?action=continue&$base";
    $form->{callback} = $form->escape( $form->{callback} );
    $callback         = "callback=$form->{callback}";

    # sort the whole thing by account numbers and display
    my @rows;
    foreach my $ref ( @{ $form->{TB} } ) {
        my $description = $form->escape( $ref->{description} );
        my %column_data;
        $i = $i % 2;
        $column_data{i} = $i;

        $pnumhref =
          "ic.pl?action=edit&id=$ref->{id}&$base&callback=$form->{callback}";
        $soldhref =
"ar.pl?action=transactions&partsid=$ref->{id}&$base&$cols&$dates&$callback";
        $rechref =
"ap.pl?action=transactions&partsid=$ref->{id}&$base&$cols&$dates&callback=$form->{callback}";

        $ml = ( $ref->{category} =~ /(A|E)/ ) ? -1 : 1;

        $debit = $form->format_amount( \%myconfig, $ref->{debit}, 2, " " );
        $credit =
          $form->format_amount( \%myconfig, $ref->{credit}, 2, " " );
        $begbalance =
          $form->format_amount( \%myconfig, $ref->{balance} * $ml, 2, " " );
        $endbalance =
          $form->format_amount( \%myconfig,
            ( $ref->{balance} + $ref->{amount} ) * $ml,
            2, " " );

        $column_data{partnumber} = {
            text => $ref->{partnumber},
            href => $pnumhref,
            };
        $column_data{sold} = {
            text => $ref->{sold},
            href => $soldhref,
            };
        $column_data{received} = {
            text => $ref->{received},
            href => $rechref,
            };

        push @rows, \%column_data;
        ++$i;
    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-dynatable',
        );
    
    my $column_heading = $template->column_heading($column_names,
        {href => $sort_href, columns => \@sort_columns}
    );
    
    $template->render({
        form => $form,
        hiddens => \%hiddens,
        options => \@options,
        columns => \@column_index,
        heading => $column_heading,
        rows => \@rows,
        row_alignment => {
            sold => 'right',
            revenue => 'right',
            received => 'right',
            expense => 'right',
            },
    });
}

sub generate_income_statement {

    RP->income_statement( \%myconfig, \%$form );

    ( $form->{department} )    = split /--/, $form->{department};
    ( $form->{projectnumber} ) = split /--/, $form->{projectnumber};

    $form->{period} =
      $locale->date( \%myconfig, $form->current_date( \%myconfig ), 1 );
    $form->{todate} = $form->current_date( \%myconfig ) unless $form->{todate};

    # if there are any dates construct a where
    unless ( $form->{todate} ) {
        $form->{todate} = $form->current_date( \%myconfig );
    }

    $longtodate  = $locale->date( \%myconfig, $form->{todate}, 1 );
    $shorttodate = $locale->date( \%myconfig, $form->{todate}, 0 );

    $longfromdate  = $locale->date( \%myconfig, $form->{fromdate}, 1 );
    $shortfromdate = $locale->date( \%myconfig, $form->{fromdate}, 0 );

    $form->{this_period_from} = $shortfromdate;
    $form->{this_period_to} = $shorttodate;
    # example output: 2006-01-01 To 2007-01-01
    $form->{period} = $locale->text('[_1] To [_2]', $longfromdate, $longtodate);

    if ( $form->{comparefromdate} || $form->{comparetodate} ) {
        $longcomparefromdate =
          $locale->date( \%myconfig, $form->{comparefromdate}, 1 );
        $shortcomparefromdate =
          $locale->date( \%myconfig, $form->{comparefromdate}, 0 );

        $longcomparetodate =
          $locale->date( \%myconfig, $form->{comparetodate}, 1 );
        $shortcomparetodate =
          $locale->date( \%myconfig, $form->{comparetodate}, 0 );

        $form->{last_period_from} = $shortcomparefromdate;
        $form->{last_period_to} = $shortcomparetodate;
        $form->{compare_period} = $locale->text('[_1] To [_2]',
            $longcomparefromdate, $longcomparetodate);
    }

    # setup variables for the form
    my @vars = qw(company address businessnumber);
    for (@vars) { $form->{$_} = $myconfig{$_} }
    ##SC: The escaped form will be converted in-template
    $form->{address} =~ s/\\n/<br>/g;


    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale, 
        template => 'income_statement',
        format => 'HTML',
	#no_escape => '1'
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

sub generate_balance_sheet {

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
    for (qw(company address businessnumber nativecurr login)) {
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

sub generate_projects {

    $form->{nextsub} = "generate_projects";
    $form->{title}   = $locale->text('Project Transactions');

    RP->trial_balance( \%myconfig, $form );

    &list_accounts;

}
sub csv_generate_projects { &generate_projects }
sub xls_generate_projects { &generate_projects }
sub ods_generate_projects { &generate_projects }

# Antonio Gallardo
#
# D.S. Feb 16, 2001
# included links to display transactions for period entered
# added headers and subtotals
#
sub generate_trial_balance {
    $form->{money_precision} = $form->{display_precision};
    # get for each account initial balance, debits and credits
    RP->trial_balance( \%myconfig, \%$form );

    $form->{nextsub} = "generate_trial_balance";
    $form->{title}   = $locale->text('Trial Balance');

    $form->{callback} = "$form->{script}?action=generate_trial_balance";
    for (
        qw(login path sessionid nextsub fromdate todate month year interval l_heading l_subtotal all_accounts accounttype title)
      )
    {
        $form->{callback} .= "&$_=$form->{$_}";
    }
    $form->{callback} = $form->escape( $form->{callback} );

    &list_accounts;

}
sub csv_generate_trial_balance { &generate_trial_balance }
sub xls_generate_trial_balance { &generate_trial_balance }
sub ods_generate_trial_balance { &generate_trial_balance }

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

    my @buttons;
    for my $type (qw(CSV XLS ODS)) {
        push @buttons, {
            name => 'action',
            value => lc "${type}_$form->{nextsub}",
            text => $locale->text("[_1] Report", $type),
            type => 'submit',
            class => 'submit',
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

sub generate_ar_aging {

    # split customer
    ( $form->{customer} ) = split( /--/, $form->{customer} );
    $customer = $form->escape( $form->{customer}, 1 );
    $title    = $form->escape( $form->{title},    1 );
    $media    = $form->escape( $form->{media},    1 );

    $form->{ct}   = "customer";
    $form->{arap} = "ar";

    RP->aging( \%myconfig, \%$form );

    $form->{callback} =
qq|$form->{script}?path=$form->{path}&action=generate_ar_aging&login=$form->{login}&sessionid=$form->{sessionid}&todate=$form->{todate}&customer=$customer&title=$title&type=$form->{type}&format=$form->{format}&media=$media&summary=$form->{summary}|;

    &aging;

}

sub csv_generate_ar_aging { &generate_ar_aging }

sub generate_ap_aging {

    # split vendor
    ( $form->{vendor} ) = split( /--/, $form->{vendor} );
    $vendor = $form->escape( $form->{vendor}, 1 );
    $title  = $form->escape( $form->{title},  1 );
    $media  = $form->escape( $form->{media},  1 );

    $form->{ct}   = "vendor";
    $form->{arap} = "ap";

    RP->aging( \%myconfig, \%$form );

    $form->{callback} =
qq|$form->{script}?path=$form->{path}&action=generate_ap_aging&login=$form->{login}&sessionid=$form->{sessionid}&todate=$form->{todate}&vendor=$vendor&title=$title&type=$form->{type}&format=$form->{format}&media=$media&summary=$form->{summary}|;

    &aging;

}

sub aging {

    my %hiddens;
    my @buttons;
    my @options;
    my %column_header;
    my @column_index;
    my %row_alignment;

    $column_header{statement} = ' ';
    $column_header{ct} = $locale->text( ucfirst $form->{ct} );
    $column_header{language} = $locale->text('Language');
    $column_header{invnumber} = $locale->text('Invoice');
    $column_header{ordnumber} = $locale->text('Order');
    $column_header{transdate} = $locale->text('Date');
    $column_header{duedate} = $locale->text('Due Date');
    $column_header{c0} = $locale->text('Current');
    $column_header{c30} = '30';
    $column_header{c60} = '60';
    $column_header{c90} = '90';
    $column_header{total} = $locale->text('Total');

    @column_index = qw(statement ct);

    if ( @{ $form->{all_language} } && $form->{arap} eq 'ar' ) {
        push @column_index, "language";
        $form->{language_options} = [{text => ' ', value => ''}];

        for ( @{ $form->{all_language} } ) {
            push @{$form->{language_options}},
              {text => $_->{description}, value => $_->{code}};
        }
    }

    my @c = ();
    for (qw(c0 c30 c60 c90)) {
        if ( $form->{$_} ) {
            push @c, $_;
            $form->{callback} .= "&$_=$form->{$_}";
        }
    }

    if ( !$form->{summary} ) {
        push @column_index, qw(invnumber ordnumber transdate duedate);
    }
    push @column_index, @c;
    push @column_index, "total";

    if ( $form->{overdue} ) {
        push @options, $locale->text('Aged Overdue');
        $form->{callback} .= "&overdue=$form->{overdue}";
    } else {
        push @options, $locale->text('Aged');
    }

    if ( $form->{department} ) {
        ($department) = split /--/, $form->{department};
        push @options, $locale->text('Department: [_1]', $department);
        $department = $form->escape( $form->{department}, 1 );
        $form->{callback} .= "&department=$department";
    }

    if ( $form->{arap} eq 'ar' ) {
        if ( $form->{customer} ) {
            push @options, $form->{customer};
        }
    }
    if ( $form->{arap} eq 'ap' ) {
        shift @column_index;
        if ( $form->{vendor} ) {
            push @options, $form->{vendor};
        }
    }

    $todate = $locale->date( \%myconfig, $form->{todate}, 1 );
    push @options, $locale->text('for Period To [_1]', $todate);

    $ctid = 0;
    $i    = 0;
    $k    = 0;
    $l    = $#{ $form->{AG} };

    my @currencies;
    foreach my $ref ( @{ $form->{AG} } ) {

        if ( $curr ne $ref->{curr} ) {
            my %column_data;
            $ctid = 0;
            for (@column_index) { $column_data{$_} = ' ' }
            if ($curr) {
                $c0total = $form->format_amount(\%myconfig, $c0total, 2, ' ');
                $c30total = $form->format_amount(\%myconfig, $c30total, 2, ' ');
                $c60total = $form->format_amount(\%myconfig, $c60total, 2, ' ');
                $c90total = $form->format_amount(\%myconfig, $c90total, 2, ' ');
                $total = $form->format_amount(\%myconfig, $total, 2, ' ' );

                for (qw(ct statement language)) {
                    $column_data{$_} = ' ';
                }
                $column_data{c0}    = $c0total;
                $column_data{c30}   = $c30total;
                $column_data{c60}   = $c60total;
                $column_data{c90}   = $c90total;
                $column_data{total} = $total;

                push @{$currencies[0]{totals}}, \%column_data;

                $c0subtotal  = 0;
                $c30subtotal = 0;
                $c60subtotal = 0;
                $c90subtotal = 0;
                $subtotal    = 0;

                $c0total  = 0;
                $c30total = 0;
                $c60total = 0;
                $c90total = 0;
                $total    = 0;

            }

            unshift @currencies, {};
            $curr = $ref->{curr};
            $currencies[0]{curr} = $curr;
        }

        $k++;
        my %column_data;

        if ( $ctid != $ref->{ctid} or $form->{summary}) {
            $i++;

            $column_data{ct} = $ref->{name};
    
            $column_data{language} = {
                name => "language_code_$i",
                options => $form->{language_options},
                default_value => $ref->{language_code},
                } if $form->{language_options};
    
            $column_data{statement} = {
                name => "statement_$i",
                type => 'checkbox',
                value => $ref->{ctid},
                };
            $column_data{statement}{checked} = 'checked' if $ref->{checked};
            $hiddens{"curr_$i"} = $ref->{curr};
        }


        $ctid = $ref->{ctid};

        for (qw(c0 c30 c60 c90)) {
            $ref->{$_} =
              $form->round_amount( $ref->{$_} / $ref->{exchangerate}, 2 );
        }

        $c0subtotal  += $ref->{c0};
        $c30subtotal += $ref->{c30};
        $c60subtotal += $ref->{c60};
        $c90subtotal += $ref->{c90};

        $c0total  += $ref->{c0};
        $c30total += $ref->{c30};
        $c60total += $ref->{c60};
        $c90total += $ref->{c90};

        $ref->{total} =
          ( $ref->{c0} + $ref->{c30} + $ref->{c60} + $ref->{c90} );
        $subtotal += $ref->{total};
        $total    += $ref->{total};

        $ref->{c0} =
          $form->format_amount( \%myconfig, $ref->{c0}, 2, ' ' );
        $ref->{c30} =
          $form->format_amount( \%myconfig, $ref->{c30}, 2, ' ' );
        $ref->{c60} =
          $form->format_amount( \%myconfig, $ref->{c60}, 2, ' ' );
        $ref->{c90} =
          $form->format_amount( \%myconfig, $ref->{c90}, 2, ' ' );
        $ref->{total} =
          $form->format_amount( \%myconfig, $ref->{total}, 2, ' ' );

        $href =
qq|$ref->{module}.pl?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=|
          . $form->escape( $form->{callback} );

        $column_data{invnumber} = {text => $ref->{invnumber}, href => $href};
        for (qw(c0 c30 c60 c90 total ordnumber transdate duedate)) {
            $column_data{$_} = $ref->{$_};
        }

        if ( !$form->{summary} ) {

            $j++;
            $j %= 2;
            $column_data{i} = $j;
            my $rowref = {};
            $rowref->{$_} = $column_data{$_} for keys %column_data;

            push @{$currencies[0]{rows}}, $rowref;
            for (qw(ct statement language)) {
                $column_data{$_} = ' ';
            }

        }
        $column_data{ct} = $ref->{name};

        # prepare subtotal
        $nextid = ( $k <= $l ) ? $form->{AG}->[$k]->{ctid} : 0;
        if ( $ctid != $nextid ) {

            $c0subtotal =
              $form->format_amount( \%myconfig, $c0subtotal, 2, ' ' );
            $c30subtotal =
              $form->format_amount( \%myconfig, $c30subtotal, 2, ' ' );
            $c60subtotal =
              $form->format_amount( \%myconfig, $c60subtotal, 2, ' ' );
            $c90subtotal =
              $form->format_amount( \%myconfig, $c90subtotal, 2, ' ' );
            $subtotal =
              $form->format_amount( \%myconfig, $subtotal, 2, ' ' );

            if ( $form->{summary} ) {
                $column_data{c0}    = $c0subtotal;
                $column_data{c30}   = $c30subtotal;
                $column_data{c60}   = $c60subtotal;
                $column_data{c90}   = $c90subtotal;
                $column_data{total} = $subtotal;

                $j++;
                $j %= 2;
                $column_data{i} = $j;

                push @{$currencies[0]{rows}}, \%column_data;

            } else {
                for (@column_index) { $column_data{$_} = ' ' }

                $column_data{c0} = $c0subtotal;
                $column_data{c30} = $c30subtotal;
                $column_data{c60} = $c60subtotal;
                $column_data{c90} = $c90subtotal;
                $column_data{total} = $subtotal;
                $column_data{class} = 'subtotal';

                push @{$currencies[0]{rows}}, \%column_data;
            }

            $c0subtotal  = 0;
            $c30subtotal = 0;
            $c60subtotal = 0;
            $c90subtotal = 0;
            $subtotal    = 0;

        }
    }

    my %column_data;
    for (@column_index) { $column_data{$_} = ' ' }

    $c0total  = $form->format_amount( \%myconfig, $c0total,  2, ' ' );
    $c30total = $form->format_amount( \%myconfig, $c30total, 2, ' ' );
    $c60total = $form->format_amount( \%myconfig, $c60total, 2, ' ' );
    $c90total = $form->format_amount( \%myconfig, $c90total, 2, ' ' );
    $total    = $form->format_amount( \%myconfig, $total,    2, ' ' );

    $column_data{c0}    = $c0total;
    $column_data{c30}   = $c30total;
    $column_data{c60}   = $c60total;
    $column_data{c90}   = $c90total;
    $column_data{total} = $total;
    
    $currencies[0]{total} = \%column_data;

    $row_alignment{c0}     = 'right';
    $row_alignment{c30}    = 'right';
    $row_alignment{c60}    = 'right';
    $row_alignment{c90}    = 'right';
    $row_alignment{total}  = 'right';
    $hiddens{rowcount} = $i;

    &print_options if ( $form->{arap} eq 'ar' );


    my @buttons;
    if ( $form->{arap} eq 'ar' ) {

        $hiddens{$_} = $form->{$_} foreach qw(todate title summary overdue c0 c30 c60 c90 callback arap ct department path login sessionid);
        $hiddens{$form->{ct}} = $form->{$form->{ct}};

        # type=submit $locale->text('Select all')
        # type=submit $locale->text('Print')
        # type=submit $locale->text('E-mail')

        my %button = (
            'select_all' =>
              { ndx => 1, key => 'A', value => $locale->text('Select all') },
            'print' =>
              { ndx => 2, key => 'P', value => $locale->text('Print') },
            'e_mail' =>
              { ndx => 5, key => 'E', value => $locale->text('E-mail') },
        );

        for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button )
        {
            push @buttons, {
                accesskey => $button{$_}->{key},
                text => $button{$_}->{value},
                title => "$button{$_}->{value} [Alt-$button{$_}->{key}]",
                value => $_,
                name => 'action',
                };
        }

    }

##SC: Temporary commenting
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    for my $type (qw(CSV XLS ODS)) {
        push @buttons, {
            name => 'action',
            value => lc "${type}_$form->{nextsub}",
            text => $locale->text("[_1] Report", $type),
            type => 'submit',
            class => 'submit',
        };
    }
    my $format;
    if ($form->{action} =~ /^(continue|generate_)/) {
	$format = 'HTML';
    } else {
        $format = uc substr $form->{action}, 0, 3;
        push @column_index, 'class';
        @column_index = grep {!/^(language|statement)$/} @column_index;
        $column_header{class} = 'rowtype';
    }
    my $template = LedgerSMB::Template->new(
        user => \%myconfig, 
        locale => $locale, 
        template => 'rp-aging',
        path => 'UI',
        format => $format,
        );
    $template->render({
        form => $form,
        hiddens => \%hiddens,
        buttons => \@buttons,
        options => \@options,
        columns => \@column_index,
        heading => \%column_header,
        currencies => [reverse @currencies],
        row_alignment => {
            'credit' => 'right',
            'debit' => 'right',
            'begbalance' => 'right',
            'endbalance' => 'right'
            },
    });
}

sub select_all {

    RP->aging( \%myconfig, \%$form );

    for ( @{ $form->{AG} } ) { $_->{checked} = "checked" }

    &aging;

}

sub print_options {

    $form->{sendmode} = "attachment";
    $form->{copies} = 1 unless $form->{copies};

    $form->{print}{format} = {name => 'format', default_values => $form->{format}};
    $form->{print}{template} = {name => 'type', default_values => $form->{type}};

    my @formats = ();
    my @media = ();
    my @templates = ();

    push @formats, {text => 'HTML', value => 'html'};
    push @templates, {text => $locale->text('Statement'), value => 'statement'};

    if ( $form->{media} eq 'email' ) {
        $form->{print}{medium} = {name => 'sendmode', default_values => $form->{sendmode}};
        push @media, {text => $locale->text('Attachment'), value => 'attachment'};
        push @media, {text => $locale->text('In-line'), value => 'inline'};
	if ($form->{SM}{attachment}) {
	    $form->{print}{medium}{default_values} = $form->{SM}{attachment};
	} elsif ($form->{SM}{inline}) {
	    $form->{print}{medium}{default_values} = $form->{SM}{inline};
	}
    } else {
        $form->{print}{medium} = {name => 'media'};
        push @media, {text => $locale->text('Screen'), value => 'screen'};
        if (   %{LedgerSMB::Sysconfig::printer}
            && ${LedgerSMB::Sysconfig::latex} )
        {
            for ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
                push @media, {text => $_, value => $_};
            }
        }
    }

    if ( ${LedgerSMB::Sysconfig::latex} ) {
        push @formats, {text => $locale->text('PDF'), value => 'pdf'};
        push @formats, {text => $locale->text('Postscript'), value => 'ps'};
    }

    if (   %{LedgerSMB::Sysconfig::printer}
        && ${LedgerSMB::Sysconfig::latex}
        && $form->{media} ne 'email' )
    {
        $form->{print}{copies} = {
            label => $locale->text('Copies'),
            name => 'copies',
            value => $form->{copies},
            size => 2,
            };
    }

    $form->{print}{template}{options} = \@templates;
    $form->{print}{format}{options} = \@formats;
    $form->{print}{medium}{options} = \@media;
}

sub e_mail {

    my %hiddens;
    # get name and email addresses
    for $i ( 1 .. $form->{rowcount} ) {
        if ( $form->{"statement_$i"} ) {
            $form->{"$form->{ct}_id"}  = $form->{"$form->{ct}_id_$i"};
            $form->{"statement_1"}     = $form->{"statement_$i"};
            $form->{"language_code_1"} = $form->{"language_code_$i"};
            $form->{"curr_1"}          = $form->{"curr_$i"};
            RP->get_customer( \%myconfig, \%$form );
            $selected = 1;
            last;
        }
    }

    $form->error( $locale->text('Nothing selected!') ) unless $selected;
    $form->{media} = "email";

    &print_options;

    for (qw(subject message type sendmode format action nextsub)) {
        delete $form->{$_};
    }

    for (keys %$form) {
        $hiddens{$_} = $form->{$_} unless ref $form->{$_};
    }

    my @buttons = ({
        name => 'action',
        value => 'send_email',
        text => $locale->text('Continue'),
    });
    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'rp-email',
        );
    $template->render({
        form => $form,
        user => \%myconfig, 
        hiddens => \%hiddens,
        buttons => \@buttons,
    });
}

sub send_email {

    $form->{subject} = $locale->text( 'Statement - [_1]', $form->{todate} )
      unless $form->{subject};
    $form->isblank( "email", $locale->text('E-mail address missing!') );

    RP->aging( \%myconfig, $form );

    my $selected = 0;
    RP->aging( \%myconfig, $form );
    my $ag = {};
    for my $ref(@{$form->{AG}}){
        push @{$ag->{$ref->{ctid}}}, $ref;
    }
    $form->{statementdate} = $locale->date( \%myconfig, $form->{todate}, 1 );
    $form->{templates} = "$myconfig{templates}";
    # CT-- These aren't working right now, seeing if they are in fact necessary
    # due to changes in structure.
    #
    #my @vars = qw(company address businessnumber tel fax);
    #for (@vars) { $form->{$_} = $myconfig{$_} }
    $form->{address} =~ s/\\n/\n/g;

    @vars = qw(name address1 address2 city state zipcode country contact);
    push @vars, "$form->{ct}phone", "$form->{ct}fax", "$form->{ct}taxnumber";
    push @vars, 'email' if !$form->{media} eq 'email';
    my $invoices = 0; 
    my $data= {};
    for $i ( 1 .. $form->{rowcount} ) {
        last if $selected;
        if ( $form->{"statement_$i"}) {
            $selected = 1;
            for (qw(invnumber ordnumber ponumber notes invdate duedate)) {
                $form->{$_} = ();
            }
            foreach $item (qw(c0 c30 c60 c90)) {
                $form->{$item} = ();
                $form->{"${item}total"} = 0;
            }
            $form->{total} = 0;
            $form->{"$form->{ct}_id"} = $form->{"$form->{ct}_id_$i"};
            $language_code            = $form->{"language_code_$i"};
            $curr                     = $form->{"curr_$i"};
            $selected                 = 1;
            
            if ( $form->{media} !~ /(screen|email)/ ) {
                $SIG{INT} = 'IGNORE';
            }
    
            @refs = @{$ag->{$form->{"statement_$i"}}};    


            
            for $ref( @refs ) {
                for (@vars) { $form->{$_} = $ref->{$_} }

                $form->{ $form->{ct} }    = $ref->{name};
                $form->{"$form->{ct}_id"} = $ref->{ctid};
                $form->{language_code}    = $form->{"language_code_$i"};
                $form->{currency}         = $form->{"curr_$i"};

                if ($ref->{curr} eq $form->{currency}){
                    ++$invoices;
                    $ref->{invdate} = $ref->{transdate};
                   my @a = qw(invnumber ordnumber ponumber notes invdate duedate);
                  for (@a) { $form->{"${_}_1"} = $ref->{$_} }
                  $form->format_string(qw(invnumber_1 ordnumber_1 ponumber_1 notes_1));
                  for (@a) { push @{ $form->{$_} }, $form->{"${_}_1"} }

                  foreach $item (qw(c0 c30 c60 c90)) {
                      eval {
                           $ref->{$item} =
                                  $form->round_amount( 
                                      $ref->{$item} / $ref->{exchangerate}, 2 );
                       };
                      $form->{"${item}total"} += $ref->{$item};
                      $form->{total}          += $ref->{$item};
                      push @{ $form->{$item} },
                      $form->format_amount( \%myconfig, $ref->{$item}, 2 );
                   }
                }
                
            }
            for ( "c0", "c30", "c60", "c90", "" ) {
                $form->{"${_}total"} =
                  $form->format_amount( \%myconfig, $form->{"${_}total"},
                    2 );
            }
            

            for (keys %$form) { $data->{$_} = $form->{$_}}
        }
    }
    delete $form->{header};
    my $template = LedgerSMB::Template->new( 
        user => \%myconfig,
        template => $form->{'formname'} || $form->{'type'},
        format => uc $form->{format},
        method => 'email',
        locale => $locale,
        output_options => {
            to => $form->{email},
            cc => $form->{cc},
            bcc => $form->{bcc},
            from => $form->{form},
            subject => $form->{subject},
            message => $form->{message},
            notify => $form->{read_receipt},
            attach => ($form->{sendmode} eq 'attachment')? 1: 0,
            },
        );
    try {
        my $csettings = $LedgerSMB::Company_Config::settings;
        $data->{company} = $csettings->{company_name};
        $data->{businessnumber} = $csettings->{businessnumber};
        $data->{email} = $csettings->{company_email};
        $data->{address} = $csettings->{company_address};
        $data->{tel} = $csettings->{company_phone};
        $data->{fax} = $csettings->{company_fax};
        $template->render({data => [$data]});
    }
    catch Error::Simple with {
        my $E = shift;
        $form->error( $E->stacktrace );
    };
    $form->redirect(
        $locale->text( 'Statement sent to [_1]', $form->{ $form->{ct} } ) );

    $form->finalize_request();
}

sub print {

    if ( $form->{media} !~ /(screen|email)/ ) {
        $form->error( $locale->text('Select postscript or PDF!') )
          if ( $form->{format} !~ /(postscript|pdf)/ );
    }

    my @batch_data = ();
    my $selected;
    RP->aging( \%myconfig, $form );
    my $ag = {};
    for my $ref(@{$form->{AG}}){
        push @{$ag->{$ref->{ctid}}}, $ref;
    }
    $form->{statementdate} = $locale->date( \%myconfig, $form->{todate}, 1 );
    $form->{templates} = "$myconfig{templates}";
    # CT-- These aren't working right now, seeing if they are in fact necessary
    # due to changes in structure.
    #
    #my @vars = qw(company address businessnumber tel fax);
    #for (@vars) { $form->{$_} = $myconfig{$_} }
    $form->{address} =~ s/\\n/\n/g;

    @vars = qw(name address1 address2 city state zipcode country contact);
    push @vars, "$form->{ct}phone", "$form->{ct}fax", "$form->{ct}taxnumber";
    push @vars, 'email' if !$form->{media} eq 'email';
    my $invoices = 0; 
    for $i ( 1 .. $form->{rowcount} ) {

        if ( $form->{"statement_$i"}) {
            for (qw(invnumber ordnumber ponumber notes invdate duedate)) {
                $form->{$_} = ();
            }
            foreach $item (qw(c0 c30 c60 c90)) {
                $form->{$item} = ();
                $form->{"${item}total"} = 0;
            }
            $form->{total} = 0;
            $form->{"$form->{ct}_id"} = $form->{"$form->{ct}_id_$i"};
            $language_code            = $form->{"language_code_$i"};
            $curr                     = $form->{"curr_$i"};
            $selected                 = 1;
            
            if ( $form->{media} !~ /(screen|email)/ ) {
                $SIG{INT} = 'IGNORE';
            }
    
            @refs = @{$ag->{$form->{"statement_$i"}}};    


            
            for $ref( @refs ) {
                for (@vars) { $form->{$_} = $ref->{$_} }

                $form->{ $form->{ct} }    = $ref->{name};
                $form->{"$form->{ct}_id"} = $ref->{ctid};
                $form->{language_code}    = $form->{"language_code_$i"};
                $form->{currency}         = $form->{"curr_$i"};

                if ($ref->{curr} eq $form->{currency}){
                    ++$invoices;
                    $ref->{invdate} = $ref->{transdate};
                   my @a = qw(invnumber ordnumber ponumber notes invdate duedate);
                  for (@a) { $form->{"${_}_1"} = $ref->{$_} }
                      $form->format_string(qw(invnumber_1 ordnumber_1 ponumber_1 notes_1));
                  for (@a) { push @{ $form->{$_} }, $form->{"${_}_1"} }

                  foreach $item (qw(c0 c30 c60 c90)) {
                      eval {
                           $ref->{$item} =
                                  $form->round_amount( 
                                      $ref->{$item} / $ref->{exchangerate}, 2 );
                       };
                      $form->{"${item}total"} += $ref->{$item};
                      $form->{total}          += $ref->{$item};
                      push @{ $form->{$item} },
                      $form->format_amount( \%myconfig, $ref->{$item}, 2 );
                   }
                }
                
            }
            for ( "c0", "c30", "c60", "c90", "" ) {
                $form->{"${_}total"} =
                  $form->format_amount( \%myconfig, $form->{"${_}total"},
                    2 );
            }
            
            my $printhash = {};
            my $csettings = $LedgerSMB::Company_Config::settings;
            $form->{company} = $csettings->{company_name};
            $form->{businessnumber} = $csettings->{businessnumber};
            $form->{email} = $csettings->{company_email};
            $form->{address} = $csettings->{company_address};
            $form->{tel} = $csettings->{company_phone};
            $form->{fax} = $csettings->{company_fax};

            for (keys %$form) { $printhash->{$_} = $form->{$_}}
            push @batch_data, $printhash;
        }
    }

    $form->error( $locale->text('Nothing selected!') ) unless $selected;
   
    my $template = LedgerSMB::Template->new( 
      user => \%myconfig,
      template => $form->{'formname'} || $form->{'type'},
      format => uc $form->{format},
      locale => $locale
    );
    try {
        $template->render({currency => $form->{currency}, 
                            data => \@batch_data});
        $template->output($form);
    }
    catch Error::Simple with {
        my $E = shift;
        $form->error( $E->stacktrace );
    };

    $form->redirect( $locale->text('Statements sent to printer!') )
      if ( $form->{media} !~ /(screen|email)/ );

}


sub generate_tax_report {
    RP->tax_report( \%myconfig, $form );

    my %hiddens;
    my @options;
    my $descvar     = "$form->{accno}_description";
    my $description = $form->escape( $form->{$descvar} );
    my $ratevar     = "$form->{accno}_rate";
    my $taxrate     = $form->{"$form->{accno}_rate"};

    if ( $form->{accno} =~ /^gifi_/ ) {
        $descvar     = "gifi_$form->{accno}_description";
        $description = $form->escape( $form->{$descvar} );
        $ratevar     = "gifi_$form->{accno}_rate";
        $taxrate     = $form->{"gifi_$form->{accno}_rate"};
    }

    my $department = $form->escape( $form->{department} );

    # construct href
    my $href =
"$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=generate_tax_report&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&db=$form->{db}&method=$form->{method}&summary=$form->{summary}&accno=$form->{accno}&$descvar=$description&department=$department&$ratevar=$taxrate&report=$form->{report}";

    # construct callback
    $description = $form->escape( $form->{$descvar}, 1 );
    $department = $form->escape( $form->{department}, 1 );

    $form->sort_order();

    my $callback =
"$form->{script}?path=$form->{path}&direction=$form->{direction}&oldsort=$form->{oldsort}&action=generate_tax_report&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&db=$form->{db}&method=$form->{method}&summary=$form->{summary}&accno=$form->{accno}&$descvar=$description&department=$department&$ratevar=$taxrate&report=$form->{report}";

    $form->{title} = $locale->text('GIFI') . " - "
      if ( $form->{accno} =~ /^gifi_/ );

    my $title = $form->escape( $form->{title} );
    $href .= "&title=$title";
    $title = $form->escape( $form->{title}, 1 );
    $callback .= "&title=$title";

    $form->{title} = qq|$form->{title} $form->{"$form->{accno}_description"} |;

    my @columns =
      $form->sort_columns(
        qw(id transdate invnumber name description netamount tax total));

    $form->{"l_description"} = "" if $form->{summary};

    my @column_index;
    foreach my $item (@columns) {
        if ( $form->{"l_$item"} eq "Y" ) {
            push @column_index, $item;

            # add column to href and callback
            $callback .= "&l_$item=Y";
            $href     .= "&l_$item=Y";
        }
    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        $callback .= "&l_subtotal=Y";
        $href     .= "&l_subtotal=Y";
    }

    if ( $form->{department} ) {
        ($department) = split /--/, $form->{department};
        push @options, $locale->text('Department: [_1]', $department);
    }

    # if there are any dates
    my $fromdate;
    my $todate;
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

    my $name;
    my $invoice;
    my $arap;
    if ( $form->{db} eq 'ar' ) {
        $name    = $locale->text('Customer');
        $invoice = 'is.pl';
        $arap    = 'ar.pl';
    }
    if ( $form->{db} eq 'ap' ) {
        $name    = $locale->text('Vendor');
        $invoice = 'ir.pl';
        $arap    = 'ap.pl';
    }

    push @options, $form->{period};

    my $column_names = {
        id => 'ID',
        invnumber => 'Invoice',
        transdate => 'Date',
        netamount => 'Amount',
        tax => 'Tax',
        total => 'Total',
        name => $name,
        description => 'Description'
        };
    my @sort_columns = qw(id invnumber transdate name description);
    my $sort_href = "$href&sort";

    # add sort and escape callback
    $callback = $form->escape( $callback . "&sort=$form->{sort}" );

    my $sameitem;
    if ( @{ $form->{TR} } ) {
        $sameitem = $form->{TR}->[0]->{ $form->{sort} };
    }

    my $totalnetamount;
    my @rows;
    my $i;
    foreach my $ref ( @{ $form->{TR} } ) {

        my %column_data;
        my $module = ( $ref->{invoice} ) ? $invoice : $arap;
        $module = 'ps.pl' if $ref->{till};

        if ( $form->{l_subtotal} eq 'Y' ) {
            if ( $sameitem ne $ref->{ $form->{sort} } ) {
                push @rows, &tax_subtotal(\@column_index);
                $sameitem = $ref->{ $form->{sort} };
            }
        }

        $totalnetamount += $ref->{netamount};
        $totaltax       += $ref->{tax};
        $ref->{total} = $ref->{netamount} + $ref->{tax};

        $subtotalnetamount += $ref->{netamount};
        $subtotaltax       += $ref->{tax};

        for (qw(netamount tax total)) {
            $ref->{$_} =
              $form->format_amount( \%myconfig, $ref->{$_}, 2, ' ' );
        }

        $column_data{id} = $ref->{id};
        $column_data{invnumber} = {
            href => "$module?path=$form->{path}&action=edit&id=$ref->{id}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$callback",
            text => $ref->{invnumber},
            };

        for (qw(id transdate name partnumber description)) {
            $column_data{$_} = $ref->{$_};
        }

        for (qw(netamount tax total)) {
            $column_data{$_} = $ref->{$_};
        }

        $i++;
        $i %= 2;
        $column_data{i} = $i;

        push @rows, \%column_data;
    }

    if ( $form->{l_subtotal} eq 'Y' ) {
        push @rows, &tax_subtotal(\@column_index);
    }

    my %column_data;
    for (@column_index) { $column_data{$_} = ' ' }

    $total = $form->format_amount( \%myconfig, $totalnetamount + $totaltax,
        2, ' ' );
    $totalnetamount =
      $form->format_amount( \%myconfig, $totalnetamount, 2, ' ' );
    $totaltax = $form->format_amount( \%myconfig, $totaltax, 2, ' ' );

    $column_data{netamount} = $totalnetamount;
    $column_data{tax}   = $totaltax;
    $column_data{total} = $total;

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'form-dynatable',
        );
    
    my $column_heading = $template->column_heading($column_names,
        {href => $sort_href, columns => \@sort_columns}
    );
    
    $template->render({
        form => $form,
        hiddens => \%hiddens,
        options => \@options,
        columns => \@column_index,
        heading => $column_heading,
        rows => \@rows,
        totals => \%column_data,
        row_alignment => {
            netamount => 'right',
            tax => 'right',
            total => 'right',
            },
    });
}

sub tax_subtotal {

    my $column_index = shift;
    my %column_data;
    for (@{$column_index}) { $column_data{$_} = ' ' }


    $column_data{'class'} = 'subtotal';
    #SC: Yes, right now these are global, inherited from generate_tax_report
    $subtotal =
      $form->format_amount( \%myconfig, $subtotalnetamount + $subtotaltax,
        2, ' ' );
    $subtotalnetamount =
      $form->format_amount( \%myconfig, $subtotalnetamount, 2, ' ' );
    $subtotaltax =
      $form->format_amount( \%myconfig, $subtotaltax, 2, ' ' );

    $column_data{netamount} = $subtotalnetamount;
    $column_data{tax} = $subtotaltax;
    $column_data{total} = $subtotal;

    $subtotalnetamount = 0;
    $subtotaltax       = 0;

    \%column_data;

}

sub list_payments {

    my %hiddens;
    my @options;
    my $vc = ($form->{db} eq 'ar') ? 'Customer' : 'Vendor';
    if ( $form->{account} ) {
        ( $form->{paymentaccounts} ) = split /--/, $form->{account};
    }
    if ( $form->{department} ) {
        ( $department, $form->{department_id} ) = split /--/,
          $form->{department};
        push @options, $locale->text('Department: [_1]', $department);
    }

    RP->payments( \%myconfig, \%$form );

    my @columns = $form->sort_columns(qw(meta_number transdate name paid source 
					memo batch_control batch_description));

    if ( $form->{till} ) {
        @columns =
          $form->sort_columns(qw(transdate name paid curr source meta_number till));
        if ( $myconfig{role} ne 'user' ) {
            @columns =
              $form->sort_columns(
                qw(transdate name paid curr source till employee));
        }
    }

    # construct href
    my $title = $form->escape( $form->{title} );
    $form->{paymentaccounts} =~ s/ /%20/g;

    my $href =
"$form->{script}?path=$form->{path}&direction=$form->{direction}&sort=$form->{sort}&oldsort=$form->{oldsort}&action=list_payments&till=$form->{till}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fx_transaction=$form->{fx_transaction}&db=$form->{db}&l_subtotal=$form->{l_subtotal}&prepayment=$form->{prepayment}&paymentaccounts=$form->{paymentaccounts}&title="
      . $form->escape( $form->{title} );

    $form->sort_order();

    $form->{callback} =
"$form->{script}?path=$form->{path}&direction=$form->{direction}&sort=$form->{sort}&oldsort=$form->{oldsort}&action=list_payments&till=$form->{till}&login=$form->{login}&sessionid=$form->{sessionid}&fromdate=$form->{fromdate}&todate=$form->{todate}&fx_transaction=$form->{fx_transaction}&db=$form->{db}&l_subtotal=$form->{l_subtotal}&prepayment=$form->{prepayment}&paymentaccounts=$form->{paymentaccounts}&title="
      . $form->escape( $form->{title}, 1 );

    my $callback;
    if ( $form->{account} ) {
        $callback .= "&account=" . $form->escape( $form->{account}, 1 );
        $href   .= "&account=" . $form->escape( $form->{account} );
        push @options, $locale->text('Account: [_1]', $form->{account});
    }
    if ( $form->{department} ) {
        $callback .= "&department=" . $form->escape( $form->{department}, 1 );
        $href   .= "&department=" . $form->escape( $form->{department} );
        push @options, $locale->text('Department: [_1]', $form->{department});
    }
    if ( $form->{description} ) {
        $callback .= "&description=" . $form->escape( $form->{description}, 1 );
        $href   .= "&description=" . $form->escape( $form->{description} );
        push @options, $locale->text('Description: [_1]', $form->{description});
    }
    if ( $form->{source} ) {
        $callback .= "&source=" . $form->escape( $form->{source}, 1 );
        $href   .= "&source=" . $form->escape( $form->{source} );
        push @options, $locale->text('Source: [_1]', $form->{source});
    }
    if ( $form->{memo} ) {
        $callback .= "&memo=" . $form->escape( $form->{memo}, 1 );
        $href   .= "&memo=" . $form->escape( $form->{memo} );
        push @options, $locale->text('Memo: [_1]', $form->{memo});
    }
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

    $callback = $form->escape( $form->{callback} );

    my %column_header;
    $column_header{name} = {
        href => "$href&sort=name",
        text => $locale->text('Description'),
        };
    $column_header{transdate} = {
        href => "$href&sort=transdate",
        text => $locale->text('Date'),
        };
    $column_header{paid} = $locale->text('Amount');
    $column_header{batch_control} = $locale->text('Batch');
    $column_header{batch_description} = $locale->text('Batch Description');
    $column_header{curr} = $locale->text('Curr');
    $column_header{memo} = $locale->text('Memo');
    $column_header{source} = {
        href => "$href&sort=source",
        text => $locale->text('Source'),
        };
    $column_header{meta_number} = {
        href => "$href&sort=meta_number",
        text => $locale->text("[_1] Number", $vc),
        };
    $column_header{employee} = {
        href => "$href&sort=employee",
        text => $locale->text('Salesperson'),
        };
    $column_header{till} = {
        href => "$href&sort=till",
        text => $locale->text('Till'),
        };

    my @column_index = @columns;

    my @accounts;
    my $i;
    foreach my $ref ( sort { $a->{accno} cmp $b->{accno} } @{ $form->{PR} } ) {

        next unless @{ $form->{ $ref->{id} } };

        push @accounts, {header => "$ref->{accno}--$ref->{description}"};

        if ( @{ $form->{ $ref->{id} } } ) {
            $sameitem = $form->{ $ref->{id} }[0]->{ $form->{sort} };
        }

        my @rows;
        foreach my $payment ( @{ $form->{ $ref->{id} } } ) {

            if ( $form->{l_subtotal} ) {
                if ( $payment->{ $form->{sort} } ne $sameitem ) {

                    # print subtotal
                    push @rows, &payment_subtotal(\@column_index);
                }
            }

            next if ( $form->{till} && !$payment->{till} );

            my %column_data;
            $column_data{meta_number} = $payment->{meta_number};
            $column_data{name}      = $payment->{name};
            $column_data{transdate} = $payment->{transdate};
            $column_data{batch_control} = $payment->{batch_control};
            $column_data{batch_description} = $payment->{batch_description};
            $column_data{paid} =
                $form->format_amount(\%myconfig, $payment->{paid}, 2, ' ');
            $column_data{curr}     = $payment->{curr};
            $column_data{source}   = $payment->{source};
            $column_data{memo}     = $payment->{memo};
            $column_data{employee} = $payment->{employee};
            $column_data{till}     = $payment->{till};

            $subtotalpaid     += $payment->{paid};
            $accounttotalpaid += $payment->{paid};
            $totalpaid        += $payment->{paid};

            $i++;
            $i %= 2;
            $column_data{i} = $i;
            push @rows, \%column_data;

            $sameitem = $payment->{ $form->{sort} };

        }
        push @rows, &payment_subtotal(\@column_index) if $form->{l_subtotal};
        $accounts[$#accounts]{rows} = \@rows;

        # print account totals
        my %column_data;
        for (@column_index) { $column_data{$_} = ' ' }

        $column_data{paid} =
            $form->format_amount( \%myconfig, $accounttotalpaid, 2, ' ' );

        $accounts[$#accounts]{totals} = \%column_data;
        $accounttotalpaid = 0;

    }

    # prepare total
    my %column_data;
    for (@column_index) { $column_data{$_} = ' ' }
    $column_data{paid} = $form->format_amount( \%myconfig, $totalpaid, 2, ' ' );

##SC: Temporary removal
##    if ( $form->{lynx} ) {
##        require "bin/menu.pl";
##        &menubar;
##    }

    my $template = LedgerSMB::Template->new_UI(
        user => \%myconfig, 
        locale => $locale, 
        template => 'rp-payments',
        );
    $template->render({
        form => $form,
        hiddens => \%hiddens,
        options => \@options,
        columns => \@column_index,
        heading => \%column_header,
        accounts => \@accounts,
        totals => \%column_data,
        row_alignment => {
            paid => 'right',
            },
    });
}

sub payment_subtotal {

    my $column_index = shift;
    my %column_data;
    if ( $subtotalpaid != 0 ) {
        for (@column_index) { $column_data{$_} = ' ' }

        $column_data{paid} =
            $form->format_amount( \%myconfig, $subtotalpaid, 2, ' ' );
        $column_data{class} = 'subtotal';
    }

    $subtotalpaid = 0;
    \%column_data;
}

