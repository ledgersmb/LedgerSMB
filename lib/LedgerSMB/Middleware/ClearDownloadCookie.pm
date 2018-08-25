
package LedgerSMB::Middleware::ClearDownloadCookie;

=head1 NAME

LedgerSMB::Middleware::ClearDownloadCookie - Clears the JS download cookie

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::ClearDownloadCookie";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::ClearDownloadCookie makes sure that the
download cookie is being set to the value 'downloaded' on response,
if the client sends a request parameter 'request.download-cookie'.

This module implements the C<Plack::Middleware> protocol.

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use Plack::Request;
use Plack::Util;


=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut



sub call {
    my $self = shift;
    my ($env) = @_;

    my $req = Plack::Request->new($env);
    my $res = $self->app->($env);

    my $cookie = eval { $req->parameters->get_one('request.download-cookie'); };
    my $secure = ($env->{SERVER_PROTOCOL} eq 'https') ? '; Secure' : '';
    my $path = $env->{SCRIPT_NAME};
    $path =~ s|[^/]*$||g;
    return Plack::Util::response_cb(
        $res, sub {
            my $res = shift;

                # Set the requested cookie's value
                Plack::Util::header_push(
                    $res->[1], 'Set-Cookie',
                    qq|$cookie=downloaded; path=$path$secure|)
                    if $cookie;
            });
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
