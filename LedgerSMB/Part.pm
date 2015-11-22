=head1 NAME

LedgerSMB::Part - Good/Service class for LedgerSMB

=head1 SYNOPSIS

This is currently a shell class pending rewrite of old code.

=cut

package LedgerSMB::Part;
use strict;
use warnings;

use Moose;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

TODO (None yet)

=head1 METHODS

=head2 basic_partlist($query)

Returns an array of hashrefs of matching parts.  All fields in the parts
table are returned.

=cut

sub basic_partslist {
    my ($self, $query) = @_;
    $query = '' unless defined $query; # no nulls
    my @parts = __PACKAGE__->call_dbmethod(
           funcname => 'parts__search_lite',
           args     => { partnumber => $query, description => $query }
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
       __PACKAGE__->call_dbmethod(
           funcname => 'parts__get_by_partnumber',
           args     => { partnumber => $partnumber }
       )
    )[0];
}

=head1 COPYRIGHT

Copyright (C) 2015 The LedgerSMB Core Team

This file may be reused under the terms of the GNU General Public License version 2 or at your option any later version.

=cut

__PACKAGE__->meta->make_immutable;
1;
