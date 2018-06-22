
package LedgerSMB::Auth;

=head1 NAME

LedgerSMB::Auth - Provides an abstraction layer for authentication.

=head1 DESCRIPTION

This routine provides an abstraction layer for authentication.  The current
application only ships with a simple authentication layer using
database-native accounts.  Other authentication methods are quite
possible though currently every LedgerSMB user must be a database user.

=head1 METHODS


=head2 factory($env)

This method instantiates an authentication class as of type
LedgerSMB::Auth::C<$LedgerSMB::Sysconfig::auth>.
More about plugin classes is described below.

=head2 plugin classes

Each plugin module must provide a class with the following methods

=over

=item new(env => $env)

$env is a hash describing the web request environment such as defined
by RFC 3875 (CGI version 1.1) and adopted by the PSGI standard.

=item get_credentials($domain)

Get credentials and return them to the application, optionally taking
$domain into account ($domain can be any of 'setup' or 'main').

Must return a hashref with the following entries:

login
password

Returning a hashref without these entries means that no valid
login data is available.

=back

=cut

use strict;
use warnings;

use LedgerSMB::Sysconfig;
use Module::Runtime qw(use_module);


my $plugin = 'LedgerSMB::Auth::' . LedgerSMB::Sysconfig::auth;
use_module($plugin) or die "Can't locate Auth parser plugin $plugin";

sub factory {
    my ($psgi_env) = @_;

    return use_module($plugin)->new(env => $psgi_env);
}


=head1 LICENSE AND COPYRIGHT

# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006-2017
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.

=cut

1;
