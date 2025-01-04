
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::Admin::Command::backup;

=head1 NAME

LedgerSMB::Admin::Command::backup - ledgersmb-admin 'backup' command

=cut

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
use experimental 'try'; # Work around Moose re-enabling experimenal warnings
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;


sub run {
    my ($self, $dbname, $filename) = @_;

    return $self->help('backup')
        if !$dbname || $dbname eq 'help';

    my $logger = $self->logger;
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($dbname)->%*,
    };
    $self->db(LedgerSMB::Database->new(
                  connect_data => $connect_data,
              ));
    try {
        $filename = $self->db->backup(file => $filename);
    }
    catch ($e) {
        ###TODO remove database after failed creation
        $logger->error("ERROR: $e");
        for my $line (split /\n/, $self->db->stderr) {
            $logger->error($line);
        }
        return 1;
    }
    $logger->info("Backup successfully created as '$filename'");
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin backup <db-uri> [<filename>]

=head1 DESCRIPTION

This command saves a database to a backup file for later restore through
the C<restore> command.



=head1 SUBCOMMANDS

None

=head1 METHODS

=head2 run(@args)

Runs the C<backup> command, according to the C<LedgerSMB::Admin::Command>
protocol.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
