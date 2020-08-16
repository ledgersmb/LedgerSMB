
package LedgerSMB::Middleware::Authenticate::Company;

=head1 NAME

LedgerSMB::Middleware::Authenticate::Company - Authenticate user to company db

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::Authenticate::Company";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::Authenticate::Company authenticates a user against
a company database in a PostgreSQL cluster.

=head1 ATTRIBUTES

=head2 provide_connection

This attribute can have one of three values: C<none>, C<open>, C<closed>.
When C<open>, the database connection created to authenticate the user,
is added to the environment under the C<lsmb.db> key.

When C<closed>, the database connection created to authenticate the user
is closed and a callback is added to the environment under the C<lsmb.db_cb>
key which can be used to create a database connection.

When C<none>, the database connection created to authenticate the user
is closed. No additional action is taken.

=head2 default_company

The default company to use.

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use DBI;
use HTTP::Status qw( is_server_error );
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor
    qw( provide_connection default_company schema );
use Scope::Guard qw( guard );

use LedgerSMB::Database;
use LedgerSMB::PSGI::Util;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

If the environment contains C<lsmb.want_db> being true, validates
the user and adds to the environment as per C<provide_connection>.

When C<lsmb.want_db> is false (or is missing), a callback C<lsmb.db_cb> is
added to authenticate and create a database connection on demand.


=head1 CALLBACKS

=head2 lsmb.db_cb($env, [$login, $password, [$company]])

Returns a database handle connected to C<$company> using the credentials
C<$login> and C<$password>, if supplied. If C<$company> isn't provided,
the value of the C<default_company> attribute is used.

When C<$login> isn't provided, credentials are taken from the session
storage available through C<$env->{'lsmb.session'}>.

=cut

sub _connect {
    my ($self, $env, $login, $password, $company) = @_;

    my $session = $env->{'lsmb.session'};
    my %creds;
    @creds{qw/dbname username password/} = (! $login)
        ? (@{$session}{qw/company login password/})
        : ($company, $login, $password);

    unless ($creds{username} && $creds{password}) {
        if (! wantarray) {
            die q{Expected username and password};
        }
        return (undef, LedgerSMB::PSGI::Util::unauthorized());
    }

    my $dbh = $env->{'lsmb.db'} =
        LedgerSMB::Database->new(schema => $self->schema, %creds)->connect;

    if (! defined $dbh) {
        $env->{'psgix.logger'}->(
            {
                level => 'error',
                msg => q|Unable to create database connection: | . DBI->errstr
            });

        if (! wantarray) {
            die q{Invalid credentials};
        }
        return (undef, LedgerSMB::PSGI::Util::unauthorized());
    }

    if (! $session->{login}) {
        # creds come from parameters, update the session
        @{$session}{qw/ login username password company /} =
            ($login, $login, $password, $company);
    }
    return $dbh;
}

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $session = $env->{'lsmb.session'};
    $env->{'lsmb.session_id'} = $session->{session_id};

    my $dbh;
    if ($self->provide_connection eq 'open'
        or $self->provide_connection eq 'closed') {
        my $r;
        ($dbh, $r) = _connect($self, $env);
        return $r if defined $r;

        if ($self->provide_connection) {
            if ($self->provide_connection eq 'open') {
                $env->{'lsmb.db'} = $dbh;
            }
            else {
                if ($self->provide_connection eq 'closed') {
                    $env->{'lsmb.db_cb'} = sub {
                        my $env = shift;
                        return $dbh =
                            $env->{'lsmb.db'} =
                            _connect($self, $env, @_);
                    };
                }
                $dbh->disconnect;
                delete $env->{'lsmb.db'};
            }
        }
        else {
            $dbh->disconnect;
            delete $env->{'lsmb.db'};
        }
    }
    else {
        # It may not want a pre-initialized db, but... it might request one.
        $env->{'lsmb.db_cb'} = sub {
            my $env = shift;
            return _connect($self, $env, @_);
        };
    }


    $env->{__dbh_guard__} = guard {
        if ($dbh and $dbh->{Active}) {
            $dbh->rollback;
            $dbh->disconnect;
        }
    };
    return Plack::Util::response_cb(
        $self->app->($env), sub {
            if ($dbh and $dbh->{Active}
                and not is_server_error($_[0])) {
                $env->{__dbh_guard__}->dismiss;
                $dbh->commit;
                $dbh->disconnect;
            }
        });
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
