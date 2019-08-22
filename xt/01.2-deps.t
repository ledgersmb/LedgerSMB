#!/usr/bin/perl

use Module::CPANfile;
use File::Find;

use Test::Needs {
    Test::Dependencies => '0.23',
};
Test::Dependencies->import(exclude => [ qw/ PageObject LedgerSMB / ], style => 'light');

my $file = Module::CPANfile->load;

my @on_disk = ();
sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module;
}
find(\&collect, 'lib/', 'old/bin/', 'old/lib/');

push @on_disk, 'bin/ledgersmb-server.psgi';

ok_dependencies($file, \@on_disk,
                phases => 'runtime',
                ignores => [ 'LaTeX::Driver',
                             'Starman', 'TeX::Encode::charmap' ] );

