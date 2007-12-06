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

require 'lsmb-request.pl';

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
    
    $employee->set( entity_class=> '3' );
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

    
    $employee->get_metadata();

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
    _render_main_screen($employee);
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
    $employee->save();
    _render_main_screen($employee);
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
