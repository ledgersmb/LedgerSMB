#!/usr/bin/perl

# This file is copyright (C) 2007the LedgerSMB core team and licensed under 
# the GNU General Public License.  For more information please see the included
# LICENSE and COPYRIGHT files

package LedgerSMB::Scripts::menu;
our $VERSION = '0.1';

$menufile = "menu.ini";
use LedgerSMB::Menu;
use LedgerSMB::Template;
use strict;

sub display {
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
    my $menu = new LedgerSMB::Menu(
        {files => ['menu.ini'], user => $request->{_user}}
    );
    my $template = LedgerSMB::Template->new(
         user => $request->{_user}, 
         locale => $request->{_locale},
         path => 'UI',
         template => 'menu_expand',
         format => 'HTML',
    );
    $request->{menu_items} = [];
    for (keys %$menu){
        push @{$request->{menu_items}}, $menu->{$_};
    }
    $menu->debug({file => '/tmp/debug-menu'});
    $request->{menu_items} = {};
    $request->{menu_items}->{subs} = $menu;
    $request->debug({file => '/tmp/debug'});
    $template->render($request);
}

1;
