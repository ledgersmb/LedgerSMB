#!/usr/bin/perl
#
# t/98-pod-coverage.t
#
# Checks POD coverage.
#

use strict;
use warnings;

use Test::More; # plan automatically generated below
use File::Find;
use File::Util;

plan skip_all => "POD_TESTING missing" if ! $ENV{POD_TESTING};

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
find(\&collect, 'lib/LedgerSMB.pm', 'lib/LedgerSMB/');

# only check new code; we're scaling down on old code anyway
@on_disk =
    grep { ! m#^old/bin/# }
    grep { ! m#^lib/LedgerSMB/..\.pm# }
    grep { ! m#^lib/LedgerSMB/Form\.pm# }
    grep { ! m#^lib/LedgerSMB/Auth/# }
    grep { ! m#^lib/LedgerSMB/Num2text\.pm# } # LedgerSMB::Num2text is old code
    grep { ! m#^lib/LedgerSMB/Sysconfig.pm# } # LedgerSMB::Sysconfig false fail
    @on_disk;


use Test::More;
eval "use Test::Pod::Coverage";
if ($@){
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
} else {
    plan tests => scalar(@on_disk);
}


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


