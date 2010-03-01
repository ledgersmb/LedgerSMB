use Test::More;
use strict;

my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 5;
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB PG_CONTRIB_DIR)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
      plan skip_all => "$evar not set";
  }
}
if ($ENV{LSMB_INSTALL_DB}){
   plan skip_all => 'LSMB_INSTALL_DB SET';
}

if ($run_tests){
	plan tests => 5;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}

ok(open (DBLOCK, '<', "$temp/LSMB_TEST_DB"), 'Opened db lock file');
my $db = <DBLOCK>;
chomp($db);
cmp_ok($db, 'eq', $ENV{LSMB_NEW_DB}, 'Got expected db name out');
ok(close (DBLOCK), 'Closed db lock file');
ok(!system ("dropdb $ENV{LSMB_NEW_DB}"), 'dropped db');
ok(unlink ("$temp/LSMB_TEST_DB"), 'Removed test db lockfile');
