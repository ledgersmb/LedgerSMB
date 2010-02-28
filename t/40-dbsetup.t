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
	plan tests => 5;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}
else {
	plan skip_all => 'Skipping all.  Told not to test db.';
}

# Manual tests
open (CREATEDB, '-|', 'createdb');

cmp_ok(<CREATEDB>, 'eq', "CREATE DATABASE\n", 'Database Created') 
|| BAIL_OUT('Database could not be created!');

close(CREATEDB);

my @contrib_scripts = qw(pg_trgm tsearch2 tablefunc);

for my $contrib (@contrib_scripts){
    open (PSQL, '-|', "psql -f $ENV{PG_CONTRIB_DIR}/$contrib.sql");
    my $test = 0;
    while (my $line = <PSQL>){
        chomp($line);
        if ($line eq 'COMMIT'){
            $test = 1;
        }
    }
    if ($contrib eq 'tablefunc'){
        $test = '1';
    }
    cmp_ok($test, 'eq', '1', "$contrib loaded and committed");
    close(PSQL);
}


open (PSQL, '-|', "psql -f sql/Pg-database.sql");
my $test = 0;
while (my $line = <PSQL>){
    chomp($line);
    if ($line eq 'COMMIT'){
        $test = 1;
    }
    if ($line =~ /error/i){
        $test = 0;
    }
}
cmp_ok($test, 'eq', '1', "DB Schema loaded and committed");
close(PSQL);

open (LOADORDER, '<', 'sql/modules/LOADORDER');
for my $mod (<LOADORDER>){
    chomp($mod);
    $mod =~ s/#.*//;
    $mod =~ s/^\s*//;
    $mod =~ s/\s*$//;
    next if $mod eq '';

    open (PSQL, '-|', "psql -f sql/modules/$mod")&& pass("$mod loaded and committed");
    my $test = 0;
    while (my $line = <PSQL>){
        chomp($line);
        if ($line eq 'COMMIT'){
            $test = 1;
        }
    }
    close(PSQL);
}
close (LOADORDER)
