
package LedgerSMB::Scripts::contact_reports;

=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 DESCRIPTION

This module provides contact reports and purchase/sales history for LedgerSMB.

=head1 METHODS

=cut

use LedgerSMB::Report::Contact::EmployeeSearch;
use LedgerSMB::Report::Contact::Search;
use LedgerSMB::Report::Contact::History;
use strict;
use warnings;

our $VERSION = '1.0';

=over

=item employee_search

Runs the employee search report and displays it

=cut

sub employee_search {
    my ($request) = @_;

    return $request->render_report(
        LedgerSMB::Report::Contact::EmployeeSearch->new(
            %$request,
            active_date_from => $request->parse_date( $request->{active_date_from} ),
            active_date_to => $request->parse_date( $request->{active_date_to} ),
            formatter_options => $request->formatter_options
        ));
}

=item search

Runs the search report and displays it

=cut

sub search {
    my ($request) = @_;

    return $request->render_report(
        LedgerSMB::Report::Contact::Search->new(
            %$request,
            active_date_from => $request->parse_date( $request->{active_date_from} ),
            active_date_to => $request->parse_date( $request->{active_date_to} ),
            formatter_options => $request->formatter_options
        ));
}

=item history

Runs the purchase history report and displays it

=cut

sub history {
    my ($request) = @_;

    return $request->render_report(
        LedgerSMB::Report::Contact::History->new(
            %$request,
            start_from => $request->parse_date( $request->{start_from} ),
            start_to => $request->parse_date( $request->{start_to} ),
            date_from => $request->parse_date( $request->{date_from} ),
            date_to => $request->parse_date( $request->{date_to} ),
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
            formatter_options => $request->formatter_options
        ));
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
