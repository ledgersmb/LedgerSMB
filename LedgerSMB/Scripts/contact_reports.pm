=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 SYNOPSIS

This module provides AR/AP aging reports and statements for LedgerSMB.

=head1 METHODS

=cut

package LedgerSMB::Scripts::contact_reports;
our $VERSION = '1.0';

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Report::Contact::Search;
use strict;

=pod

=item search

Runs the search report and displays it

=cut

sub search{
    my ($request) = @_;

    LedgerSMB::DBObject::Report::Contact::Search->prepare_criteria($request);
    my $report = LedgerSMB::DBObject::Report::Contact::Search->new(%$request);
    $report->run_report;
    $report->render($request);
}

return 1;
