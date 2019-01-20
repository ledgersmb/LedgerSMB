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
    my @classes = $self->call_procedure(funcname => 'currency__get',
                                        args => [$id]
        );
    my $ref = shift @classes;
    return $self->new($ref);
}

=item save

Saves the existing exchange rate class to the database, and updates any fields
changed in the process.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'currency__save');
    return $self->get($self->curr);
}


=item list(bool $active, string $mod_name)

Returns a list of all currencies.

=cut

sub list {
    my ($self) = @_;
    my @classes = $self->call_procedure(
            funcname => 'currency__list');
    for my $class (@classes){
        $class = $self->new(%$class);
    }
    return @classes;
}

=item delete

Deletes a currency.  Such currencies may not be referenced by other entities such as transactions or rates.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'currency__delete');
}

=back

=head1 PREDEFINED CLASSES

=over

=item Default, ID: 1

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
