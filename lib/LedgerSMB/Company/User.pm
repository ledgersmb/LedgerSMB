
use v5.38;
use Sublike::Extended 0.29 'sub';

package LedgerSMB::Company::User;

use Moo;
use namespace::autoclean;
use experimental 'builtin', 'for_list';

use builtin qw(true false);
use Carp qw(croak);
use DateTime;
use DateTime::Format::Strptime;
use Log::Any qw($log);

use LedgerSMB::Company::Roles;
use LedgerSMB::Company::Preferences;

my $formatter = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%S:%M' );

=head1 NAME

LedgerSMB::Company::User - User management

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 app

=cut

has _app => (
    is => 'ro',
    init_arg => 'app',
    reader => 'app',
    required => 1
    );

=head2 id

=cut

has id => (is => 'rw', reader => 'id', writer => '_id');

=head2 username

=cut

has username => (is => 'ro', required => 1);

=head2 entity_id

=cut

has entity_id => (is => 'ro', required => 1);

=head2 preferences

=cut

has preferences => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_preferences'
    );

sub _build_preferences($self) {
    return LedgerSMB::Company::Preferences->new(
        app => $self->app,
        for_user => $self
        );
}

=head1 METHODS

=head2 is_users_manager

=cut

sub is_users_manager($self) {
    my $dbh = $self->app->dbh;

    my ($result) = $dbh->selectrow_array(
        q{SELECT pg_has_role(?, lsmb__role('users_manage'), 'USAGE')
                 OR pg_has_role(?, (select rolname
                                   from pg_database db
                                        inner join pg_roles rol
                                                   on db.datdba = rol.oid
                                  where db.datname = current_database()),
                               'USAGE')},
        {},
        $self->username, $self->username);
    if ($dbh->err) {
        croak $log->error( q{Internal failure; can't query user rights: } . $dbh->errstr );
    }

    return $result;
}

=head2 remove

  $user->remove;

=cut

sub remove($self) {
    my $dbh = $self->app->dbh;

    $dbh->do( q{SELECT admin__delete_user( ?, ? )},
              {},
              $self->username, 0 ); # 0 => 'in_drop_role == false'
}

=head2 save

  $user->save( passwd => $passwd, import => $import, force => $force );

=cut

sub save($self, :$passwd = undef, :$import = false, :$force = false) {
    my $dbh = $self->app->dbh;

    if ($passwd and $import) {
        croak $log->error( q{User creation option 'import' incompatible with 'passwd'} );
    }

    if ($force or not defined $self->id) {
        if ($force) {
            $dbh->do('DROP ROLE IF EXISTS ' . $dbh->quote_identifier($self->username) )
                or croak $dbh->errstr;
        }

        my @roles = $dbh->selectall_array('SELECT * FROM pg_roles WHERE rolname = ?',
                                          {}, $self->username);
        if ($dbh->err) {
            croak $log->error( q{Internal error; can't retrieve user data: } . $dbh->errstr);
        }
        if (@roles) {
            croak $log->error( q{Can't create user: duplicate username} );
        }

        my $user_row =
            $dbh->selectrow_arrayref(
                q{SELECT admin__save_user(?,?,?,?,?)}, {},
                undef, # user doesn't exist yet
                $self->entity_id,
                $self->username,
                $passwd,
                $import ? 1 : 0) # until DBD::Pg supports true/false
            or croak $log->error( 'Failed to create new user: ' . $dbh->errstr );
        $self->_id( $user_row->[0] );
    }
    $self->reset_password( $passwd );
}


=head2 change_password

  $user->change_password( $passwd )

=cut

sub change_password( $self, $passwd ) {
    unless ( $self->app->current_user->username eq $self->username ) {
        croak $log->error( 'Cannot change user password of another user (use "reset_password()"' );
    }

    my $dbh = $self->app->dbh;
    $dbh->do(q{SELECT user__change_password(?)},
             {},
             $passwd)
        or croak $log->error( q{Failed to change user password: } . $dbh->errstr );
}

=head2 reset_password

  $user->reset_password( $passwd );

=cut

sub reset_password( $self, $passwd ) {
    unless ( $self->app->is_bootstrap_user
             or $self->app->current_user->is_users_manager ) {
        my $current_username = $self->app->current_user->username;
        my $db_name = $self->app->dbh->{Name};
        my $db_user = $self->app->dbh->{Username};
        croak $log->error( qq{Cannot reset user password: current user ($current_username) is not an administrator in db '$db_name' connected with '$db_user'} );
    }

    my $dbh = $self->app->dbh;

    my $quoted_username = $dbh->quote_identifier( $self->username );
    my $expiration =
        $formatter->format_datetime( DateTime->now->add( hours => 24 ) );
    my $query =
        sprintf q{ALTER ROLE %s PASSWORD ? VALID UNTIL ?}, $quoted_username;
    $dbh->do( $query, {}, $passwd, $expiration )
        or croak $log->error( 'Password reset failed: ' . $dbh->errstr );
}

=head2

  my $roles = $user->roles;

=cut

sub roles( $self ) {
    unless ( $self->app->current_user->is_users_manager ) {
        # Bug? What if a user wants to query its own roles (read-only)?
        croak $log->error( 'Cannot retrieve role information: current user is not an administrator' );
    }

    return LedgerSMB::Company::Roles->new(
        app => $self->app,
        for_user => $self
        );
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
