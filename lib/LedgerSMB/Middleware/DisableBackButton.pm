
package LedgerSMB::Middleware::DisableBackButton;

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
use feature 'postderef';

use parent qw ( Plack::Middleware );

use Plack::Util;

use LedgerSMB::App_State;
use LedgerSMB::Setting;


=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub call {
    my $self = shift;
    my ($env) = @_;


    return Plack::Util::response_cb($self->app->($env), sub {
        push $_[1]->@*, (
            'Cache-Control' => join(', ',
                                    qw| no-store  no-cache  must-revalidate
                                        post-check=0 pre-check=0 false|),
            'Pragma' => 'no-cache'
        );
    });
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
