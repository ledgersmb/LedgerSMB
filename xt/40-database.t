#!perl
# HARNESS-DURATION-SHORT

use Test2::V0;

use DBI;

use LedgerSMB::Database;
use LedgerSMB;
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Admin;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

skip_all( 'LSMB_TEST_DB not set' )
    if not $ENV{LSMB_TEST_DB};

LedgerSMB::Sysconfig->initialize( $ENV{LSMB_CONFIG_FILE} // 'ledgersmb.conf' );

my $db;
my $admin_dbh = DBI->connect('dbi:Pg:dbname=postgres',
                             undef, undef, { AutoCommit => 1 })
    or die 'Cannot set up master connection';


#
#
#
#  Database creation throws an exception when the file Pg-database.sql
#    doesn't exist
#


#
# missing schema file
#
$admin_dbh->do(q{set client_min_messages = 'warning'});
$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new(
    connect_data => {
        dbname     => 'lsmbtest_database',
        user       => $ENV{PGUSER},
        password   => $ENV{PGPASSWORD},
    },
    source_dir => './xt/data'
    );
like( dies { $db->create_and_load; },
          qr/(APPLICATION ERROR|Specified file does not exist)/,
    'Database creation fails on missing schema file');

#
# missing schema file's directory
#
$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new(
    connect_data => {
        dbname     => 'lsmbtest_database',
        user       => $ENV{PGUSER},
        password   => $ENV{PGPASSWORD},
    },
    source_dir => './xt/data/missing-directory'
    );
like( dies { $db->create_and_load; },
          qr/(APPLICATION ERROR|Specified file does not exist)/,
     'Database creation fails on missing schema');



#
#
#
#  Database creation fails when the defaults table does not exist
#

# We'll load a schema without a defaults table to simulate the failure

$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new(
    connect_data => {
        dbname     => 'lsmbtest_database',
        user       => $ENV{PGUSER},
        password   => $ENV{PGPASSWORD},
    },
    source_dir => './xt/data/40-database/no-defaults-table'
    );
like( dies { $db->create_and_load; }, qr/Base schema failed to load/,
    'Database creation fails on missing defaults table');



#
#
#
#  Database creation fails when the schema file fails to load
#

$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new(
    connect_data => {
        dbname     => 'lsmbtest_database',
        user       => $ENV{PGUSER},
        password   => $ENV{PGPASSWORD},
    },
    source_dir => './xt/data/40-database/schema-failure'
    );
like( dies { $db->create_and_load; },
          qr/(ERROR:\s*relation "defal" does not exist|error running (command|file))/,
    'Database creation fails on base schema load failure');



#
#
#
#  Database creation fails when a module fails to load
#


$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new(
    connect_data => {
        dbname     => 'lsmbtest_database',
        user       => $ENV{PGUSER},
        password   => $ENV{PGPASSWORD},
    },
    source_dir => './xt/data/40-database/module-failure-1'
    );
like( dies { $db->create_and_load; }, qr/Module FaultyModule.sql failed to load/,
    'Database creation fails when a module fails to load (empty module)');



$admin_dbh->do(q{DROP DATABASE IF EXISTS lsmbtest_database});
$db = LedgerSMB::Database->new(
    connect_data => {
        dbname     => 'lsmbtest_database',
        user       => $ENV{PGUSER},
        password   => $ENV{PGPASSWORD},
    },
    source_dir => './xt/data/40-database/module-failure-2'
    );
like( dies { $db->create_and_load; },
        qr/(ERROR:\s*function "fail_me" already exists|error running command)/,
    'Database creation fails when a module fails to load (syntax error)');




# No need to test full database loading: that happens in xt/40-dbsetup.t

done_testing;
