#!/usr/bin/perl

use Module::CPANfile;
use File::Find;

use Test2::Require::Module 'Test::Dependencies' => '0.23';


use Test::Dependencies (exclude => [ qw/ PageObject LedgerSMB / ],
                        style => 'light');

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
                             'Starman', 'TeX::Encode::charmap',
                             'Locale::CLDR::Locales::Ar::Any::Eg',
                             'Locale::CLDR::Locales::Bg',
                             'Locale::CLDR::Locales::Ca',
                             'Locale::CLDR::Locales::Cs',
                             'Locale::CLDR::Locales::Da',
                             'Locale::CLDR::Locales::De',
                             'Locale::CLDR::Locales::De::Any::Ch',
                             'Locale::CLDR::Locales::El',
                             'Locale::CLDR::Locales::En',
                             'Locale::CLDR::Locales::En::Any::Ca',
                             'Locale::CLDR::Locales::En::Any::Gb',
                             'Locale::CLDR::Locales::En::Any::Us',
                             'Locale::CLDR::Locales::Es',
                             'Locale::CLDR::Locales::Es::Any::Ar',
                             'Locale::CLDR::Locales::Es::Any::Co',
                             'Locale::CLDR::Locales::Es::Any::Ec',
                             'Locale::CLDR::Locales::Es::Any::Mx',
                             'Locale::CLDR::Locales::Es::Any::Pa',
                             'Locale::CLDR::Locales::Es::Any::Py',
                             'Locale::CLDR::Locales::Es::Any::Ve',
                             'Locale::CLDR::Locales::Et',
                             'Locale::CLDR::Locales::Fi',
                             'Locale::CLDR::Locales::Fr',
                             'Locale::CLDR::Locales::Fr::Any::Be',
                             'Locale::CLDR::Locales::Fr::Any::Ca',
                             'Locale::CLDR::Locales::Hu',
                             'Locale::CLDR::Locales::Id',
                             'Locale::CLDR::Locales::Is',
                             'Locale::CLDR::Locales::It',
                             'Locale::CLDR::Locales::Lt',
                             'Locale::CLDR::Locales::Ms::Any::My',
                             'Locale::CLDR::Locales::Nb',
                             'Locale::CLDR::Locales::Nl',
                             'Locale::CLDR::Locales::Nl::Any::Be',
                             'Locale::CLDR::Locales::Pl',
                             'Locale::CLDR::Locales::Pt',
                             'Locale::CLDR::Locales::Pt::Any::Br',
                             'Locale::CLDR::Locales::Ru',
                             'Locale::CLDR::Locales::Sv',
                             'Locale::CLDR::Locales::Tr',
                             'Locale::CLDR::Locales::Uk',
                             'Locale::CLDR::Locales::Zh::Hans::Cn',
                             'Locale::CLDR::Locales::Zh::Hant::Tw',
                             'MooseX::ClassAttribute'
                              ] );
