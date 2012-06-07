
=pod

=head1 NAME

LedgerSMB::Scripts::contact - LedgerSMB class defining the Controller
functions, template instantiation and rendering for customer editing and display.

=head1 SYOPSIS

This module is the UI controller for the customer, vendor, etc functions; it 

=head1 METHODS

=cut

package LedgerSMB::Scripts::employee;

use LedgerSMB::DBObject::Entity::Person::Employee;
use LedgerSMB::DBObject::Entity::Location;
use LedgerSMB::DBObject::Entity::Contact;
use LedgerSMB::DBObject::Entity::Bank;
use LedgerSMB::DBObject::Entity::Note;
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

Retrieves the employee based on control code.

=cut

sub get_by_cc {
    my ($request) = @_;
    my $emp = LedgerSMB::DBObject::Entity::Person::Employee->get_by_cc(
                            $request->{control_code}
    );
    _main_screen($request, $emp);
}


=item get

Requires form var: id

Retrieves the employee by id.

=cut

sub get {
    my ($request) = @_;
    my $emp = LedgerSMB::DBObject::Entity::Person::Employee->get(
                          $request->{entity_id}
    );
    _main_screen($request, $emp);
}


# private method _main_screen 
#
# this attaches everything other than employee and displays.

sub _main_screen {
    my ($request, $employee) = @_;


    # DIVS logic
    my @DIVS;
    if ($employee->{entity_id}){
       @DIVS = qw(employee address contact_info bank_act notes);
    } else {
       @DIVS = qw(employee);
    }
    $request->{target_div} ||= 'employee_div';

    my %DIV_LABEL = (
             company => $locale->text('Employee'),
             address => $locale->text('Addresses'),
        contact_info => $locale->text('Contact Info'),
            bank_act => $locale->text('Bank Accounts'),
               notes => $locale->text('Notes'),
    );

    # DIVS contents
    my $entity_id = $employee->{entity_id};

    my $entity_class = 3;

    my @locations = LedgerSMB::DBObject::Entity::Location->get_active(
                       {entity_id => $entity_id,
                        credit_id => undef}
          );

    my @contact_class_list =
          LedgerSMB::DBObject::Entity::Contact->list_classes;

    my @contacts = LedgerSMB::DBObject::Entity::Contact->list(
              {entity_id => $entity_id,
               credit_id => undef}
    );
    my @bank_account = 
         LedgerSMB::DBObject::Entity::Bank->list($entity_id);
    my @notes =
         LedgerSMB::DBObject::Entity::Note->list($entity_id,
                                                 undef);

    # Globals for the template
    my @salutations = $request->call_procedure(
                procname => 'person__list_salutations'
    );
    my @managers = $request->call_procedure(
                         procname => 'employee__all_managers'
    );

    my @language_code_list = 
             $request->call_procedure(procname=> 'person__list_languages');

    for my $ref (@language_code_list){
        $ref->{text} = "$ref->{code}--$ref->{description}";
    }
    
    my @location_class_list = 
            $request->call_procedure(procname => 'location_list_class');

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
                 employee => $employee,
             country_list => \@country_list,
                locations => \@locations,
                 contacts => \@contacts,
             bank_account => \@bank_account,
                    notes => \@notes,
                 managers => \@managers,
          # globals
                  form_id => $request->{form_id},
              salutations => \@salutations,
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
    _main_screen($request, $request);
}


=item add

This method creates a blank screen for entering a company's information.

=back

=cut 

sub add {
    my ($request) = @_;
    $request->{target_div} = 'employee_div';
    _main_screen($request, $request);
}

=item save_employee

Saves a company and moves on to the next screen

=cut

sub save_employee {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Entity::Person::Employee->new(%$request);
    $request->{target_div} = 'credit_div';
    $employee->save;
    _main_screen($request, $employee);
}

=item save_location 

Adds a location to the company as defined in the inherited object

=cut

sub save_location {
    my ($request) = @_;

    my $location = LedgerSMB::DBObject::Entity::Location->new(%$request);
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
    my $location = LedgerSMB::DBObject::Entity::Location->new(%$request);
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
    my $contact = LedgerSMB::DBObject::Entity::Contact->new(%$request);
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
    my $contact = LedgerSMB::DBObject::Entity::Contact->new(%$request);
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
    my $account = LedgerSMB::DBObject::Entity::Bank->new(%$request);
    $account->delete;
    $request->{target_div} = 'bank_act_div';
    get($request);
}

=sub save_bank_account 

Adds a bank account to a company and, if defined, an entity credit account.

=cut

sub save_bank_account {
    my ($request) = @_;
    my $bank = LedgerSMB::DBObject::Entity::Bank->new(%$request);
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
    my $note = LedgerSMB::DBObject::Entity::Note->new(%$request);
    if ($request->{note_class} == 1){
       $note->credit_id(undef);
    }
    $note->save;
    get($request);
}

=back

=head1 COPYRIGHT

Copyright (c) 2012, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

1;
