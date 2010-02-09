package LedgerSMB::ScriptLib::Company;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Customer;
use LedgerSMB::DBObject::Vendor;

my $ec_labels = {
      1 => 'Vendor',
      2 => 'Customer',
};

=pod

=head1 NAME

LedgerSMB::ScriptLib::Company - LedgerSMB class defining the Controller
functions, template instantiation and rendering for vendor and customer editing 
and display.  This would also form the basis for other forms of company
contacts.

=head1 SYOPSIS

This module is the UI controller for the vendor DB access; it provides the 
View interface, as well as defines the Save vendor. 
Save vendor/customer will update or create as needed.


=head1 METHODS

=over

=item set_entity_class($request) returns int entity class

Errors if not inherited.  Inheriting classes MUST define this to set
$entity_class appropriately.

=back

=cut

sub set_entity_class {
    my ($request) = @_;
    $request->{_script_handle}->set_entity_class(@_) || $request->error(
       "Error:  Cannot call LedgerSMB::ScriptLib::Company::set_entity_class " .
       "directly!");
}

=pod

=over

=item new_company($request) 

returns object inheriting LedgerSMB::DBObject::Company

This too must be defined in classes that inherit this class.

=back

=cut

sub new_company {
    my ($request) = @_;
    $request->{_script_handle}->new_company(@_) || $request->error(
       "Error:  Cannot call LedgerSMB::ScriptLib::Company::new_company " .
       "directly!");
}

=pod

=over

=item get($self, $request, $user)

Requires form var: id

Extracts a single company from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the company informations.

=back

=cut

sub get {
    
    my ($request) = @_;
    my $company = new_company($request);
    set_entity_class($company);
    $company->get();
    $company->get_credit_id();
#    $company->get_metadata(); It will be called from _render_main_screen
    _render_main_screen($company);
}

=pod

=over

=item add_location 

Adds a location to the company as defined in the inherited object

=back

=cut

sub add_location {
    my ($request) = @_;
    my $company = new_company($request);
    set_entity_class($company);
    $company->save_location();
    $company->get();

    
    $company->get_metadata();

    _render_main_screen($company);
	
}

=pod

=over

=item save_new_location 

Adds a location to the company as defined in the inherited object, not
overwriting existing locations.

=back

=cut

sub save_new_location {
    my ($request) = @_;
    delete $requet->{location_id};
   add_location($request);
}

=pod

=over

=item generate_control_code 

Sets $company->{control_code} equal to the next in the series of entity_control 
values

=back

=cut

sub generate_control_code {
    my ($request) = @_;
    my $company = new_company($request);
    
    my ($ref) = $company->call_procedure(
                             procname => 'setting_increment', 
                             args     => ['entity_control']
                           );
    ($company->{control_code}) = values %$ref;
    $company->{dbh}->commit;
    if ($company->{meta_number}){
        edit($company);
    } else {
       _render_main_screen($company);
    }
    
}

=pod

=over

=item add

This method creates a blank screen for entering a company's information.

=back

=cut 

sub add {
    my ($request) = @_;
    my $company = new_company($request);
    set_entity_class($company);
    _render_main_screen($company);
}

=pod

=over

