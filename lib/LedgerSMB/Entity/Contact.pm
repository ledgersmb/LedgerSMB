=head1 NAME

LedgerSMB::Entity::Contact - Contact info handling for LSMB

=head1 SYNPOSIS

  @contact_list = LedgerSMB::Entity::Contact->list(
         {entity_id = $entity_id, credit_id = $credit_id }
  );

=head1 DESCRIPTION

This module provides contact info handling for LedgerSMB.  Each contact info
record consists of optionally an entity_id or a credit_id, a class, a class
name, a description, and the actual contact information.  This is used to track
everything from phone numbers to email addresses both of natural persons and
companies in LedgerSMB.

=cut

package LedgerSMB::Entity::Contact;
use Moose;
use LedgerSMB::App_State;
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

=item class_id Int

This must be set, and references the class id of the contact.  These can be
presumed to be static values, and are contained in the contact_class table.
Currently that table contains:

  id |      class
 ----+-----------------
   1 | Primary Phone
   2 | Secondary Phone
   3 | Cell Phone
   4 | AIM
   5 | Yahoo
   6 | Gtalk
   7 | MSN
   8 | IRC
   9 | Fax
  10 | Generic Jabber
  11 | Home Phone
  12 | Email
  13 | CC
  14 | BCC
  15 | Billing Email
  16 | Billing CC
  17 | Billing BCC

=cut

has 'class_id' => (is => 'rw', isa => 'Int', required => 1);

=item class Str

This is set when retrieving a contact record to the name of the contact class,
such as IRC, Fax, or Email.

=cut

has 'class' => (is => 'ro', isa => 'Str', required => 0);

=item description Str

This is set to the description of the contact record.

=cut

has 'description' => (is => 'rw', isa => 'Str', required => 0);

=item contact Str

This is the string with the actual contact information, such as an email address
or phone number.

=cut

has 'contact' => (is => 'rw', isa => 'Str', required => 1);


=item old_class_id

If this is set, along with old_contact (below), then saving will try to overwrite
if possible.

=item old_contact

=cut

has 'old_class_id' => (is => 'rw', isa => 'Int', required => 0);

has 'old_contact' => (is => 'rw', isa => 'Str', required => 0);

=back

=head1 METHODS

=over

=item list($args, $request);

Returns a list of blessed contact references

=cut

sub list {
    my ($self, $args, $request) = @_;

    my @results;

    for my $ref (__PACKAGE__->call_procedure(funcname => 'entity__list_contacts',
                                             args => [$args->{entity_id}])
    ){
       push @results, $self->new($ref);
    }

    for my $ref (__PACKAGE__->call_procedure(funcname => 'eca__list_contacts',
                                             args => [$args->{credit_id}])
    ){
       $ref->{credit_id} = $args->{credit_id};
       push @results, __PACKAGE__->new($ref);
    }
    return @results;
}

=item save()

Saves the record

=cut

sub save {
    my ($self) = @_;
    my $ref;
    if ($self->credit_id){
        ($ref) = $self->call_dbmethod(funcname => 'eca__save_contact');
    } elsif ($self->entity_id){
        ($ref) = $self->call_dbmethod(funcname => 'entity__save_contact');
    } else {
        die $LedgerSMB::App_State::Locale->text('Must have credit or entity id');
    }
    $self->prepare_dbhash($ref);
    return $ref;
}

=item delete()

deletes the record

This can be called from $self->delete() if you have  a contact object, or it
can be called as LedgerSMB::Entity::Contact::delete($hashref) if the hashref
contains either entity_id or credit_id, and location_id, and location class.

=cut

sub delete {
    my ($ref) = @_;
    if ($ref->{for_credit}){
        __PACKAGE__->call_procedure(funcname => 'eca__delete_contact',
                                  args => [$ref->{credit_id}, $ref->{class_id},
                                           $ref->{contact}]);
    } else {
        __PACKAGE__->call_procedure(funcname => 'entity__delete_contact',
                                  args => [$ref->{entity_id}, $ref->{class_id},
                                           $ref->{contact}]);
    }
}

=item list_classes()

Lists classes as unblessed hashrefs

=cut

sub list_classes {
    return __PACKAGE__->call_procedure(
          funcname => 'contact_class__list'
    );
}

=back

=head1 COPYRIGHT

OPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
