#!/usr/bin/perl

use Module::CPANfile;
use File::Find;

use Test2::V0;
use Test::Dependencies 0.25 forward_compatible => 1;

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
                ignores => [ 'LedgerSMB', 'PageObject',
                             'LaTeX::Driver',
                             'Starman', 'TeX::Encode::charmap',
                             'Locale::CLDR::Locales',
                             'MooseX::ClassAttribute'
                              ] );

done_testing;
