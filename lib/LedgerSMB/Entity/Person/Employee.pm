
package LedgerSMB::Entity::Person::Employee;

=head1 NAME

LedgerSMB::Entity::Person::Employee -- Employee handling for LedgerSMB

=head1 DESCRIPTION

Derived from C<LedgerSMB::Entity::Person>, this class adds
"employee attributes" such as start and end dates, HR hierarchy (manager)
and organisational funcion/role name.

=head1 SYNOPSIS

To save:

 my $emp = LedgerSMB::Entity::Person::Employee(\%$request);
 $emp->save;

To get by entity id:

 my $emp = LedgerSMB::Entity::Person::Employee->get($entity_id);

To get by control code:

 my $emp
     = LedgerSMB::Entity::Person::Employee->get_by_cc($control_code);

=head1 INHERITS

=over

=item LedgerSMB::Entity::Person

=back

=cut

use Moose;
use namespace::autoclean;
use LedgerSMB::Entity::Person;
use LedgerSMB::Magic qw( EC_EMPLOYEE );
extends 'LedgerSMB::Entity::Person';

=head1 PROPERTIES

=over

=item start_date

Start date for employee.

=cut

has start_date => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item end_date

End date for employee

=cut

has end_date => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item dob

Date of Birth.  Required.

=cut

has dob => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item role

Organizational role.  Is manager, user, or administrator

=cut

has role => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item is_manager

Whether the employee is a manager.

=cut

has is_manager => (is => 'rw', isa => 'Bool');

=item ssn

Social security number, tax number, or the like for the employee.

=cut

has ssn => (is => 'rw', isa => 'Str');

=item sales

Bool, whether the individual is a salesperson or not

=cut

has sales => (is => 'rw', isa => 'Bool');

=item manager_id

Entity id of manager

=cut

has manager_id => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item employeenumber

Employee number, required, for employee.

=cut

has employeenumber => (is => 'rw', isa => 'Str', required => 1);


=item entity_class



=cut

has entity_class => (is => 'ro', isa => 'Str', default => 3);


=back

=head1 METHODS

=over

=item get($entity_id)

This does not need to be a blessed reference.  It does return a reference
blessed if the employee is found or undef otherwise.

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'employee__get',
                                          args => [$id]);
    return undef unless $ref->{control_code};
    $ref->{entity_class} = EC_EMPLOYEE;
    $ref->{name} = "$ref->{first_name} $ref->{last_name}";
    return __PACKAGE__->new(%$ref);
}

=item get_by_cc($control_code);

Similar to get above but accepts as input the control code rather than the
entity_id.

=cut

sub get_by_cc {
    my ($self, $cc) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'person__get_by_cc',
                                          args => [$cc]);
    return undef unless $ref->{control_code};
    return get($ref->{id});
}

=item save()

Saves the employee.  Must be a blessed reference.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'person__save');
    my ($id) = values(%$ref);
    $self->entity_id($id);
    return $self->call_dbmethod(funcname => 'employee__save');
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
