package LedgerSMB::DBObject::Employee;

=head1 NAME

LedgerSMB::DBObject::Employee - LedgerSMB class for managing Employees 

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

The following method is static:

=over

=item new ($LedgerSMB object);


=item save

Saves an employee.  Inputs required

=over

=item entity_id

May not be undef

=item start_date

=item end_date

=item dob date

may not be undef

=item role

Not the database role.  Either manager or user 

=item ssn

=item sales

=item manager_id

=item employee_number

=back

=item search

Returns a list of employees matching set criteria:

=over

=item employeenumber (exact match)

=item startdate_from (start of date range)

=item startdate_to (end of date range)

=item first_name (partial match)

=item middle_name (partial match)

=item last_name (partial match)

=item notes (partial match)

=back

Undef values match all values.

=cut

use base qw(LedgerSMB::DBObject);
use strict;

my $ENTITY_CLASS = 3;

=item set_entity_class

Sets the entity class to 3.

=cut

sub set_entity_class {
    my $self = shift @_;
    $self->{entity_class} = $ENTITY_CLASS;
}

sub save {
   my ($self) = @_;
   $self->set_entity_class();
   my ($ref) = $self->exec_method(funcname => 'person__save');
   $self->{entity_id} = $ref->{'person__save'};
   $self->exec_method(funcname => 'employee__save');
   $self->{dbh}->commit;
}

=item save_location

Saves the location data for the contact.

Inputs are standard location inputs (line_one, line_two, etc)

=cut

sub save_location {
    my $self = shift @_;

    $self->{country_id} = $self->{country_code};

    my ($ref) = $self->exec_method(funcname => 'person__save_location');
    my @vals = values %$ref;
    $self->{location_id} = $vals[0];

    $self->{dbh}->commit;
}

=item save_contact

Saves contact information.  Inputs are standard contact inputs:

=over

=item entity_id

=item contact_class

=item contact

=item description

=cut

sub save_contact {
    my ($self) = @_;
    $self->{contact_new} = $self->{contact};
    $self->exec_method(funcname => 'person__save_contact');
    $self->{dbh}->commit;
}

=item save_bank_account

Saves a bank account to an employee.

Standard inputs (entity_id, iban, bic)

=cut

sub save_bank_account {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_bank_account');
    $self->{dbh}->commit;
}

=item get_metadata()

This retrieves various information vor building the user interface.  Among other
things, it sets the following properties:
$self->{ar_ap_acc_list} = qw(list of ar or ap accounts)
$self->{cash_acc_list} = qw(list of cash accounts)

=cut

sub get_metadata {
    my $self = shift @_;

    @{$self->{entity_classes}} = 
		$self->exec_method(funcname => 'entity__list_classes');

    @{$self->{location_class_list}} = 
         $self->exec_method(funcname => 'location_list_class');

    @{$self->{country_list}} = 
         $self->exec_method(funcname => 'location_list_country');

    @{$self->{contact_class_list}} = 
         $self->exec_method(funcname => 'entity_list_contact_class');
    my $country_setting = LedgerSMB::Setting->new({base => $self, copy => 'base'});
    $country_setting->{key} = 'default_country';
    $country_setting->get;
    $self->{default_country} = $country_setting->{value};
    $self->get_user_info();
}

=item get

Returns the employee record with all the inputs required for "save" populated.

Also populates:

=over

=item locations

List of location info

=item contacts

List of contact info

=item notes

List of notes

=item bank account

List of bank accounts

=back

=cut

sub get {
    my $self = shift @_;
    my ($ref) = $self->exec_method(funcname => 'employee__get');
    $self->merge($ref);
    @{$self->{locations}} = $self->exec_method(
		funcname => 'person__list_locations');
    @{$self->{contacts}} = $self->exec_method(
		funcname => 'person__list_contacts');
    @{$self->{notes}} = $self->exec_method(
		funcname => 'person__list_notes');
    @{$self->{bank_account}} = $self->exec_method(
		funcname => 'person__list_bank_account');

    
     
}   

=item save_notes

Saves a note to an employee entity.

Standard inputs (note, subject, entity_id)

=cut 

sub save_notes {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_notes');
    $self->{dbh}->commit;
}

sub search {
    my $self = shift @_;
    my @results = $self->exec_method(funcname => 'employee__search');
    @{$self->{search_results}} = @results;
    return @results;
}

=item delete_contact

required request variables:

contact_class_id:  int id of contact class
contact: text of contact information
person_id: int of entity_credit_account.id, preferred value


=cut

sub delete_contact {
    my ($self) = @_;
    $self->exec_method(funcname => 'person__delete_contact');
    $self->{dbh}->commit;
}

=item delete_location

Deletes a record from the location side.

Required request variables:

location_id
location_class_id
person_id

Returns true if a record was deleted.  False otherwise.

=cut

sub delete_location {
    my ($self) = @_;
    my $rv;
    ($rv) = $self->exec_method(funcname => 'person__delete_location');
    $self->{dbh}->commit;
    return $rv;
}

=item delete_bank_account

Deletes a bank account

Requires:

entity_id
bank_account_id

Returns true if a record was deleted, false otherwise.

=back

=cut

sub delete_bank_account {
    my ($self) = @_;
    my $rv;
    ($rv) = $self->exec_method(funcname => 'entity__delete_bank_account',
                               args => [$self->{entity_id}, 
                                        $self->{bank_account_id}]);
    $self->{dbh}->commit;
    return $rv;
}

=item get_user_info

Attaches the user_id and username to the employee object.

If the user does not have manage_users powers, this will simply return false

=cut

sub get_user_info {
    my $self = shift @_;
    if (!$self->is_allowed_role({allowed_roles => [
                                 "lsmb_$self->{company}__users_manage"]
                                }
    )){
        return 0;
    }
    my ($ref) = $self->exec_method(funcname => 'employee__get_user');
    $self->{user_id} = $ref->{id};
    $self->{username} = $ref->{username};
    return 1;
}

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
