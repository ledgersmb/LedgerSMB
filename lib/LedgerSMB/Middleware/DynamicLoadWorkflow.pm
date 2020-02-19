
package LedgerSMB::Middleware::DynamicLoadWorkflow;

=head1 NAME

LedgerSMB::Middleware::DynamicLoadWorkflow - Workflow script loader

=head1 SYNOPSIS

 builder {
   enable "+LedgerSMB::Middleware::DynamicLoadWorkflow";
   $app;
 }

=head1 DESCRIPTION

LedgerSMB::Middleware::DynamicLoadWorkflow makes sure the new-style
workflow scripts have successfully been loaded before being dispatched to.

This module implements the C<Plack::Middleware> protocol.

=cut

use strict;
use warnings;
use parent qw ( Plack::Middleware );

use HTTP::Status qw/ HTTP_REQUEST_ENTITY_TOO_LARGE /;
use List::Util qw{ none any };
use Module::Runtime qw/ use_module /;
use Plack::Request;
use Plack::Util::Accessor qw( want_db );

use LedgerSMB::PSGI::Util;
use LedgerSMB::Sysconfig;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut


sub call {
    my $self = shift;
    my ($env) = @_;

    if (LedgerSMB::Sysconfig::max_post_size() != -1
        && $env->{CONTENT_LENGTH}
        && ($env->{CONTENT_LENGTH} != 0)
        && ($env->{CONTENT_LENGTH} > LedgerSMB::Sysconfig::max_post_size())) {
        return [ HTTP_REQUEST_ENTITY_TOO_LARGE,
                 [ 'Content-Type' => 'text/plain' ],
                 [ 'Request entity too large' ]
            ];
    }

    my $script_name = $env->{SCRIPT_NAME};
    $script_name =~ m/([^\/\\\?]*)\.pl$/;
    $script_name = $1;
    my $module = "LedgerSMB::Scripts::$script_name";
    my $script = "$script_name.pl";

    return LedgerSMB::PSGI::Util::internal_server_error(
        'No workflow module specified!'
        )
        unless $module;

    return LedgerSMB::PSGI::Util::internal_server_error(
        "Unable to open module $module : $! : $@"
        )
        unless use_module($module);

    my $req = Plack::Request->new($env);
    my $action_name = $req->parameters->get('action') // '__default';
    my $action = $module->can($action_name);
    return  LedgerSMB::PSGI::Util::internal_server_error(
        "Action Not Defined: $action_name"
        )
        unless $action;

    $env->{'lsmb.want_db'} = $self->want_db;
    $env->{'lsmb.module'} = $module;
    $env->{'lsmb.script'} = $script;
    $env->{'lsmb.script_name'} = $script_name;
    $env->{'lsmb.action'} = $action;
    $env->{'lsmb.action_name'} = $action_name;
    return $self->app->($env);
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
