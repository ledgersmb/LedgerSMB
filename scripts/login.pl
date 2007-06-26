#!/usr/bin/perl
package LedgerSMB::Scripts::login;
our $VERSION = 0.1;

use LedgerSMB::Locale;
use LedgerSMB::Form; # Required for now to integrate with menu module.
use LedgerSMB::User;
use strict;

sub __default {
   my ($request) = @_;
    my $locale;
    $locale = LedgerSMB::Locale->get_handle(${LedgerSMB::Sysconfig::language})
      or $request->error( __FILE__ . ':' . __LINE__ . 
         ": Locale not loaded: $!\n" );
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $locale,
        path => 'UI',
        template => 'login',
        format => 'HTML'
    );
    $template->render($request);
}


sub login {
    my ($request) = @_;
    
    if (!$request->{_user}){
        __default($request);
    }
    our $user = new LedgerSMB::User($request->{login});
    our $form = new Form; 
    for (keys %$request){
        $form->{$_} = $request->{$_};
    }
    my $menu_entrypoint;
    require "bin/menu.pl";
    if (($request->{_user}->{acs} !~ /Recurring Transactions/) || 
        $request->{_user}->{role} ne 'user'){
        if ($user->check_recurring($form) ) {
            $form->{main} = "recurring_transactions";
        }
        else {
            $form->{main} = "company_logo";
        }

    }
    else {

        $form->{main} = "company_logo";
    }
    &display;

}

sub logout {
    my ($request) = @_;
    $request->{callback}   = "";
    $request->{endsession} = 1;
    Session::session_destroy($request);
    print "Location: login.pl\n";
    print "Content-type: text/html\n\n";
    exit;
}
    
1;
