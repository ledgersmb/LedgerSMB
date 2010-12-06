use Test::More;
use strict;

my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 6;
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
	plan tests => 6;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}

ok(open (DBLOCK, '<', "$temp/LSMB_TEST_DB"), 'Opened db lock file');
my $db = <DBLOCK>;
chomp($db);
cmp_ok($db, 'eq', $ENV{LSMB_NEW_DB}, 'Got expected db name out') &&
ok(!system ("dropdb $ENV{LSMB_NEW_DB}"), 'dropped db');
ok(close (DBLOCK), 'Closed db lock file');
ok(unlink ("$temp/LSMB_TEST_DB"), 'Removed test db lockfile');

# We clean up the test DB roles.
open (PSQL, '|-', "psql");

(open (ROLES, '<', 'sql/modules/test/Drop_Roles.sql') && pass("Roles description found"))
|| fail("Roles description found");

for my $roleline (<ROLES>){
        $roleline =~ s/<\?lsmb dbname \?>/$ENV{LSMB_NEW_DB}/;
            print PSQL $roleline;
        }

close (PSQL);
