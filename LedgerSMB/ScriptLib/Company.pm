package LedgerSMB::ScriptLib::Company;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Customer;
use LedgerSMB::DBObject::Entity::Company;
use LedgerSMB::DBObject::Entity::Credit_Account;
use LedgerSMB::DBObject::Entity::Location;
use LedgerSMB::DBObject::Entity::Contact;
use LedgerSMB::DBObject::Vendor;
use Log::Log4perl;

my $logger = Log::Log4perl->get_logger("LedgerSMB::ScriptLib::Company");

use Data::Dumper;

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

=cut

sub set_entity_class {
    my ($request) = @_;
    $request->{_script_handle}->set_entity_class(@_) || $request->error(
       "Error:  Cannot call LedgerSMB::ScriptLib::Company::set_entity_class " .
       "directly!");
}


=item get_by_cc 

Populates the company area with info on the company, pulled up through the 
control code

=cut

sub get_by_cc {
    my ($request) = @_;
    $request->{legal_name} ||= 'test';
    $request->{country_id} = 0;
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    $company = $company->get_by_cc($request->{control_code});
    $request->{company} = $company;
    _render_main_screen($request);
}

=item dispatch_legacy

This is a semi-private method which interfaces with the old code.  Note that
as long as any other functions use this, the contact interface cannot be said to 
be safe for code caching.

Not fully documented because this will go away as soon as possible.

=cut

sub dispatch_legacy {
    our ($request) = shift @_;
    use LedgerSMB::Form;
    my $aa;
    my $inv;
    my $otype;
    my $qtype;
    my $cv;
    if ($request->{account_class} == 1){
       $aa = 'ap';
       $inv = 'ir';
       $otypr = 'purchase_order';
       $qtype = 'request_quotation';
       $cv = 'vendor';
    } elsif ($request->{account_class} == 2){
       $aa = 'ar';
       $inv = 'is';
       $otypr = 'sales_order';
       $qtype = 'sales_quotation';
       $cv = 'customer';
    } else {
       $request->error($request->{_locale}->text('Unsupport account type'));
    }
    our $dispatch = 
    {
        add_transaction  => {script => "bin/$aa.pl", 
                               data => {"${cv}_id" => $request->{credit_id}},
                            },
        add_invoice      => {script => "bin/$inv.pl",
                               data => {"${cv}_id" => $request->{credit_id}},
                            },
        add_order        => {script => 'bin/oe.pl', 
                               data => {"${cv}_id" => $request->{credit_id},
                                            type   => $otype,
                                               vc  => $cv,
                                       },
                            },
        rfq              => {script => 'bin/oe.pl', 
                               data => {"${cv}_id" => $request->{credit_id},
                                            type   => $qtype,
                                               vc  => $cv,
                                       },
                            },
 
    };

    our $form = new Form;
    our %myconfig = ();
    %myconfig = %{$request->{_user}};
    $form->{stylesheet} = $myconfig{stylesheet};
    our $locale = $request->{_locale};

    for (keys %{$dispatch->{$request->{action}}->{data}}){
        $form->{$_} = $dispatch->{$request->{action}}->{data}->{$_};
    }

    my $script = $dispatch->{$request->{action}}{script};
    $form->{script} = $script;
    $form->{action} = 'add';
    $form->{dbh} = $request->{dbh};
    $form->{script} =~ s|.*/||;
    { no strict; no warnings 'redefine'; do $script; }

    $form->{action}();
}

=item add_transaction

Dispatches to the Add (AR or AP as appropriate) transaction screen.

=cut

