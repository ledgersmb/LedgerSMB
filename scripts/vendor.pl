
=pod

=head1 NAME

LedgerSMB::Scripts::Vendor - LedgerSMB class defining the Controller
functions, template instantiation and rendering for Vendor editing and display.

=head1 SYOPSIS

This module is the UI controller for the Vendor DB access; it provides the 
View interface, as well as defines the Save Vendor. 
Save vendor will update or create as needed.


=head1 METHODS

=cut

package LedgerSMB::Scripts::Vendor;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Vendor;

=pod

=over

=item get($self, $request, $user)

Requires form var: id

Extracts a single Vendor from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the vendor informations.

=back

=cut

sub get {
    
    my ($class, $request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
    my $result = $vendor->get($vendor->{id});
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'vendor.html', language => $user->{language}, 
        format => 'html');
    $template->render($results);
        
}

=pod

=over

=item search($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all vendors
found that match the search parameters. Search parameters search over address 
as well as Vendor/Company name.

=back

=cut

sub search {
    my ($class, $request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
    my $results = $vendor->search($vendor->{search_pattern});
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'vendor_search.html', language => $user->{language}, 
        format => 'html');
    $template->render($results);
}

=pod

=over

=item save($self, $request, $user)

Saves a Vendor to the database. The function will update or insert a new 
vendor as needed, and will generate a new Company ID for the vendor if needed.

=back

=cut

sub save {
    
    my ($class, $request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
    my $result = $vendor->save_to_db();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'vendor.html', language => $user->{language}, 
        format => 'html');
    $template->render($result);    
}

=pod

=over

=item vendor_invoice($self, $request, $user)

Added based on existing New Vendor screen.

=back

=cut


sub vendor_invoice {
    
    
}

=pod

=over

=item purchase_order($self, $request, $user)

Added based on existing New Vendor screen.

=back

=cut

sub purchase_order {
    
    
}

=pod

=over

=item rfq($self, $request, $user)

Added based on existing New Vendor screen.

=back

=cut

sub rfq {
    
    $self->save(@_);
    my ($class, $request) = @_;
    # saves a new vendor, then generates something.
    
}

=pod

=over

=item pricelist($self, $request, $user)

Added based on existing New Vendor screen.

=back

=cut

sub pricelist {
    
    
    
}

1;
