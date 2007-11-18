#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.
#
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
# This package contains session related functions:
#
# check - checks validity of session based on the user's cookie and login
#
# create - creates a new session, writes cookie upon success
#
# destroy - destroys session
#
# password_check - compares the password with the stored cryted password
#                  (ver. < 1.2) and the md5 one (ver. >= 1.2)
#====================================================================
package LedgerSMB::Auth;
use MIME::Base64;
use strict;

sub session_check {
    use Time::HiRes qw(gettimeofday);
    my ( $cookie, $form ) = @_;
    print STFERR "Checking Session\n";

    my $path = ($ENV{SCRIPT_NAME});
    $path =~ s|[^/]*$||;

   if ($cookie eq 'Login'){
        print STDERR "creating session\n";
        return session_create($form);
    }
    my $timeout;

    
    my $dbh = $form->{dbh};

    my $checkQuery = $dbh->prepare(
        "SELECT u.username, s.transaction_id 
           FROM session as s
	   JOIN users as u ON (s.users_id = u.id)
          WHERE s.session_id = ?
            AND token = ?
            AND s.last_used > now() - ?::interval"
    );

    my $updateAge = $dbh->prepare(
        "UPDATE session 
           SET last_used = now()
         WHERE session_id = ?;"
    );

    my ($sessionID, $token, $company) = split(/:/, $cookie);

    $form->{company} ||= $company;

    #must be an integer
    $sessionID =~ s/[^0-9]//g;
    $sessionID = int $sessionID;


    if ( !$form->{timeout} ) {
        $timeout = "1 day";
    }
    else {
        $timeout = "$form->{timeout} seconds";
    }

    $checkQuery->execute( $sessionID, $token, $timeout )
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Looking for session: ' );
    my $sessionValid = $checkQuery->rows;

    if ($sessionValid) {

        #user has a valid session cookie, now check the user
        my ( $sessionLogin, $sessionTransaction ) = $checkQuery->fetchrow_array;

        my $login = $form->{login};

        $login =~ s/[^a-zA-Z0-9._+\@'-]//g;
        if (( $sessionLogin eq $login ))
        {



            $updateAge->execute( $sessionID )
              || $form->dberror(
                __FILE__ . ':' . __LINE__ . ': Updating session age: ' );

            my $newCookieValue =
              $sessionID . ':' . $token . ':' . $form->{company};

            #now update the cookie in the browser
            print qq|Set-Cookie: LedgerSMB=$newCookieValue; path=$path;\n|;
            return 1;

        }
        else {

#something's wrong, they have the cookie, but wrong user or the wrong transaction id. Hijack attempt?
#destroy the session
            my $sessionDestroy = $dbh->prepare("");

            #delete the cookie in the browser
            print qq|Set-Cookie: LedgerSMB=; path=$path;\n|;
            return 0;
        }

    }
    else {

        #cookie is not valid
        #delete the cookie in the browser
        print qq|Set-Cookie: LedgerSMB=; path=$path;\n|;
        return 0;
    }
}

sub session_create {
    my ($lsmb) = @_;
    print STDERR "Creating Session\n";
    my $path = ($ENV{SCRIPT_NAME});
    $path =~ s|[^/]*$||;
    use Time::HiRes qw(gettimeofday);
    my $dbh = $lsmb->{dbh};
    my $login = $lsmb->{login};

    #microseconds are more than random enough for transaction_id
    my ( $ignore, $newTransactionID ) = gettimeofday();
    $newTransactionID = int $newTransactionID;


    if ( !$ENV{GATEWAY_INTERFACE} ) {

        #don't create cookies or sessions for CLI use
        return 1;
    }

    # TODO Change this to use %myconfig
    my $deleteExisting = $dbh->prepare(
        "DELETE 
           FROM session
          WHERE session.users_id = (select id from users where username = ?)"
    );
    my $seedRandom = $dbh->prepare("SELECT setseed(?);");

    my $fetchSequence =
      $dbh->prepare("SELECT nextval('session_session_id_seq'), md5(random());");

    my $createNew = $dbh->prepare(
        "INSERT INTO session (session_id, users_id, token, transaction_id) 
                                        VALUES(?, (SELECT id
                                                     FROM users
                                                    WHERE username = ?), ?, ?);"
    );

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
    $createNew->execute( $newSessionID, $login, $newToken, $newTransactionID )
      || $lsmb->dberror( __FILE__ . ':' . __LINE__ . ': Create new session: ' );

    #reseed the random number generator
    my $randomSeed = 1.0 * ( '0.' . ( time() ^ ( $$ + ( $$ << 15 ) ) ) );

    $seedRandom->execute($randomSeed)
      || $lsmb->dberror(
        __FILE__ . ':' . __LINE__ . ': Reseed random generator: ' );


    my $newCookieValue = $newSessionID . ':' . $newToken . ':' 
	. $lsmb->{company};
    print STDERR "Breakpoint\n";
    #now set the cookie in the browser
    #TODO set domain from ENV, also set path to install path
    print qq|Set-Cookie: LedgerSMB=$newCookieValue; path=$path;\n|;
    $lsmb->{LedgerSMB} = $newCookieValue;
    $lsmb->{dbh}->commit;
}

sub session_destroy {

    my ($form) = @_;

    my $login = $form->{login};
    $login =~ s/[^a-zA-Z0-9._+\@'-]//g;

    # use the central database handle
    my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

    my $deleteExisting = $dbh->prepare( "
        DELETE FROM session 
               WHERE users_id = (select id from users where username = ?)
    " );

    $deleteExisting->execute($login)
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Delete from session: ' );

    #delete the cookie in the browser
    print qq|Set-Cookie: LedgerSMB=; path=/;\n|;

}

sub get_credentials {
    # Handling of HTTP Basic Auth headers
    my $auth = $ENV{'HTTP_AUTHORIZATION'};
    $auth =~ s/Basic //i; # strip out basic authentication preface
    $auth = MIME::Base64::decode($auth);
    my $return_value = {};
    ($return_value->{login}, $return_value->{password}) = split(/:/, $auth);

    return $return_value;
    
}

sub credential_prompt{
    print "WWW-Authenticate: Basic realm=\"LedgerSMB\"\n";
    print "Status: 401 Unauthorized\n\n";
    print "Please enter your credentials.\n";
    exit; 
}

sub password_check {

    use Digest::MD5;

    my ( $form, $username, $password ) = @_;

    $username =~ s/[^a-zA-Z0-9._+\@'-]//g;

    # use the central database handle
    my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

    my $fetchPassword = $dbh->prepare(
        "SELECT u.username, uc.password, uc.crypted_password
           FROM users as u, users_conf as uc
          WHERE u.username = ?
            AND u.id = uc.id;"
    );

    $fetchPassword->execute($username)
      || $form->dberror( __FILE__ . ':' . __LINE__ . ': Fetching password : ' );

    my ( $dbusername, $md5Password, $cryptPassword ) =
      $fetchPassword->fetchrow_array;

    if ( $dbusername ne $username ) {
        # User data retrieved from db not for the requested user
        return 0;
    }
    elsif ($cryptPassword) {

        #First time login from old system, check crypted password

        if ( ( crypt $password, substr( $username, 0, 2 ) ) eq $cryptPassword )
        {

            #password was good, convert to md5 password and null crypted
            my $updatePassword = $dbh->prepare(
                "UPDATE users_conf
                    SET password = md5(?),
                        crypted_password = null
                   FROM users
                  WHERE users_conf.id = users.id
                    AND users.username = ?;"
            );

            $updatePassword->execute( $password, $username )
              || $form->dberror(
                __FILE__ . ':' . __LINE__ . ': Converting password : ' );

            return 1;

        }
        else {
            return 0;    #password failed
        }

    }
    elsif ($md5Password) {

        if ( $md5Password ne ( Digest::MD5::md5_hex $password) ) {
            return 0;
        }
        else {
            return 1;
        }

    }
    else {

        #both the md5Password and cryptPasswords were blank
        return 0;
    }
}

1;
