

package LedgerSMB::Company::Menu;

=head1 NAME

LedgerSMB::Company::Menu - Entry-point for company menu tree

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new(connect_data => { ... })
       ->connect;
   my $m = LedgerSMB::Company->new(dbh => $dbh)->menu;

   my $tree  = $m->tree;
   my $nodes = $m->nodes;

=head1 DESCRIPTION

Access to the menu items.

Please note that the only correct procedure to get an instance of this
class is through a L<LedgerSMB::Company> instance.  That is the only
supported entry-point for the Perl API.

=cut


use warnings;
use strict;

use List::Util qw(first);

use Log::Any qw($log);
use XML::LibXML qw( :libxml );

use LedgerSMB::Company::Menu::Node;

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

=head2 nodes

Holds an array of L<LedgerSMB::Company::Menu::Node> instances, representing
the menu for the currently connected user.

This attribute cannot be set at object instantiation.

=cut

has nodes => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_nodes');

sub _instantiate_menu_node {
    my ($self, $node_data) = @_;

    return LedgerSMB::Company::Menu::Node->new(
        dbh => $self->dbh,
        $node_data->%*
        );
}

sub _build_nodes {
    my $self = shift;

    my @nodes = $self->dbh->selectall_array(q{select * from menu_generate()}, { Slice => {} });
    return [
        map { $self->_instantiate_menu_node( $_ ) } @nodes
        ];
}

=head1 METHODS

=head2 children( $id )

Returns a reference to an array with the children of the node
with identification C<$id>.

=cut

sub children {
    my ($self, $node_id) = @_;
    return [ grep { $_->parent == $node_id } $self->nodes->@* ];
}

=head2 root

Returns the root of the menu tree.

=cut

sub root {
    my ($self) = @_;
    return first { $_->id == 0 } $self->nodes->@*;
}

=head2 from_xml($source)

C<$source> can be a string containing the actual XML, or a
file handle (in C<:raw> mode).

The specification of the XML structure (XSD) can be found at
C<doc/company-setup/menu.xsd> in the LedgerSMB repository.

=cut

sub _skip_text_siblings {
    my $item = shift;

    while ($item and $item->nodeType != XML_ELEMENT_NODE) {
        $item = $item->nextSibling;
        if ($item and $item->nodeType == XML_TEXT_NODE) {
            my $text = $item->nodeValue;
            die "Unexpected text '$text' in XML"
                if $text !~ m/^\s*$/;
        }
    }
    return $item;
}

my $query_add_menu_node = <<~'QUERY';
   INSERT INTO menu_node (id, parent, position, label, url, standalone, menu)
          VALUES (?, ?, ?, ?, ?, ?, ?)
   QUERY
my $query_add_menu_acl = <<~'QUERY';
   SELECT lsmb__grant_menu(?, ?, ?)
   QUERY
my $query_add_menu_acl_unrestricted = <<~'QUERY';
   INSERT INTO menu_acl (role_name, acl_type, node_id)
          VALUES ('public', 'allow', ?)
   QUERY

sub _add_menu_acl {
    my ($self, $id, $xml_node) = @_;
    my $role = $xml_node->getAttribute( 'role' );
    my $access = $xml_node->getAttribute( 'access' );
    $self->dbh->do($query_add_menu_acl, {}, $role, $id, $access)
        or die $self->dbh->errstr;
}

sub _add_menu_node {
    my ($self, $ctx, $xml_node, $parent_id) = @_;
    my $id    = $xml_node->getAttribute( 'id' ) // $ctx->{id}++;
    my $label = $xml_node->getAttribute( 'label' );
    my $url   = $xml_node->getAttribute( 'url' );
    my $new_page   = $xml_node->getAttribute( 'opens-new-page' );
    my $standalone = ($new_page and $new_page eq 'yes') ? 1 : undef;
    my @submenus   = $xml_node->getChildrenByTagName('menu-item');
    my $is_menu    = @submenus > 0 ? 1 : 0;
    $self->dbh->do($query_add_menu_node, {},
                   $id, $parent_id, $ctx->{position}++, $label, $url, $standalone, $is_menu)
        or die $self->dbh->errstr;

    if ($xml_node->hasChildNodes) {
        my $item = _skip_text_siblings( $xml_node->firstChild );
        if ($item and $item->localname eq 'acls') {
            my $unrestricted = $item->getAttribute( 'unrestricted' );
            if ($unrestricted and $unrestricted eq 'yes') {
                $self->dbh->do($query_add_menu_acl_unrestricted, {}, $id)
                    or die $self->dbh->errstr;
            }
            for my $acl ($item->getChildrenByTagName('acl')) {
                $self->_add_menu_acl($id, $acl);
            }
        }

        my @submenus = $xml_node->getChildrenByTagName('menu-item');
        local $ctx->{position} = 0;
        for my $submenu (@submenus) {
            $self->_add_menu_node( $ctx, $submenu, $id );
        }
    }
}

sub from_xml {
    my $self       = shift;
    my $source     = shift;
    my $input_type = (ref $source) ? 'IO' : 'string';
    binmode($source)  if (ref $source);

    my $doc  = XML::LibXML->load_xml( $input_type => $source );
    my $root = $doc->documentElement;

    $self->dbh->do(q{DELETE FROM menu_acl})
        or die $self->dbh->errstr;
    $self->dbh->do(q{DELETE FROM menu_node})
        or die $self->dbh->errstr;

    $self->_add_menu_node(
        { id => 10000, position => 0 }, # start of series when 'id' att not provided
        $root,
        undef  # parent of the root is <undef>
        );
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
