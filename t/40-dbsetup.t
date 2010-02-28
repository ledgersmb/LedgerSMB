# Database setup tests.

use Test::More;
use strict;

my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 1;
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB PG_CONTRIB_DIR)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
      plan skipall => "$evar not set";
  }
}

if ($run_tests){
	plan tests => 25;
	$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
}

# Manual tests
open (CREATEDB, '-|', 'createdb');

cmp_ok(<CREATEDB>, 'eq', "CREATE DATABASE\n", 'Database Created') 
|| BAIL_OUT('Database could not be created!');

close(CREATEDB);

if (!$ENV{LSMB_INSTALL_DB}){
    open (DBLOCK, '>', "$temp/LSMB_TEST_DB");
    print DBLOCK $ENV{LSMB_NEW_DB};
    close (DBLOCK);
}

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

    (open (PSQL, '-|', "psql -f sql/modules/$mod")&& pass("$mod loaded"))
      || fail("$mod loaded");
    my $test = 0;
    while (my $line = <PSQL>){
        chomp($line);
        if ($line eq 'COMMIT'){
            $test = 1;
        }
    }
    close(PSQL);
}
close (LOADORDER);

# Roles processing for later permission tests and db install.
open (PSQL, '|-', "psql");

(open (ROLES, '<', 'sql/modules/Roles.sql') && pass("Roles description found"))
|| fail("Roles description found");

print PSQL "BEGIN;\n";
for my $roleline (<ROLES>){
    $roleline =~ s/<?lsmb dbname ?>/$ENV{LSMB_NEW_DB}/;
    print PSQL $roleline;
}
print PSQL "COMMIT;\n";