sub add_transaction {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item add_invoice

Dispatches to the (sales or vendor, as appropriate) invoice screen.

=cut

sub add_invoice {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item add_order

Dispatches to the sales/purchase order screen.

=cut

sub add_order {
    my $request = shift @_;
    dispatch_legacy($request);
}

=item rfq

Dispatches to the quotation/rfq screen

=cut

sub rfq {
    my $request = shift @_;
    dispatch_legacy($request);
}


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
of the company information.

=back

=cut

sub get {
    my ($request) = @_;
    $request->{legal_name} ||= 'test';
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    $company = $company->get($request->{entity_id});
    $request->{company} = $company;
    _render_main_screen($request);
}

=pod

=over

=item add_location 

Adds a location to the company as defined in the inherited object

=back

=cut

sub add_location {
    my ($request) = @_;
    my $location = LedgerSMB::DBObject::Entity::Location->new(%$request);
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);

    $location->save();
    $company = $company->get($request->{entity_id});

    _render_main_screen($request, $company);
	
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
    delete $request->{location_id};
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
    _render_main_screen($request);
}



=pod

=over

=item get_results($self, $request, $user)

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

    my $meta_number_name;
    if($company->{account_class}==1){$meta_number_name='Vendor Number';}
    elsif($company->{account_class}==2){$meta_number_name='Customer Number';}
    else{$meta_number_name='Unknown';}
    # Column definitions for dynatable
    @columns = qw(legal_name entity_control_code meta_number credit_description business_type curr);
		
	my $column_names = {
	    legal_name => 'Name',
	    entity_control_code => 'Control Code',
	    meta_number => $meta_number_name,
	    credit_description => 'Description',
	    business_type => 'Business Type',
	    curr => 'Currency'
    };
	my @sort_columns = @columns;
	my $sort_href = "$search_url&order_by";

    my @rows;
    for $ref (@{$company->{search_results}}){
    if(!$ref->{meta_number}){$ref->{meta_number}='';}
    my $http_href="$get_url&entity_id=$ref->{entity_id}"."&meta_number=$ref->{meta_number}";
	push @rows, 
                {legal_name   => {text=>$ref->{legal_name},href=>$http_href},
		entity_control_code => $ref->{entity_control_code},
		credit_description => $ref->{credit_description},
                meta_number   => {text=>$ref->{meta_number}},
		business_type => $ref->{business_type},
                curr          => $ref->{curr},
                };
    }
    #my $label = $ec_labels->{"$company->{account_class}"};
    my $label_text="Add ".$ec_labels->{"$company->{account_class}"};
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
        text => $company->{_locale}->text($label_text),
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
            
    my $column_heading = $template->column_heading($column_names,
        {href => $sort_href, columns => \@sort_columns}
    );
            
    $logger->debug("\$company = " . Data::Dumper::Dumper($company));
    $template->render({
	form    => $company,
	columns => \@columns,
#        hiddens => $company,
	buttons => \@buttons,
	heading => $column_heading,
	rows    => \@rows,
    });
}

=pod

=over

=item history($request)

Generates the filter screen for the customer/vendor history report.

=back

=cut

