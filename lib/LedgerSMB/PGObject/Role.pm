
package LedgerSMB::PGObject::Role;

=head1 NAME

LedgerSMB::PGObject::Role - PGObject::Simple::Role wrapper for LedgerSMB

=head1 SYNPOSIS

use LedgerSMB::PGObject

sub foo {
    return call_dbmethod(funcname => 'foo', args => {id => 1});
}

=head1 DESCRIPTION

This replaces the older LedgerSMB::DBObject, as it has more features and
better consistency

=head1 METHODS

This module doesn't specify any (public) methods.

=cut

use Moose::Role;
use namespace::autoclean;
with 'PGObject::Simple::Role' => { -excludes => [qw( _get_schema )], };

use LedgerSMB::App_State;


sub _get_schema {
    my $self = shift;
    return $self->dbh->{private_LedgerSMB}->{schema};
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
