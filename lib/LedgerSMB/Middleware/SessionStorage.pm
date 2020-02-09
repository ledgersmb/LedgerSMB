
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
use Plack::Util::Accessor qw( domain cookie duration inner_serialize );
use Session::Storage::Secure;

use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

# this variable exists to deal with the code in old/
our $store = Session::Storage::Secure->new(
    secret_key => LedgerSMB::Sysconfig::cookie_secret,
    default_duration => 24*60*60*90, # 90 days
    );

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $cookie      = $req->cookies->{$self->cookie};
    my $session     = $store->decode($cookie);

    my $secure = $env->{SERVER_PROTOCOL} eq 'https';
    my $path = LedgerSMB::PSGI::Util::cookie_path($env->{SCRIPT_NAME});
    $env->{'lsmb.session'} = $session;
    return Plack::Util::response_cb(
        $self->app->($env), sub {
            my $res = shift;

            if (! $self->inner_serialize) {
                Plack::Util::header_push(
                    $res->[1], 'Set-Cookie',
                    bake_cookie(
                        $self->cookie,
                        {
                            value    => $store->encode(
                                $env->{'lsmb.session'},
                                time + ($env->{'lsmb.session.duration'}
                                        // $self->duration)),
                            samesite => 'strict',
                            httponly => 1,
                            path     => $path,
                            secure   => $secure,
                            expires  => ($env->{'lsmb.session.expire'}
                                         ? '1' : undef),
                        }));
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
