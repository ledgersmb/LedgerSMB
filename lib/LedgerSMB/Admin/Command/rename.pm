
package LedgerSMB::Admin::Command::rename;

=head1 NAME

LedgerSMB::Admin::Command::rename - ledgersmb-admin 'rename' command

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
    my $existing_db = $self->connect_data_from_arg($dbname);
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
    };
    my $old_db = LedgerSMB::Database->new(
        connect_data => $connect_data,
        );
    my $old_dbh = $old_db->connect;
    $old_dbh->do(q{SELECT setting__set('role_prefix',
                             coalesce((setting_get('role_prefix')).value, ?))},
                 {},
                 "lsmb_$existing_db->{dbname}__")
        or die $old_dbh->errstr;
    $old_dbh->commit;
    $old_dbh->disconnect;

    my $connect_admin = {
        $self->config->get('connect_data')->%*,
        $existing_db->%*,
        dbname => ($self->config->get('admindb') // 'postgres'),
    };
    $self->db(
        LedgerSMB::Database->new(
            connect_data => $connect_admin,
        ));
    my $dbh = $self->db->connect;
    my $ident_dbname = $dbh->quote_identifier($existing_db->{dbname});
    my $ident_newname = $dbh->quote_identifier($newname);
    $dbh->do(qq{ALTER DATABASE $ident_dbname RENAME TO $ident_newname})
        or die $dbh->errstr;
    $dbh->commit;
    $dbh->disconnect;

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin rename <db-uri> <new-name>

=head1 DESCRIPTION

This command renames an existing database while making sure all access
rights are retained across the rename. Before trying to execute the rename
operation, the database is checked to exist and to be an existing LedgerSMB
company setup.

=head1 SUBCOMMANDS

None

=head1 METHODS

=head2 run(@args)

Runs the C<rename> command, according to the C<LedgerSMB::Admin::Command>
protocol.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
