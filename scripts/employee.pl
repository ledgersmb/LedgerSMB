#!/usr/bin/perl

=pod

=head1 NAME

LedgerSMB::Scripts::employee - LedgerSMB class defining the Controller
functions, template instantiation and rendering for employee editing and display.

=head1 SYOPSIS

This module is the UI controller for the employee DB access; it provides the 
View interface, as well as defines the Save employee. 
Save employee will update or create as needed.


=head1 METHODS

=cut

package LedgerSMB::Scripts::employee;

use LedgerSMB::Template;
use LedgerSMB::DBObject::Employee;

#require 'lsmb-request.pl';

=pod

=over

=item get($self, $request, $user)

Requires form var: id

Extracts a single employee from the database, using its company ID as the primary
point of uniqueness. Shows (appropriate to user privileges) and allows editing
of the employee informations.

=back

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


sub add_location {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new({base => $request, copy => 'all'});
    $employee->set( entity_class=> '3' );
    $employee->save_location();
    $employee->get();

    

    _render_main_screen($employee);
	
}

=pod

=over

=item add

This method creates a blank screen for entering a employee's information.

=back

=cut 

sub add {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    $employee->set( entity_class=> '3' );
    $employee->{target_div} = 'hr_div'; 
    _render_main_screen($employee);
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
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    if (_close_form($company)){
        $employee->delete_contact();
    }
    $employee->get;
    _render_main_screen( $employee);
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

sub delete_location {
    my ($request) = @_;
    my $employee= LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
    if (_close_form($employee)){
        $employee->delete_location();
    }
    $employee->get;
    _render_main_screen( $employee);
}

=pod

=over

=item search($self, $request, $user)

Requires form var: search_pattern

Directly calls the database function search, and returns a set of all employees
found that match the search parameters. Search parameters search over address 
as well as employee/Company name.

=back

=cut

sub search {
    my ($request) = @_;
    
    if ($request->type() eq 'POST') {
        # assume it's asking us to do the search, now
        
        my $employee = LedgerSMB::DBObject::Employee->new(base => $request, copy => 'all');
        $employee->set(entity_class=>3);
        my $results = $employee->search($employee->{search_pattern});

        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'Contact/employee', language => $user->{language}, 
            format => 'HTML');
        $template->render($results);
        
    }
    else {
        
        # grab the happy search page out.
        
        my $template = LedgerSMB::Template->new( 
		user => $user,
		path => 'UI/Contact' ,
    		template => 'employee_search', 
		locale => $request->{_locale}, 
		format => 'HTML');
            
        $template->render();
    }
}

=pod

=over

=item save($self, $request, $user)

Saves a employee to the database. The function will update or insert a new 
employee as needed, and will generate a new Company ID for the employee if needed.

=back

=cut

sub save {
    
    my ($request) = @_;

    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    if (!$employee->{employeenumber}){
        my ($ref) = $employee->call_procedure(
                             procname => 'setting_increment', 
                             args     => ['employeenumber']
                           );
        ($employee->{employee_number}) = values %$ref;
    }
    $employee->save();
    _render_main_screen($employee);
}

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

sub edit{
    my $request = shift @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->get();
    _render_main_screen($employee);
}

sub _render_main_screen{
    my $employee = shift @_;
    $employee->get_metadata();
    $employee->{entity_class} = 3;
    $employee->{creditlimit} = "$employee->{creditlimit}"; 
    $employee->{discount} = "$employee->{discount}"; 
    $employee->{script} = "employee.pl";

    my $template = LedgerSMB::Template->new( 
	user => $employee->{_user}, 
    	template => 'contact', 
	locale => $employee->{_locale},
	path => 'UI/Contact',
        format => 'HTML'
    );
    $template->render($employee);
}

sub save_contact {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->save_contact();
    $employee->get;
    _render_main_screen($employee );
}

sub save_bank_account {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->save_bank_account();
    $employee->get;
    _render_main_screen($employee);
}

sub save_notes {
    my ($request) = @_;
    my $employee = LedgerSMB::DBObject::Employee->new({base => $request});
    $employee->save_notes();
    $employee->get();
    _render_main_screen($employee);
}
    
eval { do "scripts/custom/employee.pl"};
1;
