#!perl
# Database setup tests.

use Test2::V0;

use LedgerSMB;
use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::DBH;
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Admin;
use DBI;
use Plack::Request;

# This entire test suite will be skipped unless environment
# variable LSMB_TEST_DB is true
defined $ENV{LSMB_TEST_DB} or plan skip_all => 'LSMB_TEST_DB is not set';

# LSMB_NEW_DB must always be set for these tests to run. It specifies
# the database used in running these tests. Unless LSMB_INSTALL_DB is true,
# the database will be created when this test is run and later dropped
# by xt/89-dropdb.t
$ENV{LSMB_NEW_DB} or bail_out('LSMB_NEW_DB is not set');

my $temp = $ENV{TEMP} || '/tmp/';

$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
#$LedgerSMB::Sysconfig::db_namespace = 'altschema';

my $db = LedgerSMB::Database->new({
         dbname       => $ENV{LSMB_NEW_DB},
         username     => $ENV{PGUSER},
         password     => $ENV{PGPASSWORD},
});

# Manual tests
ok($db->create, 'Database Created')
  || bail_out('Database could not be created! ');
ok($db->load_base_schema, 'Basic schema loaded');
ok($db->apply_changes, 'applied changes');

my $patch_log_dbh = $db->connect;
my $patch_log_sth =
    $patch_log_dbh->prepare('select count(*) from db_patch_log')
    or bail_out $patch_log_dbh->errstr;
$patch_log_sth->execute or bail_out $patch_log_sth->errstr;
my ($log_count) = $patch_log_sth->fetchrow_array;
ok(($log_count > 1), 'Applied patches are logged');

$patch_log_sth =
    $patch_log_dbh->prepare('select count(*) from db_patches')
    or bail_out $patch_log_dbh->errstr;
$patch_log_sth->execute or bail_out $patch_log_sth->errstr;
my ($patch_count) = $patch_log_sth->fetchrow_array;
ok(($patch_count > 1), 'Applied patches are recorded in db_patches table');
is($patch_count, $log_count, 'Patch and log counts are equal; all patches apply first time around');
ok($db->load_modules('LOADORDER'), 'Modules loaded');
$patch_log_sth->finish;
$patch_log_dbh->disconnect; # Without disconnecting, the copy below fails...

my $version;
my $dbh = $db->connect;
$version = LedgerSMB::DBH->require_version($dbh, $LedgerSMB::VERSION);
$dbh->disconnect;
ok(! $version,
   q{Database matches required version ('require_version' returns false)})
        or bail_out(q{LedgerSMB::DBH reports incorrect database version - no use continuing});


if (!$ENV{LSMB_INSTALL_DB}){

    # This lock file is used by xt/89-dropdb.t to determine
    # whether to drop LSMB_TEST_DB
    my $dblock_file = "$temp/LSMB_TEST_DB";
    open (my $DBLOCK, '>', $dblock_file)
        or bail_out("failed to open $dblock_file for writing : $!");
    print $DBLOCK $ENV{LSMB_NEW_DB}
        or bail_out("failed writing to $dblock_file : $!");
    close ($DBLOCK)
        or bail_out("failed to close $dblock_file after writing $!");
}

# Validate that we can copy the database
my $copy = $db->copy($ENV{LSMB_NEW_DB} . '_copy');
ok($copy, 'Copy database');
my $copy_dbh = (LedgerSMB::Database->new(
                    dbname       => $ENV{LSMB_NEW_DB} . '_copy',
                    username     => $ENV{PGUSER},
                    password     => $ENV{PGPASSWORD},
                ))->connect;
ok($copy_dbh, 'Connect to copy database');
my $copy_sth =
    $copy_dbh->prepare(q|select value from defaults
                          where setting_key='role_prefix'|);
ok($copy_sth, 'Prepare validation statement');
$copy_sth->execute();
my ($role_prefix) =
    @{$copy_sth->fetchrow_arrayref()};
is($role_prefix, "lsmb_$ENV{LSMB_NEW_DB}__",
   'Correct role prefix on copy-database');
$copy_sth->finish;
$copy_dbh->disconnect;

