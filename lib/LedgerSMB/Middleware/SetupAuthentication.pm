
package LedgerSMB::Middleware::SetupAuthentication;

=head1 NAME

LedgerSMB::Middleware::SetupAuthentication - Authentication and sessions

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::SetupAuthentication";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::AuthenticateSession makes sure a user has been
authenticated and a session has been established in all cases the
workflow scripts require it.

This module implements the C<Plack::Middleware> protocol and depends
on the request having been handled by
LedgerSMB::Middleware::DynamicLoadWorkflow to enhance the C<$env> hash.


The authentication strictly deals with authentication for setup.pl.


=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use DBI;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor;

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

    $env->{'lsmb.company'} = $req->parameters->get('database');
    $env->{'lsmb.auth'}    = LedgerSMB::Auth::factory($env, 'setup');
    return $self->app->($env);
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
