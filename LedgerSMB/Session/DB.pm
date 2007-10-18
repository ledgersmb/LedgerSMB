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
package Session;

sub session_check {

    use Time::HiRes qw(gettimeofday);

    my ( $cookie, $form ) = @_;
    my ( $sessionID, $transactionID, $token ) = split /:/, $cookie;

    # use the central database handle
    my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

    my $checkQuery = $dbh->prepare(
        "SELECT u.username, s.transaction_id 
									  FROM session as s, users as u 
									 WHERE s.session_id = ? 
									   AND s.token = ?
									   AND s.users_id = u.id
									   AND s.last_used > now() - ?::interval"
    );

    my $updateAge = $dbh->prepare(
        "UPDATE session 
									  SET last_used = now(),
										  transaction_id = ?
									WHERE session_id = ?;"
    );

    #must be an integer
    $sessionID =~ s/[^0-9]//g;
    $sessionID = int $sessionID;

    $transactionID =~ s/[^0-9]//g;
    $transactionID = int $transactionID;

    #must be 32 chars long and contain hex chars
    $token =~ s/[^0-9a-f]//g;
    $token = substr( $token, 0, 32 );

    if ( !$myconfig{timeout} ) {
        $timeout = "1 day";
    }
    else {
        $timeout = "$myconfig{timeout} seconds";
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

        if (    ( $sessionLogin eq $login )
            and ( $sessionTransaction eq $transactionID ) )
        {

            #microseconds are more than random enough for transaction_id
            my ( $ignore, $newTransactionID ) = gettimeofday();

            $newTransactionID = int $newTransactionID;

            $updateAge->execute( $newTransactionID, $sessionID )
              || $form->dberror(
                __FILE__ . ':' . __LINE__ . ': Updating session age: ' );

            $newCookieValue =
              $sessionID . ':' . $newTransactionID . ':' . $token;

            #now update the cookie in the browser
            print qq|Set-Cookie: LedgerSMB=$newCookieValue; path=/;\n|;
            return 1;

        }
        else {

#something's wrong, they have the cookie, but wrong user or the wrong transaction id. Hijack attempt?
#destroy the session
            my $sessionDestroy = $dbh->prepare("");

            #delete the cookie in the browser
            print qq|Set-Cookie: LedgerSMB=; path=/;\n|;
            return 0;
        }

    }
    else {

        #cookie is not valid
        #delete the cookie in the browser
        print qq|Set-Cookie: LedgerSMB=; path=/;\n|;
        return 0;
    }
}

sub session_create {

    use Time::HiRes qw(gettimeofday);

    #microseconds are more than random enough for transaction_id
    my ( $ignore, $newTransactionID ) = gettimeofday();
    $newTransactionID = int $newTransactionID;

    my ($form) = @_;

    if ( !$ENV{HTTP_HOST} ) {

        #don't create cookies or sessions for CLI use
        return 1;
    }

    # use the central database handle
    my $dbh = ${LedgerSMB::Sysconfig::GLOBALDBH};

    # TODO Change this to use %myconfig
    my $deleteExisting = $dbh->prepare(
        "DELETE 
		   FROM session
		  WHERE session.users_id = (select id from users where username = ?) 
		        AND age(last_used) > ?::interval"
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

# this is assuming that $form->{login} is safe, which might be a bad assumption
# so, I'm going to remove some chars, which might make previously valid logins invalid
    my $login = $form->{login};
    $login =~ s/[^a-zA-Z0-9._+\@'-]//g;

    #delete any existing stale sessions with this login if they exist
    if ( !$myconfig{timeout} ) {
        $myconfig{timeout} = 86400;
    }

    $deleteExisting->execute( $login, "$myconfig{timeout} seconds" )
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Delete from session: ' );

#doing the random stuff in the db so that LedgerSMB won't
#require a good random generator - maybe this should be reviewed, pgsql's isn't great either
    $fetchSequence->execute()
      || $form->dberror( __FILE__ . ':' . __LINE__ . ': Fetch sequence id: ' );
    my ( $newSessionID, $newToken ) = $fetchSequence->fetchrow_array;

    #create a new session
    $createNew->execute( $newSessionID, $login, $newToken, $newTransactionID )
      || $form->dberror( __FILE__ . ':' . __LINE__ . ': Create new session: ' );

    #reseed the random number generator
    my $randomSeed = 1.0 * ( '0.' . ( time() ^ ( $$ + ( $$ << 15 ) ) ) );

    $seedRandom->execute($randomSeed)
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Reseed random generator: ' );

    $newCookieValue = $newSessionID . ':' . $newTransactionID . ':' . $newToken;

    #now set the cookie in the browser
    #TODO set domain from ENV, also set path to install path
    print qq|Set-Cookie: LedgerSMB=$newCookieValue; path=/;\n|;
    $form->{LedgerSMB} = $newCookieValue;
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
