=head1 NAME

LedgerSMB::DBObject::Entity::Person -- Natural Person handling for LedgerSMB

=head1 SYNOPSIS

To save:

 my $person = LedgerSMB::DBObject::Entity::Person(\%$request);
 $person->save;

To get by entity id:

 my $person = LedgerSMB::DBObject::Entity::Person->get($entity_id);

To get by control code:

 my $person = LedgerSMB::DBObject::Entity::Person->get_by_cc($control_code);

=head1 INHERITS

=over 

=item LedgerSMB::DBObject::Entity

=back

=cut

package LedgerSMB::DBObject::Entity::Person;
use Moose;
extends 'LedgerSMB::DBObject::Entity';

use LedgerSMB::App_State;

my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item entity_id

ID of entity attached.  This is also an interal reference to this person.

=cut

has 'entity_id' => (is => 'rw', isa => 'Maybe[Int]');

=item first_name

Given name of the individual.

=cut

has 'first_name' => (is => 'rw', isa => 'Str');

=item middle_name

Middle name of individual

=cut

has 'middle_name' => (is => 'rw', isa => 'Maybe[Str]');

=item last_name

Surname of individual

=cut

has 'last_name' => (is => 'rw', isa => 'Maybe[Str]');

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

=back

=cut

has 'created' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=head1 METHODS

=over

=item get($id)

This retrieves and returns the item as a blessed reference

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref) = $self->call_procedure(procname => 'person__get',
                                          args => [$id]);
    if (!$ref){
        die $locale->text('No person found.');
    }
    $self->prepare_dbhash($ref);
    return $self->new(%$ref);
}

=item get_by_cc($cc)

This retrieves a person associated with a control code.  Dies with error if 
person does not exist.

=cut

sub get_by_cc {
    my ($self, $cc) = @_;
    my ($ref) = $self->call_procedure(procname => 'person__get_by_cc',
                                          args => [$cc]);
    if (!$ref){
        die $self->{_locale}->text('No person found.');
    }
    $self->prepare_dbhash($ref);
    return $self->new(%$ref);
}


=item save()

Saves the item and populates db defaults in id and created.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'person__save'});
    $self->prepare_dbhash($ref);
    $ref->{control_code} = $self->{control_code};
    $ref->{entity_class} = $self->{entity_class};
    $ref->{country_id} = $self->{country_id};
    $self = $self->new(%$ref);
}

=back

=head1 COPYRIGHT

Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under the GNU GPL
version 2 or at your option any future version.  Please see the accompanying LICENSE 
file for details.

=cut

__PACKAGE__->meta->make_immutable;

return 1;
