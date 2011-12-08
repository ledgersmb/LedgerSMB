
=pod

=head1 NAME

LedgerSMB::Auth.pm, Standard DB module.

=head1 SYNOPSIS

This is the standard DB-based module for authentication.  Uses HTTP basic 
authentication.

=head1 METHODS

=over

=cut

package LedgerSMB::Auth;
use MIME::Base64;
use LedgerSMB::Sysconfig;
use LedgerSMB::Log;
use strict;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Auth');

=item session_check

Checks to see if a session exists based on current logged in credentials. 

Handles failure by creating a new session, since credentials are now separate.

=cut

sub session_check {
    my ( $cookie, $form ) = @_;
    #(my $package,my $filename,my $line)=caller;

    my $path = ($ENV{SCRIPT_NAME});
    $path =~ s|[^/]*$||;
    my $secure;

   $logger->debug("\$cookie=$cookie");
   if ($cookie eq 'Login'){
        return session_create($form);
    }
    #TODO what if cookie '' ?
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
    my $sessionValid = $checkQuery->rows;
    $logger->debug("\$sessionID=$sessionID \$token=$token \$sessionValid=$sessionValid");
    $dbh->commit;

    if ($sessionValid) {

        #user has a valid session cookie, now check the user
        my ( $session_ref) =  $checkQuery->fetchrow_hashref('NAME_lc');

        my $login = $form->{login};

        $login =~ s/[^a-zA-Z0-9._+\@'-]//g;
        if (( $session_ref ))
        {
            my $newCookieValue =
              $session_ref->{session_id} . ':' . $session_ref->{token} . ':' . $form->{company};
            $logger->debug("\$newCookieValue=$newCookieValue");

            #now update the cookie in the browser
            if ($ENV{SERVER_PORT} == 443){
                 $secure = ' Secure;';
            }
            print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=$newCookieValue; path=$path;$secure\n|;
            return 1;

        }
        else {
            $logger->debug("no \$session_ref");
            my $sessionDestroy = $dbh->prepare("");#TODO meaning of this statement?

            #delete the cookie in the browser
            if ($ENV{SERVER_PORT} == 443){
                 $secure = ' Secure;';
            }
            print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=; path=$path;$secure\n|;
            return 0;
        }

    }
    else {
            $logger->debug("delete invalid cookie in the browser");
            if ($ENV{SERVER_PORT} == 443){
                 $secure = ' Secure;';
            }
        print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=; path=$path;$secure\n|;
        return 0;
    }
}

=item session_create

Creates a new session, sets $lsmb->{session_id} to that session, sets cookies, 
etc.

=cut

sub session_create {
    my ($lsmb) = @_;
    my $path = ($ENV{SCRIPT_NAME});
    my $secure;
    $path =~ s|[^/]*$||;
    my $dbh = $lsmb->{dbh};
    my $login = $lsmb->{login};


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
        http_error('401');
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
    my $rc=$deleteExisting->execute( $login)
      || $lsmb->dberror(
        __FILE__ . ':' . __LINE__ . ': Delete from session: ' . $DBI::errstr);
    $logger->debug("delete from session \$login=$login \$rc=$rc");

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
    $rc=$createNew->execute( $newSessionID, $newToken )
      || http_error('401');
    $logger->debug("createnew \$rc=$rc");
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
    print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=$newCookieValue; path=$path;$secure\n|;
    $lsmb->{LedgerSMB} = $newCookieValue;
    $lsmb->{dbh}->commit;
}

=item session_destry

Destroys a session and removes it from the db.

=cut

sub session_destroy {

    my ($form) = @_;
    my $path = ($ENV{SCRIPT_NAME});
    my $secure;
    $path =~ s|[^/]*$||;

    my $login = $form->{login};
    $login =~ s/[^a-zA-Z0-9._+\@'-]//g;

    # use the central database handle
    my $dbh = $form->{dbh};

    my $deleteExisting = $dbh->prepare( "
        DELETE FROM session 
               WHERE users_id = (select id from users where username = ?)
    " );

    my $rc=$deleteExisting->execute($login)
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Delete from session: ' );
    $logger->debug("delete from session \$login=$login \$rc=$rc");
    $dbh->commit;

    #delete the cookie in the browser
    if ($ENV{SERVER_PORT} == 443){
         $secure = ' Secure;';
    }
    print qq|Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=; path=$path;$secure\n|;

}

=item get_credentials

Gets credentials from the 'HTTP_AUTHORIZATION' environment variable which must
be passed in as per the standards of HTTP basic authentication.

Returns a hashref with the keys of login and password.

=cut

sub get_credentials {
    # Handling of HTTP Basic Auth headers
    my $auth = $ENV{'HTTP_AUTHORIZATION'};
	# Send HTTP 401 if the authorization header is missing
    credential_prompt() unless ($auth);
    $auth =~ s/Basic //i; # strip out basic authentication preface
    $auth = MIME::Base64::decode($auth);
    my $return_value = {};
    #$logger->debug("\$auth=$auth");#be aware of passwords in log!
    ($return_value->{login}, $return_value->{password}) = split(/:/, $auth);
    if (defined $LedgerSMB::Sysconfig::force_username_case){
        if (lc($LedgerSMB::Sysconfig::force_username_case) eq 'lower'){
            $return_value->{login} = lc($return_value->{login});
        } elsif (lc($LedgerSMB::Sysconfig::force_username_case) eq 'upper'){
            $return_value->{login} = uc($return_value->{login});
        }
    }

    return $return_value;
    
}

=item credential_prompt

Sends a 401 error to the browser popping up browser credential prompt.

=cut

sub credential_prompt{
    http_error(401);
}

sub password_check { # Old routine, leaving in at the moment
                     # As a reference regarding checking passwords
                     # for a password migration app. --CT

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

=cut

1;
