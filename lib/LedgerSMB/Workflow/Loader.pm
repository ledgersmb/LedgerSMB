
package LedgerSMB::Workflow::Loader;

=head1 NAME

LedgerSMB::Workflow::Loader - Loading workflow configuration into the factory

=head1 SYNOPSIS

  workflows:
    class: LedgerSMB::Workflow::Loader
    lifecycle: eager
    args:
      directories:
        - workflows/
        - custom_workflows_vendor1/
        - our_custom_workflows/
      lifecycle: eager

=head1 DESCRIPTION

This module puts the configuration from the given directories into the
C<Workflow::Factory>. In order to allow extensibility and flexibility,
it composes a set of files with unique names. In case a filename exists
in more than one directory, the one from the last directory is favored
over the file(s) from earlier directories.

This way, upgrades can be executed safely (replacing the files in
C<workflow/> only), leavin the files in the other directories. At the same
time, without much configuration, the user can quite simply change the
standard workflows by storing them in one of the alternative directories.

=cut

use strict;
use warnings;

our $VERSION = '0.0.1';

use Log::Any qw($log);

use File::Find::Rule;
use File::Spec;
use Workflow::Factory;
use Workflow::Condition;

$Workflow::Condition::STRICT_BOOLEANS = 0;

=head1 CLASS METHODS

=head2 load( directories => @directories, lifecycle => $lifecycle )

Loads the workflow specifications from the given directories and registers
them with the C<Workflow::Factory>. Default is to load the configuration
when necessary. This is a good choice for smaller applications which are
unlikely to require access to all workflows on each invocation, but makes
less sense for persistent environments such as the Plack server.

To force all workflows to be loaded on start-up, provide the C<lifecycle>
parameter with a value of C<eager>.

Returns the C<Workflow::Factory> (singleton) instance.

=cut


my $finder = File::Find::Rule->new->name( '*.xml' );

sub _fn {
    my (undef, undef, $file) = File::Spec->splitpath($_[0]);
    return $file;
}

sub _type_to_fn {
    my ($type) = @_;

    my $type_fn = ($type =~ tr|a-zA-Z /|a-za-z\-\-|r);
    return $type_fn;
}

sub load {
    my $class = shift;
    my %args = @_;
    my @directories = $args{directories}->@*;

    my %files = map {
        map { _fn($_) => $_ } $finder->in( $_ )
    } grep { -d $_ } @directories;
    my @files = values %files;

    my $config = sub {
        my $type = shift;
        my $prefix;
        if (defined $type) {
            if ($type) {
                $prefix = sprintf( '%s.', _type_to_fn($type) );
            }
            else {
                $prefix = '/';
            }
        }
        else {
            $type = '<undef>';
            $prefix = '.';
        }
        $log->debug( "workflow files finder called for $type (prefix: $prefix)" );
        my $cfg = {
            action    => [ grep { m|\Q${prefix}actions.xml\E$| } @files ],
            condition => [ grep { m|\Q${prefix}conditions.xml\E$| } @files ],
            persister => [ grep { m|\Q${prefix}persisters.xml\E$| } @files ],
            validator => [ grep { m|\Q${prefix}validators.xml\E$| } @files ],
            workflow  => [ grep { m|\Q${prefix}workflow.xml\E$| } @files ],
        };

        return $cfg;
    };

    my $instance = Workflow::Factory->instance;

    # Always load the common configuration:
    $instance->add_config_from_file( $config->('')->%* );

    # Load the workflow specific configuration based on 'lifecycle'
    if ($args{lifecycle} and $args{lifecycle} eq 'eager') {
        $instance->add_config_from_file( $config->()->%* );
    }
    else {
        $instance->config_callback($config);
    }

    return $instance;
}


1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

