#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use DBI;
use Plack::Util;
use LedgerSMB::old_code qw(dispatch_no_commit);

plan skip_all => 'Database tests not enabled' unless $ENV{LSMB_TEST_DB};

my $dbh = DBI->connect('dbi:Pg:dbname=' . $ENV{LSMB_NEW_DB}, undef, undef,
                      { AutoCommit => 0, RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TEMP TABLE legacy_render_transaction_test (value int)');
$dbh->commit;
$dbh->do('INSERT INTO legacy_render_transaction_test VALUES (1)');
my $result = dispatch_no_commit('io.pl', sub {
    print "Content-Type: text/plain\n\nprepared";
}, { language => 'en' }, { dbh => $dbh, __action => 'prepare' });
is $result->[0], 200, 'Legacy rendering returned successfully';
my $output = '';
Plack::Util::foreach($result->[2], sub { $output .= $_[0] });
is $output, 'prepared', 'Renderer output returned to parent';
$dbh->rollback;
is $dbh->selectrow_array('SELECT count(*) FROM legacy_render_transaction_test'), 0,
    'Renderer did not commit the parent transaction';
$dbh->disconnect;
done_testing;
