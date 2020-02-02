=head1 NAME

LedgerSMB::PGOld - Old DBObject replacement for 1.3-era LedgerSMB code

=head1 SYNPOSIS

This is like DBObject but uses the PGObject::Simple for base functionality.

=cut

# This is temporary until we can get rid of it.  Basically the following
# namespaces need to be moved to Moose:
#
# LedgerSMB::Setting
# LedgerSMB::DBObject
# Then we can delete this module.

package LedgerSMB::PGOld;

use strict;
use warnings;

use base 'PGObject::Simple';
use LedgerSMB::Sysconfig;

=head1 METHODS

See PGObject::Simple

=over

=item new(%args)

Constructor.

Recognized arguments are:

=over

=item base

A hashref which is imported as properties of the new object.

=back

=cut

sub new {
    my $self = PGObject::Simple::new(@_);
    return $self;
}

=back

=cut

1;
