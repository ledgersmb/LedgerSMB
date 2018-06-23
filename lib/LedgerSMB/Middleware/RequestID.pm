
package LedgerSMB::Middleware::RequestID;

=head1 NAME

LedgerSMB::Middleware::RequestID - Generate a unique ID per request

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::DisableBackButton";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::RequestID sets the variable HTTP_REQUEST_ID
in the PSGI environment to a (practically unique) value to identify
a specific request. This request ID can be used to identify log output
lines belonging to the trace of a single request.

Note that the variable is strictly not an HTTP variable, but the name
has been chosen to allow the C<AccessLog> module to use the C<%{Request-Id}i>
syntax for inclusion in log messages.

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use Data::UUID;

our $request_id;
my $ug = Data::UUID->new;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub call {
    my $self = shift;
    my ($env) = @_;

    local $request_id = substr($ug->create_hex, 2);
    $env->{HTTP_REQUEST_ID} = $request_id;

    return $self->app->($env);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
