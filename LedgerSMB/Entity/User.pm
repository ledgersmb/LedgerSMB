=head1 NAME 

LedgerSMB::Entity::User - User management Logic for LedgerSMB

=cut

package LedgerSMB::Entity::User;
use Moose;
use LedgerSMB::App_State;
with 'LedgerSMB::DBObject_Moose';

=head1 SYNOPSYS

Resetting a password (expires in 24 hrs):
  my $user = LedgerSMB::Entity::User->get($entity_id);
  my $user->reset_password('temporary_password');

Creating a new user:
  my $user = LedgerSMB::Entity::User->new(%$request); 
  $user->save;

Saving permissions:
  my $user = LedgerSMB::Entity::User->new(%$request);
  $user->set_roles($request);

=head1 PROPERTIES

=over

=item entity_id

This is the integer id of the entity of the user

=cut 

has entity_id => (is => 'ro', isa => 'Int', required => 1);

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

=item password

This is only used for new users. It sets a temporary password (good for 24 hrs)

=cut

has password => (is => 'rw', isa => 'Str', required => 0, 
                 clearer => 'clear_password');

=item role_list

A list of role names granted to the user.

=cut

has role_list => (is => 'rw', isa => 'ArrayRef[Str]', required => 0);


=back

=head1 METHODS

=over

=item get($entity_id)

Returns the user object for that entity id.

=cut

sub get {
    my ($self, $entity_id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(
                 procname => 'admin__get_user', args => [$entity_id]
    );
    $self->prepare_dbhash($ref);
    my @roles = __PACKAGE__->call_procedure(
                 procname => 'admin__get_roles_for_user', args => [$entity_id]
    );
    $_ = $_->{admin__get_roles_for_user} for (@roles);
    $ref->{role_list} = \@roles;
    return $self->new(%$ref);
}

=item reset_password($password)

Resets a user's password to a temporary password good for 24 hours.

=cut

sub reset_password{
    my ($self, $password) = @_;
    $self->password($password);
    my ($ref) = $self->exec_method({funcname => 'admin__save_user'});
    $self->clear_password();
}

=item create

Creates the new user.

=cut

sub create{
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'admin__save_user'});
    $self->clear_password();
}

=item save_roles($role_list)

Saves (grants) roles requested.

=cut

sub save_roles{
    my ($self, $role_list) = @_;
    for my $rol_name (@$role_list) {
        $self->call_procedure(procname => 'admin__add_user_to_role',
                                  args => [$self->{username}, $rol_name]);
    }
}

=item list_roles

Lists roles for database.

=cut

sub list_roles{
    my ($self) = @_;
    my @roles =  __PACKAGE__->call_procedure(procname => 'admin__get_roles');
    for my $role (@roles){
        $role->{description} = $role->{rolname};
        $role->{description} =~ s/.*__//;
        $role->{description} =~ s/_/ /g;
    }
    return @roles;
}

=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be reused under the
conditions of the GNU GPL v2 or at your option any later version.  Please see
the accompanying LICENSE.TXT for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;
