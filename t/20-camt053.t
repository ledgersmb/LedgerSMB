
use Test2::V0;

use LedgerSMB::FileFormats::ISO20022::CAMT053;

my $camt = LedgerSMB::FileFormats::ISO20022::CAMT053->new(
   't/data/inout_tests/campt053-sample.xml'
);

ok($camt, 'Parse of camt file returned true');
ok(! LedgerSMB::FileFormats::ISO20022::CAMT053->new(
   '<?xml version="1.0" ?> <foo />'
), 'Autodetection of wrong xml type correct');

is(scalar $camt->lineitems_full(), 10, 'correct number of line items, raw');
is(scalar $camt->lineitems_simple(), 10, 'correct number of line items, flattened');

done_testing;