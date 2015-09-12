=pod

=head1 NAME

LedgerSMB::Auth.pm - Provides an abstraction layer for session management and
authentication.

=head1 SYNOPSIS

This routine provides an abstraction layer for session management and
authentication.  The current application only ships with a simple authentication
layer using database-native accounts.  Other authentication methods are quite
possible though currently every LedgerSMB user must be a database user.

=head1 METHODS

Each plugin library must provide the following methods.

=over

=item get_credentials

Get credentials and return them to the application.

Must return a hashref with the following entries:

login
password

=item credential_prompt

Prompt user for credentials

=back

=head1 METHODS PROVIDED IN COMMON

=over

=item http_error

Send an http error to the browser.

=back

=cut

package LedgerSMB::Auth;

use LedgerSMB::Sysconfig;
use CGI::Simple;
use strict;
use warnings;

if ( !${LedgerSMB::Sysconfig::auth} ) {
    ${LedgerSMB::Sysconfig::auth} = 'DB';
}

my $auth_lib = "LedgerSMB/Auth/" . ${LedgerSMB::Sysconfig::auth} . ".pm";
require $auth_lib || die $!;

sub http_error {
    #my ($errcode, $msg_plus) = @_;
    my ($unknown,$errcode, $msg_plus) = @_;#tshvr4 called as LedgerSMB::Auth->http_error('401');
    $msg_plus = '' if not defined $msg_plus;
    my $cgi = CGI::Simple->new();

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
    # Ordinarily I would use $cgi->header to generate the headers
    # but this doesn't seem to be working.  Although it is generally desirable
    # to create the headers using the package, I think we should print them
    # manually.  -CT
    if ($errcode eq '401'){
        if ($msg_plus eq 'setup'){
           $err->{'401'}->{others}->{'WWW-Authenticate'}
                = "Basic realm=\"LedgerSMB-$msg_plus\"";
        }
        print $cgi->header(
           -type               => 'text/text',
           -status             => $err->{'401'}->{status},
           "-WWW-Authenticate" => $err->{'401'}->{others}->{'WWW-Authenticate'}
        );
    } else {
        print $cgi->header(
           -type   => 'text/text',
           -status => $err->{$errcode}->{status},
        );
    }
    print $err->{$errcode}->{message};
    die;
}

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
