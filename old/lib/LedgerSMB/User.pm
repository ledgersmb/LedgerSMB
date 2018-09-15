
package LedgerSMB::User;

=head1 NAME

LedgerSMB::User - Provides user support and database management functions.

=head1 DESCRIPTION

This module provides user support and database management functions.

=head1 STATUS

Deprecated

=head1 LICENSE AND COPYRIGHT

 Copyright (C) 2006-2017 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=head1 METHODS

=over

=cut

# inline documentation

use strict;
use warnings;

use LedgerSMB::Sysconfig;
use Log::Log4perl;
use Carp;

my $logger = Log::Log4perl->get_logger('LedgerSMB::User');


=item LedgerSMB::User->fetch_config($login);

Returns a reference to a hash that contains the user config for the user $login.
If that user does not exist, output 'Access denied' if in CGI and die in all
cases.

=cut

sub fetch_config {
    #I'm hoping that this function will go and is a temporary bridge
    #until we get rid of %myconfig elsewhere in the code

    my ( $self, $lsmb ) = @_;

    croak q{Can't fetch 'current user' }
          . q{information on unauthenticated connection}
        unless $lsmb->{_auth} && $lsmb->{_auth}->get_credentials->{login};

    my $login = $lsmb->{_auth}->get_credentials->{login};
    my $dbh = $lsmb->{dbh};
    my $query = q{
        SELECT * FROM user_preference
         WHERE id = (SELECT id FROM users WHERE username = ?)};
    my $sth = $dbh->prepare($query);
    $sth->execute($login);
    my $myconfig = $sth->fetchrow_hashref('NAME_lc');
    bless $myconfig, __PACKAGE__;
    return $myconfig;
}

1;

=back

