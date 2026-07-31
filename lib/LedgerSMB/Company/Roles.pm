
use v5.38;

package LedgerSMB::Company::Roles;

use Moo;
use namespace::autoclean;

use Carp qw(croak);
use Log::Any qw($log);

use LedgerSMB::Company::Role;

use Moo;
use namespace::autoclean;

=head1 NAME

LedgerSMB::Company::Roles - Management of roles

=head1 SYNOPSIS

  use LedgerSMB::Company;

  my $c = LedgerSMB::Company->new( dbh => $dbh, wire => $wire );
  my $r = $c->roles;
  for my $l ($c->roles->list->@*) {
    say $l->role_name;
  }

=head1 DESCRIPTION

Management of roles.

=head1 ATTRIBUTES

=head2 app

  my $app = $roles->app;

Contains a reference to a C<LedgerSMB::Company> instance.

=cut

has _app => (
    is       => 'ro',
    init_arg => 'app',
    reader   => 'app',
    weak_ref => 1,
    required => 1);

=head2 for_user

  my $user = $roles->for_user;

If this instance represents a collection of roles assigned to
a specific user, this contains the C<LedgerSMB::Company::User>
instance for that user.

=cut

has for_user => (
    is   => 'ro'
    );

#
#  Cached roles
#
#  Contains a hash with LedgerSMB::Company::Role instances
#  as the values and the names of the roles as keys.
#

has _roles => (
    is   => 'rw',
    init_arg => undef,
    lazy => 1,
    builder => '_build_roles');

sub _build_roles($self) {
    my $dbh = $self->app->dbh;

    my $roles;
    if ($self->for_user) {
        $roles = $dbh->selectall_arrayref('SELECT admin__get_roles_for_user(?) as rolname',
                                          { Slice => {} },
                                          $self->for_user->id )
            or croak $log->error( 'Internal failure; unable to retrieve roles: ' . $dbh->errstr );
    }
    else {
        $roles = $dbh->selectall_arrayref('SELECT rolname FROM admin__get_roles()',
                                          { Slice => {} })
            or croak $log->error( 'Internal failure; unable to retrieve roles: ' . $dbh->errstr );
    }

    return {
        map {
            $_->{rolname} => LedgerSMB::Company::Role->new(
                app => $self->app,
                name => $_->{rolname},
                for_user => $self->for_user
                );
        } $roles->@*
    };
}

=head1 METHODS

=head2 get_by_name

  my $r = $roles->get_by_name( $name );

Retrieves a role from the collection by name. Returns C<undef>
when there is no role by the given name in the collection.

=cut

sub get_by_name( $self, $name ) {
    return $self->_roles->{$name};
}

=head2 list

  my $l = $roles->list;

Lists all roles in the collection. Returns all roles for the
user indicated by C<for_user> or all roles if that's undefined.

=cut

sub list( $self ) {
    return [ sort { $a->name cmp $b->name } values $self->_roles->%* ];
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
