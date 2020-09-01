
package LedgerSMB::Scripts::login;

=head1 NAME

LedgerSMB:Scripts::login - web entry points for session creation/termination

=head1 DESCRIPTION

This script contains the request handlers for logging in and out of LedgerSMB.

=head1 METHODS

=over

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );
use JSON::MaybeXS;

use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::UI;

our $VERSION = 1.0;

=item __default (no action specified, do this)

Displays the login screen.

=cut

sub __default {
    my ($request) = @_;

    $request->{_req}->env->{'lsmb.session.expire'} = 1;
    $request->{stylesheet} = 'ledgersmb.css';
    $request->{titlebar} = "LedgerSMB $request->{version}";
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'login', $request);
}

=item authenticate

This routine checks for the authentication information and if successful
sends either a HTTP_FOUND redirect or a HTTP_OK successful response.

If unsuccessful sends a HTTP_BAD_REQUEST if the username/password is bad,
or a HTTP_454 error if the database does not exist.

=cut

my $json = JSON::MaybeXS->new( pretty => 1,
                               utf8 => 1,
                               indent => 1,
                               convert_blessed => 1,
                               allow_bignum => 1);

sub authenticate {
    my ($request) = @_;

    if ($request->{_req}->content_length > 4096) {
        # Obviously, the request to log in can't be slurped into memory
        # when bigger than 4k (which it ***NEVER*** should be...
        return LedgerSMB::PSGI::Util::unauthorized();
    }
    my $r;
    {
        local $/ = undef;
        my $fh = $request->{_req}->body;
        my $body = <$fh>;
        $r = $json->decode($body);
    }
    if (! $r->{login}
        || ! $r->{password}) {
        return LedgerSMB::PSGI::Util::unauthorized();
    }
    $r->{company} ||= $LedgerSMB::Sysconfig::default_db;
    if ($request->{_create_session}->($r->{login},
                                      $r->{password},
                                      $r->{company})) {
        return LedgerSMB::PSGI::Util::unauthorized();
    }

    return [ HTTP_OK,
             [ 'Content-Type' => 'application/json' ],
             [ '{ "target":  "erp.pl?action=root" }' ]];
}

=item logout

Logs the user out.  Handling of HTTP browser credentials is browser-specific.

Firefox, Opera, and Internet Explorer are all supported.  Not sure about Chrome

=cut

sub logout {
    my ($request) = @_;
    $request->{callback}   = '';

    $request->{_logout}->();
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'logout', $request);
}


{
    local ($!, $@) = ( undef, undef);
    my $do_ = 'scripts/custom/login.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (login.pm)\n\n" );
            }
        }
    }
};

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
