
=head1 NAME

LedgerSMB::DBObject::Customer - LedgerSMB Class for Customers

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving customers.

=head1 INHERITS

LedgerSMB::DBObject::Company

=head1 METHODS

=over

=item set_entity_class

Sets entity_class to 2.

=cut


package LedgerSMB::DBObject::Customer;

use base qw(LedgerSMB::DBObject::Company);
use strict;

our $ENTITY_CLASS = 2;

sub set_entity_class {
    
    my $self = shift @_;
    $self->{entity_class} = $ENTITY_CLASS;

}
    
=back

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

1;
