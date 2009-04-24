use LedgerSMB::DBObject;
use Test::More tests => 21;

# Array parsing tests
my $test = '{test,"test2\"\",",test3,"test4"}';
my @vals = ('test', 'test2"",', 'test3', 'test4');
my @vals2 = ('test', 'test2"",', 'test3', 'test4');

is(LedgerSMB::DBObject->_db_array_scalars(@vals2), '{test,"test2\"\"\,",test3,test4}', '_db_array_scalars creates correct array');

my $passes = 0;
for (LedgerSMB::DBObject->_parse_array($test)){
  is($_, shift @vals, "pass $pass, array parse test");
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
