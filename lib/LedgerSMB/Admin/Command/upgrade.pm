
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::Admin::Command::upgrade;

=head1 NAME

LedgerSMB::Admin::Command::upgrade - ledgersmb-admin 'upgrade' command

=cut

use Getopt::Long qw(GetOptionsFromArray);
use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

has modules_only => (is => 'ro');

sub run {
    my ($self, @args) = @_;

    my $logger = $self->logger;

    my $modules_only = 0;
    my $options = {
        'modules-only' => \$modules_only,
    };
    GetOptionsFromArray(\@args, $options, 'modules-only');
    my $dbname = shift @args;

    return $self->help('upgrade')
        if !$dbname || $dbname eq 'help';

    if (!$modules_only) {
        die 'Non-modules-only modes not implemented yet!';
    }
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($dbname)->%*,
    };
    $self->db(LedgerSMB::Database->new(
                  connect_data => $connect_data,
                  source_dir   => $self->config->sql_directory,
              ));
    try {
        if ($modules_only) {
            $self->db->load_modules('LOADORDER');
        }
    }
    catch ($e) {
        ###TODO remove database after failed creation
        $logger->error("ERROR: $e");
        for my $line (split /\n/, $self->db->stderr) {
            $logger->error($line);
        }
        return 1;
    }
    $logger->info('Database successfully upgraded');
    return 0;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin upgrade [options] <db-uri>

=head1 DESCRIPTION

This command upgrades a new database to hold a company set identified by
C<db-uri>.

=head1 SUBCOMMANDS

None

=head1 OPTIONS

=over

=item --modules-only

=back

=head1 METHODS

=head2 run(@args)

Runs the C<upgrade> command, according to the C<LedgerSMB::Admin::Command>
protocol.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
