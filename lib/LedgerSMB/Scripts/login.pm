
=pod

=head1 NAME

LedgerSMB:Scripts::login - web entry points for session creation/termination

=head1 SYNOPSIS

This script contains the request handlers for logging in and out of LedgerSMB.

=head1 METHODS

=over

=cut


package LedgerSMB::Scripts::login;

use LedgerSMB::Locale;
use HTTP::Status qw( HTTP_UNAUTHORIZED HTTP_SEE_OTHER HTTP_OK ) ;
use LedgerSMB::User;
use LedgerSMB::Scripts::menu;
use LedgerSMB::Sysconfig;
use Try::Tiny;

use strict;
use warnings;

our $VERSION = 1.0;

=item no_db_actions

Returns an array of actions which should not receive
a request object /not/ connected to the database.

=cut

sub no_db_actions {
    return qw(logout authenticate __default logout_js);
}

=item clear_session_actions

Returns an array of actions which should have the session
(cookie) cleared before verifying the session and being
dispatched to.

=cut

sub clear_session_actions {
    return qw(__default authenticate);
}

=item __default (no action specified, do this)

Displays the login screen.

=cut

sub __default {
    my ($request) = @_;

    if ($request->{cookie} && $request->{cookie} ne 'Login') {
        if (! $request->_db_init()) {
            return [ HTTP_UNAUTHORIZED,
                     [ 'WWW-Authenticate' => 'Basic realm=LedgerSMB',
                       'Content-Type' => 'text/plain; charset=utf-8' ],
                     [ 'Please provide your credentials.' ]];
        }
        if (! $request->verify_session()) {
            return [ HTTP_SEE_OTHER,
                     [ 'Location' => 'login.pl?action=logout&reason=timeout' ],
                     [ '<html><body><h1>Session expired</h1></body></html>' ] ];
        }
        $request->initialize_with_db();
        return LedgerSMB::Scripts::menu::root_doc($request);
    }

    $request->{_new_session_cookie_value} =
        qq|$LedgerSMB::Sysconfig::cookie_name=Login|;
    $request->{stylesheet} = "ledgersmb.css";
    $request->{titlebar} = "LedgerSMB $request->{VERSION}";
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'login',
        format => 'HTML'
    );
    return $template->render_to_psgi($request);
}

=item authenticate

This routine checks for the authentication information and if successful
sends either a HTTP_FOUND redirect or a HTTP_OK successful response.

If unsuccessful sends a HTTP_UNAUTHORIZED if the username/password is bad, 
or a HTTP_454 error if the database does not exist.

=cut

sub authenticate {
    my ($request) = @_;
    if (!$request->{dbh}){
        if (!$request->{company}){
             $request->{company} = $LedgerSMB::Sysconfig::default_db;
        }
        if (! $request->_db_init) {
            return [ HTTP_UNAUTHORIZED,
                     [ 'WWW-Authenticate' => 'Basic realm=LedgerSMB',
                       'Content-Type' => 'text/plain; charset=utf-8' ],
                     [ 'Please provide your credentials.' ]];
        }
    }

    if ($request->{dbh} and not $request->{log_out}){
        if (!$request->{dbonly}
            && ! LedgerSMB::Session::check($request->{cookie}, $request)) {
            return [ HTTP_UNAUTHORIZED,
                     [ 'WWW-Authenticate' => 'Basic realm=LedgerSMB',
                       'Content-Type' => 'text/plain; charset=utf-8' ],
                     [ 'Please provide your credentials.' ] ];
        }
        return [ HTTP_OK,
                 [ 'Content-Type' => 'text/plain; charset=utf-8' ],
                 [ 'Success' ] ];
    }
    else {
        if (($request->{_auth_error} )
            && ($request->{_auth_error} =~/$LedgerSMB::Sysconfig::no_db_str/i)) {
            return [ '454 Database Does Not Exist',
                     [ 'Content-Type' => 'text/plain; charset=utf-8' ],
                     [ 'Database does not exist' ] ];
        } else {
            return [ HTTP_UNAUTHORIZED,
                     [ 'WWW-Authenticate' => 'Basic realm=LedgerSMB',
                       'Content-Type' => 'text/plain; charset=utf-8' ],
                     [ 'Please enter your credentials.' ] ];
        }
    }
}

=item login

Logs in the user and displays the root document.

=cut

sub login {
    my ($request) = @_;

    if (!$request->{_user}){
        __default($request);
    }
    require LedgerSMB::Scripts::menu;
    return LedgerSMB::Scripts::menu::root_doc($request);
}

=item logout

Logs the user out.  Handling of HTTP browser credentials is browser-specific.

Firefox, Opera, and Internet Explorer are all supported.  Not sure about Chrome

=cut

sub logout {
    my ($request) = @_;
    $request->{callback}   = "";
    $request->{endsession} = 1;

    try { # failure only means we clear out the session later
        $request->_db_init();
        LedgerSMB::Session::destroy($request);
    };
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'logout',
        format => 'HTML'
    );
    return $template->render_to_psgi($request);
}

=item logout_js

This is a stub for a js logout feature.  It allows javascript to log out by
requiring only bogus credentials (logout:logout).

=cut

sub logout_js {
    my $request = shift @_;
    my $creds = $request->{_auth}->get_credentials;
    return [ HTTP_UNAUTHORIZED,
             [ 'WWW-Authenticate' => 'Basic realm=LedgerSMB',
               'Content-Type' => 'text/plain; charset=utf-8' ],
             [ 'Please enter your credentials.' ] ]
                 unless (($creds->{password} eq 'logout')
                         and ($creds->{login} eq 'logout'));
    return logout($request);
}


###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/login.pl"};

=back

=head1 COPYRIGHT

Copyright (C) 2009-2017 LedgerSMB Core Team. This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
