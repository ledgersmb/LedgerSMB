=head1 NAME

LedgerSMB::DBObject::Entity::Contact - Contact info handling for LSMB

=head1 SYNPOSIS

  @contact_list = LedgerSMB::DBObject::Entity::Contact->list(
         {entity_id = $entity_id, credit_id = $credit_id }
  );

=head1 DESCRIPTION

This module provides contact info handling for LedgerSMB.  Each contact info
record consists of optionally an entity_id or a credit_id, a class, a class
name, a description, and the actual contact information.  This is used to track
everything from phone numbers to email addresses both of natural persons and
companies in LedgerSMB.

=cut

package LedgerSMB::DBObject::Entity::Contact;
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

=cut

has 'credit_id' => (is => 'rw', isa => 'Maybe[Int]');

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

has 'class_id' => (is => 'rw', isa => 'Int');

=item class Str

This is set when retrieving a contact record to the name of the contact class,
such as IRC, Fax, or Email.

=cut

has 'class' => (is => 'ro', isa => 'Maybe[Str]');

=item description Str

This is set to the description of the contact record.

=cut

has 'description' => (is => 'rw', isa => 'Maybe[Str]');

=item contact Str

This is the string with the actual contact information, such as an email address
or phone number.

=cut

has 'contact' => (is => 'rw', isa => 'Str');


=item old_class_id

If this is set, along with old_contact (below), then saving will try to overwrite
if possible.

=item old_contact 

=cut

has 'old_class_id' => (is => 'rw', isa => 'Maybe[Int]');

has 'old_contact' => (is => 'rw', isa => 'Maybe[Str]');

=back

=head1 METHODS

=over

=item list($args, $request);

Returns a list of blessed contact references

=cut

sub list {
    my ($self, $args, $request) = @_;

    my @results;

    for my $ref ($self->call_procedure(procname => 'entity__list_contacts',
                                             args => [$args->{entity_id}])
    ){
       $self->prepare_dbhash($ref);
       push @results, $self->new($ref);
    }

    for my $ref ($self->call_procedure(procname => 'eca__list_contacts',
                                             args => [$args->{credit_id}])
    ){
       $self->prepare_dbhash($ref);
       $ref->{credit_id} = $args->{credit_id};
       push @results, $self->new($ref);
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
        ($ref) = $self->exec_method({funcname => 'eca__save_contact'});
    } elsif ($self->entity_id){
        ($ref) = $self->exec_method({funcname => 'entity__save_contact'});
    } else {
        die $LedgerSMB::App_State::Locale->text('Must have credit or entity id');
    }
    $self->prepare_dbhash($ref);
    return $self->new($ref);
}

=item delete()

deletes the record

=cut

sub delete {
    my ($self) = @_;
    if ($self->credit_id){
        $self->exec_method({funcname => 'eca__delete_contact'});
    } else {
        $self->exec_method({funcname => 'entity__delete_contact'});
    }
}

=item list_classes()

Lists classes as unblessed hashrefs

=cut

sub list_classes {
    return LedgerSMB::DBObject_Moose->call_procedure(
          procname => 'contact_class__list'
    );
}

=back

=head1 COPYRIGHT

OPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

return 1;
