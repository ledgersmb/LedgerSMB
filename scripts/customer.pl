#!/usr/bin/perl

=pod

=head1 NAME

LedgerSMB::Scripts::customer - LedgerSMB class defining the Controller
functions, template instantiation and rendering for customer editing and display.

=head1 SYOPSIS

This module is the UI controller for the customer DB access; it provides the 
View interface, as well as defines the Save customer. 
Save customer will update or create as needed.


=head1 METHODS

=cut

package LedgerSMB::Scripts::customer;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Customer;

require 'lsmb-request.pl';

=pod

=over

=item get($self, $request, $user)

Requires form var: id

Extracts a single customer from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the customer informations.

=back

=cut


sub get {
    
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new(base => $request, copy => 'all');
    
    $customer->set( entity_class=> '2' );
    my $result = $customer->get();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'contact', language => $user->{language}, 
	path => 'UI/Contact',
        format => 'HTML');
    $template->render($results);
        
}


sub add_location {
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request, copy => 'all'});
    $customer->set( entity_class=> '2' );
    $customer->save_location();
    $customer->get();

    
    $customer->get_metadata();

    _render_main_screen($customer);
	
}

=pod

=over

=item add

This method creates a blank screen for entering a customer's information.

=back

=cut 

sub add {
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new(base => $request, copy => 'all');
    $customer->set( entity_class=> '2' );
    _render_main_screen($customer);
}

=pod

=over

=item search($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all customers
found that match the search parameters. Search parameters search over address 
as well as customer/Company name.

=back

=cut

sub search {
    my ($request) = @_;
    
    if ($request->type() eq 'POST') {
        # assume it's asking us to do the search, now
        
        my $customer = LedgerSMB::DBObject::Customer->new(base => $request, copy => 'all');
        $customer->set(entity_class=>2);
        my $results = $customer->search($customer->{search_pattern});

        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'Contact/customer', language => $user->{language}, 
            format => 'HTML');
        $template->render($results);
        
    }
    else {
        
        # grab the happy search page out.
        
        my $template = LedgerSMB::Template->new( 
		user => $user,
		path => 'UI/Contact' ,
    		template => 'customer_search', 
		locale => $request->{_locale}, 
		format => 'HTML');
            
        $template->render();
    }
}

=pod

=over

=item save($self, $request, $user)

Saves a customer to the database. The function will update or insert a new 
customer as needed, and will generate a new Company ID for the customer if needed.

=back

=cut

sub save {
    
    my ($request) = @_;

    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->save();
    _render_main_screen($customer);
}

sub edit{
    my $request = shift @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->get();
    _render_main_screen($customer);
}

sub _render_main_screen{
    my $customer = shift @_;
    $customer->get_metadata();

    $customer->{creditlimit} = "$customer->{creditlimit}"; 
    $customer->{discount} = "$customer->{discount}"; 
    $customer->{script} = "customer.pl";

    my $template = LedgerSMB::Template->new( 
	user => $customer->{_user}, 
    	template => 'contact', 
	locale => $customer->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($customer);
}

sub save_contact {
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->save_contact();
    $customer->get;
    _render_main_screen($customer);
}

sub save_bank_account {
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->save_bank_account();
    $customer->get;
    _render_main_screen($customer);
}

sub save_notes {
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->save_notes();
    $customer->get();
    _render_main_screen($customer);
}
    
1;
