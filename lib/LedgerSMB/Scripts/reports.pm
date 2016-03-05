=head1 NAME

LedgerSMB::Scripts::reports - Common Report workflows

=head1 SYNOPSIS

This module holds common workflow routines for reports.

=head1 METHODS

=cut

package LedgerSMB::Scripts::reports;

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::Business_Unit;
use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Report::Balance_Sheet;
use LedgerSMB::Report::Listings::Business_Type;
use LedgerSMB::Report::Listings::GIFI;
use LedgerSMB::Report::Listings::Warehouse;
use LedgerSMB::Report::Listings::Language;
use LedgerSMB::Report::Listings::SIC;
use LedgerSMB::Report::Listings::Overpayments;
use LedgerSMB::Setting;
use LedgerSMB::DBObject::Payment; # To move this off after rewriting payments
use strict;
use warnings;

our $VERSION = '1.0';


=pod

=over

=item start_report

This displays the filter screen for the report.  It expects the following
request properties to be set:

=over

=item report_name

This is the name of the report

=item module_name

Module name for the report.  This is used in retrieving business units.  If not
set, no business units are retrieved.

=back

Other variables that are set will be passed through to the underlying template.

=cut

sub start_report {
    my ($request) = @_;
    if ($request->{module_name}){
        $request->{class_id} = 0 unless $request->{class_id};
        $request->{control_code} = '' unless $request->{control_code};
        my $buc = LedgerSMB::Business_Unit_Class->new(%$request);
        my $bu = LedgerSMB::Business_Unit->new(%$request);
        @{$request->{bu_classes}} = $buc->list(1, $request->{module_name});
        for my $bc (@{$request->{bu_classes}}){
            @{$request->{b_units}->{$bc->{id}}}
                = $bu->list($bc->{id}, undef, 0, undef);
            for my $bu (@{$request->{b_units}->{$bc->{id}}}){
                $bu->{text} = $bu->control_code . ' -- '. $bu->description;
            }
        }
    }
    @{$request->{entity_classes}} = $request->call_procedure(
                      funcname => 'entity__list_classes'
    );
    @{$request->{heading_list}} =  $request->call_procedure(
                      funcname => 'account_heading_list');
    @{$request->{account_list}} =  $request->call_procedure(
                      funcname => 'account__list_by_heading');
    @{$request->{batch_classes}} = $request->call_procedure(
                      funcname => 'batch_list_classes'
    );
    @{$request->{all_years}} = $request->call_procedure(
              funcname => 'date_get_all_years'
    );
    my $curr = LedgerSMB::Setting->get('curr');
    @{$request->{currencies}} = split ':', $curr;
    $_ = {id => $_, text => $_} for @{$request->{currencies}};
    my $months = LedgerSMB::App_State::all_months();
    $request->{all_months} = $months->{dropdown};
    if (!$request->{report_name}){
        die $request->{_locale}->text('No report specified');
    }
    @{$request->{country_list}} = $request->call_procedure(
                   funcname => 'location_list_country'
    );
    @{$request->{employees}} =  $request->call_procedure(
        funcname => 'employee__all_salespeople'
    );
    @{$request->{languages}} = $request->call_procedure(
        funcname => 'person__list_languages'
        );

    $request->{earn_id} = LedgerSMB::Setting->get('earn_id');
    my $template = LedgerSMB::Template->new(
        request => $request,
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/Reports/filters',
        template => $request->{report_name},
        format => 'HTML'
    );
    $template->render($request); # request not used for script;
                                 # forms submit to other URLs than back to here
}

=item list_business_types

Lists the business types.  No inputs expected or used.

=cut

sub list_business_types {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Listings::Business_Type->new(%$request);
    $report->render($request);
}

=item list_gifi

List the gifi entries.  No inputs expected or used.

=cut

sub list_gifi {
    my ($request) = @_;
    LedgerSMB::Report::Listings::GIFI->new(%$request)->render($request);
}

=item list_warehouse

List the warehouse entries.  No inputs expected or used.

=cut

sub list_warehouse {
    LedgerSMB::Report::Listings::Warehouse->new(%{$_[0]})->render($_[0]);
}

=item list_language

List language entries.  No inputs expected or used.

=cut

sub list_language {
    my ($request) = @_;
    LedgerSMB::Report::Listings::Language->new(%$request)->render($request);
}

=item list_sic

Lists sic codes

=cut

sub list_sic {
    my ($request) = @_;
    LedgerSMB::Report::Listings::SIC->new(%$request)->render($request);
}

=item balance_sheet

Generates a balance sheet

=cut

sub balance_sheet {
    my ($request) = @_;
    $ENV{LSMB_ALWAYS_MONEY} = 1;
    my $report = LedgerSMB::Report::Balance_Sheet->new(
        %$request,
        column_path_prefix => [ 0 ]);
    $report->run_report;
    for my $count (1 .. 3){
        next unless $request->{"to_date_$count"};
        $request->{to_date} = $request->{"to_date_$count"};
        my $comparison =
            LedgerSMB::Report::Balance_Sheet->new(
                %$request,
                column_path_prefix => [ $count ]);
        $comparison->run_report;
        $report->add_comparison($comparison);
    }
    $report->render($request);
}

=item search_overpayments

Searches overpayments based on inputs.

=cut

sub search_overpayments {
    my ($request) = @_;
    my $hiddens = {};
    $hiddens->{$_} = $request->{$_} for qw(batch_id currency exchangerate
                                        post_date batch_class account_class);
    $request->{hiddens} = $hiddens;
    LedgerSMB::Report::Listings::Overpayments->new(%$request)->render($request);
}

=item reverse_overpayment

Reverses overpayments selected from the search overpayments screen.

=cut

sub reverse_overpayment {
    my ($request) = @_;
    for my $rc (1 .. $request->{rowcount_}){
        next unless $request->{"select_$rc"};
        my $args = {id => $request->{"select_$rc"}};
        $args->{$_} = $request->{$_} for qw(post_date batch_id account_class
                                            exchangerate currency);
        $args->{curr} = $args->{currency};
        LedgerSMB::DBObject::Payment->overpayment_reverse($args);
    }
    $request->{report_name} = 'overpayments';
    start_report($request);
}


=back

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your
option).  For more information please see the included LICENSE and COPYRIGHT
files.

=cut

###TODO-LOCALIZE-DOLLAR-AT
eval { require LedgerSMB::Scripts::custom::reports };
1;
