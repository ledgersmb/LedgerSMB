
=pod

=head1 NAME

LedgerSMB::Scripts::employee - LedgerSMB class defining the Controller
functions, template instantiation and rendering for employee editing and display.

=head1 SYOPSIS

This module is the UI controller for the employee DB access; it provides the 
View interface, as well as defines the Save employee. 
Save employee will update or create as needed.


=head1 METHODS

=over 

=cut

package LedgerSMB::Scripts::employee;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Employee;

#require 'lsmb-request.pl';

=item get($self, $request, $user)

Requires form var: id

Extracts a single employee from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the employee informations.

=cut


sub get {
    
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    
    $employee->get_metadata();
    $employee->set( entity_class=> '3' );
    $employee->{target_div} = 'hr_div'; 
    my $result = $employee->get();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'contact', language => $user->{language}, 
	path => 'UI/Contact',
        format => 'HTML');
    $template->render($results);
        
}

=item add_location

Adds a location to an employee and returns to the edit employee screen.
Standard location inputs apply.

=cut

sub add_location {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new({base => $request, copy => 'all'});
    $employee->set( entity_class=> '3' );
    $employee->save_location();
    $employee->get();

    

    _render_main_screen($employee);
	
}

=item save_new_location 

Adds a location to the company as defined in the inherited object, not
overwriting existing locations.

=cut

sub save_new_location {
    my ($request) = @_;
    delete $request->{location_id};
   add_location($request);
}

=item add

This method creates a blank screen for entering a employee's information.

=cut 

sub add {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    $employee->set( entity_class=> '3' );
    $employee->{target_div} = 'hr_div'; 
    _render_main_screen($employee);
}

=item delete_contact

Deletes the selected contact info record

Must include company_id or credit_id (credit_id used if both are provided) plus:

=over

=item contact_class_id

=item contact

=item form_id

=back

=cut

sub delete_contact {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    if (_close_form($employee)){
        $employee->delete_contact();
    }
    $employee->get;
    _render_main_screen( $employee);
}

=item save_contact_new($request)

Saves contact info as a new line as per save_contact above.

=cut

sub save_contact_new{
    my ($request) = @_;
    delete $request->{old_contact};
    delete $request->{old_contact_class};
    save_contact($request);
}

=item delete_location

Deletes the selected contact info record

Must include company_id or credit_id (credit_id used if both are provided) plus:

* location_class_id
* location_id 
* form_id

=cut

sub delete_location {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    if (_close_form($employee)){
        $employee->delete_location();
    }
    $employee->get;
    _render_main_screen( $employee);
}

=item edit_bank_account($request)

displays screen to a bank account

Required data:

=over 

=item bank_account_id

=item bic

=item iban

=back

=cut

sub edit_bank_acct {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    $employee->get;
    _render_main_screen( $employee);
}

=item delete_bank_acct

Deletes the selected bank account record

Required request variables:

=over

=item bank_account_id

=item entity_id

=item form_id

=back

=cut

sub delete_bank_acct{
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    if (_close_form($employee)){
        $employee->delete_bank_account();
    }
    $employee->get;
    _render_main_screen( $employee);
}

# Private method.  Sets notice if form could not be closed.
sub _close_form {
    my ($employee) = @_;
    if (!$employee->close_form()){
        $employee->{notice} = 
               $employee->{_locale}->text('Changes not saved.  Please try again.');
        return 0;
    }
    return 1;
}

=item save($self, $request, $user)

Saves a employee to the database. The function will update or insert a new 
employee as needed, and will generate a new Company ID for the employee if needed.

=cut

sub save {
    
    my ($request) = @_;

    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    if (!$employee->{employeenumber}){
        my ($ref) = $employee->call_procedure(
                             procname => 'setting_increment', 
                             args     => ['employeenumber']
                           );
        ($employee->{employeenumber}) = values %$ref;
    }
    $employee->{employee_number}=$employee->{employeenumber};
    $employee->save();
    _render_main_screen($employee);
}

