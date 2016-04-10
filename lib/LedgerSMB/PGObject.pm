=head1 NAME

LedgerSMB::PGObject - PGObject::Simple wrapper for LedgerSMB

=head1 SYNPOSIS

use LedgerSMB::PGObject

sub foo {
    return call_dbmethod(funcname => 'foo', args => {id => 1});
}

=head1 DESCRIPTION

This replaces the older LedgerSMB::DBObject, as it has more features and
better consistency

=head1 COPYRIGHT

Copyright(C) 2014 The LedgerSMB Core Team.

This file may be reused under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.TXT for more information.

=cut

package LedgerSMB::PGObject;
use Moose::Role;
with 'PGObject::Simple::Role' => { -excludes => [qw(_get_dbh _get_schema _get_prefix)], };

use LedgerSMB::App_State;

sub _get_dbh { LedgerSMB::App_State::DBH() }
sub _get_schema { 'public' } # can be overridden
sub _get_prefix { '' } # can be overridden

1;