sub history {
    my ($request) = @_;
    set_entity_class($request);
    my $company = LedgerSMB::DBObject::Company->new(base => $request);
    $company->get_metadata;
    my $template = LedgerSMB::Template->new( 
	user => $request->{_user}, 
    	template => 'history_filter', 
	locale => $request->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($company);

} 

=pod

=over 

=item display_history($request)

Displays the customer/vendor history based on criteria from the history filter
screen.

The following request variables are optionally set in the HTTP query string
or request object.

Search Criteria
name:  search string for company name
contact_info:  Search string for contact info, can match phone, fax, or email.
salesperson:  Search string for employee name in the salesperson field
notes: Notes search.  Not currently implemented
meta_number:  Exact match for customer/vendor number
address_line:  Search string for first or second line of address.
city:  Search string for city name
state:  Case insensitive, otherwise exact match for state or province
zip:  leading match for zip/mail code
country_id:  integer for country id.  Exact match
tartdate_from:  Earliest date for startdate of entity credit account
startdate_to:  Lates date for entity credit accounts' start date
type:  either 'i' for invoice, 'o' for orders, 'q' for quotations
from_date:  Earliest date for the invoice/order
to_date:  Latest date for the invoice/order

Unless otherwise noted, partial matches are sufficient.

Control variables:
inc_open:  Include open invoices/orders.  If not true, no open invoices are
           displayed
inc_closed: Include closed invoices/orders.  If not true, no closed invoices are
            displayed
report_type:  Either summary or detail

Columns to display:
l_partnumber:    parts.partnumber
l_sellprice:     invoice/orderitems.sellprice
l_curr:          ar/ap/oe.curr
l_unit:          invoice/orderitems.unit
l_deliverydate:  invoice.deliverydate or orderitems.reqdate
l_projectnumber: project.projectnumber
l_serialnumber:  invoice/orderitems.serialnumber


=back

=cut

sub display_history {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'form-dynatable',
        locale => $request->{_locale},
        path => 'UI',
        format => 'HTML'
    );
    my $company = LedgerSMB::DBObject::Company->new(base => $request);
    $company->get_history();
    my @columns = qw(invnumber);
    for my $col (qw(l_curr l_partnumber l_description l_unit l_qty l_sellprice 
                  l_discount l_serialnumber l_deliverydate l_projectnumber)){
        if ($request->{$col}){
           my $column = $col;
           $column =~ s/l_//;
           push @columns, $column;
        }
    }
    $locale = $request->{_locale};
    my $column_header = {
       invnumber     => $locale->text('Invoice Number'),
       curr          => $locale->text('Currency'),
       qty           => $locale->text('Qty'),
       partnumber    => $locale->text('Part Number'), 
       description   => $locale->text('Description'), 
       unit          => $locale->text('Unit'),
       sellprice     => $locale->text('Sell Price'),
       discount      => $locale->text('Disc.'),
       serialnumber  => $locale->text('Serial Number'),
       deliverydate  => $locale->text('Delivery Date'),
       projectnumber => $locale->text('Project Number')
    };
    my $rows = [];
    my $last_id = 0;
    my ($eca_url, $invurl, $parturl);
    if ($company->{account_class} == 1){
       $eca_url='vendor.pl?action=edit&';
       $inv_url='ir.pl?action=edit&';
    } elsif ($company->{account_class} == 2) {
       $eca_url='customer.pl?action=edit&';
       $inv_url='is.pl?action=edit&';
    }
    if ($company->{type} ne 'i'){
       $inv_url='oe.pl?action=edit&';
    }
    for $ref(@{$company->{history_rows}}){
       my $heading;
       if ($ref->{id} != $last_id){
          $last_id = $ref->{id};
          $heading = "$ref->{meta_number} -- $ref->{name}";
          # Not implementing links to entity credit account editing because
          # not 100% sure if it is information-complete at this time --CT
          push @$rows, {class => 'divider', 
                         text => $heading,
                       };
       }
       if ($company->{account_class} == 1){
           $ref->{qty} *= -1;
       }
       $ref->{invnumber} = {text => $ref->{invnumber},
                            href => $inv_url . "id=$ref->{inv_id}",
                           };
       $ref->{qty} = $company->format_amount({amount => $ref->{qty}});
       $ref->{discount} = $company->format_amount({amount => $ref->{discount}});
       $ref->{sellprice}=$company->format_amount({amount => $ref->{sellprice}});
       push @$rows, $ref

    }
    $template->render({
        form    => $company,
        columns => \@columns,
        heading => $column_header,
        rows    => $rows,
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
    set_entity_class($request);
    my $closed = _close_form($request);
    my $company = LedgerSMB::DBObject::Entity::Company->new(%$request);
    if ($closed){
        #$logger->debug("\$company = " . Data::Dumper::Dumper($company));
        $company->save();
    }
    _render_main_screen($request, $company);
}

=pod

=over

=item save_credit($request)

This inserts or updates a credit account of the sort listed here.

=back

=cut

sub save_credit {
    
    my ($request) = @_;
    my $company;
    my @taxes;

    if (!$request->{ar_ap_account_id}){
          $request->error(
              $request->{_locale}->text('No AR or AP Account Selected')
          );
    }

    $request->{tax_ids} = [];
    for my $key(keys %$request){
        if ($key =~ /^taxact_(\d+)$/){
           my $tax = $1;
           push @{$request->{tax_ids}}, $tax;
        }  
    }
    if (_close_form($request)){
        LedgerSMB::DBObject::Entity::Credit_Account->prepare_input($request);
        $credit = LedgerSMB::DBObject::Entity::Credit_Account->new(%$request);
        $credit->save();
    }
    get($request);
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
entity_id, account_class, and meta_number.  The account_class requireent is 
typically set during the construction of scripts which inherit this library.

=back

=cut

sub edit{
    my $request = shift @_;
    my $company = new_company($request);

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
    my ($request, $company) = @_;
    delete $request->{creditlimit};
    delete $request->{discount};
    delete $request->{threshold};
    delete $request->{startdate};
    delete $request->{enddate};
    my $credit = LedgerSMB::DBObject::Entity::Credit_Account->new(%$request);
    $request->close_form;
    $request->open_form;
    $request->{dbh}->commit;
    if (ref $request->{company}){
        my @credit_list = 
           $credit->list_for_entity($request->{company}->entity_id);
        $request->{credit_list} = \@credit_list;
        $request->{entity_id} = $request->{company}->entity_id;
    }
    set_entity_class($request) unless $request->{entity_class};
    if (!$company){
        $company = new_company($request);
        $company->get_metadata();
    }
    for my $ref (@{$request->{credit_list}}){
        $company->{credit_act} = $ref; 
    }
    @{$company->{contacts}} = 
          LedgerSMB::DBObject::Entity::Contact->list(
              {entity_id => $company->{entity_id},
                        credit_id => $company->{credit_act}->{id}},
              $request
          );
    @{$company->{contact_class_list}} = 
          LedgerSMB::DBObject::Entity::Contact->list_classes;
    @{$company->{locations}} = 
          LedgerSMB::DBObject::Entity::Location->get_active(
                       $request,
                       {entity_id => $company->{entity_id},
                        credit_id => $company->{credit_act}->{id}}
          );
                         

    $company->{creditlimit} = $request->format_amount({amount => $company->{creditlimit}}) unless !defined $company->{creditlimit}; 
    $company->{discount} = "$company->{discount}" unless !defined $company->{discount}; 
    $company->{note_class_options} = [
        {label => 'Entity', value => 1},
        {label => $ec_labels->{"$company->{entity_class}"} . ' Account', 
         value => 3},
    ];
    $company->{threshold} = $request->format_amount(amount => $company->{threshold});
    if(! $company->{language_code})
    {
     #$logger->debug("company->language code not set!");
     $company->{language_code}=$company->{default_language}
    }
    #$logger->debug("\$company = " . Data::Dumper::Dumper($company));

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
   my $contact = LedgerSMB::DBObject::Entity::Contact->new(%$request);   
   if (_close_form($request)){
       $contact->save();
   }
   get( $request );
}

=pod

=over

=item delete_contact

Deletes the selected contact info record

Must include company_id or credit_id (credit_id used if both are provided) plus:

* contact_class_id
* contact
* form_id

=back

=cut

sub delete_contact {
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->delete_contact();
    }
    $company->get;
    _render_main_screen( $company );
}

=pod

=over

=item delete_bank_acct

Deletes the selected bank account record

Required request variables:
* bank_account_id
* entity_id
* form_id

=back

=cut

sub delete_bank_acct{
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->delete_bank_account();
    }
    $company->get;
    _render_main_screen( $company );
}

=pod

=over

=item delete_location

Deletes the selected contact info record

Must include company_id or credit_id (credit_id used if both are provided) plus:

* location_class_id
* location_id 
* form_id

=back

=cut

sub delete_location{
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->delete_location();
    }
    $company->get;
    _render_main_screen( $company );
}

