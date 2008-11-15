use Test::More;
use strict;

if (!defined $ENV{PGDATABASE}){
	plan skip_all => 'PGDATABASE Environment Variable not set up';
}
else {
	plan tests => 50;
}

my @testscripts = qw(Account Business_type Company Draft Payment 
			Session Voucher);

chdir 'sql/modules/test/';

for my $testscript (@testscripts){
	open (TEST, '-|', "psql -f $testscript.sql");
	my @testlines = grep /\|\s+(t|f)\s?$/, <TEST>;
	cmp_ok(scalar @testlines, '>', 0, "$testscript.sql returned test results");
	for my $test (@testlines){
		my @parts = split /\|/, $test;
		like($parts[1], qr/t/, $parts[0]);
	}
}
