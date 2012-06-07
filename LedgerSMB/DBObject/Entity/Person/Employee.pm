=head1 NAME

LedgerSMB::DBObject::Entity::Person::Employee -- Employee handling for LedgerSMB

=head1 SYNOPSIS

To save:

 my $emp = LedgerSMB::DBObject::Entity::Person::Employee(\%$request);
 $emp->save;

To get by entity id:

 my $emp = LedgerSMB::DBObject::Entity::Person::Employee->get($entity_id);

To get by control code:

 my $emp 
     = LedgerSMB::DBObject::Entity::Person::Employee->get_by_cc($control_code);

=head1 INHERITS

=over 

=item LedgerSMB::DBObject::Entity::Person

=back

=cut

package LedgerSMB::DBObject::Entity::Person::Employee;
use Moose;
extends 'LedgerSMB::DBObject::Entity::Person';

use LedgerSMB::App_State;
my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item start_date

Start date for employee.

=cut

has start_date => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item end_date

End date for employee

=cut

has end_date => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item dob

Date of Birth.  Required.

=cut

has dob => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item role

Organizational role.  Is manager, user, or administrator

=cut

has role => (is => 'rw', isa => 'Maybe[Str]');

=item ssn

Social security number, tax number, or the like for the employee.  Required

=cut

has ssn => (is => 'rw', isa => 'Str');

=item sales

Bool, whether the individual is a salesperson or not

=cut

has sales => (is => 'rw', isa => 'Bool');

=item manager_id

Entity id of manager

=cut

has manager_id => (is => 'rw', isa => 'Maybe[Int]');

=item employeenumber

Employee number, required, for employee.

=cut

has employeenumber => (is => 'rw', isa => 'Str');

=back

=head1 METHODS

=over

=item get($entity_id)

This does not need to be a blessed reference.  It does return a reference 
blessed if the employee is found or undef otherwise.

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = $self->call_procedure(procname => 'employee__get',
                                          args => [$id]);
    return undef unless $ref->{control_code};
    $self->prepare_dbhash($ref);
    return $self->new(%$ref);
}

=item get_by_cc($control_code);

Similar to get above but accepts as input the control code rather than the
entity_id.

=cut

sub get_by_cc {
    my ($self, $cc) = @_;
    my ($ref) = $self->call_procedure(procname => 'person__get_by_cc',
                                          args => [$cc]);
    return undef unless $ref->{control_code};
    return get($ref->{id});
}

=item save()

Saves the employee.  Must be a blessed reference.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'person__save'});
    my ($id) = values(%$ref);
    $self->entity_id($id);
    my ($ref) = $self->exec_method({funcname => 'employee__save'});
}

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under 
the GNU GPL version 2 or at your option any future version.  Please see the 
accompanying LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
