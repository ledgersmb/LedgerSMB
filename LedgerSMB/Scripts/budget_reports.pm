=head1 NAME

LedgerSMB::Scripts::budget_reports - Budget search and reporting workflows.

=head1 METHODS

=cut

package LedgerSMB::Scripts::budget_reports;

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::Report::Budget::Search;
use LedgerSMB::Report::Budget::Variance;
use strict;
use warnings;

our $VERSION = '1.0';

=over

=item search

Searches for budgets.  See LedgerSMB::Report::Budget::Search for
more.

=cut

sub search {
    my ($request) = @_;
    LedgerSMB::Report::Budget::Search->prepare_criteria($request);
    my $report = LedgerSMB::Report::Budget::Search->new(%$request);
    $report->run_report;
    $report->render($request);
}

=item variance_report

This runs a variance report.  Requires that id be set.  Shows amounts budgetted
vs amounts used.

=cut

sub variance_report {
    my ($request) = @_;
    my $id = $request->{id};
    my $report = LedgerSMB::Report::Budget::Variance->for_budget_id($id);
    $report->run_report;
    $report->render($request);
}

=back

=cut

1;
