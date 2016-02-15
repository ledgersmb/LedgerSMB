use Test::More;
use strict;

if (!defined $ENV{LSMB_TEST_DB}){
	plan skip_all => 'Skipping all.  Told not to test db.';
}
else {
	plan tests => 467;
	if (defined $ENV{LSMB_NEW_DB}){
		$ENV{PGDATABASE} = $ENV{LSMB_NEW_DB};
	}
	if (!defined $ENV{PGDATABASE}){
		die "We were told to run tests, but no database specified!";
        }
}

my @testscripts = qw(Account Reconciliation Business_type Company Draft Payment
			Session Voucher System Taxform COGS-FIFO PNL Report Roles);


chdir 'sql/modules/test/';

for my $testscript (@testscripts){
	open (TEST, '-|', "psql -f $testscript.sql");
	my @testlines = grep /\|\s+(t|f)\s?$/, <TEST>;
	cmp_ok(scalar @testlines, '>', 0, "$testscript.sql returned test results");
	for my $test (@testlines){
		my @parts = split /\|/, $test;
		like($parts[1], qr/t\s?$/, $parts[0]);
	}
}

