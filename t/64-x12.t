#!perl

# X12 tests for LedgerSMB 1.4
#
# This provides a few very basic tests for parsing X12 docs
# These include parsing the current test files, and creating 997 docs in 
# response.
#
use Test::More;
use LedgerSMB::Form;
eval {
require LedgerSMB::X12;
require LedgerSMB::X12::EDI850;
require LedgerSMB::X12::EDI894;
};
plan skip_all => 'X12::Parser not installed' if $@;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

plan tests => 5;


my $e850t1 = LedgerSMB::X12::EDI850->new(message => 't/data/sample_po.edi');
#print Dumper($e850t1->order) . "\n";
is($e850t1->order->{transdate}, '2009-05-08', 'Valid EDI 1, order date 2009-05-08');
is($e850t1->order->{ordnumber}, '99AKDF9DAL393', 'valid EDI 1, ordnumber 99AKDF9DAL393'); 
is($e850t1->order->{qty_1}, 100, 'Valid EDI 1, First line item quantity of 100');
is($e850t1->order->{sellprice_1}, '100.00', 'Sell price of 100.00 for first line item');
is($e850t1->order->{description_1}, 'GENERAL PURPOSE', 'Correct EDI description for line item 1');

my $e850t2 = LedgerSMB::X12::EDI850->new(message => 't/data/sample_po1.edi');

#print Dumper($e850t2->order) . "\n";

