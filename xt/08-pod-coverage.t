#!/usr/bin/perl
#
# xt/08-pod-coverage.t
#
# Checks POD coverage.
#

use Test2::V0;
use Test2::Tools::Spec;

# Only test with perl versions >= 5.20. Earlier versions of perl
# handle constants in a way which causes Test::Pod::Coverage to
# consider them naked subroutines.
use Test2::Require::Perl 'v5.20';
use Test2::Require::Module 'Test::Pod::Coverage';

use Test::Pod::Coverage;

use File::Find;
use File::Util;


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


tests feature_latex_modules => sub {
    use Test2::Require::Module 'Template::Plugin::Latex';
    use Test2::Require::Module 'Template::Latex';

    my $f = 'LedgerSMB::Template::LaTeX';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
};

tests feature_xls_modules => sub {
    use Test2::Require::Module 'Excel::Writer::XLSX';
    use Test2::Require::Module 'Spreadsheet::WriteExcel';

    my $f = 'LedgerSMB::Template::XLSX';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
};

tests feature_ods_modules => sub {
    use Test2::Require::Module 'XML::Twig';
    use Test2::Require::Module 'OpenOffice::OODoc';

    my $f = 'LedgerSMB::Template::ODS';
    pod_coverage_ok($f, { also_private => $also_private{$f} });
};

tests feature_edi_modules => sub {
    use Test2::Require::Module 'X12::Parser';

    for my $f ('LedgerSMB::X12', 'LedgerSMB::X12::EDI850',
               'LedgerSMB::X12::EDI894') {
        pod_coverage_ok($f, { also_private => $also_private{$f} });
    }
};


done_testing;
