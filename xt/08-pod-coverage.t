#!/usr/bin/perl
#
# xt/08-pod-coverage.t
#
# Checks POD coverage.
#

use strict;
use warnings;

use Test::More; # plan automatically generated below
use File::Find;
use File::Util;

# Only test with perl versions >= 5.20. Earlier versions of perl
# handle constants in a way which causes Test::Pod::Coverage to
# consider them naked subroutines.
eval{require 5.20.0} or plan skip_all => 'perl version < 5.20.0';


eval "use Test::Pod::Coverage";
if ($@){
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
}


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

# only check new code; we're scaling down on old code anyway
find(\&collect, 'lib');

@on_disk =
    grep { ! m#^lib/LedgerSMB/Sysconfig.pm# } # LedgerSMB::Sysconfig false fail
    @on_disk;

plan tests => scalar(@on_disk);

# Copied from 01-load.t
my @exception_modules =
    (
     # Exclude because tested conditionally on Template::Plugin::Latex way below
     'LedgerSMB::Template::LaTeX',

     # Exclude because tested conditionally on XML::Twig way below
     'LedgerSMB::Template::ODS',

     # Exclude because tested conditionally on Excel::Writer::XLSX
     # and Spreadsheet::WriteExcel
     'LedgerSMB::Template::XLSX',

     # Exclude because tested conditionally on CGI::Emulate::PSGI way below
     'LedgerSMB::PSGI',

     # Exclude because tested conditionally on X12::Parser way below
     'LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894',

     # Exclude, reports functions which don't exist
     'LedgerSMB::Sysconfig',
    );


my %also_private = (
    'LedgerSMB::Scripts::payment' => [ qr/(^p\_)|(_p$)/ ],
    'LedgerSMB::DBObject::Payment' => [ qr/^(format_ten_|num2text_)/ ],
    );

my $sep = File::Util::SL();
for my $f (@on_disk) {
    $f =~ s/\.pm//g;
    $f =~ s#lib/##g;
    $f =~ s#\Q$sep\E#::#g;

    pod_coverage_ok($f, { also_private => $also_private{$f} })
        unless grep { $f eq $_ } @exception_modules;
}


SKIP: {
    eval{ require Template::Plugin::Latex} ||
    skip 'Template::Plugin::Latex not installed', 1;
    eval{ require Template::Latex} ||
    skip 'Template::Latex not installed', 1;

    my $f = 'LedgerSMB::Template::LaTeX';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
}

SKIP: {
    eval { require Excel::Writer::XLSX };
    skip 'Excel::Writer::XLSX not installed', 1 if $@;

    eval { require Spreadsheet::WriteExcel };
    skip 'Spreadsheet::WriteExcel not installed', 1 if $@;

    my $f = 'LedgerSMB::Template::XLSX';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
}

SKIP: {
    eval { require XML::Twig };
    skip 'XML::Twig not installed', 1 if $@;

    eval { require OpenOffice::OODoc };
    skip 'OpenOffice::OODoc not installed', 1 if $@;

    my $f = 'LedgerSMB::Template::ODS';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
}

SKIP: {
    eval { require CGI::Emulate::PSGI };

    skip 'CGI::Emulate::PSGI not installed', 1 if $@;
    my $f = 'LedgerSMB::PSGI';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
}

SKIP: {
    eval { require X12::Parser };

    skip 'X12::Parser not installed', 3 if $@;
    for my $f ('LedgerSMB::X12', 'LedgerSMB::X12::EDI850',
               'LedgerSMB::X12::EDI894') {
        pod_coverage_ok($f, { also_private => $also_private{$f} });
    }
}


