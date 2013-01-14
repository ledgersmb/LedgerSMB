use LedgerSMB::DBObject;
use Test::More tests => 25;

# Array parsing tests
my $test =  '{test,"test2\"\",",test3,"test4"}';
my @test_dbarrays = (
   '{{1268133,9648645,2010-06-30,49753.500,0.000,0.00000000000000000000,49753.50000000000000000000,1,0},{1302678,9648659,2010-06-30,850.000,0.000,0.00000000000000000000,850.00000000000000000000,1,0},{1397340,9648659,2010-06-30,-850,0,0.00000000000000000000,-850.00000000000000000000,1,0},{1397341,9648645,2010-06-30,-49753.5,0.0,0.00000000000000000000,-49753.50000000000000000000,1,0}}',
   '{{1410396,PD-060810,2010-06-08,150,0,0.00000000000000000000,150.00000000000000000000,1,0}}',
   '{{1410389,ABCD*10K,2010-06-01,331.46,0.00,0.00000000000000000000,331.46000000000000000000,1,0}}',
   '{{1415588,T/D#QA2GG9-0980,2010-06-16,61033.33,0.00,0.00000000000000000000,61033.33000000000000000000,1,0}}',
);

for my $t (@test_dbarrays){
   my @r = LedgerSMB::DBObject->_parse_array($t);
   is($r[0]->[8], '0', "$r[0]->[0] passed");
}

my @vals = ('test', 'test2"",', 'test3', 'test4');
my @vals2 = ('test', 'test2"",', 'test3', 'test4');

is(LedgerSMB::DBObject->_db_array_scalars(@vals2), '{test,"test2\"\"\,",test3,test4}', '_db_array_scalars creates correct array');

my $passes = 0;
for (LedgerSMB::DBObject->_parse_array($test)){
  is($_, shift @vals, "pass $passes, array parse test");
}
my $test2 = '{{1,1,1,1},{1,2,2,2},{1,3,3,4}}';
my @test_arry2_c = ( [1,1,1,1], [1,2,2,2], [1,3,3,4]);
my @test_arry2 = LedgerSMB::DBObject->_parse_array($test2);
is(scalar @test_arry2, 3, 'Compount array with proper element count');
is(scalar @{$test_arry2[0]}, 4, 'Subarray 1 has correct element count');
is(scalar @{$test_arry2[1]}, 4, 'Subarray 2 has correct element count');
is(scalar @{$test_arry2[2]}, 4, 'Subarray 3 has correct element count');
for my $outer(0 .. 2){
    for my $inner(0 .. 3) {
         is ($test_arry2[$outer]->[$inner], $test_arry2_c[$outer]->[$inner], 
		"Compound array $outer/$inner correct");
    }
}
