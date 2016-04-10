=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 SYNOPSIS

This module provides AR/AP aging reports and statements for LedgerSMB.

=head1 METHODS

=cut

package LedgerSMB::Scripts::contact_reports;

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::Report::Contact::Search;
use LedgerSMB::Report::Contact::History;
use strict;
use warnings;

our $VERSION = '1.0';

=over

=item search

Runs the search report and displays it

=cut

sub search{
    my ($request) = @_;

    my $report = LedgerSMB::Report::Contact::Search->new(%$request);
    $report->run_report;
    $report->render($request);
}

=item history

Runs the purchase history report and displays it

=cut

sub history {
    my ($request) = @_;

    my $report = LedgerSMB::Report::Contact::History->new(%$request);
    $report->run_report;
    $report->render($request);
}

=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of te GNU General Public License version 2 or at your option any later
version.  Please see included LICENSE.txt for more info.

=cut

1;
