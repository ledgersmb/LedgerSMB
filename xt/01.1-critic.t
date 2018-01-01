#!/usr/bin/perl

use strict;
use warnings;
use Test::More; # plan automatically generated below
use File::Find;
use Perl::Critic;
use Perl::Critic::Violation;

my @on_disk;


sub test_files {
    my ($critic, $files) = @_;

    Perl::Critic::Violation::set_format( 'S%s %p %f: %l\n');

    for my $file (@$files) {
        my @findings = $critic->critique($file);

        ok(scalar(@findings) == 0, "Critique for $file");
        for my $finding (@findings) {
            diag ("$finding");
        }
    }

    return;
}

sub collect {
    return if $File::Find::name !~ m/\.(pm|pl|t)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/', 'old/', 't/', 'xt/');

my @on_disk_oldcode =
    grep { m#^old/#  }
    @on_disk;

my @on_disk_tests =
    grep { m#^(t|xt)/# }
    @on_disk;

@on_disk =
    grep { ! m#^(old|t|xt)/# }
    @on_disk;

plan tests => scalar(@on_disk) + scalar(@on_disk_oldcode) + scalar(@on_disk_tests);

test_files(
    Perl::Critic->new(
        -profile => 'xt/perlcriticrc',
        -theme => 'lsmb_new',
    ),
    \@on_disk
);

test_files(
    Perl::Critic->new(
        -profile => 'xt/perlcriticrc',
        -theme => 'lsmb_old',
    ),
    \@on_disk_oldcode
);

test_files(
    Perl::Critic->new(
        -profile => 'xt/perlcriticrc',
        -theme => 'lsmb_tests',
    ),
    \@on_disk_tests
);

