
use v5.36;
use experimental 'try';
use warnings;

package LedgerSMB::Admin::Command::destroy;

=head1 NAME

LedgerSMB::Admin::Command::destroy - ledgersmb-admin 'destroy' command

=cut

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

my $logger;

sub run {
    my ($self, $dbname) = @_;

    return $self->help('destroy')
        if !$dbname || $dbname eq 'help';

    $logger = $self->logger;
    my $existing_db = $self->connect_data_from_arg($dbname);
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
    };
    my $db = LedgerSMB::Database->new(
        connect_data => $connect_data,
        source_dir   => $self->config->sql_directory,
        schema       => $self->config->get('schema'),
        );
    my $role_prefix = _get_role_prefix($db);

    $db->drop;
    $logger->info('Database successfully destroyed');

    my $connect_admin = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
        dbname => ($self->config->get('admindb') // 'postgres'),
    };
    $db = LedgerSMB::Database->new(
            connect_data => $connect_admin,
        );
    my $dbh = $db->connect;

    # Scan databases which could be using the same profile
    my $sth =
        $dbh->prepare('SELECT datname FROM pg_database WHERE NOT datistemplate');

    $sth->execute
        or die $dbh->errstr;

    my $role_prefix_usage = 0;
    while (my $database = $sth->fetchrow) {
        try {
            my $connect_database = {
                $self->config->get('connect_data')->%*,
                $existing_db->%*,
                dbname => $database,
            };
            my $db = LedgerSMB::Database->new(
                    connect_data => $connect_database,
                    source_dir   => $self->config->sql_directory,
                    schema       => $self->config->get('schema'),
                );
            my $database_role_prefix = _get_role_prefix($db);
            if ( defined $database_role_prefix && $role_prefix eq $database_role_prefix ) {
                $role_prefix_usage++;
                $logger->debug("'$role_prefix' used by $database");
            }
        }
        catch ($e) {
            $logger->error($e);
        }
    }
    $sth->finish;
    $dbh->disconnect;
    # If role_prefix is not used by another database
    if ( !$role_prefix_usage ) {
        $self->db(
            LedgerSMB::Database->new(
                connect_data => $connect_admin,
            ));
        my $dbh = $self->db->connect;
        my $SQL = "SELECT rolname FROM pg_roles WHERE rolname ~ '$role_prefix.*';";
        $logger->debug("$SQL\n");
        $sth = $dbh->prepare($SQL);
        $sth->execute
            or die $dbh->errstr;

        my @company_roles;
        while (my $role = $sth->fetchrow) {
            push @company_roles, $role;
        }
        $sth->finish;

        for my $role (@company_roles) {
            my $SQL = "DROP ROLE $role;";
            $logger->debug("$SQL\n");
            $dbh->do($SQL)
                or die $dbh->errstr;
        }
        $dbh->commit
            or die $dbh->errstr;
        $logger->info('Database related roles successfully destroyed');
    }
    else {
        $logger->info("Database related roles still in use by $role_prefix_usage database"
                      .( $role_prefix_usage > 1 ? 's' : ''));
    }
    $dbh->disconnect;
    return 0;
}

sub _get_role_prefix {
    my $db = shift;

    my $dbh = $db->connect;
    my $role_prefix;
    try {
        my $sth = $dbh->prepare(q{SELECT * FROM lsmb__role_prefix()});
        $sth->execute;
        if (!$dbh->errstr) {
            $role_prefix = $sth->fetchrow_array;
            $logger->debug("Role_prefix = '$role_prefix'");
            $sth->finish;
        }
    } catch ($e) {
        $logger->debug($e);
    }
    $dbh->disconnect;

    return $role_prefix;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin destroy <db-uri>

=head1 DESCRIPTION

This command destroys an existing database. Before trying to execute the
destroy operation, the database is checked to exist and to be an existing
LedgerSMB company setup.

=head1 SUBCOMMANDS

None

=head1 METHODS

=head2 run(@args)

Runs the C<destroy> command, according to the C<LedgerSMB::Admin::Command>
protocol.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2021 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
