
package LedgerSMB::Admin::Command::destroy;

=head1 NAME

LedgerSMB::Admin::Command::destroy - ledgersmb-admin 'destroy' command

=cut

use strict;
use warnings;

use LedgerSMB::Admin::Command;
use LedgerSMB::Database;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

sub run {
    my ($self, $dbname, $newname) = @_;
    my $logger = $self->logger;
    my $existing_db = $self->connect_data_from_arg($dbname);
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
    };
    my $db = LedgerSMB::Database->new(
        connect_data => $connect_data,
        );
    my $dbh = $db->connect;
    $dbh->do(q{SELECT setting__set('role_prefix',
                             coalesce((setting_get('role_prefix')).value, ?))},
                 {},
                 "lsmb_$existing_db->{dbname}__")
        or die $dbh->errstr;
    $dbh->commit;
    $dbh->disconnect;

    $db->drop
        or die $db->errstr;
    $logger->info('Database successfully destroyed');

    my $connect_admin = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
        dbname => ($self->config->get('admindb') // 'postgres'),
    };
    $self->db(
        LedgerSMB::Database->new(
            connect_data => $connect_admin,
        ));
    $dbh = $self->db->connect;
    my $sth = $dbh->prepare("SELECT rolname FROM pg_roles WHERE rolname LIKE 'lsmb_$existing_db->{dbname}__%';");
    $sth->execute
        or die $dbh->errstr;

    my @company_roles;
    while (my $role = $sth->fetchrow) {
        push @company_roles, $role;
    }
    $sth->finish;

    for my $role (@company_roles) {
        my $SQL = "DROP ROLE $role;";
        $dbh->do($SQL)
            or die $dbh->errstr;
    }
    $dbh->commit
        or die $dbh->errstr;
    $dbh->disconnect;
    $logger->info('Database related roles successfully destroyed');

    return 0;
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

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
