
use Test2::V0;

use LedgerSMB::FileFormats::ISO20022::CAMT053;

my $file_content;
{
    local $/ = undef;
    my $filename = 't/data/inout_tests/campt053-sample.xml';
    open my $fh, '<', $filename
        or die "failed to open $filename for reading";
    $file_content = <$fh>;
}

my $camt = LedgerSMB::FileFormats::ISO20022::CAMT053->new(
    $file_content
);

ok($camt, 'Parse of camt file returned true');
ok(! LedgerSMB::FileFormats::ISO20022::CAMT053->new(
   '<?xml version="1.0" ?> <foo />'
), 'Autodetection of wrong xml type correct');

is(scalar $camt->lineitems_simple(), 10, 'correct number of line items, flattened');

done_testing;
