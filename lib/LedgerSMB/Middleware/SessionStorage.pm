
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
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor
    qw( cookie cookie_path domain duration inner_serialize secret store force_create );
use Session::Storage::Secure;
use String::Random;

use LedgerSMB::PSGI::Util;

=head1 METHODS

=head2 $self->prepare_app

Implements C<Plack::Component->prepare_app()>.

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub prepare_app {
    my $self = shift;
    my $store = Session::Storage::Secure->new(
        secret_key => $self->secret,
        default_duration => 24*60*60*90, # 90 days
        );
    $self->store( $store );
}

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $cookie             = $req->cookies->{$self->cookie};
    my $session            = (not $self->force_create) ? $self->store->decode($cookie) : undef;
    $session->{csrf_token} //= String::Random->new->randpattern('.' x 23);

    my $secure = defined($env->{HTTPS}) && $env->{HTTPS} eq 'ON';
    $env->{'lsmb.session'} = $session;
    return Plack::Util::response_cb(
        $self->app->($env), sub {
            my $res = shift;

            if (! $self->inner_serialize) {
                my $token = $env->{'lsmb.session'}->{token}  ?
                    $env->{'lsmb.session'}->{token} . '/' : '';
                my $path  = $self->cookie_path
                    ? ($self->cookie_path . $token)
                    : LedgerSMB::PSGI::Util::cookie_path($env->{SCRIPT_NAME});
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
