#!/usr/bin/perl

# This is the SL-Short listener.  It listens for the "parts_short" signal and
# when the signal comes in, prepares a list of short parts to be sent to
# at least one person.
#
# By Chris Travers, Metatron Technology Consulting
# chris@metatrontech.com
#
# Released under the GNU GPL v2.0 or later.  See included GPL.txt for more
# information.

require "config.pl";

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

