
use strict;
use warnings;

use DBI;
use Test::Exception;
use Test::More;


use LedgerSMB::Database;
use LedgerSMB;
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Admin;


plan skip_all => 'LSMB_TEST_DB not set'
    if not $ENV{LSMB_TEST_DB};


my $db;
my $admin_dbh = DBI->connect('dbi:Pg:dbname=postgres',
                             undef, undef, { AutoCommit => 1 })
    or die 'Cannot set up master connection';

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


#
#
#
#  Database creation throws an exception when the file Pg-database.sql
#    doesn't exist
#


#
# missing schema file
#
$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new({
    dbname     => 'lsmbtest_database',
    username   => $ENV{PGUSER},
    password   => $ENV{PGPASSWORD},
    source_dir => './xt/data'
                               });
throws_ok { $db->create_and_load }
          qr/(APPLICATION ERROR|Specified file does not exist)/,
    'Database creation fails on missing schema file';

#
# missing schema file's directory
#
$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new({
    dbname     => 'lsmbtest_database',
    username   => $ENV{PGUSER},
    password   => $ENV{PGPASSWORD},
    source_dir => './xt/data/missing-directory'
                               });
throws_ok { $db->create_and_load }
          qr/(APPLICATION ERROR|Specified file does not exist)/,
     'Database creation fails on missing schema';



#
#
#
#  Database creation fails when the defaults table does not exist
#

# We'll load a schema without a defaults table to simulate the failure

$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new({
    dbname     => 'lsmbtest_database',
    username   => $ENV{PGUSER},
    password   => $ENV{PGPASSWORD},
    source_dir => './xt/data/40-database/no-defaults-table'
                               });
throws_ok { $db->create_and_load } qr/Base schema failed to load/,
    'Database creation fails on missing defaults table';



#
#
#
#  Database creation fails when the schema file fails to load
#

$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new({
    dbname     => 'lsmbtest_database',
    username   => $ENV{PGUSER},
    password   => $ENV{PGPASSWORD},
    source_dir => './xt/data/40-database/schema-failure'
                               });
throws_ok { $db->create_and_load }
          qr/(ERROR:\s*relation "defal" does not exist|error running command)/,
    'Database creation fails on base schema load failure';



#
#
#
#  Database creation fails when a module fails to load
#


$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new({
    dbname     => 'lsmbtest_database',
    username   => $ENV{PGUSER},
    password   => $ENV{PGPASSWORD},
    source_dir => './xt/data/40-database/module-failure-1'
                               });
throws_ok { $db->create_and_load } qr/Module FaultyModule.sql failed to load/,
    'Database creation fails when a module fails to load (empty module)';



$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new({
    dbname     => 'lsmbtest_database',
    username   => $ENV{PGUSER},
    password   => $ENV{PGPASSWORD},
    source_dir => './xt/data/40-database/module-failure-2'
                               });
throws_ok { $db->create_and_load }
        qr/(ERROR:\s*function "fail_me" already exists|error running command)/,
    'Database creation fails when a module fails to load (syntax error)';




# No need to test full database loading: that happens in xt/40-dbsetup.t

done_testing;
