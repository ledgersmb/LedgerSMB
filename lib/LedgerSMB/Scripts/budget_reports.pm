
package LedgerSMB::Scripts::budget_reports;

=head1 NAME

LedgerSMB::Scripts::budget_reports - Budget search and reporting workflows.

=head1 DESCRIPTION

Budget search and reporting entry points.

=head1 METHODS

=cut

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
    return $report->render($request);
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
    return $report->render($request);
}

=back

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
