
package LedgerSMB::Scripts::inv_reports;

=head1 NAME

LedgerSMB::Scripts::inv_reports - Inventory Reports in LedgerSMB

=head1 SYNPOSIS

  LedgerSMB::Scripts::inv_reports::search_adj($request);

=head1 DESCRIPTION

This provides the general inventory reports for LedgerSMB.

=head1 METHODS

This module doesn't specify any methods.

=head1 ROUTINES

=over

=item search_adj

Searches for inventory adjustment reports

=cut

use strict;
use warnings;

use LedgerSMB::Report::Inventory::Search_Adj;
use LedgerSMB::Report::Inventory::Adj_Details;
use LedgerSMB::Scripts::reports;

sub search_adj{
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Inventory::Search_Adj->new(%$request)
        );
}

=item adj_detail

Shows adjustment details

=cut

sub adj_detail {
    my ($request) = @_;
    $request->{hiddens} = { id => $request->{id}};
    return $request->render_report(
        LedgerSMB::Report::Inventory::Adj_Details->new(%$request)
        );
}

=item approve

Approves the inventory report and enters invoices against them.

=cut

sub approve {
    my ($request) = @_;
    my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
    $rpt->approve;
    $request->{report_name} = 'inventory_adj';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item delete

Deletes the inventory report

=cut

sub delete {
    my ($request) = @_;
    my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
    $rpt->delete;
    $request->{report_name} = 'inventory_adj';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
