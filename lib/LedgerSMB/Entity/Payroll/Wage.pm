=head1 NAME

LedgerSMB::Entity::Payroll::Wage - Wages and Salary Handling
for LedgerSMB

=head1 SYNPOSIS

To retrieve a list of wages for an entity:

  my @wages = LedgerSMB::Entity::Person::Wage->list($entity_id);

To retrieve a list of wage categories for selection:
  my @classes = LedgerSMB::Entity::Person::Wage->classes($entity_id);

To save a new wage:

  my $wage = LedgerSMB::Entity::Person::Wage->new(%$request);
  $wage->save;

=cut

package LedgerSMB::Entity::Payroll::Wage;
use Moose;
use LedgerSMB::MooseTypes;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item entry_id

This is the entry id (when set) of the wage.

=cut

has entry_id => (is => 'rw', isa => 'Int', required => 0);

=item type_id

This is the class id of the wage (when set)

=cut

has type_id => (is => 'rw', isa => 'Int', required => 1);

=item rate

This is the rate that one is paid.  Depending on class could be hourly, per
month, or per unit produced.

=cut

has rate => (is => 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Number',
             required => 1);

=back

=head1 METHODS

=over

=item list($entity_id)

Retrns a list of wage objects for entity

=cut

sub list {
    my ($self, $entity_id) = @_;
    return __PACKAGE__->call_procedure(funcname => 'wage__list_for_entity',
                                     args => [$entity_id]);
}

=item classes($country_id)

Returns a list of wage classes

=cut

sub types{
    my ($self, $country_id) = @_;
    return __PACKAGE__->call_procedure(funcname => 'wage__list_types',
                                     args => [$country_id]);
}

=item save

Saves the wage and attaches to the entity record

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'wage__save');
    $self->entry_id($ref->{entry_id});
}

=back

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
