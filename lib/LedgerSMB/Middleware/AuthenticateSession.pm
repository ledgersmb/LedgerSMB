
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

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use Data::Dumper;
use HTTP::Status qw{ HTTP_SEE_OTHER HTTP_UNAUTHORIZED };
use Plack::Request;
use Plack::Util;

use LedgerSMB::Sysconfig;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut



sub call {
    my $self = shift;
    my ($env) = @_;

    my $req = Plack::Request->new($env);
    my $cookie_name = LedgerSMB::Sysconfig::cookie_name;
    my $session_cookie = $req->cookies->{$cookie_name};
    if (! $env->{'lsmb.want_cleared_session'}) {
        if ($session_cookie) {
            $env->{'lsmb.company'} = $1
                if $session_cookie =~ m/.*:([^:]*)$/ && $1 ne 'Login';
            $env->{'lsmb.company'} ||= LedgerSMB::Sysconfig::default_db;
        }
        else {
            return _unauthorized();
        }
    }

    # when there's no 'want_db' key, the entry point essentially asked for
    # "no authentication"
    if ($env->{'lsmb.want_db'}) {
        my $auth = LedgerSMB::Auth::factory($env);
        my $creds = $auth->get_credentials;

        # if the environment also has 'want_cleared_cookie',
        # we have a problem which we probably should be logging somewhere:
        # with a clear session cookie, we have no company name to log into!
        $env->{'lsmb.db'} = LedgerSMB::DBH->connect($env->{'lsmb.company'},
                                                    $creds->{login},
                                                    $creds->{password})
            or return _unauthorized();

        my $extended_cookie = _verify_cookie($env->{'lsmb.db'},
                                             $creds->{login},
                                             $creds->{password},
                                             $env->{'lsmb.company'},
                                             $session_cookie);
        return _session_timed_out()
            if ! $extended_cookie;

        my $res = $self->app->($env);

        my $secure = ($env->{SERVER_PROTOCOL} eq 'https') ? '; Secure' : '';
        my $path = $env->{SCRIPT_NAME};
        $path =~ s|[^/]*$||g;
        return Plack::Util::response_cb(
            $res, sub {
                my $res = shift;

                # Set the new cookie (with the extended life-time on response
                Plack::Util::header_set(
                    $res->[1], 'Set-Cookie',
                    qq|$cookie_name=$extended_cookie; path=$path$secure|)
            });
    }

    return $self->app->($env);
}

sub _unauthorized {
    return [ HTTP_UNAUTHORIZED,
             [ 'Content-Type' => 'text/plain; charset=utf-8',
               'WWW-Authenticate' => 'Basic realm=LedgerSMB' ],
             [ 'Please enter your credentials' ]
        ];
}

sub _session_timed_out {
    return [ HTTP_SEE_OTHER,
             [ 'Location' => 'login.pl?action=logout&reason=timeout' ],
             [] ];
}

sub _verify_cookie {
    my ($dbh, $login, $password, $company, $cookie) = @_;
    my ($session_id, $token, $cookie_company) = split(/:/, $cookie, 3);
    my ($extended_session) = $dbh->selectall_array(
        qq{SELECT * FROM session_check(?, ?)}, { Slice => {} },
        $session_id, $token);
    $dbh->commit if $extended_session->{session_id};

    return $extended_session->{session_id} ?
        join(':', $extended_session->{session_id},
             $extended_session->{token}, $company) : '';
}

=head1 COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
