=head1 NAME

LedgerSMB::Session

=head1 SYNOPSIS

Routines for tracking general session actions (create, check, and destroy
sessions).

=head1 METHODS

=over

=cut

package LedgerSMB::Session;

use LedgerSMB::Sysconfig;
use Log::Log4perl;
use LedgerSMB::Auth;
use CGI::Simple;
use strict;
use warnings;


my $logger = Log::Log4perl->get_logger('LedgerSMB');

=item check

Checks to see if a session exists based on current logged in credentials.

Handles failure by creating a new session, since credentials are now separate.

=cut

sub check {
    my ( $cookie, $form ) = @_;

    my $path = ($ENV{SCRIPT_NAME});
    $path =~ s|[^/]*$||;
    my $secure;
   if (($cookie eq 'Login') or ($cookie =~ /^::/) or (!$cookie)){
        return create($form);
    }
    my $timeout;


    my $dbh = $form->{dbh};

    my $checkQuery = $dbh->prepare(
        "SELECT * FROM session_check(?, ?)");

    my ($sessionID, $token, $company) = split(/:/, $cookie);

    $form->{company} ||= $company;
    $form->{session_id} = $sessionID;

    #must be an integer
    $sessionID =~ s/[^0-9]//g;
    $sessionID = int $sessionID;


    if ( !$form->{timeout} ) {
        $timeout = "1 day";
    }
    else {
        $timeout = "$form->{timeout} seconds";
    }

    $checkQuery->execute( $sessionID, $token)
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Looking for session: ' );
    my $sessionValid = $checkQuery->fetchrow_hashref('NAME_lc');
    my ($session_ref) = $sessionValid;
    $sessionValid = $sessionValid->{session_id};

    if ($sessionValid) {



        my $login = $form->{login};

        $login =~ s/[^a-zA-Z0-9._+\@'-]//g;
        if (( $session_ref ))
        {




            my $newCookieValue =
              $session_ref->{session_id} . ':' . $session_ref->{token} . ':' . $form->{company};

            #now update the cookie in the browser
            if ($ENV{SERVER_PORT} == 443){
                 $secure = ' Secure;';
            }
            else {
                $secure = '';
            }
            print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=$newCookieValue; path=$path;$secure\n|;
            return 1;

        }
        else {

            return 0;
        }

    }
    else {

        #cookie is not valid
        #delete the cookie in the browser
            if ($ENV{SERVER_PORT} == 443){
                 $secure = ' Secure;';
            }
            destroy($form);
            LedgerSMB::Auth::credential_prompt;
    }
}

=item create

Creates a new session, sets $lsmb->{session_id} to that session, sets cookies,
etc.

=cut

sub create {
    my ($lsmb) = @_;
    my $path = ($ENV{SCRIPT_NAME});
    my $secure;
    $path =~ s|[^/]*$||;
    my $dbh = $lsmb->{dbh};
    my $login = $lsmb->{login};
    if (!$login) {
       my $creds = LedgerSMB::Auth::get_credentials;
       $login = $creds->{login};
    }


    if ( !$ENV{GATEWAY_INTERFACE} ) {

        #don't create cookies or sessions for CLI use
        return 1;
    }

    my $fetchUserID = $dbh->prepare(
        "SELECT id
            FROM users
            WHERE username = ?;"
    );

    # TODO Change this to use %myconfig
    my $deleteExisting = $dbh->prepare(
        "DELETE
           FROM session
          WHERE session.users_id = (select id from users where username = ?)"
    );
    my $seedRandom = $dbh->prepare("SELECT setseed(?);");

    my $fetchSequence =
      $dbh->prepare("SELECT nextval('session_session_id_seq'), md5(random()::text);");

    my $createNew = $dbh->prepare(
        "INSERT INTO session (session_id, users_id, token)
                                        VALUES(?, (SELECT id
                                                     FROM users
                                                    WHERE username = SESSION_USER), ?);"
    );

# Fail early if the user isn't in the users table
    $fetchUserID->execute($login)
      || $lsmb->dberror( __FILE__ . ':' . __LINE__ . ': Fetch login id: ' );
    my ( $userID ) = $fetchUserID->fetchrow_array;
    unless($userID) {
        $logger->error(__FILE__ . ':' . __LINE__ . ": no such user: $login");
        LedgerSMB::Auth->http_error('401');#tshvr4
        return;#tshvr4?
    }

# this is assuming that the login is safe, which might be a bad assumption
# so, I'm going to remove some chars, which might make previously valid
# logins invalid --CM

# I am changing this to use HTTP Basic Auth credentials for now.  -- CT

    my $auth = $ENV{HTTP_AUTHORIZATION};
    $auth =~ s/^Basic //i;

    #delete any existing stale sessions with this login if they exist
    if ( !$lsmb->{timeout} ) {
        $lsmb->{timeout} = 86400;
    }
    $deleteExisting->execute( $login)
      || $lsmb->dberror(
        __FILE__ . ':' . __LINE__ . ': Delete from session: ' . $DBI::errstr);

#doing the random stuff in the db so that LedgerSMB won't
#require a good random generator - maybe this should be reviewed,
#pgsql's isn't great either  -CM
#
#I think we should be OK.  The random number generator is only a small part
#of the credentials in 1.3.x, and for people that need greater security, there
#is always Kerberos....  -- CT
    $fetchSequence->execute()
      || $lsmb->dberror( __FILE__ . ':' . __LINE__ . ': Fetch sequence id: ' );
    my ( $newSessionID, $newToken ) = $fetchSequence->fetchrow_array;

    #create a new session
    $createNew->execute( $newSessionID, $newToken )
      || LedgerSMB::Auth->http_error('401');#tshvr4
    $lsmb->{session_id} = $newSessionID;

    #reseed the random number generator
    my $randomSeed = 1.0 * ( '0.' . ( time() ^ ( $$ + ( $$ << 15 ) ) ) );

    $seedRandom->execute($randomSeed)
      || $lsmb->dberror(
        __FILE__ . ':' . __LINE__ . ': Reseed random generator: ' );


    my $newCookieValue = $newSessionID . ':' . $newToken . ':'
    . $lsmb->{company};

    #now set the cookie in the browser
    #TODO set domain from ENV, also set path to install path
    if ($ENV{SERVER_PORT} == 443){
         $secure = ' Secure;';
    }
    else {
        $secure = '';
    }
    print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=$newCookieValue; path=$path;$secure\n|;
    $lsmb->{LedgerSMB} = $newCookieValue;
}

=item destroy

Destroys a session and removes it from the db.

=cut

sub destroy {

    my ($form) = @_;
    my $path = ($ENV{SCRIPT_NAME});
    my $secure = '';
    $path =~ s|[^/]*$||;

    my $login = $form->{login};
    $login =~ s/[^a-zA-Z0-9._+\@'-]//g;

    # use the central database handle
    my $dbh = $form->{dbh};

    my $deleteExisting = $dbh->prepare( "
        DELETE FROM session
               WHERE users_id = (select id from users where username = ?)
    " );

    $deleteExisting->execute($login)
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Delete from session: ' );

    #delete the cookie in the browser
    if ($ENV{SERVER_PORT} == 443){
         $secure = ' Secure;';
    }
    print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=Login; path=$path;$secure\n|;
    $dbh->commit; # called before anything else on the page, make sure the
                  # session is really gone.  -CT
}

1;


=back

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

