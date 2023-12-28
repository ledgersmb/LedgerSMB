
package LedgerSMB::Scripts::goods;

=head1 NAME

LedgerSMB::Scripts::goods - Goods and Services workflows for LedgerSMB

=head1 DESCRIPTION

Implements the goods search, parts groups, price groups and
inventory activity screens.

=head1 SYNOPSIS

 LedgerSMB::Scripts::goods::search_screen($request);
 LedgerSMB::Scripts::goods::search($request);

=cut

use strict;
use warnings;

use List::Util qw(any);

use LedgerSMB::Report::Inventory::Search;
use LedgerSMB::Report::Inventory::History;
use LedgerSMB::Report::Invoices::COGS;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Report::Inventory::Partsgroups;
use LedgerSMB::Report::Inventory::Pricegroups;
use LedgerSMB::Report::Inventory::Activity;

=head1 METHODS

=over

=item search_screen

=cut

sub search_screen {
    my ($request) = @_;
    @{$request->{partsgroups}} = $request->call_procedure(
       funcname => 'partsgroup__search', args => [undef]
    );
    $request->{report_name} = 'search_goods';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item search

=cut

sub search {
    my ($request) = @_;
    if (any { $request->{"inc_$_"} } qw(so po is ir quo rfq) ) {
       $request->{col_ordnumber} = 1;
       return $request->render_report(
           LedgerSMB::Report::Inventory::History->new(
               %$request,
               formatter_options => $request->formatter_options,
               from_date => $request->parse_date( $request->{from_date} ),
               to_date => $request->parse_date( $request->{to_date} ),
           ));
    }
    return $request->render_report(
        LedgerSMB::Report::Inventory::Search->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
        ));
}

=item search_partsgroups

This routine searches partsgroups.  The partsgroup input is optionally set
for a prefix search

=cut

sub search_partsgroups {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Inventory::Partsgroups->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item search_pricegroups

This routine searches pricegroups.  The pricegroup input is optionally set
for a prefix search

=cut

sub search_pricegroups {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Inventory::Pricegroups->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item inventory_activity

This routine runs the inventory activity report/

=cut

sub inventory_activity {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Inventory::Activity->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
        ));
}

=item cogs_lines

Runs the cogs lines report.

=cut

sub cogs_lines {
    my ($request) = shift;
    return $request->render_report(
        LedgerSMB::Report::Invoices::COGS->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
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
