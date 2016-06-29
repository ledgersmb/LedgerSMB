#!/usr/bin/perl

use Module::CPANfile;
use File::Find;

use Test::Dependencies exclude =>
  [ qw/ LedgerSMB PageObject / ],
  style => 'light';;


use Data::Dumper;

my $file = Module::CPANfile->load;

my @on_disk = ();
sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/', 'bin/');

push @on_disk, 'tools/starman.psgi';

ok_dependencies($file, \@on_disk,
                phases => 'runtime',
                ignores => [ 'App::LedgerSMB::Admin', 'Image::Size',
                             'LaTeX::Driver', 'PGObject::Util::DBAdmin',
                             'Starman' ] );

