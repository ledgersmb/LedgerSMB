=head1 NAME

LedgerSMB::Entity::Person -- Natural Person handling for LedgerSMB

=head1 SYNOPSIS

To save:

 my $person = LedgerSMB::Entity::Person->new(\%$request);
 $person->save;

To get by entity id:

 my $person = LedgerSMB::Entity::Person->get($entity_id);

To get by control code:

 my $person = LedgerSMB::Entity::Person->get_by_cc($control_code);

=head1 INHERITS

=over

=item LedgerSMB::Entity

=back

=cut

package LedgerSMB::Entity::Person;
use Moose;
extends 'LedgerSMB::Entity';
use LedgerSMB::MooseTypes;

use LedgerSMB::App_State;
my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item entity_id

ID of entity attached.  This is also an interal reference to this person.

=cut

has 'entity_id' => (is => 'rw', isa => 'Int', required => 0);

=item first_name

Given name of the individual.

=cut

has 'first_name' => (is => 'rw', isa => 'Str', required => 1);

=item middle_name

Middle name of individual

=cut

has 'middle_name' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item last_name

Surname of individual

=cut

has 'last_name' => (is => 'rw', isa => 'Str', required => 1);

=item salutation_id

Salutation id.  These are fixed as:

  id | salutation
 ----+------------
   1 | Dr.
   2 | Miss.
   3 | Mr.
   4 | Mrs.
   5 | Ms.
   6 | Sir.
 (6 rows)

It is highly recommended that this is used, but for backward compatibility and
upgrade reasons it is not enforced at this time.  This may change at some point as our user interface does not allow this to be left blank.

=cut

has 'salutation_id' => (is => 'rw', isa => 'Int');

=item salutations

Constant hashref of above salutations, key is id.

=cut

sub salutations {
    return {
       '1' => $locale->text('Dr.'),
       '2' => $locale->text('Miss.'),
       '3' => $locale->text('Mr.'),
       '4' => $locale->text('Mrs.'),
       '5' => $locale->text('Ms.'),
       '6' => $locale->text('Sir.'),
    };
}

=item created

Date when the  person was entered into LedgerSMB

=cut

has 'created' => (is => 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item birthdate

Date of birth.  Optional

=item personal_id

Personal id, such as a passport or other government-issued or other ID.

=cut

has 'birthdate' => (is => 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Date');
has 'personal_id' => (is => 'ro', isa => 'Maybe[Str]');

=back

=head1 METHODS

=over

=item get($id)

This retrieves and returns the item as a blessed reference

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'person__get',
                                          args => [$id]);
    return undef unless $ref->{control_code};
    return __PACKAGE__->new(%$ref);
}

=item get_by_cc($cc)

This retrieves a person associated with a control code.  Dies with error if
person does not exist.

=cut

sub get_by_cc {
    my ($self, $cc) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'person__get_by_cc',
                                          args => [$cc]);
    return undef unless $ref->{control_code};
    return __PACKAGE__->new(%$ref);
}


=item save()

Saves the item and populates db defaults in id and created.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'person__save');
    $self->entity_id(values %$ref);
}

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under the GNU GPL
version 2 or at your option any future version.  Please see the accompanying LICENSE
file for details.

=cut

# Not sure why but making the class immutable causes parent attributes to be
# lost.  Is this a bug in Class::MOP?
#
__PACKAGE__->meta->make_immutable;

1;
