#!perl

use Test::More no_plan;
use Test::Exception;

use LedgerSMB::Request::Helper::ParameterMap;


my $map;



$map = input_map(
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is_deeply $map->({ abc => 1, def => 2 }), { abc => 1, def => 2 },
    'Mapping one-to-one succeeds';


$map = input_map(
    [ qr/^abc$/ => '!' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is_deeply $map->({ abc => 1, def => 2 }), { def => 2 },
    'Ignoring key "abc" succeeds';


$map = input_map(
    [ qr/^abc$/ => '%ghi' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is_deeply $map->({ abc => 1, def => 2 }), { ghi => 1, def => 2 },
    'Rename key "abc" to "ghi" succeeds';


$map = input_map(
    [ qr/^abc$/ => '%ghi:%abc' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is_deeply $map->({ abc => 1, def => 2 }), { ghi => { abc => 1 }, def => 2 },
    'Nested static definition of hashes';

$map = input_map(
    [ qr/^(?<foo>abc)$/ => '%ghi:@klm<foo>:%a' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
is_deeply $map->({ abc => 1, def => 2 }), {
    ghi => {
        klm => [
            {
                __row_id => 'abc',
                a => 1,
            },
            ] }, def => 2 },
    'Array contents';


throws_ok(sub {
$map = input_map(
    [ qr/^(?<foo>abc)$/ => 'a' ],
    [ qr/^(?<key>.+)$/ => '%<key>' ]
    );
          },
    qr/Unsupported targetspec definition/,
    'Incorrect $spec');
