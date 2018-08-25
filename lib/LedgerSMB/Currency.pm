=head1 NAME

LedgerSMB::Currency

=head1 DESCRIPTION

This holds the information as to the handling of classes of exchange rates.
Different classes may be created for the purpose of daily entry, revaluation,
translation or other purposes.

=cut

package LedgerSMB::Currency;

use Moose;
use namespace::autoclean;

use LedgerSMB::PGObject;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item curr

This is the identifier of the currency as per the ISO currency tables.

=cut

has 'curr' => (is => 'rw', isa => 'Str', required => 1);

=item description

This is the description of the currency.

=cut

has 'description' => (is => 'rw', isa => 'Str');


=back

=head1 METHODS

=over

=item get($id)

returns the currency that corresponds to the id requested.

=cut

sub get {
    my ($self, $id) = @_;
    my @classes = $self->call_procedure(procname => 'currency__get',
                                            args => [$id]
        );
    my $ref = shift @classes;
    return $self->prepare_dbhash($ref);
}

=item save

Saves the existing exchange rate class to the database, and updates any fields
changed in the process.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'currency__save'});
    return $self->get($self->curr);
}


=item list(bool $active, string $mod_name)

Returns a list of all currencies.

=cut

sub list {
    my ($self) = @_;
    my @classes = $self->call_procedure(
            procname => 'currency__list');
    for my $class (@classes){
        $self->prepare_dbhash($class);
        $class = $self->new(%$class);
    }
    return @classes;
}

=item delete

Deletes a currency.  Such currencies may not be referenced by other entities such as transactions or rates.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'currency__delete'});
}

=back

=head1 PREDEFINED CLASSES

=over

=item Default, ID: 1

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team.  This module may be used under the
GNU GPL in accordance with the LICENSE file listed.

=cut

__PACKAGE__->meta->make_immutable;
1;
