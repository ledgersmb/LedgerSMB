#!/usr/bin/perl

=pod

This script scans Perl files for translatable strings. The only exceptions
are the localization extraction functionality test, which explicitly test
for invalid cases and feature support files, which use a test function which
isn't for localization.

=cut

use Test2::V0;
use Test2::Tools::Spec;

use File::Find;
use Capture::Tiny ':all';


if ($ENV{COVERAGE} && $ENV{CI}) {
    skip_all q{CI && COVERAGE excludes source code translation string checks};
}

my @on_disk;
sub collect {

    return if $File::Find::dir  =~ m!^\./(blib|xt/lib/|xt/66-cucumber/|LaTex|node_modules|local/lib/perl5|\..+)!;

    my $module = $File::Find::name;
    return if $module !~ m(\.(pl|pm|t)$);
    return if $module =~ m(t/07.1-extract-perl.t$);

    push @on_disk, $module
}
find(\&collect, '.');

for my $file (@on_disk) {

    tests $file => { async => (! $ENV{COVERAGE}) }, sub {

        my $errors = 0;

        # Produce a PO file
        my $stderr = capture_stderr {
            local $ENV{PERL5OPT} = undef;
            #clear PERL5OPTS; we don't want to inherit it from the testing environment
            system("echo \"$file\" | utils/devel/extract-perl >/dev/null");
        };
        for my $err (grep { $_ !~ m/^Parsing: / } split /\n/, $stderr) {

            ok(0, $err);
            $errors++;
        }
        ok(!$errors,$file) if !$errors;
    }
}


done_testing;
