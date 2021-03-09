
package LedgerSMB::User;

=head1 NAME

LedgerSMB::User - Provides user support and database management functions.

=head1 DESCRIPTION

This module provides user support and database management functions.

=head1 STATUS

Deprecated

=head1 LICENSE AND COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006-2017
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

    my $dbh = $lsmb->{dbh};
    my $query = q{
        select 'id' as "name",
               (select id from users where username = session_user)::text as value
        union all
        SELECT "name", "value" FROM user_preference
         WHERE user_id = (SELECT id FROM users WHERE username = SESSION_USER)
        UNION ALL
        SELECT "name", "value" FROM user_preference up
         WHERE user_id IS NULL
               AND NOT EXISTS (select 1 from user_preference
                                where up."name" = user_preference."name"
                                  and user_preference.user_id = (SELECT id FROM users WHERE username = SESSION_USER))
        };
    my $sth = $dbh->prepare($query)
        or die $dbh->errstr;
    $sth->execute
        or die $dbh->errstr;
    my $myconfig = {};
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        $myconfig->{$row->{name}} = $row->{value};
    }
    bless $myconfig, __PACKAGE__;
    return $myconfig;
}

1;

=back

