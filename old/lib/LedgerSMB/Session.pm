=head1 NAME

LedgerSMB::Session - Web app user session management

=head1 SYNOPSIS

Routines for tracking general session actions (create, check, and destroy
sessions).

=head1 METHODS

=over

=cut

package LedgerSMB::Session;

use LedgerSMB::Sysconfig;
use Log::Log4perl;
use strict;
use warnings;
use Carp;

use HTTP::Status qw(HTTP_UNAUTHORIZED);

my $logger = Log::Log4perl->get_logger('LedgerSMB');

sub _http_error {
    my ($errcode, $msg_plus) = @_;
    $msg_plus = '' if not defined $msg_plus;

    my $err = {
        '500' => {status  => '500 Internal Server Error',
          message => 'An error occurred. Information on this error has been logged.',
                  others  => {}},
        '403' => {status  => '403 Forbidden',
                  message => 'You are not allowed to access the specified resource.',
                  others  => {}},
        '401' => {status  => '401 Unauthorized',
                  message => 'Please enter your credentials',
                  others  => {'WWW-Authenticate' => "Basic realm=\"LedgerSMB\""}
                 },
        '404' => {status  => '404 Resource not Found',
                  message => "The following resource was not found, $msg_plus",
                 },
        '454' => {status  => '454 Database Does Not Exist',
                  message => 'Database Does Not Exist' },
    };

    print qq|Status: $err->{$errcode}->{status}
Content-Type: text/plain
|;
    my $others = $err->{$errcode}->{others};
    for my $key (keys %{$others}) {
        print qq|$key: $others->{$key}\n|;
    }
    print $err->{$errcode}->{message};
    die;
}


=item credential_prompt

Sends a 401 error to the browser popping up browser credential prompt.

=cut

sub credential_prompt{
    my ($suffix) = @_;
    _http_error(HTTP_UNAUTHORIZED, $suffix);
}



=item check

Checks to see if a session exists based on current logged in credentials.

Handles failure by creating a new session, since credentials are now separate.

Returns true (1) on success, false (0) on failure.

=cut

sub check {
    my ( $cookie, $form ) = @_;

   if (($cookie eq 'Login') or ($cookie =~ /^::/) or (!$cookie)){
       return 0;
    }
    my $dbh = $form->{dbh};

    my $checkQuery = $dbh->prepare(
        "SELECT * FROM session_check(?, ?)");

    my ($sessionID, $token, $company) = split(/:/, $cookie);

    $form->{company} ||= $company;
    $form->{session_id} = $sessionID;

    #must be an integer
    $sessionID =~ s/[^0-9]//g;
    $sessionID = int $sessionID;


    $checkQuery->execute( $sessionID, $token)
      || $form->dberror(
        __FILE__ . ':' . __LINE__ . ': Looking for session: ' );
    my $session_ref = $checkQuery->fetchrow_hashref('NAME_lc');

    if ($session_ref && $session_ref->{session_id}) {
        my $newCookieValue =
            $session_ref->{session_id} . ':' . $session_ref->{token} . ':' . $form->{company};

        $form->{_new_session_cookie_value} =
                qq|${LedgerSMB::Sysconfig::cookie_name}=$newCookieValue|;
        return 1;
    }
    else {
        #cookie is not valid
        destroy($form);
        return 0;
    }
}

1;


=back

=head1 COPYRIGHT

# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006-2017
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.

