

package LedgerSMB::Company::Menu::Node;

=head1 NAME

LedgerSMB::Company::Menu::Node - Entry in the menu tree

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new(connect_data => { ... })
       ->connect;
   my $m = LedgerSMB::Company->new(dbh => $dbh)->menu;

   my $tree  = $m->tree;
   my $nodes = $m->nodes;
   say $_->label for ($nodes->@*);

=head1 DESCRIPTION

Access to the attributes of a menu item.

Please note that the only correct procedure to get an instance of this
class is through a L<LedgerSMB::Company> instance.  That is the only
supported entry-point for the Perl API.

=cut


use warnings;
use strict;

use Log::Any qw($log);

use Moose;
use namespace::autoclean;


=head1 ATTRIBUTES

=head2 dbh (required)

This attribute is required and automatically passed into the instance
upon instantiation by C<LedgerSMB::Company>.

=cut

has '_dbh' => (
    is => 'ro',
    init_arg => 'dbh',
    reader   => 'dbh',
    required => 1);

=head2 id

The unique value identifying the menu node.

=cut

has id => (
    is => 'ro'
    );

=head2 label

The text shown in the menu tree for this menu item.

=cut

has label => (
    is => 'ro'
    );

=head2 url

The URL associated with the menu item.

=cut

has url => (
    is => 'ro'
    );

=head2 standalone

Indicates whether the menu item triggers opening a new window.

=cut

has standalone => (
    is => 'ro'
    );

=head2 is_menu

Indicates whether the menu item has children.

=cut

has is_menu => (
    is => 'ro'
    );


=head1 METHODS

This class has no methods.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
