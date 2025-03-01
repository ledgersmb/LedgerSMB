
package LedgerSMB::Entity::Bank;

=head1 NAME

LedgerSMB::Entity::Bank - Bank account info for customers, vendors,
employees, and more.

=head1 SYNPOSIS

  @bank_list = LedgerSMB::Entity::Bank->list($entity_id);
  $bank->save;

=head1 DESCRIPTION

This module manages bank accounts, for wire transfers, etc. for customers,
vendors, employees etc.   Bank accounts are attached to the entity with the
credit account being able to attach itself to a single bank account.

=cut

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';
use PGObject::Util::DBMethod;

sub _get_prefix { return 'entity__' };

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

This is never set on retrieval, but is used to attach this as the default bank
account for a given entity credit account.

=cut

has 'credit_id' => (is => 'rw', isa => 'Int', required => 0);

=item id

If set this indicates this has been saved to the db.

=cut

has 'id' => (is =>'ro', isa => 'Int', required => 0);

=item bic

Banking Institution Code, such as a SWIFT code or ABA routing number.  This can
be omitted because there are cases where the BIC is not needed for wire
transfers.

=cut

has 'bic' => (is =>'rw', isa => 'Str', required => 0);

=item iban

This is the bank account number.  It is required on all records.

=cut

has 'iban' => (is => 'rw', isa => 'Str', required => 1);

=item remark

This is a note to help select bank accounts.

=cut

has 'remark' => (is => 'rw', isa => 'Str', required => 0);

=back

=head1 METHODS

=over

=item list($entity_id)

Lists all bank accounts for entity_id.  This does not need to be performed on a
blessed reference.  All return results are objects.

=cut

dbmethod list => (funcname => 'list_bank_account',
                   arg_list => ['entity_id'],
           returns_objects => 1 );

=item save()

Saves the bank account object to the database and reinstantiates it, thus
setting things like the id field.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'save_bank_account');
    return $self = $self->new(%$ref);
}

=item delete($id, $entity_id)

Deletes the bank account object from the database.

=cut

dbmethod delete => (funcname => 'delete_bank_account', arg_list => ['id', 'entity_id']);

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
