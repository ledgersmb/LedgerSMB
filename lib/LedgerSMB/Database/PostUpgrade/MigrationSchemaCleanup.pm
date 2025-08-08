
use v5.36;
use warnings;
use experimental qw( signatures );

package LedgerSMB::Database::PostUpgrade::MigrationSchemaCleanup;

=head1 NAME

LedgerSMB::Database::PostUpgrade::MigrationSchemaCleanup - Cleanup of schema created during migration

=head1 SYNOPSIS



=head1 DESCRIPTION

This post-upgrade action removes a schema which was created during a migration from LedgerSMB 1.2 or
1.3 or a migration from SQL Ledger 2.8, 3.0 or 3.2.

=head1 METHODS

=head2 $class->run( $context, $args )

This class method expects a database handle C<dbh> in the C<$context> and a C<schema> key in
C<$args> naming the schema to be removed.

=cut

sub run($class, $context, $args) {
    my $dbh    = $context->{dbh};
    my $schema = $dbh->quote_identifier($$args->{schema});

    $dbh->do(qq{DROP SCHEMA IF EXISTS $schema})
        or die $dbh->errstr;

    return undef;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
