#!/usr/bin/perl


use Test2::V0;
use Test2::Tools::Spec;

use File::Find;
use Perl::Critic;
use Perl::Critic::Violation;


if ($ENV{COVERAGE} && $ENV{CI}) {
    skip_all q{CI && COVERAGE excludes source code checks};
}

my @on_disk;


sub test_files {
    my ($critic, $files) = @_;

    Perl::Critic::Violation::set_format( 'S%s %p %f: %l\n');

    for my $file (@$files) {
        tests critique => { async => (! $ENV{COVERAGE}) }, sub {
            my @findings = map { "$_" } $critic->critique($file);

            ok(scalar(@findings) == 0, "Critique for $file");
            diag(join('', @findings)) if scalar(@findings);
        };
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

done_testing;
