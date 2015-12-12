#!/usr/bin/perl

use Test::More (tests => 10);
use strict;
use warnings;

use LedgerSMB::Report::Axis;

my $axis = LedgerSMB::Report::Axis->new;

ok($axis->map_path(['a']) == 1, 'one-element path');
ok($axis->map_path(['b']) == 3, 'second one-element path');
ok($axis->map_path(['b','c']) == 5, 'sub-item of existing element');
ok($axis->map_path(['b','c','d','f']) == 9, 'sub path of existing path');
ok($axis->map_path(['b','c','d','e']) == 11, 'second leaf in existing path');

is_deeply($axis->sort(), [1, 4, 6, 8, 11, 9, 7, 5, 3], 'tree-order sorted row-IDs');
is_deeply($axis->tree(),
          {
              'a' => {
                  'children' => {},
                  'accno' => 'a',
                  'path' => ['a'],
                  'id' => 1,
                  'section' => {
                      id => 2,
                      'path' => ['a'],
                      props => {
                          section_for => 1,
                      },
                  },
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
                          'parent_id' => 3,
                          'children' => {
                              'd' => {
                                  'path' => ['b','c','d'],
                                  'accno' => 'd',
                                  'parent_id' => 5,
                                  'children' => {
                                      'e' => {
                                          'path' => ['b','c','d','e'],
                                          'accno' => 'e',
                                          'parent_id' => 7,
                                          'children' => {},
                                          'id' => 11,
                                          'section' => {
                                              id => 12,
                                              'path' => ['b','c','d','e'],
                                              props => {
                                                  section_for => 11,
                                              },
                                          },
                                      },
                                      'f' => {
                                          'path' => ['b','c','d','f'],
                                          'accno' => 'f',
                                          'parent_id' => 7,
                                          'children' => {},
                                          'id' => 9,
                                          'section' => {
                                              id => 10,
                                              'path' => ['b','c','d','f'],
                                              props => {
                                                  section_for => 9,
                                              },
                                          },
                                      },
                                  },
                                  'id' => 7,
                                  'section' => {
                                      id => 8,
                                      'path' => ['b','c','d'],
                                      props => {
                                          section_for => 7,
                                      },
                                  },
                              }
                          },
                          'id' => 5,
                          'section' => {
                              id => 6,
                              'path' => ['b','c'],
                              props => {
                                  section_for => 5,
                              },
                          },
                      },
                  },
                  'id' => 3,
                  'section' => {
                      id => 4,
                      'path' => ['b'],
                      props => {
                          section_for => 3,
                      },
                  },
              }
          },
          'tree structure');

$axis->id_props(3, { desc => 'Desc' });
is_deeply($axis->id_props(3), { desc => 'Desc' },
          'properties returned correctly');
is_deeply($axis->id_props(3), { desc => 'Desc' },
          "props getter didn't overwrite props");
ok(! defined $axis->id_props(1), "unset props return undefined");
