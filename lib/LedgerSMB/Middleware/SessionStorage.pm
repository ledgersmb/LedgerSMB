
package LedgerSMB::Middleware::SessionStorage;

=head1 NAME

LedgerSMB::Middleware::SessionStorage - Client side session (cookie) storage

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::SessionStorage",
         domain   => 'setup',
         cookie   => 'LedgerSMB/setup',
         duration => 15*60;
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::SessionStorage makes sure session state exists
(but empty if it didn't exist before) and is persisted at the end of
the request.

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use Cookie::Baker;
use HTTP::Status qw( HTTP_BAD_REQUEST );
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor
    qw( cookie cookie_path domain duration inner_serialize secret store force_create );
use Session::Storage::Secure;
use String::Random;
use URI;

use LedgerSMB::PSGI::Util;

=head1 METHODS

=head2 $self->prepare_app

Implements C<Plack::Component->prepare_app()>.

=cut

sub prepare_app {
    my $self = shift;
    my $store = Session::Storage::Secure->new(
        secret_key => $self->secret,
        default_duration => 24*60*60*90, # 90 days
        );
    $self->store( $store );
}

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub _prefix_path {
    my ($self, $env) = @_;
    my $token = $env->{'lsmb.session'}->{company_path}  ?
        $env->{'lsmb.session'}->{company_path} . '/' : '';

    if ($self->cookie_path) {
        return $self->cookie_path . $token;
    }
    else {
        my $path  = ($env->{SCRIPT_NAME} =~ s|[^/]*$||r);
        $path .= $token
            if $path !~ m/$token/;

        return $path;
    }
}

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $referer            = $req->headers->header( 'referer' );
    my $referer_uri        = $referer ? URI->new( $referer ) : undef;
    my $referer_user       = $referer_uri ? $referer_uri->query_param( 'user' ) : '';
    my $cookie             = $req->cookies->{$self->cookie};
    my $session            = (not $self->force_create) ? $self->store->decode($cookie) : undef;
    my $session_user       = $session ? $session->{login} : '';

    if ($referer_user
        and $session_user
        and $session_user ne $referer_user) {
        return [ HTTP_BAD_REQUEST,
                 [ 'Content-Type' => 'text/plain' ],
                 [ "Browser expects session for user '$referer_user', ",
                   "but session for user '$session_user' found" ]
            ];
    }

    $session->{csrf_token} //= String::Random->new->randpattern('.' x 23);
    $env->{'lsmb.session'} = $session;
    my $secure = defined($env->{HTTPS}) && $env->{HTTPS} eq 'ON';
    return Plack::Util::response_cb(
        $self->app->($env), sub {
            my $res = shift;

            if (! $self->inner_serialize) {
                my $path = $self->_prefix_path( $env );
                my $_cookie_attributes = {
                    value    => $self->store->encode(
                        $env->{'lsmb.session'},
                        time + ($env->{'lsmb.session.duration'}
                                // $self->duration)),
                    httponly => 1,
                    path     => $path,
                    secure   => $secure,
                    samesite => 'Strict',
                    expires  => ($env->{'lsmb.session.expire'}
                                    ? '1' : undef),
                };
                Plack::Util::header_push(
                    $res->[1], 'Set-Cookie',
                    bake_cookie(
                        $self->cookie,
                        $_cookie_attributes
                    ));
            }
        });
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
