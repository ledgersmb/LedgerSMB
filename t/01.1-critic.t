#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Find;
use Perl::Critic;

my $critic = Perl::Critic->new(
    -profile => '',
    -severity => 5,
    -theme => '',
    -exclude => [ 'BuiltinFunctions',
                  'ClassHierarchies',
                  'ControlStructures',
                  'Documentation',
                  'ErrorHandling',
                  'InputOutput',
                  'Miscelenea',
                  'Modules',
                  'Objects',
                  'RegularExpressions',
                  'Subroutines',
                  'TestingAndDebugging',
                  'ValuesAndExpressions',
                  'Variables'
    ],
    -include => [ 'ProhibitTrailingWhitespace',
                  'ProhibitHardTabs',
    ]);

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'LedgerSMB/', 'bin/');


plan tests => scalar(@on_disk);

for my $file (@on_disk) {
    my @findings = $critic->critique($file);

    ok(scalar(@findings) == 0, "Critique for $file");
    for my $finding (@findings) {
        diag($finding->description);
    }
}

