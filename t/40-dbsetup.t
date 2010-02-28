# Database setup tests.

use Test::More;
use LedgerSMB::Form;
use strict;

#util functions

# sub ok_or_die($name, $success)
# if $success is true, then pass.
# else bail out.

my $run_tests = 1;
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB PG_CONTRIB_DIR)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
  }
}

if ($run_tests){
	plan tests => 2;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}
else {
	plan skip_all => 'Skipping all.  Told not to test db.';
}

# Manual tests
open (CREATEDB, '-|', 'createdb');
ok_cmp(<CREATEDB>, 'eq', "CREATE DATABASE\n") || BAIL_OUT('Database could not be created!');
close(CREATEDB);
