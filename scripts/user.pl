#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::DBObject::User;
our $VERSION = 1.0;
use strict;

my $slash = "::";

package LedgerSMB::Scripts::user;

sub preference_screen {
    my ($request) = @_;
    my $user = LedgerSMB::DBObject::User->new({base => $request});
    $user->get_option_data;

    for my $format(@{$user->{dateformats}}){
        $format->{id} = $format->{format};
        $format->{id} =~ s/\//$slash/g;
    }

    $user->{dateformat} = $user->{_user}->{dateformat};
    $user->{dateformat} =~ s/\//$slash/g;
     
    my $template = LedgerSMB::Template->new(
            user     =>$request->{_user}, 
            locale   => $request->{_locale},
            path     => 'UI/users',
            template => 'preferences',
	    format   => 'HTML'
    );
    $user->{user} = $request->{_user};
    $template->render($user);
}

sub save_preferences {
    my ($request) = @_;
    my $user = LedgerSMB::DBObject::User->new({base => $request});
    $user->{dateformat} =~ s/$slash/\//g;
    if ($user->{confirm_password}){
        $user->change_my_password;
    }
    $user->save_preferences;
    preference_screen($user);
}
