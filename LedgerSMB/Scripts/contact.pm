
=pod

=head1 NAME

LedgerSMB::Scripts::contact - LedgerSMB class defining the Controller
functions, template instantiation and rendering for customer editing and display.

=head1 SYOPSIS

This module is the UI controller for the customer, vendor, etc functions; it 

=head1 METHODS

=cut

package LedgerSMB::Scripts::contact;

use LedgerSMB::Entity::Company;
use LedgerSMB::Entity::Person;
use LedgerSMB::Entity::Credit_Account;
use LedgerSMB::Entity::Location;
use LedgerSMB::Entity::Contact;
use LedgerSMB::Entity::Bank;
use LedgerSMB::Entity::Note;
use LedgerSMB::File;
use LedgerSMB::App_State;
use LedgerSMB::Template;

use strict;
use warnings;

my $locale = $LedgerSMB::App_State::Locale;

=head1 COPYRIGHT

Copyright (c) 2012, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

=head1 METHODS

=over

=item get_by_cc 

Populates the company area with info on the company, pulled up through the 
control code

=cut

sub get_by_cc {
    my ($request) = @_;
    my $entity = 
           LedgerSMB::Entity::Company->get_by_cc($request->{control_code});
    $entity ||=  LedgerSMB::Entity::Person->get_by_cc($request->{control_code});
    my ($company, $person) = (undef, undef);
    if (eval {$entity->isa('LedgerSMB::Entity::Company')}){
       $company = $entity;
    } elsif (eval {$entity->isa('LedgerSMB::Entity::Person')}){
       $person = $entity;
    }
    _main_screen($request, $company, $person);
}


=item get($self, $request, $user)

Requires form var: id

Extracts a single company from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the company information.

=cut

sub get {
    my ($request) = @_;
    my $entity = LedgerSMB::Entity::Company->get($request->{entity_id});
    $entity ||= LedgerSMB::Entity::Person->get($request->{entity_id});
    my ($company, $person) = (undef, undef);
    if ($entity->isa('LedgerSMB::Entity::Company')){
       $company = $entity;
    } elsif ($entity->isa('LedgerSMB::Entity::Person')){
       $person = $entity;
    }
    _main_screen($request, $company, $person);
}


# private method _main_screen 
#
# this attaches everything other than {company} to $request and displays it.

