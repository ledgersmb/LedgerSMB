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
package LedgerSMB::Scripts::customer;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Customer;

#require 'lsmb-request.pl';

=over

=item begin_adjust

This entry point specifies the screen for setting up an inventory adjustment.

=back

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

=over

=item enter_adjust

This entry point specifies the screen for entering an inventory adjustment.

=back

=cut

sub enter_adjust {
    my ($request) = @_;
    my $adjustment = LedgerSMB::DBObject::Inventory->new(base => $request);
    my $template = LedgerSMB::Template->new(
	user => $request->{_user}, 
    	template => 'adjustment_entry', 
	locale => $request->{_locale},
	path => 'UI/inventory',
        format => 'HTML'
    );
    $template->render($adjustment);
}


=over

=item adjustment_next

This function is triggered on the next button on the adjustment entry screen.
It retrieves inventory information, calculates adjustment values, and displays the
screen.

=back

=cut

sub adjustment_next {
    my ($request) = @_;
    my $adjustment = LedgerSMB::DBObject::Inventory->new(base => $request);
    for my $i (1 .. $adjustment->{rowcount}){
        if ($adjustment->{"row_$i"} eq "new"){
            my $item = $adjustment->retrieve_item_at_date(
		$adjustment->{"partnumber_new_$i"});
            $adjustment->{"row_$i"} = $item->{id};
            $adjustment->{"description_$i"} = $item->{description};
            $adjustment->{"onhand_$i"} = $item->{onhand};
        }
        $adjustment->{"qty_$i"} = $adjustment->{"onhand_$i"} 
		- $adjustment->{"counted_$i"}; 
    }
    ++$adjustment->{rowcount};
    enter_adjust($adjustment);
}

=over

=item adjustment_save

This function saves the inventory adjustment report and then creates the required
invoices.

=back

=cut

sub adjustment_save {
    my ($request) = @_;
    my $adjustment = LedgerSMB::DBObject::Inventory->new(base => $request);
    $adjustment->save;
    begin_adjust($request);
} 
1;