=item get_result($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all vendors
found that match the search parameters. Search parameters search over address 
as well as vendor/Company name.

=back

=cut

sub get_results {
    my ($request) = @_;
        
    my $company = new_company($request);
    set_entity_class($company);
    $company->{contact_info} = 
             qq|{"%$request->{email}%","%$request->{phone}%"}|;
    my $results = $company->search();
    if ($company->{order_by}){
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
    @columns = qw(legal_name entity_control_code meta_number credit_description 
		business_type curr);
    my %column_heading;
    $column_heading{legal_name} = {
        text => $request->{_locale}->text('Name'),
	href => "$search_url&order_by=legal_name",
    };
    $column_heading{entity_control_code} = {
        text => $request->{_locale}->text('Control Code'),
	href => "$search_url&order_by=entity_control_code",
    };
    $column_heading{legal_name} = {
        text => $request->{_locale}->text('Name'),
	href => "$search_url&order_by=legal_name",
    };
    $column_heading{meta_number} = {
        text => $request->{_locale}->text('Vendor Number'),
	href => "$search_url&order_by=meta_number",
    };
    $column_heading{credit_description} = {
        text => $request->{_locale}->text('Description'),
	href => "$search_url&order_by=credit_description",
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
    for $ref (@{$company->{search_results}}){
	push @rows, 
                {legal_name   => $ref->{legal_name},
		entity_control_code => $ref->{entity_control_code},
		credit_description => $ref->{credit_description},
                meta_number   => {text => $ref->{meta_number},
                                  href => "$get_url&entity_id=$ref->{entity_id}"		                           . "&meta_number=$ref->{meta_number}"
		                 },
		business_type => $ref->{business_type},
                curr          => $ref->{curr},
                };
    }
    my $label = $ec_labels->{"$company->{account_class}"};
# CT:  Labels for i18n:
# text->{'Add Customer')
# text->('Add Vendor')

# CT:  The CSV Report is broken.  I get:
# Not an ARRAY reference at 
# /usr/lib/perl5/site_perl/5.8.8/CGI/Simple.pm line 423
# Disabling the button for now.
    my @buttons = (
#	{name => 'action',
#        value => 'csv_company_list',
#        text => $company->{_locale}->text('CSV Report'),
#        type => 'submit',
#        class => 'submit',
#        },
	{name => 'action',
        value => 'add',
        text => $company->{_locale}->text("Add $label"),
        type => 'submit',
        class => 'submit',
	}
    );

    my $template = LedgerSMB::Template->new( 
		user => $user,
		path => 'UI' ,
    		template => 'form-dynatable', 
		locale => $company->{_locale}, 
		format => ($request->{FORMAT}) ? $request->{FORMAT}  : 'HTML',
    );
            
    $template->render({
	form    => $company,
	columns => \@columns,
        hiddens => $company,
	buttons => \@buttons,
	heading => \%column_heading,
	rows    => \@rows,
    });
}

=pod

=over

=item csv_company_list($request)

Generates CSV report (not working at present)

=back

=cut

sub csv_company_list {
    my ($request) = @_;
    $request->{FORMAT} = 'CSV';
    get_results($request); 
}

=pod

=over

=item save($self, $request, $user)

Saves a company to the database. The function will update or insert a new 
company as needed, and will generate a new Company ID for the company if needed.

=back

=cut

sub save {
    
    my ($request) = @_;

    my $company = new_company($request);
    if (_close_form($company)){
        $company->save();
    }
    _render_main_screen($company);
}

=pod

=over

=item save_credit($request)

This inserts or updates a credit account of the sort listed here.

=back

=cut

sub save_credit {
    
    my ($request) = @_;

    my $company = new_company($request);
    my @taxes;
    $company->{tax_ids} = [];
    for my $key(keys %$company){
        if ($key =~ /^taxact_(\d+)$/){
           my $tax = $1;
           push @{$company->{tax_ids}}, $tax;
        }  
    }
    if (_close_form($company)){
        $company->save_credit();
    }
    $company->get();
    _render_main_screen($company);
}

=pod

=over

=item save_credit_new($request)

This inserts a new credit account.

=back

=cut


sub save_credit_new {
    my ($request) = @_;
    $request->{credit_id} = undef;
    save_credit($request);
}

=pod

=over

=item edit($request)

Displays a company for editing.  Needs the following to be set:
entity_id, account_class, and meta_number.

=back

=cut

sub edit{
    my $request = shift @_;
    my $company = LedgerSMB::DBObject::Vendor->new({base => $request});

    $company->get();
    _render_main_screen($company);
}

=pod

=over

=item PRIVATE _render_main_screen($company)

Pulls relevant data from db and renders the data entry screen for it.

=back

=cut

sub _render_main_screen{
    my $company = shift @_;
    $company->close_form;
    $company->open_form;
    $company->{dbh}->commit;
    $company->get_metadata();

    $company->{creditlimit} = "$company->{creditlimit}"; 
    $company->{discount} = "$company->{discount}"; 
    $company->{note_class_options} = [
        {label => 'Entity', value => 1},
        {label => $ec_labels->{"$company->{entity_class}"} . ' Account', 
         value => 3},
    ];
    $company->{threshold} = $company->format_amount(amount => $company->{threshold});

    my $template = LedgerSMB::Template->new( 
	user => $company->{_user}, 
    	template => 'contact', 
	locale => $company->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($company);
}

=pod

=over

=item search($request)

Renders the search criteria screen.

=back

=cut

sub search {
    my ($request) = @_;
    set_entity_class($request);
    my $template = LedgerSMB::Template->new( 
	user => $request->{_user}, 
    	template => 'search', 
	locale => $request->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($request);
}    

=pod

=over

=item save_contact($request)

Saves contact info as per LedgerSMB::DBObject::Company::save_contact.

=back

=cut

sub save_contact {
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->save_contact();
    }
    $company->get;
    _render_main_screen($company );
}

=pod

=over

=item save_contact_new($request)

Saves contact info as a new line as per save_contact above.

=cut

sub save_contact_new{
    my ($request) = @_;
    delete $request->{old_contact};
    delete $request->{old_contact_class};
    save_contact($request);
}

# Private method.  Sets notice if form could not be closed.
sub _close_form {
    my ($company) = @_;
    if (!$company->close_form()){
        $company->{notice} = 
               $company->{_locale}->text('Changes not saved.  Please try again.');
        return 0;
    }
    return 1;
}
=pod

=over

=item save_bank_account($request)

Adds a bank account to a company and, if defined, an entity credit account.

=back

=cut

sub save_bank_account {
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->save_bank_account();
    }
    $company->get;
    _render_main_screen($company );
}

sub save_notes {
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->save_notes();
    }
    $company->get();
    _render_main_screen($company );
}
1;
