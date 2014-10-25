use Test::More;
use strict;
use DBI;
    
my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 6;
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
      plan skip_all => "$evar not set";
  }
}
if ($ENV{LSMB_INSTALL_DB}){
   $run_tests = 0;
   plan skip_all => 'LSMB_INSTALL_DB SET';
}

if ($run_tests){
	plan tests => $run_tests;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}

ok(open (DBLOCK, '<', "$temp/LSMB_TEST_DB"), 'Opened db lock file')
  || BAIL_OUT("could not open lock file: \$!=$!, \$@=$@");
my $db = <DBLOCK>;
chomp($db);
cmp_ok($db, 'eq', $ENV{LSMB_NEW_DB}, 'Got expected db name out') &&
ok(!system ("dropdb $ENV{LSMB_NEW_DB}"), 'dropped db');
ok(close (DBLOCK), 'Closed db lock file');
ok(unlink ("$temp/LSMB_TEST_DB"), 'Removed test db lockfile');


my $dbh = DBI->connect("dbi:Pg:dbname=template1",
                                       undef, undef, { AutoCommit => 0 });

my $sth_getroles = $dbh->prepare(
                           "select quote_ident(rolname) as role 
                              FROM pg_roles 
                             WHERE rolname LIKE ?");

$sth_getroles->execute("lsmb_$ENV{LSMB_NEW_DB}__%");

my $rc = 0;
while (my $ref = $sth_getroles->fetchrow_hashref('NAME_lc')){
    $dbh->do("drop role ".$ref->{role}) || ++$rc;
}

$dbh->commit;

is($rc, 0, 'Roles dropped');

