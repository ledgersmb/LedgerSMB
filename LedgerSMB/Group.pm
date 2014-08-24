=head1 NAME

LedgerSMB::Group - Group Management for LedgerSMB

=head1 SYNPOSIS

To create a group, add roles, and save it:

  my $grp = LedgerSMB::Group->new(%$request);
  $grp->roles(\@roles);
  $grp->save;

To retrieve a role from the db:

  my $grp->get($name);

=cut

package LedgerSMB::Group;
use Moose;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item Str name

This is the name of the group role, minus the prefix.

=cut

has name => (is => 'ro', isa => 'Str', required => 1);

=item Str fqname

This is the name of the group role including the prefix.

=cut

has fqname => (is => 'ro', isa => 'Str', required => 1);

=item Arrayref[Str] roles

Roles granted to group role.

=cut

has roles => (is => 'rw', isa => 'ArrayRef[Str]', required => 0);

=back

=head1 METHODS

=over

=item get

=item save

=back

=head1 COPYRIGHT

=cut

1;

