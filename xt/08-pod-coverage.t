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

use Config;
use File::Find;
use File::Spec;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

if ($ENV{COVERAGE} && $ENV{CI}) {
    skip_all q{CI && COVERAGE excludes POD checks};
}


#### Test setup

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


my %also_private = (
    'LedgerSMB::Scripts::payment' => [ qr/(^p\_)|(_p$)/ ],
    'LedgerSMB::DBObject::Payment' => [ qr/^(format_ten_|num2text_)/ ],
    );

my %tested;
sub module_covered {
    my ($module, @required_modules) = @_;

    return if $tested{$module}; # don't test twice

    $tested{$module} = 1;

    tests modules_covered => sub {
        for (@required_modules) {
            eval "require $_"
                or skip_all "Test missing required module '$_'";
        }

        pod_coverage_ok($module, { also_private => $also_private{$module} });
    };
}


##### The actual tests


module_covered
    'LedgerSMB::Template::Plugin::ODS' => qw( XML::Twig OpenOffice::OODoc );

module_covered
    'LedgerSMB::Template::Plugin::LaTeX'
    => qw( Template::Plugin::Latex Template::Latex );

module_covered
    'LedgerSMB::Template::Plugin::XLSX'
    => qw( Excel::Writer::XLSX Spreadsheet::WriteExcel );

for ('LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894') {
    module_covered $_ => qw( X12::Parser );
}


for my $f (@on_disk) {
    $f =~ s/\.pm//g;
    $f =~ s#lib/##g;
    $f = join('::', File::Spec->splitdir( $f ) );

    module_covered $f;
}

done_testing;
