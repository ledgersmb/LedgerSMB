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
    } elsif ( $form->{report} eq "balance_sheet" ) {
        $hiddens{nextsub} = 'generate_balance_sheet';
        $subform = 'generate_balance_sheet';
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
        if($form->{db} eq 'ar'){$form->{meta_number_text}='Customer Number';}
        else {$form->{meta_number_text}='Vendor Number';}

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
    my $meta_number_text;
    if($form->{db} eq 'ar'){$meta_number_text='Customer Number';}
    else {$meta_number_text='Vendor Number';}
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
        text => $locale->text($meta_number_text),
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

