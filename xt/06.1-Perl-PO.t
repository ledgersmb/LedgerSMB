#!/usr/bin/perl

=pod

This script scans Perl files for translatable strings. The only exceptions 
are the localization extraction functionality test, which explicitly test
for invalid cases and feature support files, which use a test function which
isn't for localization.

=cut

use strict;
use warnings;
use utf8;

use Test::More;
use File::Find;
use Capture::Tiny ':all';

my @on_disk;
sub collect {
    return if $File::Find::dir  =~ m(^blib|xt/lib/|xt/66-cucumber/|LaTex);

    my $module = $File::Find::name;
    return if $module !~ m(\.(pl|pm|t)$);
    return if $module =~ m(t/07.1-extract-perl.t$);

    push @on_disk, $module
}
find(\&collect, '.');

plan tests => scalar @on_disk;

for my $file (@on_disk) {

    subtest $file => sub {

        my $errors = 0;

        # Produce a PO file
        my $stderr = capture_stderr {
            system("echo \"$file\" | utils/devel/extract-perl >/dev/null");
        };
        for my $err (split /\n/, $stderr) {

            ok(0, $err);
            $errors++;
        }
        ok(!$errors,$file) if !$errors;
    }
}