sub _main_screen {
    my ($request, $company, $person) = @_;


    # DIVS logic
    my @DIVS;
    my @entity_files;
    my @eca_files;
    if ($company->{entity_id} or $person->{entity_id}){
       my $entity_id = $company->{entity_id};
       $entity_id ||= $person->{entity_id};
       @DIVS = qw(credit address contact_info bank_act notes files);
       unshift @DIVS, 'company' if $company->{entity_id};
       unshift @DIVS, 'person' if $person->{entity_id};
       @entity_files = LedgerSMB::File->list(
               {ref_key => $entity_id, file_class => '4'}
       );
    } else {
       @DIVS = qw(company person);
    }
    $request->{target_div} ||= 'company';

    my %DIV_LABEL = (
             company => $locale->text('Company'),
              person => $locale->text('Person'),
              credit => $locale->text('Credit Accounts'),
             address => $locale->text('Addresses'),
        contact_info => $locale->text('Contact Info'),
            bank_act => $locale->text('Bank Accounts'),
               notes => $locale->text('Notes'),
               files => $locale->text('Files'),
    );

    # DIVS contents
    my $entity_id = $company->{entity_id};
    $entity_id ||= $person->{entity_id};
    my @pricegroups = $request->call_procedure(
        procname => 'pricegroups__list'
    );
    my @credit_list = 
       LedgerSMB::Entity::Credit_Account->list_for_entity(
                          $entity_id,
                          $request->{entity_class}
        );
    my $credit_act;
    for my $ref(@credit_list){
        if (($request->{credit_id} eq $ref->{id}) 
              or ($request->{meta_number} eq $ref->{meta_number})){
        
            $credit_act = $ref;
            @eca_files = LedgerSMB::File->list(
               {ref_key => $ref->{id}, file_class => '5'}
             );

        }     
    }

    my $entity_class = $credit_act->{entity_class};
    $entity_class ||= $company->{entity_class};
    $entity_class ||= $request->{entity_class};
    $entity_class ||= $request->{account_class};
    my @locations = LedgerSMB::Entity::Location->get_active(
                       {entity_id => $entity_id,
                        credit_id => $credit_act->{id}}
          );

    my @contact_class_list =
          LedgerSMB::Entity::Contact->list_classes;

    my @contacts = LedgerSMB::Entity::Contact->list(
              {entity_id => $entity_id,
               credit_id => $credit_act->{id}}
    );
    my @bank_account = 
         LedgerSMB::Entity::Bank->list($entity_id);
    my @notes =
         LedgerSMB::Entity::Note->list($entity_id,
                                                 $credit_act->{id});

    # Globals for the template
    my @salutations = $request->call_procedure(
                procname => 'person__list_salutations'
    );
    my @all_taxes = $request->call_procedure(procname => 'account__get_taxes');

    my @ar_ap_acc_list = $request->call_procedure(procname => 'chart_get_ar_ap',
                                           args => [$entity_class]);

    my @cash_acc_list = $request->call_procedure(procname => 'chart_list_cash',
                                           args => [$entity_class]);

    my @discount_acc_list =
         $request->call_procedure(procname => 'chart_list_discount',
                                     args => [$entity_class]);

    for my $var (\@ar_ap_acc_list, \@cash_acc_list, \@discount_acc_list){
        for my $ref (@$var){
            $ref->{text} = "$ref->{accno}--$ref->{description}";
        }
    }

#
    my @language_code_list = 
             $request->call_procedure(procname=> 'person__list_languages');

    for my $ref (@language_code_list){
        $ref->{text} = "$ref->{code}--$ref->{description}";
    }
    
    my @location_class_list = 
            $request->call_procedure(procname => 'location_list_class');

    my @business_types =
               $request->call_procedure(procname => 'business_type__list');

    my ($curr_list) =
          $request->call_procedure(procname => 'setting__get_currencies');

    my @all_currencies;
    for my $curr (@{$curr_list->{'setting__get_currencies'}}){
        push @all_currencies, { text => $curr};
    }

    my ($default_country) = $request->call_procedure(
              procname => 'setting_get',
                  args => ['default_country']);
    $default_country = $default_country->{value};

    my ($default_language) = $request->call_procedure(
              procname => 'setting_get',
                  args => ['default_language']);
    $default_language = $default_language->{value};

    my $attach_level_options = [
        {text => $locale->text('Entity'), value => 1} ];
    push@{$attach_level_options},
        {text => $locale->text('Credit Account'),
         value => 3} if $credit_act->{id};
    ;

    $request->close_form();
    $request->open_form();

    # Template info and rendering 
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'contact',
        locale => $request->{_locale},
        path => 'UI/Contact',
        format => 'HTML'
    );

    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;
    #die '<pre>' . Dumper($request) . '</pre>';
    my @country_list = $request->call_procedure(
                     procname => 'location_list_country'
      );
    my @entity_classes = $request->call_procedure(
                      procname => 'entity__list_classes'
    );

    $template->render({
                     DIVS => \@DIVS,
                DIV_LABEL => \%DIV_LABEL,
                  request => $request,
                  company => $company,
                   person => $person,
             country_list => \@country_list,
               credit_act => $credit_act,
              credit_list => \@credit_list,
              pricegroups => \@pricegroups,
           entity_classes => \@entity_classes,
                locations => \@locations,
                 contacts => \@contacts,
             bank_account => \@bank_account,
                    notes => \@notes,
             entity_files => \@entity_files,
                eca_files => \@eca_files,
          # globals
                  form_id => $request->{form_id},
              salutations => \@salutations,
           ar_ap_acc_list => \@ar_ap_acc_list,
            cash_acc_list => \@cash_acc_list,
        discount_acc_list => \@discount_acc_list,
       language_code_list => \@language_code_list,
           all_currencies => \@all_currencies,
     attach_level_options => $attach_level_options, 
                entity_id => $entity_id,
             entity_class => $entity_class,
      location_class_list => \@location_class_list,
       contact_class_list => \@contact_class_list,
    });
}

=item generate_control_code 

Generates a control code and hands off execution to other routines

=cut

