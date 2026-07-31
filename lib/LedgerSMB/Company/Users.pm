
use v5.38;
use Sublike::Extended 0.29 'sub';

package LedgerSMB::Company::Users;

use Moo;
use namespace::autoclean;
use experimental 'builtin', 'for_list';

use builtin qw(true false);
use Carp qw(croak);
use Log::Any qw($log);

use LedgerSMB::Company::User;
use LedgerSMB::Company::Preferences;

=head1 NAME

LedgerSMB::Company::Users - Creation and retrieval of users

=head1 SYNOPSIS

  use LedgerSMB::Company;

  my $c = LedgerSMB::Company( dbh => $dbh, wire => $wire );
  my $w = $c->users;

=head1 DESCRIPTION

Manages users.

=head1 ATTRIBUTES

=head2 app

Reference to the main application instance.

=cut

has _app => (
    is       => 'ro',
    init_arg => 'app',
    reader   => 'app',
    weak_ref => 1,
    required => 1);

=head2 for_role

Set to the C<LedgerSMB::Company::Role> instance for which
this collection contains the members. If this field is undefined
the collection holds all users in the company.

=cut

has for_role => (
    is => 'ro');

=head2 preferences

=cut

has preferences => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_preferences');

sub _build_preferences($self) {
    return LedgerSMB::Company::Preferences->new(
        app => $self->app
        );
}

=head1 METHODS

=head2 create

  my $user = $users->create( $name, passwd => $passwd, entity_id => $entity_id, roles => \@roles, import => $bool, preferences => $preferences );

Creates a new user with username C<$name>. The values C<$passwd> and C<$entity_id> are
required. The other fields have these defaults:

=over 8

=item C<roles>

Defaults to an empty array, meaning no roles will be assigned to the user.

=item C<import>

Defaults to false, meaning that a new database login will be created.

=item C<force>

Defaults to false. When true, will delete an existing database login
before creating a new one.

=item C<preferences>

Defaults to an empty hash, meaning that no account-specific preferences
are set up.

=back

=cut

sub create($self, $name,
           :$passwd,
           :$entity_id,
           :$roles = [],
           :$import = false,
           :$force = false,
           :$preferences = {}) {
    my $dbh = $self->app->dbh;

    my $user = LedgerSMB::Company::User->new(
        app => $self->app,
        username => $name,
        entity_id => $entity_id
        );
    $user->save( passwd => $passwd, 'import' => $import, force => $force );

    if ($roles) {
        for my $role ($roles->@*) {
            $role->assign( $self );
        }
    }

    if ($preferences) {
        my $sth = $dbh->prepare(
            q{INSERT INTO user_preference (user_id, name, value)
              VALUES (?, ?, ?)})
            or croak $log->error( 'Internal failure: ' . $dbh->error );

        for my ($pref, $value) ($preferences->%*) {
            $sth->execute( $user->id, $pref, $value )
                or croak $log->error( 'Internal failure: ' . $dbh->errstr );
        }
    }

    return $user;
}

=head2 get_by_id

  my $user = $users->get_by_id( $id );

Returns a C<LedgerSMB::Company::User> identified by C<id>.

=cut

sub get_by_id( $self, $id ) {
    my $dbh = $self->app->dbh;

    my $user_data = $dbh->selectrow_hashref(
        q{SELECT id, entity_id, username FROM users WHERE id = ?},
        {}, $id);
    if ($dbh->err) {
        croak $log->error( q{Internal failure; can't query user data} );
    }

    return undef unless $user_data;
    return LedgerSMB::Company::User->new(
        app      => $self->app,
        $user_data->%*
        );
}

=head2 get_by_entity_id

  my $user = $users->get_by_entity_id( $entity_id );

Returns a C<LedgerSMB::Company::User> identified by C<entity_id>.

=cut

sub get_by_entity_id( $self, $entity_id ) {
    my $dbh = $self->app->dbh;

    my $user_data = $dbh->selectrow_hashref(
        q{SELECT id, entity_id, username FROM users WHERE entity_id = ?},
        {}, $entity_id);
    if ($dbh->err) {
        croak $log->error( q{Internal failure; can't query user data} );
    }

    return undef unless $user_data;
    return LedgerSMB::Company::User->new(
        app      => $self->app,
        $user_data->%*
        );
}

=head2 get_by_name

  my $user = $users->get_by_name( $name );

Looks up a user by its C<username> account name. Returns a
C<LedgerSMB::Company::User> instance.

=cut

sub get_by_name( $self, $name ) {
    my $dbh = $self->app->dbh;

    my $user_data = $dbh->selectrow_hashref(
        q{SELECT id, entity_id, username FROM users WHERE username = ?},
        {}, $name);
    if ($dbh->err) {
        croak $log->error( q{Internal failure; can't query user data} );
    }

    return undef unless $user_data;
    return LedgerSMB::Company::User->new(
        app      => $self->app,
        $user_data->%*
        );
}

=head2 list

  my $users = $users->list;

Returns a reference to an array of C<LedgerSMB::Company::User> instances, one
for each user.

=cut


sub list($self) {
    my $dbh = $self->app->dbh;

    if ($self->for_role) {
        my $query = <<~'SQL';
           SELECT id, entity_id, username
             FROM user__get_al_users()
            WHERE pg_has_role(lsmb_role(username, ?, 'USAGE')
           SQL
        my $members = $dbh->selectall_arrayref($query, { Slice => {} }, $self->name)
            or croak $log->error(
                q{Internal failure; Can't retrieve members for role: } . $dbh->errstr );
        return [
            map {
                LedgerSMB::Company::User->new(
                    app => $self->app,
                    $_->%*
                    );
            } $members->@* ];
    }
    else {
        my $query = 'SELECT id, entity_id, username FROM user__get_all_users()';
        my $users = $dbh->selectall_arrayref($query, { Slice => {} } )
            or croak $log->error( q{Internal failure; Can't retrieve all users: } . $dbh->errstr );
        return [
            map {
                LedgerSMB::Company::User->new(
                    app => $self->app,
                    $_->%*
                    );
            } $users->@* ];
    }
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
