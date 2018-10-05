
package LedgerSMB::Scripts::reports;

=head1 NAME

LedgerSMB::Scripts::reports - Common Report workflows

=head1 DESCRIPTION

This module holds common workflow routines for reports.

=head1 METHODS

=cut

use strict;
use warnings;

use LedgerSMB::App_State;
use LedgerSMB::DBObject::Payment; # To move this off after rewriting payments
use LedgerSMB::Business_Unit;
use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Report::Balance_Sheet;
use LedgerSMB::Report::Listings::Business_Type;
use LedgerSMB::Report::Listings::GIFI;
use LedgerSMB::Report::Listings::Language;
use LedgerSMB::Report::Listings::SIC;
use LedgerSMB::Report::Listings::Overpayments;
use LedgerSMB::Report::Listings::Warehouse;
use LedgerSMB::Template::UI;

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
    my $curr = $request->setting->get('curr');
    @{$request->{currencies}} = split /:/, $curr;
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

    $request->{earn_id} = $request->setting->get('earn_id');
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request,
                             'Reports/filters/' . $request->{report_name},
                             $request);
    # request not used for script;
    # forms submit to other URLs than back to here
}

=item list_business_types

Lists the business types.  No inputs expected or used.

=cut

sub list_business_types {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Listings::Business_Type->new(%$request);
    return $report->render($request);
}

=item list_gifi

List the gifi entries.  No inputs expected or used.

=cut

sub list_gifi {
    my ($request) = @_;
    return LedgerSMB::Report::Listings::GIFI->new(%$request)
        ->render($request);
}

=item list_warehouse

List the warehouse entries.  No inputs expected or used.

=cut

sub list_warehouse {
    return LedgerSMB::Report::Listings::Warehouse->new(%{$_[0]})
        ->render($_[0]);
}

=item list_language

List language entries.  No inputs expected or used.

=cut

sub list_language {
    my ($request) = @_;
    return LedgerSMB::Report::Listings::Language->new(%$request)
        ->render($request);
}

=item list_sic

Lists sic codes

=cut

sub list_sic {
    my ($request) = @_;
    return LedgerSMB::Report::Listings::SIC->new(%$request)
        ->render($request);
}

=item generate_balance_sheet

Generates a balance sheet

=cut

use Log::Log4perl;
my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::reports');

sub generate_balance_sheet {
    my ($request) = @_;
    local $ENV{LSMB_ALWAYS_MONEY} = 1;
    $logger->debug("Stub LedgerSMB::Scripts::reports->generate_balance_sheet\n");
    my $rpt = LedgerSMB::Report::Balance_Sheet->new(
        %$request,
        column_path_prefix => [ 0 ]);
    $rpt->run_report;

    for my $key (qw(from_month from_year from_date to_date internal)) {
        delete $request->{$_} for (grep { /^$key/ } keys %$request);
    }

    for my $cmp_dates (@{$rpt->comparisons}) {
        my $cmp = LedgerSMB::Report::Balance_Sheet->new(
            %$request, %$cmp_dates);
        $cmp->run_report;
        $rpt->add_comparison($cmp);
    }
    return $rpt->render($request);
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
    return LedgerSMB::Report::Listings::Overpayments->new(%$request)
        ->render($request);
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
    return start_report($request);
}



{
    local $@ = undef;
    eval { require LedgerSMB::Scripts::custom::reports };
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
