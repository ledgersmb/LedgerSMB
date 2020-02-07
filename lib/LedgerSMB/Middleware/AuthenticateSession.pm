
package LedgerSMB::Middleware::AuthenticateSession;

=head1 NAME

LedgerSMB::Middleware::AuthenticateSession - Authentication and sessions

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::AuthenticateSession";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::AuthenticateSession makes sure a user has been
authenticated and a session has been established in all cases the
workflow scripts require it.

This module implements the C<Plack::Middleware> protocol and depends
on the request having been handled by
LedgerSMB::Middleware::DynamicLoadWorkflow to enhance the C<$env> hash.


The authentication can deal with a number of situations (authentication
configurations):

=over

=item Regular unauthenticated

The route explicitly requests not to authenticate at all.

This type of authentication misses the PSGI environment key 'lsmb.want_db'.

=item Regular authenticated

The route does not specify authentication options, meaning
full authentication required. This means a session cookie is available
with a database name and auth parameters are available for db connection
and the session is validated against sessions in the database.

This type of authentication has the PSGI environment key 'lsmb.want_db'
but misses the key 'lsmb.dbonly'.

In case the company name is missing, the default company configured in
ledgersmb.conf will be used.

=item Database only

The route explicitly requests not to be handled through a session cookie,
instead to authenticate against a database (named as a query or POST parameter)
with auth parameters available.

This type of authentication has both the 'lsmb.want_db' and 'lsmb.dbonly'
PSGI environment keys.

=back

Both regular unauthenticated and database only entry points may request
clearing/ disregarding session cookie information by specifying the
'lsmb.want_cleared_session' PSGI environment key.



=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use Cookie::Baker;
use DBI;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw( domain );
use Session::Storage::Secure;

use LedgerSMB;
use LedgerSMB::Auth;
use LedgerSMB::Auth::DB;
use LedgerSMB::App_State;
use LedgerSMB::DBH;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

