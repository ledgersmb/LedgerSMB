
package LedgerSMB::Middleware::MainAppConnect;

=head1 NAME

LedgerSMB::Middleware::MainAppConnect - Set up the application (db) connection

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::MainAppConnect";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::MainAppConnect sets up an application (database)
connection and adds that connection to the environment in the C<lsmb.app>
key (when C<provide_connection> equals 'open') or provides a callback
to set up the connection (when C<provide_connection> equals 'closed').

The database connection will either be inherited by an authorization
module which left a connection or callback in the environment under
C<lsmb.db> or C<lsmb.db_cb> respectively, or it will set up a connection
using the parameters C<host>, C<port>, C<user> and C<password>.

The resulting database connection will have its C<SESSION_USER>
initialized to the value of the C<username> key found in the environment's
C<lsmb.session> hash. The authorization module(s) are expected to initialize
this value in the session hash.

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use DBI;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor
    qw( host port user password provide_connection require_version );

use LedgerSMB::DBH;
use LedgerSMB::PSGI::Util;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub _connect {
    my $self = shift;
    my $env  = shift;
    # @_ retains $login, $password, $company
    my $dbh  = $env->{'lsmb.db'};
    if (!$dbh) {
        my $cb = $env->{'lsmb.db_cb'};
        if ($cb) {
            $dbh = $cb->(@_);
        }
        else {
            die q{Environment contains neither 'db' nor 'db_cb'};
        }
    }

    if ($self->require_version) {
        my $version =
            LedgerSMB::DBH->require_version($dbh, $self->require_version);
        if ($version) {
            $env->{'lsmb.session.expire'} = 1;
            return (undef, LedgerSMB::PSGI::Util::incompatible_database(
                        $self->require_version, $version));
        }
    }

    $dbh->do(q{SET SESSION AUTHORIZATION ?}, {},
             $env->{'lsmb.session'}->{username})
        or die 'Unable to switch to authenticated user: ' . $dbh->errstr;

    $env->{'lsmb.app'} = $dbh;
    return ($dbh, undef);
}

sub _alloc_cb {
    my ($self, $env) = @_;
    ###TODO oops: forgetting to verify the session!
    return sub { _connect($self, $env, @_); return $env->{'lsmb.app'}; };
}

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $dbh;
    if ($env->{'lsmb.want_db'}
        || $self->provide_connection eq 'closed') {
        if ($self->provide_connection eq 'closed') {
            $env->{'lsmb.app_cb'} = _alloc_cb($self, $env);
        }
        else {
            my $r;
            ($dbh, $r) = _connect($self, $env);
            return $r if defined $r;

            $r = _verify_session($dbh, $env);
            return $r if defined $r;
        }
    }
    else {
        # we may or may not have a valid application session...
        $env->{'lsmb.create_session_cb'} = sub {
            my ($login, $password, $company) = @_;

            die q{'provide_connection' can't be "closed" for login & logout}
               if $self->provide_connection eq 'closed';

            my $r;
            ($dbh, $r) = _connect($self, $env, @_);
            if (defined $r) {
                $env->{'lsmb.session.expire'} = 1;
                return $r;
            }

            _create_session($dbh, $company, $env->{'lsmb.session'});
            return;
        };
        # we don't have a validated session, but the route may want
        # to invalidate one if we have one anyway.
        # create a session invalidation callback here.
        $env->{'lsmb.invalidate_session_cb'} = sub {
            my $r;

            die q{'provide_connection' can't be "closed" for login & logout}
               if $self->provide_connection eq 'closed';

            my $session = $env->{'lsmb.session'};
            if ($session->{company}
                and $session->{login}
                and $session->{password}) {
                ($dbh, $r) = _connect($self, $env);

                return $r if defined $r;
            }
            if ($dbh) {
                _delete_session($dbh, $session);
            }

            $env->{'lsmb.session.expire'} = 1;
            return;
        };
    }

    return Plack::Util::response_cb(
        $self->app->($env), sub {
            if ($dbh) {
                $dbh->rollback;
                $dbh->disconnect;
            }
        });
}


sub _verify_session {
    my ($dbh, $env) = @_;
    my $session = $env->{'lsmb.session'};
    my ($extended_session) = $dbh->selectall_array(
        q{SELECT * FROM session_check(?, ?)}, { Slice => {} },
        $session->{session_id}, $session->{token})
        or die $dbh->errstr;
    $dbh->commit or die $dbh->errstr;

    if (not defined $extended_session->{session_id}) {
        $env->{'lsmb.session.expire'} = 1;
        return LedgerSMB::PSGI::Util::session_timed_out();
    }

    @{$session}{keys %$extended_session} = values %$extended_session;
    return;
}

sub _create_session {
    my ($dbh, $company, $session) = @_;

    my ($created_session) = $dbh->selectall_array(
        q{SELECT * FROM session_create();}, { Slice => {} },
        ) or die $dbh->errstr;
    $dbh->commit if $created_session->{session_id};

    @{$session}{keys %$created_session} = values %$created_session;
    return;
}

sub _delete_session {
    my ($dbh, $session) = @_;

    $dbh->selectall_array(q{SELECT session_delete(?)}, {},
                          $session->{session_id})
        or die $dbh->errstr;
    $dbh->commit;

    delete $session->{session_id};
    delete $session->{token};
    return;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
