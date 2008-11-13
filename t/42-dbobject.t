use LedgerSMB::DBObject;
use Test::More tests => 4;

# Array parsing tests
my $test = '{test,"test2\"\",",test3,"test4"}';
my @vals = ('test', 'test2"",', 'test3', 'test4');
my $passes = 0;
for (LedgerSMB::DBObject->_parse_array($test)){
  is($_, shift @vals, "pass $pass, array parse test");
}


