=head1 NAME

LedgerSMB::DBObject::Entity::Note - Notes handling for customers, vendors, 
employees, etc.

=head1 SYNPOSIS

  @notes = LedgerSMB::DBObject::Entity::Bank->list($entity_id, [$credit_id]);
  $note->add;

=head1 DESCRIPTION

This module handles tracking of notes for customers, vendors, employees, sales
leads, and more.  Notes are expected to be read-only, and essentially
append-only.

This module handles attaching notes either at the entity level or the credit id
level.  

=cut

package LedgerSMB::DBObject::Entity::Note;
use Moose;
extends 'LedgerSMB::DBObject_Moose';

=head1 INHERITS

=over

=item LedgerSMB::DBObject_Moose;

=back

head1 PROPERTIES

=over

=item entity_id Int

If set this is attached to an entity.  This can optionally be set to a contact
record attached to a credit account but is ignored in that case.

=cut

has 'entity_id' => (is => 'rw', isa => 'Maybe[Int]');

=item credit_id Int

If this is set, this is attached to an entity credit account.  If this and
entity_id are set, entity_id is ignored.

=cut

has 'credit_id' => (is => 'rw', isa => 'Maybe[Int]');

=item id

If set this indicates this has been saved to the db. 

=cut

has 'id' => (is =>'ro', isa => 'Maybe[Int]');

=item subject

This is the subject of the note. 

=cut

has 'subject' => (is =>'rw', isa => 'Maybe[Str]');

=item note

The contents of the note.  Required

=cut

has 'note' => (is => 'rw', isa => 'Str');

=back

=head1 METHODS

=over

=item list($entity_id, [$credit_id])

Lists all bank accounts for entity_id.  This does not need to be performed on a
blessed reference.  All return results are objects.

=cut

sub list{
    my ($self, $entity_id, $credit_id) = @_;
    my @results;
    if ($credit_id){
        @results = $self->call_procedure(procname =>
             'eca__list_notes', args => [$credit_id]);
    } else {
        @results = $self->call_procedure(procname =>
             'entity__list_notes', args => [$credit_id]);
    }
    for my $row(@results){
        $self->prepare_dbhash($row); 
        $row = $self->new(%$row);
    }
    return @results;
}

=item save()

Saves the bank account object to the database and reinstantiates it, thus
setting things like the id field.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'entity__save_notes'});
    $self->prepare_dbhash($ref);
    $self = $self->new(%$ref);
}

=back

=head1 COPYRIGHT

OPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

return 1;
