
use v5.36;
use experimental 'try';
use warnings;

package LedgerSMB::Admin::Command::create;

=head1 NAME

LedgerSMB::Admin::Command::create - ledgersmb-admin 'create' command

=cut

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

use Getopt::Long qw(GetOptionsFromArray);

has options => (is => 'ro', default => sub { {} });

sub _option_spec {
    my ($self, $command) = @_;
    return (
        'prepare-only' => \$self->options->{'prepare-only'},
    );
}

sub run {
    my ($self, @args) = @_;
    my $options = {};

    Getopt::Long::Configure(qw(bundling require_order));
    GetOptionsFromArray(\@args, $self->options, $self->_option_spec());

    my $dbname = shift @args;

    return $self->help('create')
        if !$dbname || $dbname eq 'help';

    my $logger = $self->logger;
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($dbname)->%*,
    };
    $self->db(LedgerSMB::Database->new(
                  connect_data => $connect_data,
                  source_dir   => $self->config->sql_directory,
                  schema       => $self->config->get('schema'),
              ));
    ###TODO shouldn't we want to generate the logging output as part of
    ## the the regular logging output ? Meaning that STDERR gets logged
    ## as WARN output while STDOUT gets logged as INFO ?
    my $log = LedgerSMB::Database::loader_log_filename;
    my $errlog = LedgerSMB::Database::loader_log_filename;
    try {
        unless ($self->options->{'prepare-only'}) {
            $self->db->create();
            $logger->warn('Database successfully created');
        } else {
            $logger->warn('Preparing existing database');
        }
        $self->db->load_base_schema();
        $self->db->apply_changes();
        $self->db->load_modules('LOADORDER');
        $logger->warn('Database successfully created and prepared');
    }
    catch ($e) {
        ###TODO remove database after failed creation
        $logger->error("ERROR: $e");
        for my $line (split /\n/, $self->db->stderr) {
            $logger->error($line);
        }
        return 1;
    }
    $logger->info('Database successfully created');
    return 0;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin create [options] <db-uri>

=head1 DESCRIPTION

This command creates a new database to hold a company set identified by
C<db-uri>.

The resulting database does not have any setup, settings or users. See the
C<setup>, C<setting> and C<user> commands.

=head1 OPTIONS

=over

=item B<--prepare-only>

Prepares an existing database without attempting to create it. This is useful when the database has been pre-created and you only need to prepare it for use with LedgerSMB.

=back

=head1 SUBCOMMANDS

None

=head1 METHODS

=head2 run(@args)

Runs the C<create> command, according to the C<LedgerSMB::Admin::Command>
protocol.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
