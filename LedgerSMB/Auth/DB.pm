
=pod

=head1 NAME

LedgerSMB::Auth::DB - Standard Authentication DB module.

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
    $auth =~ s/Basic //i; # strip out basic authentication preface
    $auth = MIME::Base64::decode($auth);
    #tshvr4 2014-01-14 Firefox, after logout on normal application (login.pl) and coming to setup.pl, auth seems to be  'logout:logout', TODO remove Dumper statements

    #$auth =~ s/Basic //i; # strip out basic authentication preface
    #$auth = MIME::Base64::decode($auth);
    my $return_value = {};
    #$logger->debug("\$auth=$auth");#be aware of passwords in log!
    ($return_value->{login}, $return_value->{password}) = split(/:/, $auth, 2);
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
    my ($suffix) = @_;
    LedgerSMB::Auth->http_error(401, $suffix);#tshvr4
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
