#!/usr/bin/env perl

use strict;
use warnings;

use lib 'xt/41-coaload';

use Test::Requires {
    'Parallel::ForkManager' => 0,
};

use Test::Most; # To check missing

use Test::Class::Moose::Load qw(xt/41-coaload);
use Test::Class::Moose::Runner;

my @missing = grep { ! $ENV{$_} } (qw(LSMB_NEW_DB COA_TESTING LSMB_TEST_DB));
plan skip_all => (join ', ', @missing) . ' not set' if @missing;

my $test_suite = Test::Class::Moose::Runner->new(
    jobs        => 5,
    randomize   => 1, # Random order
#    show_timing => 1, # Detailed timings of each test
    statistics  => 1, # Display statistics at the end of the tests
    test_classes => 'TestsFor::COATest',
);

$test_suite->runtests;
$test_suite->test_report;
