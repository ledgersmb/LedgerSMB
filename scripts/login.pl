package LedgerSMB::Scripts::login;
our $VERSION = 1.0;

use LedgerSMB::Locale;
use LedgerSMB::Form; # Required for now to integrate with menu module.
use LedgerSMB::User;
use LedgerSMB::Auth;
use strict;

# this is kind of silly, as it doesn't check if someone IS trying to log in.
# If one looks at the login template (get_password.html), it does not post
# to any action, so this code will always get called, thereby preventing
# anyone from actually logging in.

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

# Directly printing like this is made of fail.

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
	    exit;	    
    }
    elsif ($request->{dbh} and !$request->{log_out}){
        print "Content-Type: text/html\n";
        print "Set-Cookie: ${LedgerSMB::Sysconfig::cookie_name}=Login; path=$path\n";
	    print "Status: 200 Success\n\n";
        if ($request->{log_out}){
            exit;
        }
    }
    else {
        if ($request->{_auth_error} =~/database/i){
            print "Status: 454 Database Does Not Exist\n\n";
            print "No message here";
        } else {
            print "WWW-Authenticate: Basic realm=\"LedgerSMB\"\n";
            print "Status: 401 Unauthorized\n\n";
	    print "Please enter your credentials.\n";
        } 
        exit; 
    }
}

sub login {
    my ($request) = @_;
    
    if (!$request->{_user}){
        __default($request);
    }
    require "scripts/menu.pl";
    LedgerSMB::Scripts::menu::root_doc($request);

}

sub logout {
    my ($request) = @_;
    $request->{callback}   = "";
    $request->{endsession} = 1;
    LedgerSMB::Auth::session_destroy($request);
    print "Location: login.pl\n";
    print "Content-type: text/html\n\n";
    exit;
}

sub continue {
    
    my ($request) = @_;
    
    if ($request->{next} && $request->{password}) {
                
        $request->{user} = "admin";
        
        if (&authenticate($request)) {
#            LedgerSMB::Handler::call_script();
        }
    }
    else {
        # well, wtf? This is kind of useless.
        $request->error("Cannot continue to a Nonexistent page.");
    }
}
    
eval { do "scripts/custom/login.pl"};
1;
