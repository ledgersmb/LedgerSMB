=head1 NAME

LedgerSMB::Scripts::goods - Goods and Services workflows for LedgerSMB

=cut

package LedgerSMB::Scripts::goods;

use strict;
use warnings;

use LedgerSMB::Report::Inventory::Search;
use LedgerSMB::Report::Inventory::History;
use LedgerSMB::Report::Invoices::COGS;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Report::Inventory::Partsgroups;
use LedgerSMB::Report::Inventory::Pricegroups;
use LedgerSMB::Report::Inventory::Activity;

=head1 SYNOPSIS

 LedgerSMB::Scripts::goods::search_screen($request);
 LedgerSMB::Scripts::goods::search($request);

=head1 Routines

=over

=item search_screen

=cut

sub search_screen {
    my ($request) = @_;
    $request->{partsgroups} = $request->call_procedure(
       funcname => 'partsgroup__search', args => [undef]
    );
    $request->{report_name} = 'search_goods';
    LedgerSMB::Scripts::reports::start_report($request);
}

=item search

=cut

sub search {
    my ($request) = @_;
    for (qw(so po is ir quo rfq)){
       $request->{col_ordnumber} = 1;
       return LedgerSMB::Report::Inventory::History->new(%$request)
              ->render($request)
               if ($request->{"inc_$_"});
    }
    my $report = LedgerSMB::Report::Inventory::Search->new(%$request);
    $report->render($request);
};

=item search_partsgroups

This routine searches partsgroups.  The partsgroup input is optionally set
for a prefix search

=cut

sub search_partsgroups {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Inventory::Partsgroups->new(%$request);
    $report->render($request);
}

=item search_pricegroups

This routine searches pricegroups.  The pricegroup input is optionally set
for a prefix search

=cut

sub search_pricegroups {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Inventory::Pricegroups->new(%$request);
    $report->render($request);
}

=item inventory_activity

This routine runs the inventory activity report/

=cut

sub inventory_activity {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Inventory::Activity->new(%$request);
    $report->render($request);
}

=item cogs_lines

Runs the cogs lines report.

=cut

sub cogs_lines {
    my ($request) = shift;
    LedgerSMB::Report::Invoices::COGS->new(%$request)->render($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
