
use strict;
use warnings;

use DBI;
use Test::More;


use LedgerSMB::Database;
use LedgerSMB;
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Admin;


plan skip_all => 'LSMB_TEST_DB not set'
    if not $ENV{LSMB_TEST_DB};


my $db;

#
#
#
#  Object instantiation test
#

my %options = (
    dbname       => 'dbname',
    username     => 'username',
    password     => 'password',
    source_dir   => 'source_dir'
    );

$db = LedgerSMB::Database->new(\%options);
for my $key (keys %options) {
    is($db->{$key}, $options{$key}, "Database creation option: $key");
}



done_testing;
