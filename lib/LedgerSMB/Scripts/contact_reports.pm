
package LedgerSMB::Scripts::contact_reports;

=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 DESCRIPTION

This module provides contact reports and purchase/sales history for LedgerSMB.

=head1 METHODS

=cut

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

    return $request->render_report(
        LedgerSMB::Report::Contact::Search->new(%$request)
        );
}

=item history

Runs the purchase history report and displays it

=cut

sub history {
    my ($request) = @_;

    return $request->render_report(
        LedgerSMB::Report::Contact::History->new(%$request)
        );
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
