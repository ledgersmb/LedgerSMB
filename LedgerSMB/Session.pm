#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
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
#====================================================================
package Session;

sub session_check {

	my ($cookie, $form, %myconfig) = @_;
	my ($sessionid, $token) = split /:/, $cookie;

	# connect to database
	my $dbh = DBI->connect($myconfig{dbconnect}, $myconfig{dbuser}, $myconfig{dbpasswd});

	my $checkQuery = $dbh->prepare("SELECT sl_login FROM session WHERE session_id = ? AND token = ? AND last_used > now() - ?::interval");

	my $updateAge = $dbh->prepare("UPDATE session SET last_used = now() WHERE session_id = ?;");

	#must be an integer
	$sessionid =~ s/[^0-9]//g;
	$sessionid = int $sessionid;

	#must be 32 chars long and contain hex chars
	$token =~ s/[^0-9a-f]//g;
	$token = substr($token, 0, 32);

	if (!$myconfig{timeout}){
		$timeout = "1 day";
	} else {
		$timeout = "$myconfig{timeout} seconds";
	}

	$checkQuery->execute($sessionid, $token, $timeout) || $form->dberror('Looking for session: ');
	my $sessionValid = $checkQuery->rows;

	if($sessionValid){

		#user has a valid session cookie, now check the user
		my ($sessionLogin) = $checkQuery->fetchrow_array;

		my $login = $form->{login};
		$login =~ s/[^a-zA-Z0-9@.-]//g;

		if($sessionLogin eq $login){
			$updateAge->execute($sessionid) || $form->dberror('Updating session age: ');
			return 1;

		} else {
			#something's wrong, they have the cookie, but wrong user. Hijack attempt?
			#delete the cookie in the browser
			print qq|Set-Cookie: LedgerSMB=; path=/;\n|;
			return 0;
		}
	
	} else {
		#cookie is not valid
		#delete the cookie in the browser
		print qq|Set-Cookie: LedgerSMB=; path=/;\n|;
		print qq|Set-Cookie: DiedHere=true; path=/;\n|;
		return 0;
	}
}

sub session_create {
	my ($form, %myconfig) = @_;

	# connect to database
	my $dbh = DBI->connect($myconfig{dbconnect}, $myconfig{dbuser}, $myconfig{dbpasswd});

	# TODO Change this to use %myconfig
	my $deleteExisting = $dbh->prepare("DELETE FROM session WHERE sl_login = ? AND age(last_used) > ?::interval");  

	my $seedRandom = $dbh->prepare("SELECT setseed(?);");

	my $fetchSequence = $dbh->prepare("SELECT nextval('session_session_id_seq'), md5(random());");
	
	my $createNew = $dbh->prepare("INSERT INTO session (session_id, sl_login, token) VALUES(?, ?, ?);");


	# this is assuming that $form->{login} is safe, which might be a bad assumption
	# so, I'm going to remove some chars, which might make previously valid logins invalid
	my $login = $form->{login};
	$login =~ s/[^a-zA-Z0-9@.-]//g;

	#delete any existing stale sessions with this login if they exist
	if (!$myconfig{timeout}){
	   $myconfig{timeout} = 86400;
	}

	$deleteExisting->execute($login, "$myconfig{timeout} seconds") || $form->dberror('Delete from session: ');

	#doing the md5 and random stuff in the db so that LedgerSMB won't
	#require new perl modules (Digest::MD5 and a good random generator)
	$fetchSequence->execute() || $form->dberror('Fetch sequence id: ');
	my ($newSessionID, $newToken) = $fetchSequence->fetchrow_array;

	#create a new session
	$createNew->execute($newSessionID, $login, $newToken) || $form->dberror('Create new session: ');

	#reseed the random number generator
	my $randomSeed = 1.0 * ('0.'. (time() ^ ($$ + ($$ <<15))));
	$seedRandom->execute($randomSeed)|| $form->dberror('Reseed random generator: ');;

	$newCookieValue = $newSessionID . ':' . $newToken;

	#now set the cookie in the browser
	#TODO set domain from ENV, also set path to install path
	print qq|Set-Cookie: LedgerSMB=$newCookieValue; path=/;\n|;
	$form->{LedgerSMB} = $newCookieValue;
}

sub session_destroy {

	# Under the current architecture, this function is a bit problematic
	# %myconfig is often not defined when this function needs to be called.
	# which means that the db connection parameters are not available.
	# moving user prefs and the session table into a central db will solve this issue

	my ($form, %myconfig) = @_;

	my $login = $form->{login};
	$login =~ s/[^a-zA-Z0-9@.-]//g;

	# connect to database
	my $dbh = DBI->connect($myconfig{dbconnect}, $myconfig{dbuser}, $myconfig{dbpasswd});

	my $deleteExisting = $dbh->prepare("DELETE FROM session WHERE sl_login = ?;");
	$deleteExisting->execute($login) || $form->dberror('Delete from session: ');

	#delete the cookie in the browser
	print qq|Set-Cookie: LedgerSMB=; path=/;\n|;

}

1;
