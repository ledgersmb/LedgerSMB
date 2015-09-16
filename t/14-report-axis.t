#!/usr/bin/perl

use Test::More (tests => 10);
use strict;
use warnings;

use LedgerSMB::Report::Axis;

my $axis = LedgerSMB::Report::Axis->new;

ok($axis->map_path(['a']) == 1, 'one-element path');
ok($axis->map_path(['b']) == 2, 'second one-element path');
ok($axis->map_path(['b','c']) == 3, 'sub-item of existing element');
ok($axis->map_path(['b','c','d','f']) == 5, 'sub path of existing path');
ok($axis->map_path(['b','c','d','e']) == 6, 'second leaf in existing path');

is_deeply($axis->sort(), [1, 2, 3, 4, 6, 5], 'tree-order sorted row-IDs');
is_deeply($axis->tree(),
          {
              'a' => {
                  'children' => {},
                  'accno' => 'a',
                  'path' => ['a'],
                  'id' => 1,
                  'parent_id' => undef,
              },
              'b' => {
                  'path' => ['b'],
                  'accno' => 'b',
                  'parent_id' => undef,
                  'children' => {
                      'c' => {
                          'path' => ['b','c'],
                          'accno' => 'c',
                          'parent_id' => 2,
                          'children' => {
                              'd' => {
                                  'path' => ['b','c','d'],
                                  'accno' => 'd',
                                  'parent_id' => 3,
                                  'children' => {
                                      'e' => {
                                          'path' => ['b','c','d','e'],
                                          'accno' => 'e',
                                          'parent_id' => 4,
                                          'children' => {},
                                          'id' => 6
                                      },
                                      'f' => {
                                          'path' => ['b','c','d','f'],
                                          'accno' => 'f',
                                          'parent_id' => 4,
                                          'children' => {},
                                          'id' => 5
                                      }
                                  },
                                  'id' => 4
                              }
                          },
                          'id' => 3
                      }
                  },
                  'id' => 2
              }
          },
          'tree structure');

$axis->id_props(3, { desc => 'Desc' });
is_deeply($axis->id_props(3), { desc => 'Desc' },
          'properties returned correctly');
is_deeply($axis->id_props(3), { desc => 'Desc' },
          "props getter didn't overwrite props");
ok(! defined $axis->id_props(1), "unset props return undefined");
