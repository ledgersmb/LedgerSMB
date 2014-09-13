# Database setup tests.

use Test::More;
use LedgerSMB::Database;
use LedgerSMB;
use LedgerSMB::Sysconfig;
use LedgerSMB::DBObject::Admin;
use strict;
use DBI;

if ($ENV{LSMB_INSTALL_DB} && !$ENV{LSMB_NEW_DB}){
   BAIL_OUT('Told to install db, but no LSMB_NEW_DB set.

HINT:  Set LSMB_NEW_DB environment variable and try running again.');
}

my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 1;
for my $log (qw(dblog dblog_stderr dblog_stdout)){
    unlink "$LedgerSMB::Sysconfig::tempdir/$log";
}
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
      plan skip_all => "$evar not set";
  }
}

if ($run_tests){
	plan tests => 11;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}

my $db = LedgerSMB::Database->new({
         countrycode  => $ENV{LSMB_COUNTRY_CODE},
         chart_name   => $ENV{LSMB_LOAD_COA},
         chart_gifi   => $ENV{LSMB_LOAD_GIFI},
         dbname       => $ENV{LSMB_NEW_DB},
         username     => $ENV{PGUSER},
         password     => $ENV{PGPASSWORD},
         source_dir   => $ENV{LSMB_SOURCE_DIR}
});

# Manual tests
ok($db->create, 'Database Created') 
  || BAIL_OUT('Database could not be created! ');
ok($db->load_base_schema, 'Basic schema loaded');

ok($db->load_modules('LOADORDER'), 'Modules loaded');
if (!$ENV{LSMB_INSTALL_DB}){
    open (DBLOCK, '>', "$temp/LSMB_TEST_DB");
    print DBLOCK $ENV{LSMB_NEW_DB};
    close (DBLOCK);
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
     my $lsmb = new LedgerSMB;
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
      my $user = LedgerSMB::DBObject::Admin->new({base => $lsmb});
      ok($user->save_user, 'User saved');
      $sth = $dbh->prepare("SELECT admin__add_user_to_role(?, ?)");
      my $rolename = "lsmb_" . $ENV{PGDATABASE} . "__users_manage";
      ok($sth->execute($ENV{LSMB_ADMIN_USERNAME}, $rolename), 
            'Admin user assigned rights');
      $sth->finish;
      $dbh->commit;
};

open  my $log, "< $LedgerSMB::Sysconfig::tempdir/dblog";

my $passed_no_errs = 1;
while (my $line = <$log>){
    last if $line =~ /Fixes/i; # Fixes roll back!
    $passed_no_errs = 0 if $line =~ /Rollback/i;
}

is($passed_no_errs, 1, 'No rollbacks in db scripts');

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

