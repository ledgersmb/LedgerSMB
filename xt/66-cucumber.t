#!perl

use strict;
use warnings;
use lib;
use File::Find;

use File::Spec;
use Path::Class qw(file dir);
use Module::Runtime qw(use_module module_notional_filename);
use YAML::Syck;

use Test::More;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TestBuilder;
use Test::BDD::Cucumber::Model::TagSpec;

my @reqenv = qw(PGUSER PGPASSWORD LSMB_BASE_URL);
my @missing = grep { ! $ENV{$_} } @reqenv;

plan skip_all => join (' and ', @missing) . ' not set'
    if @missing;

my $config_data_whole = LoadFile('t/.pherkin.yaml');
my $profile_name = $ENV{LSMB_TEST_PROFILE} || 'default';
my $profile = $config_data_whole->{$profile_name};

if ($profile->{includes}) {
    lib->import( @{ $profile->{includes} } );
}

my @extensions =
    map { use_module $_; $_->new( $profile->{extensions}->{$_} );  }
keys %{ $profile->{extensions} };
my @steps_directories;
@steps_directories = @{ $profile->{steps} } if $profile->{steps};

for my $ext (@extensions) {
    my $base_dir = file($INC{module_notional_filename(ref $ext)})->dir;
    my @steps =
        map { File::Spec->rel2abs($_, $base_dir) }
        @{ $ext->step_directories };
    push @steps_directories, @steps;
}


$_->pre_execute for @extensions;

my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new(
    {
        fail_skip => 1
    }
);

# Do not run @wip scenarios
my $tagspec = Test::BDD::Cucumber::Model::TagSpec->new(
    tags => [ not => 'wip' ],
    );
for my $directory (qw(
      01-basic
      11-ar
))
{
    my ( $executor, @features ) =
        Test::BDD::Cucumber::Loader->load('xt/66-cucumber/' . $directory);
    die "No features found" unless @features;
    $executor->add_extensions(@extensions);
    Test::BDD::Cucumber::Loader->load_steps( $executor, $_ )
        for (@steps_directories);

    $executor->execute( $_, $harness, $tagspec ) for @features;
}


$_->post_execute for @extensions;

done_testing;
