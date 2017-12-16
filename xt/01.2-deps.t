#!/usr/bin/perl

use Module::CPANfile;
use File::Find;

BEGIN {
 local $@;
  eval {
   require Test::Dependencies;
   if ($Test::Dependencies::VERSION < 0.20) {
       require Test::More;
       Test::More::plan(skip_all =>'Must have Test::Dependencies version 0.20 or higher, had version ' . $Test::Dependencies::VERSION);
       exit 0;
   }
   Test::Dependencies->import(exclude => [ qw/ LedgerSMB PageObject / ], style => 'light');
  };
  if ($@){
       require Test::More;
       Test::More::plan(skip_all => 'Must have Test::Dependencies version 0.20 or higher');
       exit 0;
  }
}

my $file = Module::CPANfile->load;

my @on_disk = ();
sub collect {
    return if $File::Find::name !~ m/\.(pm|pl)$/;

    my $module = $File::Find::name;
    push @on_disk, $module;
}
find(\&collect, 'lib/', 'old/bin/', 'old/lib/');

push @on_disk, 'tools/starman.psgi';

#TODO: Implement Template plugins <?lsmb USE plugin ?>
ok_dependencies($file, \@on_disk,
                phases => 'runtime',
                ignores => [ 'Image::Size', 'LaTeX::Driver',
                             'Template::Plugin::JSON',
                             'Starman', 'TeX::Encode::charmap'] );

