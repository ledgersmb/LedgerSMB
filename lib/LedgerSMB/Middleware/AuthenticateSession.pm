
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

This type of authentication has the PSGI environment key 'lsmb.want_db'.

In case the company name is missing, the default company configured in
ledgersmb.conf will be used.

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
use Session::Storage::Secure;

use LedgerSMB;
use LedgerSMB::Auth;
use LedgerSMB::Auth::DB;
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

    $env->{'lsmb.company'} =
        $env->{'lsmb.session'}->{company} ||
        $req->parameters->get('company') ||
        ###TODO: falling back generally seems like a good idea,
        # but in case of login.pl::logout() it would seem better
        # just to report an error...
        LedgerSMB::Sysconfig::default_db;

    my $session = $env->{'lsmb.session'};
    $session->{company} = $env->{'lsmb.company'};
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

    my $dbh;
    if ($env->{'lsmb.want_db'}) {
        my $creds = $env->{'lsmb.auth'}->get_credentials($env->{'lsmb.company'});
        return LedgerSMB::PSGI::Util::unauthorized()
            unless $creds->{login} && $creds->{password};
        $dbh = $env->{'lsmb.db'} =
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

        my $version =
            LedgerSMB::DBH->require_version($dbh, $LedgerSMB::VERSION);
        if ($version) {
            $env->{'lsmb.session.expire'} = 1;
            return LedgerSMB::PSGI::Util::incompatible_database(
                $LedgerSMB::VERSION, $version);
        }

        if (! _verify_session($env->{'lsmb.db'},
                              $env->{'lsmb.company'},
                              $session)) {
            $dbh->commit;  # potentially log something
            $dbh->disconnect;

            $env->{'lsmb.session.expire'} = 1;
            return LedgerSMB::PSGI::Util::session_timed_out();
        }
    }
    else {
        # we may or may not have a session...
        $env->{'lsmb.create_session_cb'} = sub {
            my ($login, $password) = @_;

            if (! $dbh) {
                $dbh = LedgerSMB::DBH->connect($env->{'lsmb.company'},
                                               $login,
                                               $password);
                @{$session}{qw/ login password /} =
                    ($login, $password);
            }
            return _create_session($dbh, $env->{'lsmb.company'}, $session);
        };
        # we don't have a validated session, but the route may want
        # to invalidate one if we have one anyway.
        # create a session invalidation callback here.
        $env->{'lsmb.invalidate_session_cb'} = sub {
            if (not $dbh
                and $env->{'lsmb.company'}
                and $session->{login}
                and $session->{password}) {
                $dbh = LedgerSMB::DBH->connect($env->{'lsmb.company'},
                                               $session->{login},
                                               $session->{password});
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
    my ($dbh, $company, $session) = @_;
    my ($extended_session) = $dbh->selectall_array(
        q{SELECT * FROM session_check(?, ?)}, { Slice => {} },
        $session->{session_id}, $session->{token}) or die $dbh->errstr;
    $dbh->commit if $extended_session->{session_id};

    return unless $extended_session;

    @{$session}{keys %$extended_session} = values %$extended_session;
    return $session;
}

sub _create_session {
    my ($dbh, $company, $session) = @_;

    my ($created_session) = $dbh->selectall_array(
        q{SELECT * FROM session_create();}, { Slice => {} },
        ) or die $dbh->errstr;
    $dbh->commit if $created_session->{session_id};

    @{$session}{keys %$created_session} = values %$created_session;
    return $created_session;
}

sub _delete_session {
    my ($dbh, $session) = @_;

    $dbh->selectall_array(q{SELECT session_delete(?)}, {},
                          $session->{session_id})
        or die $dbh->errstr;

    return;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
