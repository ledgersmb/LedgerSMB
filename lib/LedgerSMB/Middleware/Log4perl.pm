
package LedgerSMB::Middleware::Log4perl;

=head1 NAME

LedgerSMB::Middleware::Log4perl - Sets up Log4perl logging environment

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::Log4perl";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::Log4perl sets up the 'psgix.logger' PSGI environment
variable with a Log4perl category of 'lsmb.<script_name>.<entrypoint>' where
<script_name> excludes the script's extension and <entrypoint> is the
sub routine name of the entrypoint being invoked. E.g. the category
for the authentication entrypoint is 'lsmb.login.authenticate'.

This middleware depends on the PSGI environment variables 'lsmb.script_name'
and 'lsmb.action_name' to exist. These variables are set up by the
middleware C<DynamicLoadWorkflow>.

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
                                           . $env->{'lsmb.script_name'}
                                           . '.' . $env->{'lsmb.action_name'});
    $env->{'psgix.logger'} = sub {
        my $args = shift;
        my $level = $args->{level};
        my $msg = $args->{message};

        return if ! defined $msg;

        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
        $msg =~ s/\n/\\n/g;
        $logger->$level($msg);
    };
    local $SIG{__WARN__} = sub {
        my $msg = shift;

        return if ! defined $msg;

        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
        $msg =~ s/\n/\\n/g;
        $logger->warn($msg);
    };

    return $self->app->($env);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
