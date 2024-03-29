use Test2::V0;
use warnings;
use strict;

use LedgerSMB::FileFormats::OFX::BankStatement;

my $filename = 't/data/inout_tests/ofx_bank_statement.xml';
open my $fh, '<', $filename
    or die "failed to open $filename for reading";
my $ofx = LedgerSMB::FileFormats::OFX::BankStatement->new($fh);

ok($ofx, 'Parse of OFX bank statement file returned true');
is(scalar @{$ofx->transactions}, 3, 'correct number of transaction items');
is(
    $ofx->transactions,
    [
        {
            amount => 26.59,
            cleared_date => '20200220',
            scn => 'SUPPLIER ONE',
            type => 'OFX FITID:202002202659117123782934'
        },
        {
            amount => -25.00,
            cleared_date => '20200302',
            scn => 'CUSTOMER ONE',
            type => 'OFX FITID:202003022500117148782934'
        },
        {
            amount => 6.50,
            cleared_date => '20200304',
            scn => 'TOTAL CHARGES TO 11FEB2020',
            type => 'OFX FITID:20200304650116645202934'
        },
    ],
    'Yielded expected transactions'
);

open $fh, '<', \'<?xml>'
     or die 'Failed to open string for reading';
ok(
    !LedgerSMB::FileFormats::OFX::BankStatement->new($fh),
    'Detected wrong data format'
);

done_testing;
