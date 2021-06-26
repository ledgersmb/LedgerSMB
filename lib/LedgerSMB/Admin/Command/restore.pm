
package LedgerSMB::Admin::Command::restore;

=head1 NAME

LedgerSMB::Admin::Command::restore - ledgersmb-admin 'restore' command

=cut

use strict;
use warnings;

use Feature::Compat::Try;

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;


sub run {
    my ($self, $dbname, $filename) = @_;
    my $logger = $self->logger;
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($dbname)->%*,
    };
    $self->db(LedgerSMB::Database->new(
                  connect_data => $connect_data,
              ));
    try {
        $self->db->create;
        $self->db->restore(file => $filename);
    }
    catch ($e) {
        ###TODO remove database after failed creation
        $logger->error("ERROR: $e");
        for my $line (split /\n/, $self->db->stderr) {
            $logger->error($line);
        }
        return 1;
    }
    $logger->info("Backup successfully restored into '$dbname'");
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin restore <db-uri> <filename>

=head1 DESCRIPTION

This command creates a new database to hold the data restored from C<filename>.

NOTE: The content should be restored into a database by the same name that
it was backup-ed from, however nothing ensures this.



=head1 SUBCOMMANDS

None

=head1 METHODS

=head2 run(@args)

Runs the C<restore> command, according to the C<LedgerSMB::Admin::Command>
protocol.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
