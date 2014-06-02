=head1 NAME

LedgerSMB::PGObject - PGObject::Simple wrapper for LedgerSMB

=head1 SYNPOSIS

use LedgerSMB::PGObject

sub foo {
    return call_dbmethod(funcname => 'foo', args => {id => 1});
}

=head1 DESCRIPTION

This replaces the plder LedgerSMB::DBObject, as it has more features and 
better consistency

=head1 COPYRIGHT

Copyright(C) 2014 The LedgerSMB Core Team.

This file may be reused under the terms of the GNU General Public License 
version 2 or at your option any later version.  Please see the included 
LICENSE.TXT for more information.

=cut

package LedgerSMB::PGObject;
use Moose::Role;
with 'PGObject::Simple::Role';

use LedgerSMB::App_State;



1;