=item search

Displays the search criteria screen

=cut

sub search {
    my $request = shift @_;
    my $template = LedgerSMB::Template->new(
        user => $employee->{_user},
        template => 'filter',
        locale => $employee->{_locale},
        path => 'UI/employee',
        format => 'HTML'
    );
    $template->render($request);
}

=item search_results

Displays search results.

=cut

sub search_results {
    my $request = shift @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    my @rows = $employee->search();
    my $template = LedgerSMB::Template->new(
        user => $employee->{_user},
        template => 'form-dynatable',
        locale => $employee->{_locale},
        path => 'UI',
        format => 'HTML'
    );
    my @columns;
    my $locale = $request->{_locale};
    $request->{title} = $locale->text('Search Results');
    for my $col (qw(l_position l_id l_employeenumber l_salutation 
                    l_first_name l_middle_name l_last_name l_dob 
                    l_startdate l_enddate l_role l_ssn l_sales l_manager_id
                    l_manager_first_name l_manager_last_name)){
        if ($request->{$col}){
           my $pcol = $col;
           $pcol =~ s/^l_//;
           push @columns, $pcol;
        }
    }
    # Omitting headers for the running number and salutation fields --CT
    my $header = { 
           id => $locale->text('ID'),
employeenumber=> $locale->text('Employee Number'),
   first_name => $locale->text('First Name'),
  middle_name => $locale->text('Middle Name'),
    last_name => $locale->text('Last Name'),
          dob => $locale->text('DOB'),
    startdate => $locale->text('Start Date'),
      enddate => $locale->text('End Date'),
         role => $locale->text('Role'),
          ssn => $locale->text('SSN'),
        sales => $locale->text('Sales'),
   manager_id => $locale->text('Manager ID'),


   manager_first_name => $locale->text('Manager First Name'),
    manager_last_name => $locale->text('Manager Last Name'),
    };

    my $pos = 1;
    for my $ref(@rows){
        $ref->{position} = $pos;
        my $href = "employee.pl?action=edit&entity_id=$ref->{entity_id}";
        $ref->{id} = {href => $href,
                      text => $ref->{entity_id}};
        $ref->{employeenumber} = { href => $href,
                                   text => $ref->{employeenumber} };
        ++$pos;
    } 
    $template->render({
          form => $request,
       columns => \@columns,
       heading => $header,
          rows => \@rows,
    });
}

=item edit

displays the edit employee screen. Requires id field to be set.

=cut

sub edit{
    my $request = shift @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->get();
    _render_main_screen($employee);
}

sub _render_main_screen{
    my $employee = shift @_;
    $employee->get_metadata();
    $employee->close_form;
    $employee->open_form;
    $employee->{dbh}->commit;
    $employee->{entity_class} = 3;
    $employee->{creditlimit} = "$employee->{creditlimit}"; 
    $employee->{discount} = "$employee->{discount}"; 
    $employee->{script} = "employee.pl";
    if ($employee->is_allowed_role({allowed_roles => [
                                 "lsmb_$employee->{company}__users_manage"]
                                }
    )){
        $employee->{manage_users} = 1;
    }
    $employee->debug({file => '/tmp/emp'});
    my $template = LedgerSMB::Template->new( 
	user => $employee->{_user}, 
    	template => 'contact', 
	locale => $employee->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($employee);
}

=item save_contact

Saves contact info and returns to edit employee screen

=cut

sub save_contact {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->save_contact();
    $employee->get;
    _render_main_screen($employee );
}

=item save_bank_account

Saves bank account information (bic, iban, id required) and returns to the 
edit employee screen

=cut

sub save_bank_account {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->save_bank_account();
    $employee->get;
    _render_main_screen($employee);
}

=item save_notes

Attaches note (subject, note, id required) and returns to the edit employee
screen.

=cut

sub save_notes {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->save_notes();
    $employee->get();
    _render_main_screen($employee);
}
    
eval { do "scripts/custom/employee.pl"};

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
