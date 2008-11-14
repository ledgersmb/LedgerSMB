use LedgerSMB::DBObject;
use Test::More tests => 5;

# Array parsing tests
my $test = '{test,"test2\"\",",test3,"test4"}';
my @vals = ('test', 'test2"",', 'test3', 'test4');
my $passes = 0;
for (LedgerSMB::DBObject->_parse_array($test)){
  is($_, shift @vals, "pass $pass, array parse test");
}

my $test2 = '{{1,1,1,1},{1,2,2,2}}';

my @test_arry2 = LedgerSMB::DBObject->_parse_array($test2);
is(scalar @test_arry2, 2, 'Compount array with proper element count');
