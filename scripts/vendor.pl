#!/usr/bin/perl

=pod

=head1 NAME

LedgerSMB::Scripts::vendor - LedgerSMB class defining the Controller
functions, template instantiation and rendering for vendor editing and display.

=head1 SYOPSIS

This module is the UI controller for the vendor DB access; it provides the 
View interface, as well as defines the Save vendor. 
Save vendor will update or create as needed.


=head1 METHODS

=cut

package LedgerSMB::Scripts::vendor;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Vendor;

require 'lsmb-request.pl';

=pod

=over

=item get($self, $request, $user)

Requires form var: id

Extracts a single vendor from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the vendor informations.

=back

=cut


sub get {
    
    my ($request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
    
    $vendor->set( entity_class=> '2' );
    my $result = $vendor->get();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'contact', language => $user->{language}, 
	path => 'UI/Contact',
        format => 'HTML');
    $template->render($results);
        
}


sub add_location {
    my ($request) = @_;
    my $vendor= LedgerSMB::DBObject::Vendor->new({base => $request, copy => 'all'});
    $vendor->set( entity_class=> '2' );
    $vendor->save_location();
    $vendor->get();

    
    $vendor->get_metadata();

    _render_main_screen($vendor);
	
}

=pod

=over

=item add

This method creates a blank screen for entering a vendor's information.

=back

=cut 

sub add {
    my ($request) = @_;
    my $vendor= LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
    $vendor->set( entity_class=> '2' );
    _render_main_screen($vendor);
}

=pod

=over

=item search($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all vendors
found that match the search parameters. Search parameters search over address 
as well as vendor/Company name.

=back

=cut

sub search {
    my ($request) = @_;
    
    if ($request->type() eq 'POST') {
        # assume it's asking us to do the search, now
        
        my $vendor = LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
        $vendor->set(entity_class=>2);
        my $results = $vendor->search($vendor->{search_pattern});

        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'Contact/vendor', language => $user->{language}, 
            format => 'HTML');
        $template->render($results);
        
    }
    else {
        
        # grab the happy search page out.
        
        my $template = LedgerSMB::Template->new( 
		user => $user,
		path => 'UI/Contact' ,
    		template => 'vendor_search', 
		locale => $request->{_locale}, 
		format => 'HTML');
            
        $template->render();
    }
}

=pod

=over

=item save($self, $request, $user)

Saves a vendor to the database. The function will update or insert a new 
vendor as needed, and will generate a new Company ID for the vendor if needed.

=back

=cut

sub save {
    
    my ($request) = @_;

    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor->save();
    _render_main_screen($vendor);
}

sub edit{
    my $request = shift @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor->get();
    _render_main_screen($vendor);
}

sub _render_main_screen{
    my $vendor = shift @_;
    $vendor->get_metadata();

    $vendor->{creditlimit} = "$vendor->{creditlimit}"; 
    $vendor->{discount} = "$vendor->{discount}"; 
    $vendor->{script} = "vendor.pl";

    my $template = LedgerSMB::Template->new( 
	user => $vendor->{_user}, 
    	template => 'contact', 
	locale => $vendor->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($vendor);
}

sub save_contact {
    my ($request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor ->save_contact();
    $vendor ->get;
    _render_main_screen($vendor );
}

sub save_bank_account {
    my ($request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor ->save_bank_account();
    $vendor ->get;
    _render_main_screen($vendor );
}

1;
