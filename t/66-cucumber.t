#!perl

use strict;
use warnings;
use File::Find;

use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

my @reqenv = qw(PGUSER PGPASSWORD LSMB_BASE_URL);
my @missing = grep { ! $ENV{$_} } @reqenv;

plan skip_all => join (' and ', @missing) . ' not set'
    if @missing;

my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new(
    {
        fail_skip => 1
    }
);

for my $directory (qw(
      01-basic
))
{
    my ( $executor, @features ) =
        Test::BDD::Cucumber::Loader->load('t/66-cucumber/' . $directory);
    die "No features found" unless @features;
    $executor->execute( $_, $harness ) for @features;
}

done_testing;
