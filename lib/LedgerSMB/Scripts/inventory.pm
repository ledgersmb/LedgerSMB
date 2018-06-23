
package LedgerSMB::Scripts::inventory;

=head1 NAME

LedgerSMB::Scripts::inventory - Web entry points for inventory adjustment

=head1 DESCRIPTION

This module implements inventory adjustment entry points.

=head1 METHODS

=cut

use strict;
use warnings;

use LedgerSMB::Template;
use LedgerSMB::Inventory::Adjust;
use LedgerSMB::Inventory::Adjust_Line;
use LedgerSMB::Report::Inventory::Search_Adj;
use LedgerSMB::Report::Inventory::Adj_Details;

=over

=item begin_adjust

This entry point specifies the screen for setting up an inventory adjustment.

=cut

sub begin_adjust {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
    user => $request->{_user},
        template => 'adjustment_setup',
    locale => $request->{_locale},
    path => 'UI/inventory',
        format => 'HTML'
    );
    return $template->render($request);
}

=item enter_adjust

This entry point specifies the screen for entering an inventory adjustment.

=cut

sub enter_adjust {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
    user => $request->{_user},
        template => 'adjustment_entry',
    locale => $request->{_locale},
    path => 'UI/inventory',
        format => 'HTML'
    );
    return $template->render($request);
}


=item adjustment_next

This function is triggered on the next button on the adjustment entry screen.
It retrieves inventory information, calculates adjustment values, and displays the
screen.

=cut

sub adjustment_next {
    my ($request) = @_;
    my $adjustment = LedgerSMB::Inventory::Adjust->new(%$request);
    for my $i (1 .. $request->{rowcount}){
        if ($request->{"id_$i"} eq 'new' or not $request->{"id_$i"}){
            my $item = $adjustment->get_part_at_date(
                $request->{transdate}, $request->{"partnumber_$i"});
            $request->{"id_$i"} = $item->{id};
            $request->{"description_$i"} = $item->{description};
            $request->{"onhand_$i"} = $item->{onhand};
        }
        $request->{"counted_$i"} ||= 0;
        $request->{"qty_$i"} =
            $request->{"onhand_$i"} - $request->{"counted_$i"};
    }
    ++$request->{rowcount};
    return enter_adjust($request);
}

=item adjustment_save

This function saves the inventory adjustment report and then creates the required
invoices.

=cut

sub _lines_from_form {
    my ($adjustment, $hashref) = @_;
    my @lines;
    for my $ln (1 .. $hashref->{rowcount}){
        next
          if $hashref->{"id_$ln"} eq 'new';
        my $line = LedgerSMB::Inventory::Adjust_Line->new(
          parts_id => $hashref->{"id_$ln"},
         partnumber => $hashref->{"partnumber_$ln"},
            counted => $hashref->{"counted_$ln"},
           expected => $hashref->{"onhand_$ln"},
           variance => $hashref->{"onhand_$ln"} - $hashref->{"counted_$ln"});
        push @lines, $line;
    }
    my $rows = $adjustment->rows;
    push @$rows, @lines;
    return $adjustment->rows($rows);
}


sub adjustment_save {
    my ($request) = @_;
    my $adjustment = LedgerSMB::Inventory::Adjust->new(%$request);
    _lines_from_form($adjustment, $request);
    $adjustment->save;
    return begin_adjust($request);
}

=item adjustment_list

=cut

sub adjustment_list {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Inventory::Adjustments->new(%$request);
    return $report->render($request);
}

=item adjustment_approve

=cut

sub adjustment_approve {
    my ($request) = @_;
    my $adjust = LedgerSMB::Inventory::Adjustment->new(%$request);
    $adjust->approve;
    $request->{report_name} = 'list_inventory_counts';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item adjustment_delete

=back

=cut

sub adjustment_delete {
    my ($request) = @_;
    my $adjust = LedgerSMB::Inventory::Adjustment->new(%$request);
    $adjust->delete;
    $request->{report_name} = 'list_inventory_counts';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
