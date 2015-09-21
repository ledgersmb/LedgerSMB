=head1 NAME

LedgerSMB::DBObject::Part - Base parts functions to support new 1.3 stuff

=head1 SYNOPSIS

 my $psearch  = LedgerSMB::DBObject::Part->new({base => $request});
 my $results = $psearch->search_lite(
           {partnumber => '124',
           description => '200GB USB Drive' };


=cut

package LedgerSMB::DBObject::Part;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;

=head1 DESCRIPTION

This package contains the basic parts search functions for 1.3.  In future
versions this may be heavily expanded.

=head1 PROPERTIES

None yet

=head1 METHODS

=over

=item search_lite($args)

This performs a light-weight search, suitable for parts lookups, not heavy parts
searching.  It takes a single hashref as an argument, which contains any of the
following attributes

=over

=item partnumber

This matches on the beginning of the string of the partnumber only.

=item description

This is a full text search of the description.  So '200GB USB Drive' matches
'USB Hard Drive, 200GB' as well as 'Thumb drive, USB, 200gb'.  This is believed
to currently be the most forgiving yet useful way of doing this part of the
search.

=back

=cut

sub search_lite {
    my ($self, $args) = @_;
    return $self->call_procedure(funcname => 'parts__search_lite',
                                     args => [$args->{partnumber},
                                              $args->{description},]
    );
}

=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the included LICENSE.txt for more information.

=cut

1;
