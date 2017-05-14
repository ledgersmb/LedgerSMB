#!/usr/bin/env perl

use strict;
use warnings;

use lib 'xt/41-coaload';

use Test::Most; # To check missing

use Test::Class::Moose::Load qw(xt/41-coaload);
use Test::Class::Moose::Runner;

my @missing = grep { ! $ENV{$_} } (qw(LSMB_NEW_DB COA_TESTING LSMB_TEST_DB));
plan skip_all => (join ', ', @missing) . ' not set' if @missing;

use File::Find::Rule;

my $rule = File::Find::Rule->new;
$rule->or($rule->new
               ->directory
               ->name(qr(gifi|sic))
               ->prune
               ->discard,
          $rule->new);
my @files = sort $rule->name("*.sql")->file->in("sql/coa"); # "sql/coa/ar/chart/General.sql"

my @classes = qw(TestsFor::COATest);
my %tests;

for my $sqlfile (@files) {
    my ($_1,$dir,$type,$name) = $sqlfile =~ qr(sql\/coa\/(([a-z]{2})\/)?(.+\/)?([^\/\.]+)\.sql$);
    $dir //= '';
    if (!defined($tests{"x$dir"})) {
        $tests{"x$dir"} = 1;
        if ( $dir ) {
            Class::MOP::Class->create(
                "TestsFor::COATest::$dir" => (
                    version      => '0.01',
                    superclasses => ['TestsFor::COATest'],
                    attributes   => [
                    ],
                    methods => {
                    }
                )
            );
            push @classes, "TestsFor::COATest::$dir";
        }
    }
}

my $test_suite = Test::Class::Moose::Runner->new(
    jobs        => 5,
    randomize   => 0, # Random order
#    show_timing => 1, # Detailed timings of each test
    statistics  => 1, # Display statistics at the end of the tests
    test_classes => \@classes,
);

$test_suite->runtests;
$test_suite->test_report;

# Expected results until parallel works
# Test classes:    1
# Test instances:  45
# Test methods:    45
# Total tests run: 180
