
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

use HTTP::Throwable::Factory qw( http_throw );
use HTTP::Status qw/ is_server_error HTTP_UNAUTHORIZED /;
use Log::Any qw($log);
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor
    qw( host port user password provide_connection require_version );
use Scope::Guard qw/ guard /;

use LedgerSMB::Database;
use LedgerSMB::PSGI::Util;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub _get_settings {
    my ($self, $dbh) = @_;
    my $sth = $dbh->prepare(
        q{SELECT n.setting_key, s.value
        FROM unnest(?::text[]) n(setting_key), setting_get(setting_key) s})
        or die $dbh->errstr;
    $sth->execute(
        [ qw(templates weightunit curr
             default_email_from default_email_to
             default_email_bcc  default_email_cc
             default_language default_country papersize
             separate_duties company_name company_email
             company_phone company_fax businessnumber vclimit
             company_address dojo_theme decimal_places min_empty)
        ])
        or die $sth->errstr;

    my $results = $sth->fetchall_arrayref({})
        or die $sth->errstr;

    my $settings = {
        map { $_->{setting_key} => $_->{value} }
        @$results
    };
    $settings->{curr} = [ split (/:/, $settings->{curr}) ];
    $settings->{default_currency} = $settings->{curr}->[0];
    $settings->{format}           = $settings->{papersize};

    return $settings;
}

sub _connect {
    my $self = shift;
    my $env  = shift;
    # @_ retains $login, $password, $company
    my $dbh  = $env->{'lsmb.db'};
    if (!$dbh) {
        my $cb = $env->{'lsmb.db_cb'};
        if ($cb) {
            my ($r, $e) = $cb->($env, @_);

            return (undef, $e) if $e;
            $dbh = $r;
        }
        else {
            die q{Environment contains neither 'db' nor 'db_cb'};
        }
    }

    if ($self->require_version) {
        my $version =
            LedgerSMB::Database->require_version($dbh, $self->require_version);
        if ($version) {
            $env->{'lsmb.session.expire'} = 1;
            $log->fatalf(
                'Database version mismatch for "%s""; found %s; expected %s',
                $dbh->{pg_db}, $version, $self->require_version);
            return (undef, LedgerSMB::PSGI::Util::incompatible_database(
                        $self->require_version, $version));
        }
    }

    if ($env->{'lsmb.session'}->{username}) {
        $dbh->do(q{SET SESSION AUTHORIZATION ?}, {},
                 $env->{'lsmb.session'}->{username})
            or do {
                $log->fatalf( 'Unable to switch to authenticated user %s@%s',
                              $dbh->{pg_user}, $dbh->{pg_db} );
                die 'Unable to switch to authenticated user: ' . $dbh->errstr;
        };
        $dbh->do(q{SET SEARCH_PATH TO }
                 . $dbh->{private_LedgerSMB}->{schema})
            or do {
                $log->fatalf( 'Unable to set schema resolution: %s',
                              $dbh->errstr );
                die $dbh->errstr;
        };
#        $log->infof( 'Schema resolution set to %s', $dbh->quote
    }
    else {
        $log->fatal(
            q{Can't set db authorization: username missing in session}
            );
        die 'Unable to switch to authenticated user: none supplied';
    }

    $env->{'lsmb.app'} = $dbh;
    $env->{'lsmb.settings'} = $self->_get_settings( $dbh );
    return ($dbh, undef);
}

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $dbh;
    if ($self->provide_connection eq 'open'
        || $self->provide_connection eq 'closed') {
        if ($self->provide_connection eq 'closed') {
            $env->{'lsmb.app_cb'} = sub {
                my $env = shift;
                my $r;
                ($dbh, $r) = _connect($self, $env);
                http_throw(
                    {
                        status_code => HTTP_UNAUTHORIZED,
                        reason => 'Unauthorized',
                        message => 'Missing credentials or session expired'
                    })
                    if defined $r;

                $r = _verify_session($dbh, $env);
                http_throw(
                    {
                        status_code => HTTP_UNAUTHORIZED,
                        reason => 'Unauthorized',
                        message => 'Missing credentials or session expired'
                    })
                    if defined $r;

                return $dbh;
            };
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

    $env->{__app_guard__} = guard {
        if ($dbh and $dbh->{Active}) {
            $dbh->rollback;
            $dbh->disconnect;
            $log->warn('Unexpected exit; rolling back current db transaction');
        }
    };
    return Plack::Util::response_cb(
        $self->app->($env), sub {
            $log->info("Server response: $_[0]->[0]");
            if ($dbh and $dbh->{Active}) {
                if (is_server_error($_[0]->[0])) {
                    $dbh->rollback;
                    $log->info('Rolling back current db transaction');
                }
                else {
                    $dbh->commit;
                    $log->debug('Committing current db transaction');
                }
                $dbh->disconnect;
                $env->{__app_guard__}->dismiss;
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
        $log->infof( 'Session %s(token: %s) expired for %s@%s',
                     $session->{session_id}, $session->{token},
                     $dbh->{pg_user}, $dbh->{pg_db} );
        $env->{'lsmb.session.expire'} = 1;
        return LedgerSMB::PSGI::Util::session_timed_out();
    }

    @{$session}{keys %$extended_session} = values %$extended_session;
    return;
}

sub _create_session {
    my ($dbh, $company, $session) = @_;

    $log->info('Session database schema: ' . $dbh->{private_LedgerSMB}->{schema});
    $log->info('Session database pg_options: ' . $dbh->{pg_options});
    my ($current_schemas) = $dbh->selectall_array(
        q{SHOW search_path}, { },
        ) or die $dbh->errstr;
    $log->info("Current schema settings: $current_schemas->[0]");

    my ($created_session) = $dbh->selectall_array(
        q{SELECT * FROM session_create()}, { Slice => {} },
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
