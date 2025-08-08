
package LedgerSMB::Database::PostUpgrade::CogsAllocation;

use strict;
use warnings;
use experimental qw( signatures );

=head1 NAME

LedgerSMB::Database::PostUpgrade::CogsAllocation - Post-Upgrade reallocation of COGS

=head1 SYNOPSIS



=head1 DESCRIPTION



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
      SELECT cogs__add_for_ap_line(?, ?)
      SQL

    # If there's no value in the defaults table, use "today"
    # If the value in the defaults table is "NULL",
    #  use the regular COGS posting logic
    # If the value in the defaults table is a date,
    #  post corrections on that specific date
    my @date_setting = $dbh->selectrow_array(<<~'SQL');
      SELECT "value"::date
        FROM defailts
       WHERE setting_key = 'migration:cogs-allocation-posting-date'
      UNION ALL
      SELECT CURRENT_DATE
      SQL
    die $dbh->errstr if $dbh->err;

    foreach my $parts_id ($parts_ids->@*) {
        $sth->execute( $parts_id )
            or die $sth->errstr;

        while (my $inv = $sth->fetchrow_hashref('NAME_lc')) {
            $rah->execute($inv->{id}, $date_setting[0])
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
    $dbh->do(<<~'SQL') or die $dbh->errstr;
        DELETE FROM defaults
              WHERE setting_key = 'migration:cogs-allocation-posting-date'
        SQL

    return undef;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
