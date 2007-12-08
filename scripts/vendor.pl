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
    
    $vendor->set( entity_class=> '1' );
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
    $vendor->set( entity_class=> '1' );
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
    $vendor->set( entity_class=> '1' );
    _render_main_screen($vendor);
}

=pod

=over

=item search_result($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all vendors
found that match the search parameters. Search parameters search over address 
as well as vendor/Company name.

=back

=cut

sub get_results {
    my ($request) = @_;
        
    my $vendor = LedgerSMB::DBObject::Vendor->new(base => $request, copy => 'all');
    $vendor->set(entity_class=>1);
    $vendor->{contact_info} = qq|{"%$request->{email}%","%$request->{phone}%"}|;
    my $results = $vendor->search();
    if ($vendor->{order_by}){
       # TODO:  Set ordering logic
    };

    # URL Setup
    my $baseurl = "$request->{script}";
    my $search_url = "$base_url?action=get_results";
    my $get_url = "$base_url?action=get";
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
        text => $request->{_locale}->text('Vendor Number'),
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
    for $ref (@{$vendor->{search_results}}){
	push @rows, 
                {legal_name   => $ref->{legal_name},
                meta_number   => {text => $ref->{meta_number},
                                  href => "$get_url&id=$ref->{entity_id}"},
		business_type => $ref->{business_type},
                curr          => $ref->{curr},
                };
    }

    my @buttons = (
	{name => 'action',
        value => 'csv_chart_of_accounts',
        text => $vendor->{_locale}->text('CSV Report'),
        type => 'submit',
        class => 'submit',
        },
	{name => 'action',
        value => 'add',
        text => $vendor->{_locale}->text('Add Vendor'),
        type => 'submit',
        class => 'submit',
	}
    );

    my $template = LedgerSMB::Template->new( 
		user => $user,
		path => 'UI' ,
    		template => 'form-dynatable', 
		locale => $vendor->{_locale}, 
		format => 'HTML');
            
    $template->render({
	form    => $vendor,
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

sub search {
    my ($request) = @_;
    $request->{account_class} = 1;
    $request->{script} = 'vendor.pl';
    my $template = LedgerSMB::Template->new( 
	user => $request->{_user}, 
    	template => 'search', 
	locale => $request->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($request);
}    

sub save_contact {
    my ($request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor->save_contact();
    $vendor->get;
    _render_main_screen($vendor );
}


sub save_bank_account {
    my ($request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor->save_bank_account();
    $vendor->get;
    _render_main_screen($vendor );
}

sub save_notes {
    my ($request) = @_;
    my $vendor = LedgerSMB::DBObject::Vendor->new({base => $request});
    $vendor->save_notes();
    $vendor->get();
    _render_main_screen($vendor );
}
eval { do "scripts/custom/vendor.pl"};
    
1;
