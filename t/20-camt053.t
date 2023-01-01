
use Test2::V0;

use LedgerSMB::FileFormats::ISO20022::CAMT053;

my $filename = 't/data/inout_tests/campt053-sample.xml';
open my $fh, '<', $filename
    or die "failed to open $filename for reading";

my $camt = LedgerSMB::FileFormats::ISO20022::CAMT053->new($fh);

ok($camt, 'Parse of camt file returned true');
open $fh, '<', \'<?xml version="1.0" ?> <foo />'
     or die 'Failed to open string for reading';
ok(! LedgerSMB::FileFormats::ISO20022::CAMT053->new($fh),
 'Autodetection of wrong xml type correct');

is(scalar $camt->lineitems_simple(), 10, 'correct number of line items, flattened');

done_testing;
