
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

use DBI;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw( domain );

use LedgerSMB;
use LedgerSMB::Auth;
use LedgerSMB::App_State;
use LedgerSMB::DBH;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut



sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    if (not $env->{'lsmb.want_db'}) {
        $env->{'lsmb.company'} =
            $req->parameters->get('database');
        $env->{'lsmb.auth'} =  LedgerSMB::Auth::factory($env);
        $env->{'lsmb.auth'}->get_credentials($self->domain,
                                             $env->{'lsmb.company'});
        return $self->app->($env)
    }

    my $cookie_name = LedgerSMB::Sysconfig::cookie_name;
    my $session_cookie =
        $env->{'lsmb.want_cleared_session'} ? ''
        : $req->cookies->{$cookie_name};

    my ($unused_token, $cookie_company);
    ($env->{'lsmb.session_id'}, $unused_token, $cookie_company) =
        split(/:/, $session_cookie // '', 3);
    if (! $env->{'lsmb.dbonly'}
        && $cookie_company && $cookie_company ne 'Login') {
        $env->{'lsmb.company'} = $cookie_company;
    }
    elsif ($env->{'lsmb.dbonly'}) {
        $env->{'lsmb.company'} ||=
            $req->parameters->get('company') ||
            # temporarily accept a 'database' parameter too,
            # while we cut over 'setup.pl' in a later commit.
            $req->parameters->get('database') ||
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

    $env->{'lsmb.auth'} = LedgerSMB::Auth::factory($env);
    my $creds = $env->{'lsmb.auth'}->get_credentials(
        $self->domain,
        $env->{'lsmb.company'});
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

    my $extended_cookie = '';
    if (! $env->{'lsmb.dbonly'}) {
        my $version;
        LedgerSMB::App_State::run_with_state sub {
            $version = LedgerSMB::DBH->require_version($LedgerSMB::VERSION);
        }, DBH => $dbh;
        if ($version) {
            return LedgerSMB::PSGI::Util::incompatible_database(
                $LedgerSMB::VERSION, $version);
        }

        $extended_cookie = _verify_session($env->{'lsmb.db'},
                                           $env->{'lsmb.company'},
                                           $session_cookie);
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

            return $extended_cookie;
        };
        # we don't have a validated session, but the route may want
        # to invalidate one if we have one anyway.
        # create a session invalidation callback here.
        $env->{'lsmb.invalidate_session_cb'} = sub {
            $extended_cookie = _delete_session($dbh, $session_cookie);

            return $extended_cookie;
        };
    }

    my $res = $self->app->($env);
    $dbh->rollback;
    $dbh->disconnect;

    my $secure = ($env->{HTTPS} eq 'ON') ? '; Secure' : '';
    my $path = LedgerSMB::PSGI::Util::cookie_path($env->{SCRIPT_NAME});
    return Plack::Util::response_cb(
        $res, sub {
            my $res = shift;

            # Set the new cookie (with the extended life-time on response
            Plack::Util::header_push(
                $res->[1], 'Set-Cookie',
                qq|$cookie_name=$extended_cookie; Path=$path$secure; SameSite=Strict|)
                if $extended_cookie;
        });
}


sub _verify_session {
    my ($dbh, $company, $cookie) = @_;
    my ($session_id, $token, $cookie_company) = split(/:/, $cookie, 3);
    my ($extended_session) = $dbh->selectall_array(
        q{SELECT * FROM session_check(?, ?)}, { Slice => {} },
        $session_id, $token) or die $dbh->errstr;
    $dbh->commit if $extended_session->{session_id};

    return _session_to_cookie_value($extended_session, $company);
}

sub _create_session {
    my ($dbh, $company) = @_;

    my ($created_session) = $dbh->selectall_array(
        q{SELECT * FROM session_create();}, { Slice => {} },
        ) or die $dbh->errstr;
    $dbh->commit if $created_session->{session_id};

    return _session_to_cookie_value($created_session, $company);
}

sub _delete_session {
    my ($dbh, $cookie) = @_;
    my ($session_id, $token, $cookie_company) = split(/:/, $cookie, 3);

    $dbh->selectall_array(q{SELECT session_delete(?)}, {}, $session_id)
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
