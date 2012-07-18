=head1 NAME

LedgerSMB::DBObject::Entity::Bank - Bank account info for customers, vendors, 
employees, and more.

=head1 SYNPOSIS

  @bank_list = LedgerSMB::DBObject::Entity::Bank->list($entity_id);
  $bank->save;

=head1 DESCRIPTION

This module manages bank accounts, for wire transfers, etc. for customers,
vendors, employees etc.   Bank accounts are attached to the entity with the
credit account being able to attach itself to a single bank account.

=cut

package LedgerSMB::DBObject::Entity::Bank;
use Moose;
with 'LedgerSMB::DBObject_Moose';

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

This is never set on retrieval, but is used to attach this as the default bank
account for a given entity credit account.

=cut

has 'credit_id' => (is => 'rw', isa => 'Maybe[Int]');

=item id

If set this indicates this has been saved to the db. 

=cut

has 'id' => (is =>'ro', isa => 'Maybe[Int]');

=item bic

Banking Institution Code, such as a SWIFT code or ABA routing number.  This can
be set to undef because there are cases where the BIC is not needed for wire
transfers.

=cut

has 'bic' => (is =>'rw', isa => 'Maybe[Str]');

=item iban

This is the bank account number.  It is required on all records.

=cut

has 'iban' => (is => 'rw', isa => 'Str');

=back

=head1 METHODS

=over

=item list($entity_id)

Lists all bank accounts for entity_id.  This does not need to be performed on a
blessed reference.  All return results are objects.

=cut

sub list{
    my ($self, $entity_id) = @_;
    my @results = $self->call_procedure(procname =>
             'entity__list_bank_account', args => [$entity_id]);
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
    my ($ref) = $self->exec_method({funcname => 'entity__save_bank_account'});
    $self->prepare_dbhash($ref);
    $self = $self->new(%$ref);
}

=item delete

Deletes the bank account object from the database.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'entity__delete_bank_account'});
    return $ref;
}

=back

=head1 COPYRIGHT

OPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

return 1;
