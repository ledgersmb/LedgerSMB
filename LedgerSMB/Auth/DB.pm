
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
use Log::Log4perl;
use strict;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Auth');

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
