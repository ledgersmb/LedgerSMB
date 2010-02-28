use Test::More;
use strict;

my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 5;
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB PG_CONTRIB_DIR LSMB_INSTALL_DB)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
      plan skipall => "$eval not set";
  }
}

if ($run_tests){
	plan tests => 5;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}

ok(open (DBLOCK, '<', "$temp/LSMB_TEST_DB"), 'Opened db lock file');
my $db = <DBLOCK>;
chomp($db);
ok(close (DBLOCK), 'Closed db lock file');
ok(open (DROPDB, '-|', "dropdb -d $db"), 'Opened drop db');
my $dropvar = <DROPDB>
chomp($dropvar);
cmp_ok($dropdb, 'eq', 'DROP DATABASE', 'Database dropped');
ok(unlink "$temp/LSMB_TEST_DB", 'Removed test db lockfile');
