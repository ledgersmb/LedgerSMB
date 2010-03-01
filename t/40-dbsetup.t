# Database setup tests.

use Test::More;
use strict;
use DBI;

my $temp = $ENV{TEMP} || '/tmp/';
my $run_tests = 1;
for my $evar (qw(LSMB_NEW_DB LSMB_TEST_DB PG_CONTRIB_DIR)){
  if (!defined $ENV{$evar}){
      $run_tests = 0;
      plan skip_all => "$evar not set";
  }
}

if ($run_tests){
	plan tests => 29;
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
    $roleline =~ s/<\?lsmb dbname \?>/$ENV{LSMB_NEW_DB}/;
    print PSQL $roleline;
}

print PSQL "COMMIT;\n";
close (PSQL);
SKIP: {
     skip 'No admin info', 4
           if (!defined $ENV{LSMB_USERNAME} 
                or !defined $ENV{LSMB_PASSWORD}
                or !defined $ENV{LSMB_COUNTRY_CODE}
                or !defined $ENV{LSMB_ADMIN_FNAME}
                or !defined $ENV{LSMB_ADMIN_LNAME});
     my $dbh = DBI->connect("dbi:Pg:dbname=$ENV{PGDATABASE}", 
                                       undef, undef);
     ok($dbh, 'Connected to new database');
     $dbh->{autocommit} = 1;
     my $sth = $dbh->prepare(
              "SELECT admin__save_user(NULL, -- no user id yet, create new user
                                       person__save(NULL, -- create new person
                                                    NULL,
                                                    ?, -- First Name
                                                    NULL,
                                                    ?, -- Last Name
                                                    (select id from country
                                                    where short_name = ?) 
                                       ),
                                       ?, -- Username desired
                                       ? -- password
                       )");
      ok($sth->execute($ENV{LSMB_ADMIN_FNAME}, 
              $ENV{LSMB_ADMIN_LNAME}, 
              $ENV{LSMB_COUNTRY_CODE},
              $ENV{LSMB_USERNAME},
              $ENV{LSMB_PASSWORD}), 'Admin user creation query ran');
      my ($var) = $sth->fetchrow_array();
      cmp_ok($var, '>', 0, 'User id retrieved');
      $sth->finish;
      $sth = $dbh->prepare("SELECT admin__add_user_to_role(?, ?)");
      my $rolename = "lsmb_" . $ENV{PGDATABASE} . "__users_manage";
      ok($sth->execute($ENV{LSMB_USERNAME}, $rolename), 
            'Admin user assigned rights');
      $sth->finish;
};
