=head1 NAME

LedgerSMB::Entity::Note - Notes handling for customers, vendors,
employees, etc.

=head1 SYNPOSIS

  @notes = LedgerSMB::Entity::Bank->list($entity_id, [$credit_id]);
  $note->add;

=head1 DESCRIPTION

This module handles tracking of notes for customers, vendors, employees, sales
leads, and more.  Notes are expected to be read-only, and essentially
append-only.

This module handles attaching notes either at the entity level or the credit id
level.

=cut

package LedgerSMB::Entity::Note;
use Moose;
with 'LedgerSMB::PGObject';


=head1 PROPERTIES

=over

=item entity_id Int

If set this is attached to an entity.  This can optionally be set to a contact
record attached to a credit account but is ignored in that case.

=cut

has 'entity_id' => (is => 'rw', isa => 'Int', required => 0);

=item credit_id Int

If this is set, this is attached to an entity credit account.  If this and
entity_id are set, entity_id is ignored.

=cut

has 'credit_id' => (is => 'rw', isa => 'Int', required => 0);

=item id

If set this indicates this has been saved to the db.

=cut

has 'id' => (is =>'ro', isa => 'Int', required => 0);

=item subject

This is the subject of the note.

=cut

has 'subject' => (is =>'rw', isa => 'Maybe[Str]', required => 0);

=item note

The contents of the note.  Required

=cut

has 'note' => (is => 'rw', isa => 'Str', required => 1);

=item 'note_class'

ID for note class (1 for entity, 3 for eca, etc)

=cut

has 'note_class'  => (is => 'rw', isa => 'Int', required => 1);

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
        @results = __PACKAGE__->call_procedure(funcname =>
             'eca__list_notes', args => [$credit_id]);
    } else {
        @results = __PACKAGE__->call_procedure(funcname =>
             'entity__list_notes', args => [$entity_id]);
    }
    for my $row(@results){
        $row = __PACKAGE__->new(%$row);
    }
    return @results;
}

=item save()

Saves the bank account object to the database and reinstantiates it, thus
setting things like the id field.

=cut

sub save {
    my ($self) = @_;
    my $ref;
    if (3 == $self->note_class){
        ($ref) = $self->call_dbmethod(funcname => 'eca__save_notes');
    } else {
        ($ref) = $self->call_dbmethod(funcname => 'entity__save_notes');
    }
    return $ref;
}

=back

=head1 COPYRIGHT

OPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
