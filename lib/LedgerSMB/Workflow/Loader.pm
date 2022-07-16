
package LedgerSMB::Workflow::Loader;

=head1 NAME

LedgerSMB::Workflow::Loader

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

our $VERSION = '0.0.1';

use File::Find::Rule;
use File::Spec;
use Workflow::Factory;

=head1 CLASS METHODS

=head2 load( directories => @directories, lifecycle => $lifecycle )

=cut


my $finder = File::Find::Rule->new->name( '*.xml' );

sub _fn {
    my (undef, undef, $file) = File::Spec->splitpath($_[0]);
    return $file;
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
        my $prefix = defined $type ? ($type ? "/$type." : '/') : '.';
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

