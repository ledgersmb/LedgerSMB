
use v5.36;
use warnings;
use experimental qw( signatures );

package LedgerSMB::Database::PostUpgrade::CogsAllocationCleanup;

=head1 NAME

LedgerSMB::Database::PostUpgrade::CogsAllocationCleanup - Cleanup of backup tables created on upgrade

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 METHODS

=head2 $class->run( $context, $args )

This class method expects a database handle C<dbh> in the C<$context>.

=cut

sub run($class, $context, $args) {
    my $parts_ids = $args->{parts_ids} // [];

    $context->{dbh}->do(q{DROP TABLE IF EXISTS invoice_before_cogs_allocation_fix})
        or die $context->{dbh}->errstr;

    return undef;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
