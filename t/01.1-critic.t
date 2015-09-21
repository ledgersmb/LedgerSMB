#!/usr/bin/perl

use strict;
use warnings;
use Test::More; # plan automatically generated below
use File::Find;
use Perl::Critic;

my @on_disk;


sub test_files {
    my ($critic, $files) = @_;

    for my $file (@$files) {
        my @findings = $critic->critique($file);

        ok(scalar(@findings) == 0, "Critique for $file");
        for my $finding (@findings) {
            diag($finding->description);
        }
    }

    return;
}

sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'LedgerSMB.pm', 'LedgerSMB/', 'bin/');

my @on_disk_oldcode =
    grep { m#^bin/# || m#^LedgerSMB/..\.pm#
               || m#^LedgerSMB/Form\.pm# } @on_disk;

@on_disk =
    grep { ! m#^bin/# }
    grep { ! m#^LedgerSMB/..\.pm# }
    grep { ! m#^LedgerSMB/Form\.pm# }
    grep { ! m#^LedgerSMB/Auth/# }
    @on_disk;


plan tests => scalar(@on_disk) + scalar(@on_disk_oldcode);

&test_files(Perl::Critic->new(
                -profile => 't/perlcriticrc',
                -severity => 5,
                -theme => '',
                -exclude => [ 'BuiltinFunctions',
                              'ClassHierarchies',
                              'ControlStructures',
                              'Documentation',
                              'ErrorHandling',
                              'InputOutput',
                              'Miscelenea',
                              'Modules::RequireVersionVar',
                              'Objects',
                              'RegularExpressions',
                              'Subroutines',
                              'TestingAndDebugging::ProhibitNoStrict',
                              'TestingAndDebugging::ProhibitNoWarnings',
                              'ValuesAndExpressions',
                              'Variables'
                ],
                -include => [ 'ProhibitTrailingWhitespace',
                              'ProhibitHardTabs',
                              'Modules',
                              'TestingAndDebugging',
                ]),
            \@on_disk);

&test_files(Perl::Critic->new(
                -profile => 't/perlcriticrc',
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
                ]),
            \@on_disk_oldcode);


