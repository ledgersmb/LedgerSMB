
=head1 NAME

LedgerSMB::Scripts::menu - LedgerSMB controller script for menus

=head1 SYOPSIS

This script provides a controller class for generating menus.  It can operate in
two modes:  One creates a standard expanding menu which works with or without
javascript.  The second creates drilldown menus for small-screen or text-only
devices.

=head1 METHODS

=cut

package LedgerSMB::Scripts::menu;

use LedgerSMB::DBObject::Menu;
use LedgerSMB::Template;
use strict;
use warnings;

our $VERSION = '1.0';

=pod

=over

=item __default

This pseudomethod is used to trap menu clicks that come back through the file
and route to the appropriate function.  It routes to expanding_menu.

=back

=cut

sub __default {
    my ($request) = @_;
    if ($request->{new}){
        return root_doc($request);
    }
    return expanding_menu($request);
}

=pod

=over

=item root_doc

Creates the root document.

=back


=cut

sub root_doc {
    my ($request) = @_;
    my $template;

    $request->{title} = "LedgerSMB $request->{VERSION} -- ".
    "$request->{login} -- $request->{company}";

    my $menu = LedgerSMB::DBObject::Menu->new({base => $request});
    $menu->generate();
    for my $item (@{$menu->{menu_items}}){
        if ($request->{'open'}
            && $request->{'open'} =~ /:$item->{id}:/ ){
            $item->{'open'} = 'true';
        }
    }

    $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'main',
        format => 'HTML'
    );
    return $template->render_to_psgi($menu);
}

=pod

=over

=item expanding_menu

This function generates an expanding menu.  By default all nodes are closed, but
there nodes which are supposed to be open are marked.


=back

=cut

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
         path => 'UI/menu',
         template => 'expanding',
         format => 'HTML',
    );
    return $template->render_to_psgi($menu);
}


=pod

=over

=item menuitems_json

Returns the menu items in JSON format

=back


=cut

sub menuitems_json {
    my ($request) = @_;
    # There must be a better way
    my $method = $request->{_auth}->{env}->{REQUEST_METHOD};
    my $menu = LedgerSMB::DBObject::Menu->new({base => $request});

    if ( $method eq 'GET' ) {

        #TODO: Localize Menus here before sending to client
        if ( defined($request->{id}) && $request->{id} ne "" ) {
            my ($item) = $menu->generate_item;
            return $request->to_json( $item );
        } elsif ( defined($request->{parent_id}) && $request->{parent_id} ne "" ) {
            $menu->generate_section;
        } else {
            $menu->generate(1); # Keep the root item
        }
        return $request->to_json( [@{$menu->{menu_items}}] );
    }
    return [400, [], []];
}

=pod

=over

=back

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your
option).  For more information please see the included LICENSE and COPYRIGHT
files.

=cut

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/menu.pl"};
1;
