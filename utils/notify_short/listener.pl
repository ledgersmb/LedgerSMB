#!/usr/bin/perl

# Short Parts Notifier for LedgerSMB
# By Chris Travers, Metatron Technology Consulting

# To use this software, edit docs/conf/notify-short.conf.pl so that you can
# connect to the database.  Then you can run listener.pl and it will
# periodically check to see if new there are parts that have become short
# through transactions.

# At the moment, the report is triggered when an AR or AP invoice occurs and a
# part affected by the transaction is lower than the ROP.  When this happens, a
# Notify is sent from the database, and the application prepares the report on
# its next cycle.  Note that although the creation of a new part will not cause
# it to trigger the report, the new part will appear on the report on the next
# run.

# Any feedback, improvements, etc. are welcome.

# Released under the GNU GPL v2.0 or later.  See included LICENSE for more
# information.

my $config = shift @ARGV;

unless ($config) {
    while (<DATA>) { print };
    exit 1;
}

require $config;

use DBI;
my $dsn = "dbi:Pg:dbname=$database";
my $dbh = DBI->connect(
    $dsn, $db_user,
    $db_passwd,
    {
        AutoCommit => 1,
        PrintError => 0,
        RaiseError => 1,
    }
);
$dbh->{pg_enable_utf8} = 1;

my $sth;

$dbh->do("LISTEN parts_short");
while (1) {    # loop infinitely
    if ( $dbh->func('pg_notifies') ) {
        &on_notify;
    }
    sleep $cycle_delay;
}

sub on_notify {
    open( MAIL, '|-', "$sendmail" );
    $sth = $dbh->prepare( "
        SELECT partnumber, description, onhand, rop FROM parts
        WHERE onhand <= rop
  " );
    $sth->execute;
    print MAIL $template_top;
    while ( ( $partnumber, $description, $avail, $rop ) = $sth->fetchrow_array )
    {
        write MAIL;
    }
    print MAIL $template_foot;
    close MAIL;
}

__DATA__
Usage: notify-short <config-file>

This script connects a database and monitors onhand parts falling below
the rop (re-order point) number required. It responds to this condition by
sending e-mail to a configured mail address.

The exact condition the script responds to is when an AR or AP invoice occurs
and a part affected by the transaction is lower than the ROP.

An example configuration file is provided in the LedgerSMB repository under
doc/conf/notify-short.conf.pl.

