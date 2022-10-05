
package LedgerSMB::Part;

=head1 NAME

LedgerSMB::Part - Good/Service class for LedgerSMB

=head1 DESCRIPTION

This is currently a shell class pending rewrite of old code.

=cut

use strict;
use warnings;

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

TODO (None yet)

=head1 METHODS

=head2 basic_partslist(partnumber => $number, description => $desc)

Returns an array of hashrefs of matching parts.  All fields in the parts
table are returned.

=cut

sub basic_partslist {
    my ($self, %args) = @_;
    my @parts = $self->call_dbmethod(
        funcname => 'parts__search_lite',
        args     => \%args
        );
    return @parts;
}

=head2 get_by_partnumber

TODO:  Move to blessed moose object

currently returns a hashref from parts table where the partnumber is an exact
match and the part is not obsolete.

=cut

sub get_by_partnumber {
    my ($self, $partnumber) = @_;
    return (
        $self->call_dbmethod(
            funcname => 'parts__get_by_partnumber',
            args     => { partnumber => $partnumber }
        )
        )[0];
}

=head2 get_by_id

TODO:  Move to blessed moose object

currently returns a hashref from parts table where the partnumber is an exact
match and the part is not obsolete.

=cut

sub get_by_id {
    my ($self, $id) = @_;
    return (
        $self->call_dbmethod(
            funcname => 'parts__get_by_id',
            args     => { id => $id }
        )
        )[0];
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
