=head1 NAME

LedgerSMB::DBObject::Entity::Payroll::Wage - Wages and Salary Handling 
for LedgerSMB

=head1 SYNPOSIS

To retrieve a list of wages for an entity:

  my @wages = LedgerSMB::DBObject::Entity::Person::Wage->list($entity_id);

To retrieve a list of wage categories for selection:
  my @classes = LedgerSMB::DBObject::Entity::Person::Wage->classes($entity_id);

To save a new wage:

  my $wage = LedgerSMB::DBObject::Entity::Person::Wage->new(%$request);
  $wage->save;

=cut

package LedgerSMB::DBObject::Entity::Payroll::Wage;
use Moose;
extends 'LedgerSMB::DBObject_Moose';

=head1 PROPERTIES

=over

=item entry_id 

This is the entry id (when set) of the wage.

=cut

has entry_id => (is => 'rw', isa => 'Maybe[Int]');

=item type_id

This is the class id of the wage (when set)

=cut

has type_id => (is => 'rw', isa => 'Int');

=item rate

This is the rate that one is paid.  Depending on class could be hourly, per 
month, or per unit produced.

=cut 

has rate => (is => 'rw', isa => 'Num');

=back

=head1 METHODS

=over

=item list($entity_id)

Retrns a list of wage objects for entity

=cut

sub list {
    my ($self, $entity_id) = @_;
    return $self->call_procedure(procname => 'wage__list_for_entity',
                                     args => [$entity_id]);
}

=item classes($country_id)

Returns a list of wage classes

=cut

sub types{
    my ($self, $country_id) = @_;
    return $self->call_procedure(procname => 'wage__list_types', 
                                     args => [$country_id]);
}

=item save

Saves the wage and attaches to the entity record

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'wage__save'});
    $self->entry_id($ref->{entry_id});
}

=back

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
