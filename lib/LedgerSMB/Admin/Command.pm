
package LedgerSMB::Admin::Command;

=head1 NAME

LedgerSMB::Admin::Command - ledgersmb-admin abstract command class

=cut

use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);
use Log::Log4perl;
use Pod::Find qw(pod_where);
use Pod::Usage qw(pod2usage);

use Moose;
use namespace::autoclean;

use LedgerSMB::Database;


has config => (is => 'ro', required => 1,
               isa => 'LedgerSMB::Admin::Configuration');
has db => (is => 'rw');
has logger => (is => 'ro', lazy => 1, builder => '_build_logger');

sub _build_logger {
    return Log::Log4perl->get_logger(ref $_[0]);
}


sub help {
    my $self = shift;

    pod2usage(-verbose => 99, -output => \*STDOUT,
              -sections => 'SYNOPSIS|DESCRIPTION|COMMANDS|OPTIONS',
              -input => pod_where({ -inc => 1 }, ref $self));
}

sub _option_spec {
    return ();
}

sub _before_dispatch {
    my ($self) = shift;
    $self->db(LedgerSMB::Database->new(
                  connect_data => $self->config->get('connect_data'),
              ));
    return @_;
}

sub dispatch {
    my ($self, $command, @args) = @_;

    $command //= 'help';
    my $dispatch = $self->can($command);
    die "Unknown command '$command'"
        if (not $dispatch
            or ($command eq 'run')
            or ($command !~ m/^([a-zA-Z]+)$/));

    return $self->help($command, @args)
        if $command eq 'help';

    my $options = {};
    GetOptionsFromArray(\@args, $options,
                        $self->_option_spec($command));
    return $self->$dispatch($self->_before_dispatch($options, @args));
}

sub run {
    my ($self, $command, @args) = @_;

    return $self->dispatch($command, @args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   package LedgerSMB::Admin::Command::mycommand;

   use Moose;
   extends 'LedgerSMB::Admin::Command';

   ...;

   1;


=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 config

=head2 db

=head1 METHODS

=head2 dispatch($subcommand, @args)

Runs C<help> when C<$subcommand> equals C<'help'>. Otherwise, looks up the
existence of a method in the module by the name of C<$subcommand> and
invokes that with C<@args> as its method call arguments.

Before actually invoking the C<$subcommand>, this module parses any
subcommand options using L<Getopt::Long>. The specification of options
is retrieved by calling C<$self->_option_spec($subcommand)>. Then it calls the
C<_before_dispatch> method with a hash of specified options as its first
argument and its own arguments as the remainder; this provides a hook into
argument processing. The method can be overridden by children of this class.
The implementation in this class initializes the C<db> attribute based on
database connection data provided in the C<config> attribute and simply
returns the arguments passed to it. The call is expected to return
the arguments to be passed to the actual C<$subcommand> method.

Note: the default implementation of C<_option_spec> defines no options.
C<_option_spec> is expected to return a list of option specifications that
can be passed as part of the arguments in a call to C<GetOptions>.

=head2 help

Prints the command's help based on the POD in the command's module by
printing the sections:

=over

=item * SYNOPSIS

=item * DESCRIPTION

=item * OPTIONS

=item * COMMANDS

=back

=head2 run(@args)

Runs the module's main command. The default implementation splits C<@args>
into a C<$subcommand> and C<@remaining_args> and calls C<dispatch>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

