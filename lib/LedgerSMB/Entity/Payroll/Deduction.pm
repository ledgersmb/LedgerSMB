=head1 NAME

LedgerSMB::Entity::Payroll::Deduction - Payroll Deduction handling for
LedgerSMB

=head1 SYNPOSIS

To retrieve a list of deductions for an entity:

  my @deducts = LedgerSMB::Entity::Person::Deductions->list(
             $entity_id
  );

To retrieve a list of deduction categories for selection:
  my @types = LedgerSMB::Entity::Person::Deduction->types(
              $country_id
  );

To save a new deduction:

  my $deduct= LedgerSMB::Entity::Person::Deduction->new(%$request);
  $deduct->save;

=cut

package LedgerSMB::Entity::Payroll::Deduction;
use Moose;
use LedgerSMB::MooseTypes;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item entry_id

This is the entry id (when set) of the deduction.

=cut

has entry_id => (is => 'rw', isa => 'Int', required => 0);

=item type_id

This is the class id of the deduction

=cut

has type_id => (is => 'rw', isa => 'Int', required => 1);

=item rate

The rate handling here is deduction class specific.  Some deductions may be
percentages of income, they may be fixed amounts, or they may be calculated on
some other basis.  Therefore.....

=cut

has rate => (is => 'rw', coerce => 1., isa => 'LedgerSMB::Moose::Number',
             required => 1);

=back

=head1 METHODS

=over

=item list($entity_id)

Retrns a list of  deduction objects for entity

=cut

sub list {
    my ($self, $entity_id) = @_;
    return __PACKAGE__->call_procedure(funcname => 'deduction__list_for_entity',
                                     args => [$entity_id]);
}

=item classes($country_id)

Returns a list of deduction classes

=cut

sub types{
    my ($self, $country_id) = @_;
    return __PACKAGE__->call_procedure(funcname => 'deduction__list_types',
                                     args => [$country_id]);
}

=item save

Saves the deduction and attaches to the entity record

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'deduction__save');
    $self->entry_id($ref->{entry_id});
}

=back

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
