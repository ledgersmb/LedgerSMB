
=pod

=head1 NAME

LedgerSMB:Scripts::login, LedgerSMB workflow scripts for managing drafts

=head1 SYNOPSIS

This script contains the request handlers for logging in and out of LedgerSMB.

=head1 METHODS

=over

=cut


package LedgerSMB::Scripts::login;

use LedgerSMB::Locale;
use LedgerSMB;
use LedgerSMB::User;
use LedgerSMB::Auth;
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

=item __default (no action specified, do this)

Displays the login screen.

=cut

sub __default {
    my ($request) = @_;

    if ($request->{cookie} && $request->{cookie} ne 'Login') {
        $request->_db_init();
        $request->initialize_with_db();
        LedgerSMB::Scripts::menu::root_doc($request);
        return;
    }

    my $secure = '';
    my $path = $ENV{SCRIPT_NAME};
    my $cookie_name = $LedgerSMB::Sysconfig::cookie_name;
    if ($ENV{SERVER_PORT} == 443){
        $secure = ' Secure;';
    }
    print qq|Set-Cookie: $cookie_name=Login; path=$path;$secure\n|;
    $request->{stylesheet} = "ledgersmb.css";
    $request->{titlebar} = "LedgerSMB $request->{VERSION}";
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'login',
        format => 'HTML'
    );
    $template->render($request);
}

=item authenticate

This routine checks for the authentication information and if successful
sends either a 302 redirect or a 200 successful response.

If unsuccessful sends a 401 if the username/password is bad, or a 454 error
if the database does not exist.

=cut

sub authenticate {
    my ($request) = @_;
    if (!$request->{dbh}){
        if (!$request->{company}){
             $request->{company} = $LedgerSMB::Sysconfig::default_db;
        }
        $request->_db_init;
    }
    my $path = $ENV{SCRIPT_NAME};
    $path =~ s|[^/]*$||;

    # if ($request->{dbh} && $request->{next}) {

    #     print "Content-Type: text/html\n";
    #     print "Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=Login; path=$path\n";
    #     print "Status: 302 Found\n";
    #     print "Location: ".$path.$request->{next}."\n";
    #     print "\n";
    #     $request->finalize_request();
    # }
    # els
    if ($request->{dbh} and !$request->{log_out}){

        print "Content-Type: text/plain\n";
        LedgerSMB::Session::check($request->{cookie}, $request)
             unless $request->{dbonly};
        print "Status: 200 Success\n\nSuccess\n";
    }
    else {
        if (($request->{_auth_error} ) && ($request->{_auth_error} =~/$LedgerSMB::Sysconfig::no_db_str/i)){
            print "Status: 454 Database Does Not Exist\n\n";
            print "No message here";
        } else {
            print "WWW-Authenticate: Basic realm=\"LedgerSMB\"\n";
            print "Status: 401 Unauthorized\n\n";
            print "Please enter your credentials.\n";
        }
        $request->finalize_request();
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
    LedgerSMB::Scripts::menu::root_doc($request);
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
    $template->render($request);
}

=item logout_js

This is a stup for a js logout feature.  It allows javascript to log out by
requiring only bogus credentials (logout:logout).

=cut

sub logout_js {
    my $request = shift @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    LedgerSMB::Auth::credential_prompt
        unless ($creds->{password} eq 'logout')
               and ($creds->{login} eq 'logout');
    logout($request);
}


###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/login.pl"};

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
