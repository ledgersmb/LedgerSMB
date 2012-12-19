=head1 NAME

LedgerSMB::Scripts::order - Order search functions for LedgerSMB

=head1 SYNPOSIS

  LedgerSMB::Scripts::order->get_criteria($request);

=head1 DESCRIPTION

This module contains the routines needed to search for orders, whether for 
shipping or receiving, merging several orders into one, or the like.

=cut

package LedgerSMB::Scripts::order;
use LedgerSMB::App_State;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Report::Orders;

=head1 ROUTINES

=over

=item get_criteria

Expects "search_type" and "oe_class_id" to be set.  Any other properties of 
LedgerSMB::Report::Orders can be set here and will act as defaults.

Search type can be one of

=over

=item search (valid for all types)

=item combine (valid for sales/purchase orders only at this time)

=item generate (valid for sales/purchase orders only)

=back

=cut

sub get_criteria {
    my ($request) = @_;
    my $locale = $LedgerSMB::App_State::Locale;
    $request->{entity_class} = $request->{oe_class_id} % 2 + 1;
    $request->{report_name} = 'orders';
    if ($request->{oe_class_id} == 1){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Sales Orders');
        } elsif ($request->{search_type} eq 'generate'){
            $request->{title} = 
                   $locale->text('Generate Sales Orders from Purchase Orders');
        } elsif ($request->{search_type} eq 'combine'){
            $request->{title} = $locale->text('Combine Sales Orders');
        } elsif ($request->{search_type} eq 'ship'){
            $request->{title} = $locale->text('Ship');
        }
    } elsif ($request->{oe_class_id} == 2){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Purchase Orders');
        } elsif ($request->{search_type} eq 'generate'){
            $request->{title} = 
                   $locale->text('Generate Purchase Orders from Sales Orders');
        } elsif ($request->{search_type} eq 'ship'){
            $request->{title} = $locale->text('Receive');
        }
    } elsif ($request->{oe_class_id} == 3){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Quotations');
        } 
    } elsif ($request->{oe_class_id} == 4){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Requests for Quotation');
        } 
    }
    LedgerSMB::Scripts::reports::start_report($request);
}

=item search

=cut

sub search {
    my $request = shift @_;
    if ($request->{search_type} eq 'combine' 
         or $request->{search_type} eq 'generate'){
       $request->{selectable} = 1;
    }
    my $report = LedgerSMB::Report::Orders->new(%$request);
    $report->render(%request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
