#!perl

use strict;
use warnings;
use File::Find;

use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;

my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new(
    {
        fail_skip => 1
    }
);

# my @directories;
# find({ no_chdir => 1,
#        wanted => sub { push @directories, $File::Find::name
#                            if -d $File::Find::name
#        },
#      },
#     't/66-cucumber/');

# print STDERR @directories;

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
