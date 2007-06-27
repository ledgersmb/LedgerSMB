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
    $request->{subs} = [];
    _attach_references({source => $menu, dest => $request->{subs}, path => ""});
    $menu->debug({file => '/tmp/debug-menu'});
    $request->debug({file => '/tmp/debug'});
    $template->render($request);
}

sub _attach_references {
    no strict qw(refs);
    my ($args) = @_;
    my ($source, $dest, $path) 
	= ($args->{source}, $args->{dest}, $args->{path});
    my %hash;
    if ($path and $source->{id}){
        for (sort keys %$source){
            next if $_ eq 'subs';
            $hash{$_} = $source->{$_};
        }
        $hash{path} = $path;
        push @{$dest}, \%hash;
        foreach (sort keys %{$source->{subs}}) {
            _attach_references({
                 source => $source->{subs}->{$_}, 
                 dest => $dest,
                 path => "$path--$_",
            });
        }
    } else {
        foreach (sort keys %$source){
            _attach_references({
                source => $source->{$_},
                dest => $dest,
                path => "$_",
            });
        }
    }
}

1;
