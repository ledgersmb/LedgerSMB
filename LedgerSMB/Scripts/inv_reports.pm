=head1 NAME

LedgerSMB::Scripts::inv_reports - Inventory Reports in LedgerSMB

=head1 SYNPOSIS

  LedgerSMB::Scripts::inv_reports::search_adj($request);

=head1 DESCRIPTION

This provides the general inventory reports for LedgerSMB.

=head1 ROUTINES

=over

=item search_adj

Searches for inventory adjustment reports

=cut

package LedgerSMB::Scripts::inv_reports;

use strict;
use warnings;

use LedgerSMB::Report::Inventory::Search_Adj;
use LedgerSMB::Report::Inventory::Adj_Details;
use LedgerSMB::Scripts::reports;

sub search_adj{
    my ($request) = @_;
    my $rpt = LedgerSMB::Report::Inventory::Search_Adj->new(%$request);
    $rpt->run_report;
    $rpt->render($request);
}

=item adj_detail

Shows adjustment details

=cut

sub adj_detail {
    my ($request) = @_;
    $request->{hiddens} = { id => $request->{id}};
    my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
    $rpt->run_report;
    $rpt->render($request);
}

=item approve

Approves the inventory report and enters invoices against them.

=cut

sub approve {
    my ($request) = @_;
    my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
    $rpt->approve;
    $request->{report_name} = 'inventory_adj';
    LedgerSMB::Scripts::reports::start_report($request);
}

=item delete

Deletes the inventory report

=cut

sub delete {
    my ($request) = @_;
    my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
    $rpt->delete;
    $request->{report_name} = 'inventory_adj';
    LedgerSMB::Scripts::reports::start_report($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
