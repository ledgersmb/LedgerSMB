
use v5.36;
use experimental 'try';
use warnings;

package LedgerSMB::Admin::Command::copy;

=head1 NAME

LedgerSMB::Admin::Command::copy - ledgersmb-admin 'copy' command

=cut

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

sub run {
    my ($self, $dbname, $newname) = @_;

    return $self->help('copy')
        if !$dbname || $dbname eq 'help';

    my $logger = $self->logger;
    my $existing_db = $self->connect_data_from_arg($dbname);
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
        dbname => $newname,
    };
    $self->db(
        LedgerSMB::Database->new(
            connect_data => $connect_data,
            source_dir   => $self->config->sql_directory,
        ));
    ###TODO shouldn't we want to generate the logging output as part of
    ## the the regular logging output ? Meaning that STDERR gets logged
    ## as WARN output while STDOUT gets logged as INFO ?
    my $log = LedgerSMB::Database::loader_log_filename;
    my $errlog = LedgerSMB::Database::loader_log_filename;
    try {
        $self->db->create(copy_of => $existing_db->{dbname});
    }
    catch ($e) {
        ###TODO error reporting?!
        ###TODO remove database after failed creation
        $logger->error("ERROR: $e");
        return 1;
    }
    $logger->info('Database successfully copied');
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin copy <db-uri> <new-database-name>

=head1 DESCRIPTION

This command creates a new database to hold a company set named
C<new-database-name> by copying the database identified by C<db-uri>.


=head1 SUBCOMMANDS

None

=head1 METHODS

=head2 run(@args)

Runs the C<copy> command, according to the C<LedgerSMB::Admin::Command>
protocol.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
