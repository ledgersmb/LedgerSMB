
package LedgerSMB::Middleware::Log4perl;

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

use Log::Log4perl;


=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut

sub call {
    my $self = shift;
    my ($env) = @_;

    my $logger = Log::Log4perl->get_logger('LedgerSMB.'
                                           . $env->{'lsmb.script'}
                                           . '.' . $env->{'lsmb.action_name'});
    $env->{'psgix.logger'} = sub {
        my $args = shift;
        my $level = $args->{level};
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
        $args->{message} =~ s/\n/\\n/g;
        $logger->$level($args->{message});
    };
    local $SIG{__WARN__} = sub {
        my $msg = shift;

        $msg =~ s/\n/\\n/g;
        $logger->warn($_);
    };

    return $self->app->($env);
}

=head1 COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
