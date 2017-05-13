=head1 NAME

LedgerSMB::Exchangerate_Type

=head1 SYNOPSYS

This holds the information as to the handling of types of exchange rates.
Different classes may be created for the purpose of daily entry, revaluation,
translation or other purposes.

=cut

package LedgerSMB::Exchangerate_Type;

use Moose;
use namespace::autoclean;

use LedgerSMB::PGObject;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item id

This is the internal id of the rate type.  It is undef when the type has not
yet been saved in the database.

=cut

has 'id' => (is => 'rw', isa => 'Int');

=item description

This is the human-readible type description.  It must be unique among types.

=cut

has 'description' => (is => 'rw', isa => 'Str');

=item builtin

This boolean indicates every LedgerSMB application should hold this
value and it thus can't be deleted.

=cut

has 'builtin' => (is => 'ro', isa => 'Bool');


=back

=head1 METHODS

=over

=item get($id)

returns the business unit type that corresponds to the id requested.

=cut

sub get {
    my ($self, $id) = @_;
    my @classes = $self->call_procedure(procname => 'exchangerate_type__get',
                                            args => [$id]
        );
    my $ref = shift @classes;
    $self->prepare_dbhash($ref);
    return $self->new($ref);
}

=item save

Saves the existing exchange rate type to the database, and updates any fields
changed in the process.

=cut

sub save {
    my ($self) = @_;
    my $id = $self->exec_method({funcname => 'exchangerate_type__save'});
    return $self->get($id);
}


=item list

Returns a list of all exchange rate types.

=cut

sub list {
    my ($self) = @_;
    my @classes = $self->call_procedure(
            procname => 'exchangerate_type__list');
    for my $class (@classes){
        $self->prepare_dbhash($class);
        $class = $self->new(%$class);
    }
    return @classes;
}

=item delete

Deletes an exchange rate type.  Such types may not have actual rates attached.

=cut

sub delete {
    my ($self) = @_;
    $self->exec_method({funcname => 'exchangerate_type__delete'});
}

=back

=head1 PREDEFINED TYPES

=over

=item Default, ID: 1

=back

=head1 COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team.  This module may be used under the
GNU GPL in accordance with the LICENSE file listed.

=cut

__PACKAGE__->meta->make_immutable;
1;