our $store = Session::Storage::Secure->new(
    secret_key => LedgerSMB::Sysconfig::cookie_secret,
    default_duration => 24*60*60*90, # 90 days
    );

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    if (not $env->{'lsmb.want_db'}) {
        $env->{'lsmb.company'} =
            $req->parameters->get('database');
        $env->{'lsmb.auth'} =  LedgerSMB::Auth::factory($env, $self->domain);
        return $self->app->($env)
    }

    my $session = {};
    my $cookie_company;
    if (! $env->{'lsmb.want_cleared_session'}) {
        my $cookie_name = LedgerSMB::Sysconfig::cookie_name;
        my $cookie      = $req->cookies->{$cookie_name};
        $session        = $store->decode($cookie);

        if ($session) {
            $cookie_company = $session->{company};
            $env->{'lsmb.session_id'} = $session->{session_id};
            $env->{'lsmb.auth'}       =
                LedgerSMB::Auth::DB->new(
                    env => $env,
                    credentials => {
                        login => $session->{login},
                        password => $session->{password},
                    },
                    domain => $self->domain
                );
        }
    }

    if (! $env->{'lsmb.dbonly'}
        && $cookie_company && $cookie_company ne 'Login') {
        $env->{'lsmb.company'} = $cookie_company;
    }
    elsif ($env->{'lsmb.dbonly'}) {
        $env->{'lsmb.company'} ||=
            $req->parameters->get('company') ||
            # we fall back to what the cookie has to offer before
            # falling back to using the default database, because
            # login.pl::logout() does not require a valid session
            # and is therefor marked 'dbonly'; it does however require
            # a session cookie in order to be able to delete the
            # session from the database indicated by the cookie.
            $cookie_company ||
            ###TODO: falling back generally seems like a good idea,
            # but in case of login.pl::logout() it would seem better
            # just to report an error...
            LedgerSMB::Sysconfig::default_db;
    }
    return LedgerSMB::PSGI::Util::unauthorized()
        unless $env->{'lsmb.company'};

    $env->{'lsmb.auth'} //= LedgerSMB::Auth::factory($env, $self->domain);
    my $creds = $env->{'lsmb.auth'}->get_credentials($env->{'lsmb.company'});
    return LedgerSMB::PSGI::Util::unauthorized()
        unless $creds->{login} && $creds->{password};
    my $dbh = $env->{'lsmb.db'} =
        LedgerSMB::DBH->connect($env->{'lsmb.company'},
                                $creds->{login},
                                $creds->{password});

    if (! defined $dbh) {
        $env->{'psgix.logger'}->(
            {
                level => 'error',
                msg => q|Unable to create database connection: | . DBI->errstr
            });
        return LedgerSMB::PSGI::Util::unauthorized();
    }

    @{$session}{keys %$creds} = values %$creds;

    my $extended_cookie = '';
    if (! $env->{'lsmb.dbonly'}) {
        my $version =
            LedgerSMB::DBH->require_version($dbh, $LedgerSMB::VERSION);
        if ($version) {
            return LedgerSMB::PSGI::Util::incompatible_database(
                $LedgerSMB::VERSION, $version);
        }

        $extended_cookie = _verify_session($env->{'lsmb.db'},
                                           $env->{'lsmb.company'},
                                           $session);
        if (! $extended_cookie) {
            $dbh->commit;  # potentially log something
            $dbh->disconnect;

            return LedgerSMB::PSGI::Util::session_timed_out();
        }

        # create a session invalidation callback here.
        $env->{'lsmb.invalidate_session_cb'} = sub {
            $extended_cookie = _delete_session($dbh, $extended_cookie);

            return $extended_cookie;
        };
    }
    else {
        # we don't have a session, but the route may want to create one
        $env->{'lsmb.create_session_cb'} = sub {
            $extended_cookie =
                _create_session($dbh, $env->{'lsmb.company'});

            @{$session}{keys %$extended_cookie} = values %$extended_cookie;
            return $session;
        };
        # we don't have a validated session, but the route may want
        # to invalidate one if we have one anyway.
        # create a session invalidation callback here.
        $env->{'lsmb.invalidate_session_cb'} = sub {
            $extended_cookie = _delete_session($dbh, $session);

            return $extended_cookie;
        };
    }

    my $res = $self->app->($env);
    $dbh->rollback;
    $dbh->disconnect;

    my $secure = $env->{SERVER_PROTOCOL} eq 'https';
    my $path = LedgerSMB::PSGI::Util::cookie_path($env->{SCRIPT_NAME});
    return Plack::Util::response_cb(
        $res, sub {
            my $res = shift;

            # Set the new cookie (with the extended life-time) on response
            my $value = {
                company       => $env->{'lsmb.company'},
                %$session,
            };
            Plack::Util::header_push(
                $res->[1], 'Set-Cookie',
                bake_cookie(LedgerSMB::Sysconfig::cookie_name,
                            {
                                value    => $store->encode($value),
                                samesite => 'strict',
                                httponly => 1,
                                path     => $path,
                                secure   => $secure,
                                expires  => ($extended_cookie eq 'Login' ?
                                             '1' : undef),
                            }))
                if $extended_cookie;
        });
}


sub _verify_session {
    my ($dbh, $company, $cookie) = @_;
    my ($extended_session) = $dbh->selectall_array(
        q{SELECT * FROM session_check(?, ?)}, { Slice => {} },
        $cookie->{session_id}, $cookie->{token}) or die $dbh->errstr;
    $dbh->commit if $extended_session->{session_id};

    return unless $extended_session;

    @{$cookie}{keys %$extended_session} = values %$extended_session;
    return $cookie;
}

sub _create_session {
    my ($dbh, $company) = @_;

    my ($created_session) = $dbh->selectall_array(
        q{SELECT * FROM session_create();}, { Slice => {} },
        ) or die $dbh->errstr;
    $dbh->commit if $created_session->{session_id};

    return $created_session;
}

sub _delete_session {
    my ($dbh, $cookie) = @_;

    $dbh->selectall_array(q{SELECT session_delete(?)}, {},
                          $cookie->{session_id})
        or die $dbh->errstr;

    return 'Login';
}

sub _session_to_cookie_value {
    my ($session, $company) = @_;

    return $session->{session_id} ?
        join(':', $session->{session_id}, $session->{token}, $company) : '';
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
