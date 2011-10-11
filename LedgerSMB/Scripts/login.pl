
=pod

=head1 NAME

LedgerSMB:Scripts::login, LedgerSMB workflow scripts for managing drafts

=head1 SYNOPSIS

This script contains the request handlers for logging in and out of LedgerSMB.
    
=head1 METHODS
        
=over   
        
=cut


package LedgerSMB::Scripts::login;
our $VERSION = 1.0;

use LedgerSMB::Locale;
use LedgerSMB; 
use LedgerSMB::User;
use LedgerSMB::Auth;
use LedgerSMB::Sysconfig;
use strict;

=item __default (no action specified, do this)

Displays the login screen.

=cut

sub __default {
   my ($request) = @_;
    my $locale;
    $locale = LedgerSMB::Locale->get_handle(${LedgerSMB::Sysconfig::language})
      or $request->error( __FILE__ . ':' . __LINE__ . 
         ": Locale not loaded: $!\n" );         

    $request->{stylesheet} = "ledgersmb.css";
    $request->{titlebar} = "LedgerSMB $request->{VERSION}";
     my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $locale,
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
    
    if ($request->{dbh} && $request->{next}) {
        
        print "Content-Type: text/html\n";
        print "Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=Login; path=$path\n";
	    print "Status: 302 Found\n";
	    print "Location: ".$path.$request->{next}."\n";
	    print "\n";
	    $request->finalize_request();	    
    }
    elsif ($request->{dbh} and !$request->{log_out}){
        print "Content-Type: text/html\n";
        print "Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=Login; path=$path\n";
	    print "Status: 200 Success\n\n";
        if ($request->{log_out}){
            $request->finalize_request();
        }
    }
    else {
        if ($request->{_auth_error} =~/$LedgerSMB::Sysconfig::no_db_str/i){
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
    require "scripts/menu.pl";
    LedgerSMB::Scripts::menu::root_doc($request);

}

=item logout

Logs the user out.  Handling of HTTP browser credentials is browser-specific.

Firefox, Opera, and Internet Explorer are all supported.  Not sure about Chrome

=cut

sub logout {
    my ($request) = @_;
    @{$request->{scripts}} = 
                  qw(UI/logout/iexplore.js 
                     UI/logout/firefox.js
                     UI/logout/opera.js
                     UI/logout/safari.js
                     UI/logout/konqueror.js
                     UI/logout/epiphany.js
                   );
    $request->{callback}   = "";
    $request->{endsession} = 1;
    LedgerSMB::Auth::session_destroy($request);
     my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI',
        template => 'logout',
        format => 'HTML'
    );
    $template->render($request);
}

eval { do "scripts/custom/login.pl"};

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
