
package LedgerSMB::Scripts::reports;

=head1 NAME

LedgerSMB::Scripts::reports - Common Report workflows

=head1 DESCRIPTION

This module holds common workflow routines for reports.

=head1 METHODS

=cut

use strict;
use warnings;

use LedgerSMB::DBObject::Payment; # To move this off after rewriting payments
use LedgerSMB::Business_Unit;
use LedgerSMB::Business_Unit_Class;
use LedgerSMB::I18N;
use LedgerSMB::Report::Balance_Sheet;
use LedgerSMB::Report::Listings::Business_Type;
use LedgerSMB::Report::Listings::GIFI;
use LedgerSMB::Report::Listings::Language;
use LedgerSMB::Report::Listings::SIC;
use LedgerSMB::Report::Listings::Overpayments;
use LedgerSMB::Report::Listings::Warehouse;

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
    my $locale = $request->{_locale};
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
    @{$request->{entity_classes}} =
        map { $_->{class} = $locale->maketext($_->{class}) ; $_ }
        $request->call_procedure(
                      funcname => 'entity__list_classes'
        );
    @{$request->{heading_list}} =  $request->call_procedure(
                      funcname => 'account_heading_list');
    @{$request->{account_list}} =  $request->call_procedure(
                      funcname => 'account__list_by_heading');
    @{$request->{gifi_list}} =  $request->call_procedure(
                      funcname => 'gifi__list');
    @{$request->{batch_classes}} = $request->call_procedure(
                      funcname => 'batch_list_classes'
    );
    $request->{all_years} = $request->all_years->{as_hashref};
    @{$request->{currencies}} = $request->setting->get_currencies();
    $_ = {id => $_, text => $_} for @{$request->{currencies}};
    $request->{all_months} = $request->all_months->{dropdown};

    if (!$request->{report_name}){
        die $request->{_locale}->text('No report specified');
    }
    $request->{country_list} = $request->enabled_countries;
    @{$request->{employees}} =  $request->call_procedure(
        funcname => 'employee__all_salespeople'
    );
    @{$request->{languages}} = $request->call_procedure(
        funcname => 'person__list_languages'
        );

    $request->{earn_id} = $request->setting->get('earn_id');
    my $template = $request->{_wire}->get('ui');
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
    return $request->render_report(
        LedgerSMB::Report::Listings::Business_Type->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item list_gifi

List the gifi entries.  No inputs expected or used.

=cut

sub list_gifi {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::GIFI->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item list_warehouse

List the warehouse entries.  No inputs expected or used.

=cut

sub list_warehouse {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::Warehouse->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item list_language

List language entries.  No inputs expected or used.

=cut

sub list_language {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::Language->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item list_sic

Lists sic codes

=cut

sub list_sic {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::SIC->new(%$request)
        );
}

=item generate_balance_sheet

Generates a balance sheet

=cut

sub generate_balance_sheet {
    my ($request) = @_;
    my $rpt = LedgerSMB::Report::Balance_Sheet->new(
        %$request,
        formatter_options => $request->formatter_options,
        from_date  => $request->{from_date} ? $request->parse_date( $request->{from_date} ) : undef,
        to_date  => $request->{to_date} ? $request->parse_date( $request->{to_date} ) : undef,
        column_path_prefix => [ 0 ]);
    $rpt->run_report($request);

    for my $cmp_dates (@{$rpt->comparisons}) {
        my $cmp = LedgerSMB::Report::Balance_Sheet->new(
            %$request,
            formatter_options => $request->formatter_options,
            %$cmp_dates);
        $cmp->run_report($request);
        $rpt->add_comparison($cmp);
    }
    return $request->render_report($rpt);
}

=item search_overpayments

Searches overpayments based on inputs.

=cut

sub search_overpayments {
    my ($request) = @_;
    $request->{hiddens}->{$_} = $request->{$_}
        for qw(batch_id currency exchangerate
               post_date batch_class account_class);

    return $request->render_report(
        LedgerSMB::Report::Listings::Overpayments->new(
            %$request,
            post_date => $request->parse_date( $request->{post_date} ),
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
            formatter_options => $request->formatter_options
        ));
}

=item reverse_overpayment

Reverses overpayments selected from the search overpayments screen.

=cut

sub reverse_overpayment {
    my ($request) = @_;
    my $payment = LedgerSMB::DBObject::Payment->new(%$request);
    for my $rc (1 .. $request->{rowcount_}){
        next unless $request->{"select_$rc"};
        my $args = {id => $request->{"select_$rc"}};
        $args->{$_} = $request->{$_} for qw(post_date batch_id account_class
                                            exchangerate currency);
        $args->{curr} = $args->{currency};
        $payment->overpayment_reverse($args);
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