=pod

=over

=item edit_bank_acct($request)

displays screen to a bank account

Required data:
bank_account_id
bic
iban

=back

=cut

sub edit_bank_acct {
    my ($request) = @_;
    my $company = new_company($request);
    $company->get;
    _render_main_screen( $company );
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

=item save_notes($request)

Saves notes.  entity_id or credit_id must be set, as must note_class, note, and 
subject.

=cut

sub save_notes {
    my ($request) = @_;
    my $company = new_company($request);
    if (_close_form($company)){
        $company->save_notes();
    }
    $company->get();
    _render_main_screen($company );
}

=item pricelist

This returns and displays the pricelist.  The id field is required.

=cut

sub pricelist {
    my ($request) = @_;
    my $company = new_company($request);
    $company->get();
    $company->get_pricematrix();
    for my $l (qw(pricematrix pricematrix_pricegroup)){
        for my $p (@{$company->{$l}}){
            $p->{sellprice} = $company->format_amount(
                     {amount => $p->{sellprice}, money => 1}
            );
            $p->{pricebreak} = $company->format_amount(
                     {amount => $p->{sellprice}, money => 1}
            );
            $p->{lastcost} = $company->format_amount(
                     {amount => $p->{sellprice}, money => 1}
            );
        } 
    }
    my $template = LedgerSMB::Template->new(
                user => $request->{_user},
                path => 'UI/Contact' ,
                template => 'pricelist',
                format => uc($request->{format} || 'HTML'),
                locale => $company->{_locale},
    );

    $template->render($company);
}


=item delete_price

=item save_pricelist

This routine saves the price matrix.  For existing rows, valid_to, valid_from,
price fields are saved.

For the new row, the partnumber field matches the beginning of the part number,
and the description is a full text search.

=cut

sub save_pricelist {
    my ($request) = @_;
    use LedgerSMB::ScriptLib::Common_Search::Part;
    use LedgerSMB::DBObject::Pricelist;
    my $count = $request->{rowcount_pricematrix};

    my $pricelist = LedgerSMB::DBObject::Pricelist->new({base => $request});
    my @lines;
    my $redirect_to_selection = 0;
    my $psearch;

    # Search and populate
    if (defined $request->{"int_partnumber_tfoot_$count"} 
         or defined $request->{"description_tfoot_$count"})
    {
        $psearch = LedgerSMB::ScriptLib::Common_Search::Part->new($request);
        my @parts = $psearch->search(
                   { partnumber => $request->{"int_partnumber_tfoot_$count"},
                    description => $request->{"description_tfoot_$count"}, }
        );

        if (scalar @parts == 0) {
            $request->error($request->{_locale}->text('Part not found'));
        } elsif (scalar @parts > 1){
            $redirect_to_selection = 1;
        } else {
            my $part = shift @parts;
            push @lines, {
                   parts_id => $part->{id},
                  validfrom => $request->{"validfrom_tfoot_$count"},
                    validto => $request->{"validto_tfoot_$count"},
                      price => $request->{"lastcost_tfoot_$count"} ||
                               $request->{"sellprice_tfoot_$count"},
                   leadtime => $request->{"leadtime_tfoot_$count"},
             }; 
        }
    }

    # Save rows
    for (1 .. ($count - 1)){
        $id = $request->{"row_$_"};
        push @lines, { 
                entry_id => $id,
                parts_id => $request->{"parts_id_$id"},
               validfrom => $request->{"validfrom_$id"},
                 validto => $request->{"validto_$id"},
                   price => $request->{"lastcost_$id"} || 
                            $request->{"sellprice_$id"},
                leadtime => $request->{"leadtime_$id"},
        };
    }

    $pricelist->save(\@lines);

    # Return to UI

    pricelist($request) unless $redirect_to_selection;

    $request->{search_redirect} = 'pricelist_search_handle';
    $psearch->render($request);
}


=item pricelist_search_handle

Handles the return from the parts search from the pricelist screen.

=cut

sub pricelist_search_handle {
    my ($request) = @_;
    use LedgerSMB::ScriptLib::Common_Search::Part;
    use LedgerSMB::DBObject::Pricelist;

    my $psearch = LedgerSMB::ScriptLib::Common_Search::Part->new($request);
    my $part = $psearch->extract($request);

    my $plist = LedgerSMB::DBObject::Pricelist->new({base => $request });
    my $row = $request->{rowcount_pricematrix};

    $plist->save([{parts_id => $part->{id},
                  validfrom => $request->{"validfrom_tfoot_$row"},
                    validto => $request->{"validto_tfoot_$row"},
                      price => $request->{"lastcost_tfoot_$row"} ||
                               $request->{"sellprice_tfoot_$row"},
                   leadtime => $request->{"leadtime_tfoot_$row"},
    }]);
    pricelist($request);
}


=back

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

1;