sub generate_control_code {
    my ($request) = @_;
    my ($ref) = $request->call_procedure(
                             procname => 'setting_increment', 
                             args     => ['entity_control']
                           );
    ($request->{control_code}) = values %$ref;
    _main_screen($request, $request, $request);
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
    no strict;
    use Data::Dumper;
    my $aa;
    my $inv;
    my $otype;
    my $qtype;
    my $cv;
    $request->{account_class} ||= $request->{entity_class};
    if ($request->{account_class} == 1){
       $aa = 'ap';
       $inv = 'ir';
       $otype = 'purchase_order';
       $qtype = 'request_quotation';
       $cv = 'vendor';
    } elsif ($request->{account_class} == 2){
       $aa = 'ar';
       $inv = 'is';
       $otype = 'sales_order';
       $qtype = 'sales_quotation';
       $cv = 'customer';
    } else {
       $request->error($request->{_locale}->text('Unsupported account type'));
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

=item add

This method creates a blank screen for entering a company's information.

=cut 

sub add {
    my ($request) = @_;
    $request->{target_div} = 'company_div';
    _main_screen($request, $request);
}

=item save_company

Saves a company and moves on to the next screen

=cut

sub save_company {
    my ($request) = @_;
    $request->{name} ||= $request->{legal_name};
    my $company = LedgerSMB::Entity::Company->new(%$request);
    $request->{target_div} = 'credit_div';
    _main_screen($request, $company->save);
}

=item save_person

Saves a person and moves on to the next screen

=cut

sub save_person {
    my ($request) = @_;
    my $person = LedgerSMB::Entity::Person->new(
              %$request
    );
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;
    $request->{target_div} = 'credit_div';
    $person->save;
    _main_screen($request, undef, $person);
}

=item save_credit($request)

This inserts or updates a credit account of the sort listed here.

=cut

sub save_credit {
    
    my ($request) = @_;
    $request->{target_div} = 'credit_div';
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
    if ($request->close_form){
        my $credit = LedgerSMB::Entity::Credit_Account->new(%$request);
        $credit = $credit->save();
        $request->{meta_number} = $credit->{meta_number};
    }
    get($request);
}

=item save_credit_new($request)

This inserts a new credit account.

=cut


sub save_credit_new {
    my ($request) = @_;
    $request->{credit_id} = undef;
    save_credit($request);
}

=item save_location 

Adds a location to the company as defined in the inherited object

=cut

sub save_location {
    my ($request) = @_;

    my $location = LedgerSMB::Entity::Location->new(%$request);
    if ($request->{attach_to} eq '1'){
       $location->credit_id(undef);
    }
    $location->id($request->{location_id});
    $location->save;
    $request->{target_div} = 'address_div';
    get($request);
	
}

=item save_new_location 

Adds a location to the company as defined in the inherited object, not
overwriting existing locations.

=cut

sub save_new_location {
    my ($request) = @_;
    delete $request->{location_id};
    save_location($request);
}

=item edit

This is a synonym of get() which is preferred to use for editing operations.

=cut

sub edit {
    get (@_);
}

=item delete_location

Deletes the specified location

=cut

sub delete_location {
    my ($request) = @_;
    my $location = LedgerSMB::Entity::Location->new(%$request);
    $location->id($request->{location_id});
    if (!$request->{is_for_credit}){
       $location->credit_id(undef);
    }
    $location->delete;
    $request->{target_div} = 'address_div';
    get($request);
}

=item save_contact

Saves the specified contact info

=cut

sub save_contact {
    my ($request) = @_;
    my $contact = LedgerSMB::Entity::Contact->new(%$request);
    if ($request->{attach_to} == 1){
       $contact->credit_id(undef);
    }
    $contact->save;
    $request->{target_div} = 'address_div';
    $request->{target_div} = 'contact_info_div';
    get($request);
} 

=item delete_contact

Deletes the specified contact info.  Note that for_credit is used to pass the 
credit id over in this case.

=cut

sub delete_contact {
    my ($request) = @_;
    my $contact = LedgerSMB::Entity::Contact->new(%$request);
    $contact->credit_id($request->{for_credit});
    $contact->delete;
    $request->{target_div} = 'contact_info_div';
    get($request);
}

=item delete_bank_acct

Deletes the selected bank account record

Required request variables:
* bank_account_id
* entity_id
* form_id

=cut

sub delete_bank_account{
    my ($request) = @_;
    my $account = LedgerSMB::Entity::Bank->new(%$request);
    $account->delete;
    $request->{target_div} = 'bank_act_div';
    get($request);
}

=item save_bank_account 

Adds a bank account to a company and, if defined, an entity credit account.

=cut

sub save_bank_account {
    my ($request) = @_;
    my $bank = LedgerSMB::Entity::Bank->new(%$request);
    $bank->save;
    $request->{target_div} = 'bank_act_div';
    get($request);
}

=item save_notes($request)

Saves notes.  entity_id or credit_id must be set, as must note_class, note, and 
subject.

=cut

sub save_notes {
    my ($request) = @_;
    my $note = LedgerSMB::Entity::Note->new(%$request);
    if ($request->{note_class} == 1){
       $note->credit_id(undef);
    }
    $note->save;
    get($request);
}

=item get_pricelist

This returns and displays the pricelist.  The id field is required.

=cut

sub get_pricelist {
    my ($request) = @_;
    my $credit = LedgerSMB::Entity::Credit_Account->get_by_id(
       $request->{credit_id}
    );
    my $pricelist = $credit->get_pricematrix;
    $request->merge($credit) if $credit;
    $request->merge($pricelist) if $pricelist;
    my $template = LedgerSMB::Template->new(
                user => $request->{_user},
                path => 'UI/Contact' ,
                template => 'pricelist',
                format => uc($request->{format} || 'HTML'),
                locale => $request->{_locale},
    );

    $template->render($request);
}

=back

=head1 COPYRIGHT

Copyright (c) 2012, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

1;
