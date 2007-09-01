#!/usr/bin/perl

# This file is copyright (C) 2007the LedgerSMB core team and licensed under 
# the GNU General Public License.  For more information please see the included
# LICENSE and COPYRIGHT files

package LedgerSMB::Scripts::menu;
our $VERSION = '0.1';

$menufile = "menu.ini";
use LedgerSMB::DBObject::Menu;
use LedgerSMB::Template;
use strict;

sub __default {
    my ($request) = @_;
    if ($request->{menubar}){
        # todo
    } else {
        expanding_menu($request);
    }
}

sub root_doc {
    my ($request) = @_;
    my $template;
    if (!$request->{menubar}){
        $request->{main} = "splash.html" if $request->{main} eq 'company_logo';
        $request->{main} = "am.pl?action=recurring_transactions"
            if $request->{main} eq 'recurring_transactions';
        $template = LedgerSMB::Template->new(
             user =>$request->{_user}, 
             locale => $request->{_locale},
             path => 'UI',
             template => 'frameset',
		     format => 'HTML'
		);
	    } else {
		# TODO:  Create Lynx Initial Menu
	    }
	    $template->render($request);
	}

	sub expanding_menu {
	    my ($request) = @_;
	    if ($request->{'open'} !~ s/:$request->{id}:/:/){
		$request->{'open'} .= ":$request->{id}:";
	    }

	    # The above system can lead to extra colons.
	    $request->{'open'} =~ s/:+/:/g;

	    

	    my $menu = LedgerSMB::DBObject::Menu->new({base => $request});
	    $menu->generate();
	    for my $item (@{$menu->{menu_items}}){
                if ($request->{'open'} =~ /:$item->{id}:/ ){
                    $item->{'open'} = 'true';
                }
            }

    my $template = LedgerSMB::Template->new(
         user => $request->{_user}, 
         locale => $request->{_locale},
         path => 'UI',
         template => 'menu_expand',
         format => 'HTML',
    );
    $template->render($menu);
}


1;
