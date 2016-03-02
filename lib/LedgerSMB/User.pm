
=head1 NAME

LedgerSMB::User - Provides user support and database management functions.

=head1 SYNOPSIS

This module provides user support and database management functions.

=head1 STATUS

Deprecated

=head1 COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
 # This work contains copyrighted information from a number of sources
 # all used with permission.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders,
 # see the CONTRIBUTORS file.
 #
 # Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
 # Copyright (C) 2000
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 #  Contributors: Jim Rawlings <jim@your-dba.com>
 #
 #====================================================================
 #
 # This file has undergone whitespace cleanup.
 #
 #====================================================================
 #
 # user related functions
 #
 #====================================================================

=head1 METHODS

=over

=cut

# inline documentation

package LedgerSMB::User;

use strict;
use warnings;

use LedgerSMB::Sysconfig;
use LedgerSMB::Auth;
use Log::Log4perl;

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

    my $login;
    my $creds = LedgerSMB::Auth::get_credentials;
    $login = $creds->{login};

    my $dbh = $lsmb->{dbh};

    if ( !$login ) { # Assume this is for current connected user
        my $sth = $dbh->prepare('SELECT SESSION_USER');
        $sth->execute();
        ($login) = $sth->fetchrow_array();
    }

    my $query = qq|
        SELECT * FROM user_preference
         WHERE id = (SELECT id FROM users WHERE username = ?)|;
    my $sth = $dbh->prepare($query);
    $sth->execute($login);
    my $myconfig = $sth->fetchrow_hashref('NAME_lc');
    $myconfig->{templates} = "DB";
    bless $myconfig, __PACKAGE__;
    return $myconfig;
}

1;

=back

