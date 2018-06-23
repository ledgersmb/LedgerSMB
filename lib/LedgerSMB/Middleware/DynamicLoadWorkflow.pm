
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

use Module::Runtime qw/ use_module /;
use List::Util qw{ none any };

use LedgerSMB::PSGI::Util;

=head1 METHODS

=head2 $self->call($env)

Implements C<Plack::Middleware->call()>.

=cut


sub call {
    my $self = shift;
    my ($env) = @_;

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
    my $action_name =
        eval { $req->parameters->get_one('action') } // '__default';
    my $action = $module->can($action_name);
    return  LedgerSMB::PSGI::Util::internal_server_error(
        "Action Not Defined: $action_name"
        )
        unless $action;

    # This authorization stuff seems to belong elsewhere...
    # but it's very much tied to our current style of request handling.
    ###TODO: factor out in its own 'authentication middleware'
    my $clear_session_actions =
        $module->can('clear_session_actions');
    $env->{'lsmb.want_cleared_session'} =
        $clear_session_actions
        && ( ! none { $_ eq $action_name }
               $clear_session_actions->() );

    my $no_db_actions = $module->can('no_db_actions');
    $env->{'lsmb.want_db'} =
        ! ($module->can('no_db')
           || ($no_db_actions &&
               any { $_ eq $action_name } $no_db_actions->()));

    my $dbonly_actions = $module->can('dbonly_actions');
    $env->{'lsmb.dbonly'} =
        ($module->can('dbonly')
         || ($dbonly_actions &&
             any { $_ eq $action_name } $dbonly_actions->()));

    $env->{'lsmb.module'} = $module;
    $env->{'lsmb.script'} = $script;
    $env->{'lsmb.script_name'} = $script_name;
    $env->{'lsmb.action'} = $action;
    $env->{'lsmb.action_name'} = $action_name;
    return $self->app->($env);
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
