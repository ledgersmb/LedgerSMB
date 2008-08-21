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
    $customer->get_credit_id();
    my $template = LedgerSMB::Template->new( 
	template => 'contact', 
	user => $request->{_user},
	locale => $request->{_locale},
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
    
        
    $request->{script} = "customer.pl";
    $request->{account_class} = 2; 
    my $template = LedgerSMB::Template->new( 
		user => $request->{_user},
		path => 'UI/Contact' ,
    		template => 'search', 
		locale => $request->{_locale}, 
		format => 'HTML');
            
    $template->render($request);
}

=pod

=item get_result($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all vendors
found that match the search parameters. Search parameters search over address 
as well as vendor/Company name.

=back

=cut

sub get_results {
    my ($request) = @_;
        
    my $customer = LedgerSMB::DBObject::Customer->new(base => $request, copy => 'all');
    $customer->set(entity_class=>2);
    $customer->{contact_info} = qq|{"%$request->{email}%","%$request->{phone}%"}|;
    my $results = $customer->search();
    if ($customer->{order_by}){
       # TODO:  Set ordering logic
    };

    # URL Setup
    my $baseurl = "$request->{script}";
    my $search_url = "$base_url?action=get_results";
    my $get_url = "$base_url?action=get&account_class=$request->{account_class}";
    for (keys %$vendor){
        next if $_ eq 'order_by';
        $search_url .= "&$_=$form->{$_}";
    }

    # Column definitions for dynatable
    @columns = qw(legal_name meta_number business_type curr);
    my %column_heading;
    $column_heading{legal_name} = {
        text => $request->{_locale}->text('Name'),
	href => "$search_url&order_by=legal_name",
    };
    $column_heading{meta_number} = {
        text => $request->{_locale}->text('Customer Number'),
	href => "$search_url&order_by=meta_number",
    };
    $column_heading{business_type} = {
        text => $request->{_locale}->text('Business Type'),
	href => "$search_url&order_by=business_type",
    };
    $column_heading{curr} = {
        text => $request->{_locale}->text('Currency'),
	href => "$search_url&order_by=curr",
    };

    my @rows;
    for $ref (@{$customer->{search_results}}){
	push @rows, 
                {legal_name   => $ref->{legal_name},
                meta_number   => {text => $ref->{meta_number},
                                  href => "$get_url&entity_id=$ref->{entity_id}"		                           . "&meta_number=$ref->{meta_number}"
		                 },
		business_type => $ref->{business_type},
                curr          => $ref->{curr},
                };
    }
# CT:  The CSV Report is broken.  I get:
# Not an ARRAY reference at 
# /usr/lib/perl5/site_perl/5.8.8/CGI/Simple.pm line 423
# Disabling the button for now.
    my @buttons = (
#	{name => 'action',
#        value => 'csv_vendor_list',
#        text => $vendor->{_locale}->text('CSV Report'),
#        type => 'submit',
#        class => 'submit',
#        },
	{name => 'action',
        value => 'add',
        text => $customer->{_locale}->text('Add Customer'),
        type => 'submit',
        class => 'submit',
	}
    );

    my $template = LedgerSMB::Template->new( 
		user => $user,
		path => 'UI' ,
    		template => 'form-dynatable', 
		locale => $customer->{_locale}, 
		format => ($request->{FORMAT}) ? $request->{FORMAT}  : 'HTML',
    );
            
    $template->render({
	form    => $customer,
	columns => \@columns,
        hiddens => $vendor,
	buttons => \@buttons,
	heading => \%column_heading,
	rows    => \@rows,
    });
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

sub save_credit {
    my ($request) = @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->save_credit();
    $customer->get();
    _render_main_screen($customer);
}

sub save_credit_new {
    my ($request) = @_;
    $request->{credit_id} = undef;
    save_credit($request);
}


sub edit{
    my $request = shift @_;
    my $customer = LedgerSMB::DBObject::Customer->new({base => $request});
    $customer->get();
    $customer->get_credit_id();
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
    
eval { do "scripts/custom/customer.pl"};
1;
