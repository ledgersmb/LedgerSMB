#!/usr/bin/perl

=pod

This script scans various Perl files for translatable strings.

The scanner uses our extractor tool to find text() or marktext()
translation routines, either in code or comments, because they sometimes
intentionally contain translatable strings.

This script exists because xgettext and xgettext.pl don't allow us to
extract a sub-set of strings from our SQL files.

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
