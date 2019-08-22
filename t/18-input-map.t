#!perl

use Test2::V0;

use LedgerSMB::Request::Helper::ParameterMap;


my $map;



$map = input_map(
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is $map->({ abc => 1, def => 2 }), { abc => 1, def => 2 },
    'Mapping one-to-one succeeds';


$map = input_map(
    [ qr/^abc$/ => '!' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is $map->({ abc => 1, def => 2 }), { def => 2 },
    'Ignoring key "abc" succeeds';


$map = input_map(
    [ qr/^abc$/ => '%ghi' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is $map->({ abc => 1, def => 2 }), { ghi => 1, def => 2 },
    'Rename key "abc" to "ghi" succeeds';


$map = input_map(
    [ qr/^abc$/ => '%ghi:%abc' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is $map->({ abc => 1, def => 2 }), { ghi => { abc => 1 }, def => 2 },
    'Nested static definition of hashes';

$map = input_map(
    [ qr/^(?<foo>abc)$/ => '%ghi:@klm<foo>:%a' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is $map->({ abc => 1, def => 2 }), {
    ghi => {
        klm => [
            {
                __row_id => 'abc',
                a => 1,
            },
            ] }, def => 2 },
    'Array contents';


like( dies {
$map = input_map(
    [ qr/^(?<foo>abc)$/ => 'a' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
          },
    qr/Unsupported targetspec definition/,
    'Incorrect $spec');

done_testing;
