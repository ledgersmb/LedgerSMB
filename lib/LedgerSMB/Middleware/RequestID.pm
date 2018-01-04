
package LedgerSMB::Middleware::RequestID;

=head1 NAME

LedgerSMB::Middleware::DisableBackButton - Disables back button

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::DisableBackButton";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::DisableBackButton sets extremely strict cache
control policies, effectively rendering the back button useless as a
means of leaking information (no way to "back button back into the
ledger" after logging out).

The policy kicks in when so configured in the company database.

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

=head1 COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