# Validate that a database which already has a role prefix
# maintains that role prefix
my $copy_copy = (LedgerSMB::Database->new(
                     dbname       => $ENV{LSMB_NEW_DB} . '_copy',
                     username     => $ENV{PGUSER},
                     password     => $ENV{PGPASSWORD},
                 ))->copy($ENV{LSMB_NEW_DB} . '_copy_copy');
ok($copy_copy, 'Copy copy-database');
$copy_dbh = (LedgerSMB::Database->new(
                 dbname       => $ENV{LSMB_NEW_DB} . '_copy_copy',
                 username     => $ENV{PGUSER},
                 password     => $ENV{PGPASSWORD},
             ))->connect;
ok($copy_dbh, 'Connect to copy copy-database');
$copy_sth =
    $copy_dbh->prepare(q|select value from defaults
                          where setting_key='role_prefix'|);
ok($copy_sth, 'Prepare validation statement');
$copy_sth->execute();
($role_prefix) =
    @{$copy_sth->fetchrow_arrayref()};
is($role_prefix, "lsmb_$ENV{LSMB_NEW_DB}__",
   'Correct role prefix on copy of copy-database');
$copy_sth->finish;
$copy_dbh->disconnect;

{
    my $dbh = $db->connect;
    $dbh->do(qq|DROP DATABASE "$ENV{LSMB_NEW_DB}_copy"|);
    $dbh->do(qq|DROP DATABASE "$ENV{LSMB_NEW_DB}_copy_copy"|);
}

#Changed the COA and GIFI loading to use this, and move admin user to
#Database.pm --CT

SKIP: {
     skip 'No admin info', 5
           if (!defined $ENV{LSMB_ADMIN_USERNAME}
                or !defined $ENV{LSMB_ADMIN_PASSWORD}
                or !defined $ENV{LSMB_COUNTRY_CODE}
                or !defined $ENV{LSMB_ADMIN_FNAME}
                or !defined $ENV{LSMB_ADMIN_LNAME});
     # Move to LedgerSMB::DBObject::Admin calls.
     my $request = Plack::Request->new({});
     my $lsmb = LedgerSMB->new($request);
     ok(defined $lsmb, '$lsmb defined');
     isa_ok($lsmb, 'LedgerSMB');
     $lsmb->{dbh} = DBI->connect("dbi:Pg:dbname=$ENV{PGDATABASE}",
                                       undef, undef, { AutoCommit => 0 });
     my $dbh = $lsmb->{dbh};
     ok($dbh, 'Connected to new database');
     my $sth = $dbh->prepare("select id from country where short_name ilike ?");
     $sth->execute($ENV{LSMB_COUNTRY_CODE});
     my ($id) = $sth->fetchrow_array();
     $sth->finish;
     $lsmb->merge({username   => $ENV{LSMB_ADMIN_USERNAME},
                   password   => $ENV{LSMB_ADMIN_PASSWORD},
                   first_name => $ENV{LSMB_ADMIN_FNAME},
                   last_name  => $ENV{LSMB_ADMIN_LNAME},
                   country_id => $id,
                   import     => 't',
                 });
      my $user = LedgerSMB::DBObject::Admin->new(%$lsmb);
      ok($user->save_user, 'User saved');
      $sth = $dbh->prepare("SELECT admin__add_user_to_role(?, ?)");
      my $rolename = "lsmb_" . $ENV{PGDATABASE} . "__users_manage";
      ok($sth->execute($ENV{LSMB_ADMIN_USERNAME}, $rolename),
            'Admin user assigned rights');
      $sth->finish;
      $dbh->commit;
};


SKIP: {
     skip 'No COA specified', 1 if !defined $ENV{LSMB_LOAD_COA};
     is($db->exec_script({script => 'sql/coa/'
                                     . lc($ENV{LSMB_COUNTRY_CODE})
                                     ."/chart/$ENV{LSMB_LOAD_COA}.sql"
                         }), 0,
        'Ran Chart of Accounts Script');
}

SKIP: {
     skip 'No GIFI specified', 1 if !defined $ENV{LSMB_LOAD_GIFI};
     is($db->exec_script({script => 'sql/coa/'
                                   . lc($ENV{LSMB_COUNTRY_CODE})
                                    ."/gifi/$ENV{LSMB_LOAD_GIFI}.sql"
                         }), 0,
        'Ran GIFI Script');
}

done_testing;
