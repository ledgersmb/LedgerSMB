
use v5.38;

package LedgerSMB::Company::Role;

use Carp qw(croak);
use Log::Any qw($log);

use LedgerSMB::Company::Users;

use Moo;
use namespace::autoclean;

=head1 NAME

LedgerSMB::Company::Role - Role management

=head1 SYNOPSIS

=head1 DESCRIPTION



=head1 ATTRIBUTES

=head2 app

=cut

has _app => (
    is       => 'ro',
    init_arg => 'app',
    reader   => 'app',
    weak_ref => 1,
    required => 1);

=head2 for_user

  my $user = $role->for_user;

Returns the user for which this instance tracks role membership. If
this isn't set, this instance does not track specific role membership
and represents the global role instead.

=cut

has for_user => (
    is    => 'ro',
    );

=head2 name

  my $rolename = $role->name;

Returns the (technical) name of the role.

=cut

has name => (
    is    => 'ro',
    init_arg => 'name',
    required => 1);

=head2 pretty

  my $pretty = $role->pretty;

Returns a - slightly less technical - name of the role.

=cut

has pretty => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_pretty');

sub _build_pretty($self) {
    return (($self->name =~ s/^.*__//gr) =~ s/_/ /gr);
}

=head1 METHODS

=head2 assign

  $role->assign( $user );

Makes the C<$user> (an instance of C<LedgerSMB::Company::User>)
member of this role.

=cut

sub assign($self, $user) {
    my $dbh = $self->app->dbh;

    $dbh->do(q{SELECT admin__add_user_to_role(?, ?)}, {}, $user->username, $self->name)
        or croak $log->error( q{Internal failure; Can't assign role to user} );
}

=head2 members

  my $members = $role->members;

Returns a C<LedgerSMB::Company::Users> collection holding
the members of this role.

=cut

sub members( $self ) {
    return LedgerSMB::Company::Users->new(
        app => $self->app,
        for_role => $self
        );
}

=head2 revoke

  $role->revoke;
  $role->revoke( $user );

Removes a role from C<$user>, or, if no user is provided, removes
the role from the user named by C<for_user>.

=cut

sub revoke($self, $user = $self->for_user) {
    my $dbh = $self->app->dbh;

    $dbh->do(q{SELECT admin__remove_user_from_role(?, ?)}, {}, $user->username, $self->name)
        or croak $log->error( q{Internal failure; Can't revoke role from user} );
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
