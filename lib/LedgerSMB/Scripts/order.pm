
package LedgerSMB::Scripts::order;

=head1 NAME

LedgerSMB::Scripts::order - Order search functions for LedgerSMB

=head1 SYNPOSIS

  LedgerSMB::Scripts::order->get_criteria($request);

=head1 DESCRIPTION

This module contains the routines needed to search for orders, whether for
shipping or receiving, merging several orders into one, or the like.

=cut

use strict;
use warnings;

use LedgerSMB::Scripts::reports;
use LedgerSMB::Report::Orders;
use LedgerSMB::Magic qw( OEC_PURCHASE_ORDER OEC_SALES_ORDER OEC_QUOTATION OEC_RFQ );

use LedgerSMB::old_code qw(dispatch);

=head1 METHODS

This module doesn't specify any methods.

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
    my $locale = $request->{_locale};
    $request->{entity_class} = $request->{oe_class_id} % 2 + 1;
    $request->{report_name} = 'orders';
    $request->{open} = 1 if $request->{search_type} ne 'search';
    if ($request->{oe_class_id} == OEC_SALES_ORDER ){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Sales Orders');
        } elsif ($request->{search_type} eq 'generate'){
            $request->{title} =
                   $locale->text('Generate Purchase Orders from Sales Orders');
        } elsif ($request->{search_type} eq 'combine'){
            $request->{title} = $locale->text('Combine Sales Orders');
        } elsif ($request->{search_type} eq 'ship'){
            $request->{title} = $locale->text('Ship');
        }
    } elsif ($request->{oe_class_id} == OEC_PURCHASE_ORDER ){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Purchase Orders');
        } elsif ($request->{search_type} eq 'combine'){
            $request->{title} = $locale->text('Combine Purchase Orders');
        } elsif ($request->{search_type} eq 'generate'){
            $request->{title} =
                   $locale->text('Generate Sales Orders from Purchase Orders');
        } elsif ($request->{search_type} eq 'ship'){
            $request->{title} = $locale->text('Receive');
        }
    } elsif ($request->{oe_class_id} == OEC_QUOTATION ){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Quotations');
        }
    } elsif ($request->{oe_class_id} == OEC_RFQ ){
        if ($request->{search_type} eq 'search'){
            $request->{title} = $locale->text('Search Requests for Quotation');
        }
    }
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item search

=cut

sub search {
    my $request = shift @_;
    if ($request->{search_type} ne 'search'){
       $request->{open} =1;
       delete $request->{closed};
    }
    if (($request->{search_type} eq 'combine') or
        ($request->{search_type} eq 'generate')
    ){
       $request->{selectable} = 1;
       $request->{col_select} = 1;
    } elsif ($request->{search_type} eq 'ship'){
       $request->{href_action}='ship_receive';
    }
    my $report = LedgerSMB::Report::Orders->new(%$request);
    if ($request->{search_type} eq 'combine'){
        $report->buttons([{
            text => $request->{_locale}->text('Combine'),
            type => 'submit',
           class => 'submit',
            name => 'action',
           value => 'combine',
        }]);
    } elsif ($request->{search_type} eq 'generate'){
        $report->buttons([{
            text => $request->{_locale}->text('Generate'),
            type => 'submit',
           class => 'submit',
            name => 'action',
           value => 'generate',
        }]);
    }
    return $report->render($request);
}

=item combine

This combines sales orders or purchase orders.  It could be easily supported for
quotations and rfq's but this is not currently allowed.

=cut

sub combine {
    my ($request) = @_;
    my @ids;
    for (1 .. $request->{rowcount_}){
        push @ids, $request->{"selected_$_"} if $request->{"selected_$_"};
    }
    $request->call_procedure(funcname => 'order__combine', args => [\@ids]);
    $request->{search_type} = 'combine';
    return get_criteria($request);
}

=item generate

This is just a dispatch handle currently to old/bin/oe's generate_purchase_orders
callback.

=cut

sub generate {
    my ($request) = @_;

    return dispatch('oe.pl', 'generate_purchase_orders', $request);
}

=back

=head1 LICENSE AND COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
