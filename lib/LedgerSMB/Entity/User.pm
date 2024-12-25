
package LedgerSMB::Entity::User;

=head1 NAME

LedgerSMB::Entity::User - User management Logic for LedgerSMB

=head1 DESCRIPTION

Implements mapping to database routines for creating/getting/retrieving
user information ("login accounts").

Note that this class isn't derived from LedgerSMB::Entity.

=head1 SYNOPSIS

Resetting a password (expires in 24 hrs):
  my $user = LedgerSMB::Entity::User->get($entcity_id);
  my $user->reset_password('temporary_password');

Creating a new user:
  my $user = LedgerSMB::Entity::User->new(%$request);
  $user->save;

Saving permissions:
  my $user = LedgerSMB::Entity::User->new(%$request);
  $user->save_roles($request);

=cut

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item id

This is the integer id of the user

=cut

has id => (is => 'ro', isa => 'Int');

=item entity_id

This is the integer id of the entity of the user

=cut

has entity_id => (is => 'ro', isa => 'Int', required => 0);

=item username

Username of the individual.  Would be the name of a valid Pg role.

=cut

has username => (is => 'rw', isa => 'Str', required => 1);

=item pls_import

If this flag is set, we don't try to set a password on creating a new user. Also
we don't create the user account.  This assumes that we are making a
pre-existing PostgreSQL user into a LedgerSMB user.

=cut

has pls_import => (is => 'rw', isa => 'Bool');

=item role_list

A list of role names granted to the user.

=cut

has role_list => (is => 'rw', isa => 'ArrayRef[Str]', required => 0,
                  default => sub { [] });


=back

=head1 METHODS

=over

=item get($entity_id)

Returns the user object for that entity id.

=cut

sub get {
    my ($self, $entity_id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(
                 funcname => 'admin__get_user_by_entity', args => [$entity_id]
    );
    return unless $ref->{entity_id};
    my @roles = __PACKAGE__->call_procedure(
                 funcname => 'admin__get_roles_for_user_by_entity', args => [$entity_id]
        );

    $ref->{role_list} =
        [ map { $_->{admin__get_roles_for_user_by_entity} } @roles ];
    return $self->new(%$ref);
}

=item reset_password($password)

Resets a user's password to a temporary password good for 24 hours.

=cut

sub reset_password {
    my ($self, $password) = @_;
    my ($ref) = $self->call_dbmethod(
        funcname => 'admin__save_user',
        args => { password => $password });
   return;
}

=item create( $password, [ \%prefs ] )

Creates the new user.

=cut

sub create {
    my ($self, $password, $prefs) = @_;
    my ($ref) = $self->call_dbmethod(
        funcname => 'admin__save_user',
        args => { password => $password });

    for my $role (@{$self->role_list}) {
        $self->call_procedure(
            funcname => 'admin__add_user_to_role',
            args => [ $self->username, $role ]);
    }
    $prefs //= {};
    my $query = q|insert into user_preference (user_id, name, value)
 values ($1, $2, $3)
 on conflict (user_id, name) do update set value = $3|;
    my $sth = $self->dbh->prepare($query)
        or die $self->dbh->errstr;
    for my $pref (keys $prefs->%*) {
        $sth->execute($self->id, $pref, $prefs->{$pref})
            or die $sth->errstr;
    }
    return;
}

=item delete

Deletes the user.

=cut

sub delete {
    my ($self) = @_;
    $self->call_dbmethod(funcname => 'admin__delete_user');
}

=item save_roles($role_list)

Saves (grants) roles requested.

=cut

sub save_roles {
    my ($self, $role_list) = @_;
     my @all_roles = map { $_->{rolname} } @{$self->list_roles};
     my (%have_role, %want_role);
     $have_role{$_} = 1
          for @{$self->role_list};
     $want_role{$_} = 1
          for @$role_list;
    for my $rol_name (@all_roles) {
        if ($want_role{$rol_name} && !$have_role{$rol_name}) {
            $self->call_procedure(funcname => 'admin__add_user_to_role',
                                  args => [$self->{username}, $rol_name]);
        }
        elsif ($have_role{$rol_name} && !$want_role{$rol_name}) {
            $self->call_procedure(funcname => 'admin__remove_user_from_role',
                                  args => [$self->{username}, $rol_name]);
        }
    }
    return $self->role_list($role_list);
}

=item list_roles

Lists roles for database.

=cut

sub list_roles {
    my ($self) = @_;
    my @roles =  $self->call_procedure(funcname => 'admin__get_roles');
    for my $role (@roles){
        $role->{description} = $role->{rolname};
        $role->{description} =~ s/.*__//;
        $role->{description} =~ s/_/ /g;
    }
    return \@roles;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
