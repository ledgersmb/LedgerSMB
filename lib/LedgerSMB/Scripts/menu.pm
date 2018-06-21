
package LedgerSMB::Scripts::menu;

=head1 NAME

LedgerSMB::Scripts::menu - LedgerSMB controller script for menus

=head1 DESCRIPTION

This script provides a controller class for generating menus.  It can operate in
two modes:  One creates a standard expanding menu which works with or without
javascript.  The second creates drilldown menus for small-screen or text-only
devices.

=head1 METHODS

=cut

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

    return root_doc($request);
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

    $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'main',
    );
    return $template->render($menu);
}

=pod

=over

=item menuitems_json

Returns the menu items in JSON format

=back


=cut

sub menuitems_json {
    my ($request) = @_;
    my $locale = $request->{_locale};
    my $menu = LedgerSMB::DBObject::Menu->new({base => $request});

    $menu->generate;
    $_->{label} = $locale->maketext($_->{label})
        for (@{$menu->{menu_items}});

    return $request->to_json( $menu->{menu_items} );
}

=pod

=over

=back

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your
option).  For more information please see the included LICENSE and COPYRIGHT
files.

=cut

{
    local ($!, $@) = ( undef, undef);
    my $do_ = 'scripts/custom/menu.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (menu.pm)\n\n" );
            }
        }
    }
};

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut



1;
