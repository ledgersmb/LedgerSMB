
package LedgerSMB::Admin::Command::create;

=head1 NAME

LedgerSMB::Admin::Command::create - ledgersmb-admin 'create' command

=cut

use strict;
use warnings;

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

use Feature::Compat::Try;


sub run {
    my ($self, $dbname) = @_;
    my $logger = $self->logger;
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($dbname)->%*,
    };
    $self->db(LedgerSMB::Database->new(
                  connect_data => $connect_data,
                  source_dir   => $self->config->sql_directory,
              ));
    ###TODO shouldn't we want to generate the logging output as part of
    ## the the regular logging output ? Meaning that STDERR gets logged
    ## as WARN output while STDOUT gets logged as INFO ?
    my $log = LedgerSMB::Database::loader_log_filename;
    my $errlog = LedgerSMB::Database::loader_log_filename;
    try {
        $self->db->create_and_load(
            {
                log    => $log,
                errlog => $errlog,
            });
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

   ledgersmb-admin create <db-uri>

=head1 DESCRIPTION

This command creates a new database to hold a company set identified by
C<db-uri>.

The resulting database does not have any setup, settings or users. See the
C<setup>, C<setting> and C<user> commands.

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
