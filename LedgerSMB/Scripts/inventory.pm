=pod

=head1 NAME

LedgerSMB::Scripts::inventory - LedgerSMB class defining the Controller
functions, template instantiation and rendering for inventory management.

=head1 SYOPSIS

This module is the UI controller for the customer DB access; it provides the
View interface, as well as defines the Save customer.
Save customer will update or create as needed.


=head1 METHODS

=cut
package LedgerSMB::Scripts::inventory;

use strict;
use warnings;

use LedgerSMB::Template;
use LedgerSMB::Inventory::Adjust;
use LedgerSMB::Inventory::Adjust_Line;
use LedgerSMB::Report::Inventory::Search_Adj;
use LedgerSMB::Report::Inventory::Adj_Details;

#require 'lsmb-request.pl';

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
    $template->render($request);
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
    $template->render($request);
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
        if ($request->{"id_$i"} eq "new" or !$request->{"id_$i"}){
            my $item = $adjustment->get_part_at_date(
        $request->{transdate}, $request->{"partnumber_$i"});
            $request->{"id_$i"} = $item->{id};
            $request->{"description_$i"} = $item->{description};
            $request->{"onhand_$i"} = $item->{onhand};
        }
        $request->{"counted_$i"} ||= 0;
        $request->{"qty_$i"} = $request->{"onhand_$i"}
        - $request->{"counted_$i"};
    }
    ++$request->{rowcount};
    enter_adjust($request);
}

=item adjustment_save

This function saves the inventory adjustment report and then creates the required
invoices.

=cut

sub adjustment_save {
    my ($request) = @_;
    my $adjustment = LedgerSMB::Inventory::Adjust->new(%$request);
    $adjustment->lines_from_form($request);
    $adjustment->save;
    begin_adjust($request);
}

=item adjustment_list

=cut

sub adjustment_list {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Inventory::Adjustments->new(%$request);
    $report->render($request);
}

=item adjustment_approve

=cut

sub adjustment_approve {
    my ($request) = @_;
    my $adjust = LedgerSMB::Inventory::Adjustment->new(%$request);
    $adjust->approve;
    $request->{report_name} = 'list_inventory_counts';
    LedgerSMB::Scripts::report::begin_report($request);
}

=item adjustment_delete

=back

=cut

sub adjustment_delete {
    my ($request) = @_;
    my $adjust = LedgerSMB::Inventory::Adjustment->new(%$request);
    $adjust->delete;
    $request->{report_name} = 'list_inventory_counts';
    LedgerSMB::Scripts::report::begin_report($request);
}

1;
