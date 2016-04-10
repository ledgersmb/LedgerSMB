=head1 NAME

LedgerSMB::App_Module -- Application Module Lists for LedgerSMB

=head1 SYNOPSYS

Application modules, new to LedgerSMB 1.4, are ways to categorize functionality in
LedgerSMB.  In future versions, these may be important to security management and the
like.  However at present they are mostly available to tie various reporting entries
to various parts of the software.

Note that modules are generally read-only and not expected to be saved in the system.

The id attribute is expected to be static and hardcoded, so these must be assigned.

A default module (id 0, label '') is available for doing lookups.

=cut

package LedgerSMB::App_Module;
use Moose;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item int id

This is the internal system id of the module.

=cut

has 'id' => (is => 'ro', isa => 'Int', default => '0');

=item string label

This is the human readable label.

=cut

has 'label' => (is => 'ro', isa => 'Str', default => '');

=back

=head1 METHODS

=over

=item get($id)

This retrieves a single module by id, and returns it.

=cut

sub get {
    my ($self, $id) = @_;
    my ($ref)  = $self->call_procedure(funcname => 'lsmb_module__get', args => [$id]);
    return $self->new($ref);
}

=item list()

This returns a list of all modules, ordered by id.

=cut

sub list{
    my ($self) = @_;
    my @results = $self->call_procedure(funcname => 'lsmb_module__list');
    for my $ref(@results){
        $ref = $self->new($ref);
    }
    return @results;
}


=back

=head1 COPYRIGHT

Copyright (C) 2012, The LedgerSMB Core Team.  This file may be reused under the terms of
the GNU General Public License, version 2, or at your option any later version.  See
the included LICENSE.txt for details.

=cut

1;
