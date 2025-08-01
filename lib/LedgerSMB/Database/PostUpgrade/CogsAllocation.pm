
use v5.36;
use warnings;
use experimental qw( signatures );

package LedgerSMB::Database::PostUpgrade::CogsAllocation;

=head1 NAME

LedgerSMB::Database::PostUpgrade::CogsAllocation - Post-Upgrade reallocation of COGS

=head1 SYNOPSIS



=head1 DESCRIPTION

This post-upgrade action ensures that all available purchased parts are allocated to
available sold parts as part of the COGS calculation. This post-processing is required
after fixing the allocated numbers for COGS as done by C<sql/changes/1.11/cogs-allocation.sql>.

=head1 METHODS

=head2 $class->run( $context, $args )

This class method expects a database handle C<dbh> in the C<$context>. Additionally,
it expects a list of parts in C<$args->{parts_ids}> identifying the parts for which
COGS might need adjustment.

=cut

sub run($class, $context, $args) {
    my $parts_ids = $args->{parts_ids} // [];

    my $dbh = $context->{dbh};
    my ($last_entry) = $dbh->selectrow_array('SELECT max(entry_id) FROM acc_trans');

    # COGS follows FIFO, so allocate oldest transdates and invoice IDs first
    my $sth = $dbh->prepare(<<~'SQL') or die $dbh->errstr;
      SELECT i.*
        FROM invoice i
             JOIN transactions t
                  ON i.trans_id = t.id
       WHERE t.approved
             AND i.parts_id = ?
             AND qty < 0
             AND (qty + allocated) <> 0
      ORDER BY t.transdate ASC, i.id ASC
      SQL
    my $rah = $dbh->prepare(<<~'SQL') or die $dbh->errstr;
      SELECT cogs__add_for_ap_line(?, CURRENT_DATE)
      SQL


    foreach my $parts_id ($parts_ids->@*) {
        $sth->execute( $parts_id )
            or die $sth->errstr;

        while (my $inv = $sth->fetchrow_hashref('NAME_lc')) {
            $rah->execute($inv->{id})
                or die $rah->errstr;

            my ($allocated) = $rah->fetchrow_array();
            die $rah->errstr if $rah->err;

            last if $allocated == 0;
        }
    }


    $dbh->do(
        <<~'SQL',
        UPDATE acc_trans
           SET memo = 'Added due to COGS adjustment at database upgrade'
         WHERE entry_id > ?
        SQL
        {}, # attrs
        $last_entry)
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
