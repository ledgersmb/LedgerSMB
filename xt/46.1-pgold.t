#!/usr/bin/perl

=head1 UNIT TESTS FOR LedgerSMB::PGOld

Partial tests for the LedgerSMB::PGOld module which subclasses
PGObject::Simple.

=cut


use strict;
use warnings;

use Test::More;
use LedgerSMB::PGOld;

my $pgold;

plan tests => (4);

# Basic construction with no base properties to import
isa_ok(
    $pgold = LedgerSMB::PGOld->new(),
    'LedgerSMB::PGOld',
    'object created with no imported properties'
);

# Construction with base properties
my $base = {
    key1 => 'value1',
    key2 => ['a', 'b'],
};

isa_ok(
    $pgold = LedgerSMB::PGOld->new({base => $base}),
    'LedgerSMB::PGOld',
    'object created with base properties'
);
is($pgold->{key1}, 'value1', 'property key1 initialised ok');
is_deeply($pgold->{key2}, ['a', 'b'], 'property key2 initialised ok');
