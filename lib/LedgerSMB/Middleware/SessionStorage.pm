
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
    qw( domain cookie cookie_path duration inner_serialize );
use Session::Storage::Secure;

use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;

=head1 METHODS

=head2 $self->prepare_app

Implements C<Plack::Component->prepare_app()>.

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=head2 Internal routines to go around samesite bug in some browsers

=head3 _isSameSiteNoneIncompatible

Check is browser is incompatible with samesite cookie attribute

=head3 _hasWebKitSameSiteBug

Check if the browser has the samesite cookie attribute bug

=head3 _dropsUnrecognizedSameSiteCookies

Check if dropping samesite=strict required

=head3 _isIosVersion

Check if the browser is running on iOS

=head3 _isMacosxVersion

Check if the browser is runnig on MACOS

=head3 _isSafari

Check if the browser is Safari

=head3 _isMacEmbeddedBrowser

Check if the browser is an embedded MACOS browser

=head3 _isChromiumBased

Check if the browser is Chrome

=head3 _isChromiumVersionAtLeast

Check minimum Chrome version


=cut

# this variable exists to deal with the code in old/
our $store;

sub prepare_app {
    # delay initializing $store to allow LedgerSMB::Sysconfig to be loaded
    $store = Session::Storage::Secure->new(
        secret_key => LedgerSMB::Sysconfig::cookie_secret,
        default_duration => 24*60*60*90, # 90 days
        );
}

sub call {
    my $self = shift;
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $cookie      = $req->cookies->{$self->cookie};
    my $session     = $store->decode($cookie);

    my $secure = $env->{SERVER_PROTOCOL} eq 'https';
    my $path =
        $self->cookie_path //
        LedgerSMB::PSGI::Util::cookie_path($env->{SCRIPT_NAME});
    $env->{'lsmb.session'} = $session;
    return Plack::Util::response_cb(
        $self->app->($env), sub {
            my $res = shift;

            if (! $self->inner_serialize) {
                my $_cookie_attributes = {
                    value    => $store->encode(
                        $env->{'lsmb.session'},
                        time + ($env->{'lsmb.session.duration'}
                                // $self->duration)),
                    httponly => 1,
                    path     => $path,
                    secure   => $secure,
                    expires  => ($env->{'lsmb.session.expire'}
                                    ? '1' : undef),
                };
                $_cookie_attributes->{samesite} = 'strict'
                    if !_isSameSiteNoneIncompatible($env->{'HTTP_USER_AGENT'});
                Plack::Util::header_push(
                    $res->[1], 'Set-Cookie',
                    bake_cookie(
                        $self->cookie,
                        $_cookie_attributes
                    ));
            }
        });
}

# Classes of browsers known to be incompatible with samesite cookie attribute.

sub _isSameSiteNoneIncompatible {
    my $useragent = shift;
    return _hasWebKitSameSiteBug($useragent)
        || _dropsUnrecognizedSameSiteCookies($useragent);
}

sub _hasWebKitSameSiteBug {
    my $useragent = shift;
    return _isIosVersion($useragent, { major => 12 })
        || (    _isMacosxVersion($useragent, { major => 10, minor => 14 })
            && (_isSafari($useragent) || _isMacEmbeddedBrowser($useragent)));
}

sub _dropsUnrecognizedSameSiteCookies {
    my $useragent = shift;
    return  _isChromiumBased($useragent)
        &&  _isChromiumVersionAtLeast($useragent, { major => 51 })
        && !_isChromiumVersionAtLeast($useragent, { major => 67 });
}

# Regex parsing of User-Agent

sub _isIosVersion{
    my ($useragent,$version) = @_;
    # Extract digits from first capturing group.
    return $useragent =~ /\(iP.+; CPU .*OS (\d+)[_\d]*.*\) AppleWebKit\//
        ? $1 eq "$version->{major}"
        : 0;
}

sub _isMacosxVersion{
    my ($useragent,$version) = @_;
    # Extract digits from first and second capturing groups.
    return $useragent =~ /\(Macintosh;.*Mac OS X (\d+)_(\d+)[_\d]*.*\) AppleWebKit\//
         ?    $1 eq "$version->{major}"
           && $2 eq "$version->{minor}"
         : 0;
}

sub _isSafari {
    my $useragent = shift;
    return $useragent =~ /Version\/.* Safari\//
        && !_isChromiumBased($useragent);
}

sub _isMacEmbeddedBrowser {
    my $useragent = shift;
    return $useragent =~ /^Mozilla\/[\.\d]+ \(Macintosh;.*Mac OS X [_\d]+\)
                          AppleWebKit\/[\.\d]+ \(KHTML, like Gecko\)\$/x;
}

sub _isChromiumBased {
    my $useragent = shift;
    return $useragent =~ /Chrom(e|ium)/;
}

sub _isChromiumVersionAtLeast{
    my ($useragent,$version) = @_;
    # Extract digits from first capturing group.
    return $useragent =~ /Chrom[^ \/]+\/(\d+)[\.\d]* /
         ? $1 >= $version->{major}
         : 0;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
