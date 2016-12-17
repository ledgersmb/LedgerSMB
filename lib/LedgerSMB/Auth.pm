=pod

=head1 NAME

LedgerSMB::Auth.pm - Provides an abstraction layer for session management and
authentication.

=head1 SYNOPSIS

This routine provides an abstraction layer for session management and
authentication.  The current application only ships with a simple authentication
layer using database-native accounts.  Other authentication methods are quite
possible though currently every LedgerSMB user must be a database user.

=head1 METHODS

Each plugin library must provide the following methods.

=over

=item get_credentials

Get credentials and return them to the application.

Must return a hashref with the following entries:

login
password

=back

=cut

package LedgerSMB::Auth;

use LedgerSMB::Sysconfig;
use strict;
use warnings;

if ( !$LedgerSMB::Sysconfig::auth ) {
    $LedgerSMB::Sysconfig::auth = 'DB';
}

my $auth_lib = "LedgerSMB/Auth/" . $LedgerSMB::Sysconfig::auth . ".pm";
require $auth_lib || die $!;

=head1 COPYRIGHT

# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006-2011
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.

=cut

1;
