
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

use Carp;
use Log::Any;

use LedgerSMB::StopProcessing;

my $logger = Log::Any->get_logger(category => 'LedgerSMB::User');


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


=item get_all_users()

Retrieves a list of users for the company (database).
Sets $self->{users} and returns an arrayref.

=cut

sub get_all_users {
    my ($self, $lsmb) = @_;

    return $lsmb->{dbh}->selectall_array('select * from user__get_all_users()',
                                         { Slice => {} });
}

=item change_my_password($request)

Uses the request keys:

 * login
 * old_password
 * new_password
 * company
 * _locale
 * _wire

to establish a database connection and change the user's password.

=cut

sub change_my_password {
    my ($pkg, $request) = @_;

    # Before doing any work at all, reject the request when the passwords
    # don't match...
    if ($request->{new_password} ne $request->{confirm_password}){
        Carp::croak $request->{_locale}->text('Passwords must match.');
        LedgerSMB::StopProcessing->throw;
    }

    my $verify = $request->{_wire}->get('db')->instance(
        dbname   => $request->{company},
        user     => $request->{login},
        password => $request->{old_password}
        )->connect();
    if (!$verify){
        Carp::croak $request->{_locale}->text('Incorrect Password');
    }
    $verify->disconnect;

    return $request->call_procedure(
        funcname => 'user__change_password',
        args     => [ $request->{new_password} ]);
}

=item save_preferences($request)

Saves preferences to the database and reloads the values in the object
from the db for consistency.

=cut

sub save_preferences {
    my ($pkg, $request) = @_;
    my $dbh = $request->{dbh};
    my $sth = $dbh->prepare('select * from preference__set(?, ?)')
        or die $dbh->errstr;

    for my $setting (
        qw( dateformat numberformat language stylesheet printer )) {
        $sth->execute( $setting, $request->{$setting} )
            or die $sth->errstr;
    }
}


1;

=back

