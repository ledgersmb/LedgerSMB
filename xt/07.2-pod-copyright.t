#!/usr/bin/perl
#
# xt/07.2-pod-copyright.t
#
# Checks that every pod file has a LICENSE AND COPYRIGHT section
# matching a template in `xt/data/07.2-license-and-copyright.template`.

use Test2::V0;
use Test2::Require::Module 'Test::Pod' => '1.00';
use Test::Pod;

use Perl::Critic::Utils::POD qw(
    get_raw_pod_section_from_file
    trim_raw_pod_section
);
use File::Slurp;


if ($ENV{COVERAGE} && $ENV{CI}) {
    skip_all q{CI && COVERAGE excludes POD checks};
}

# perhaps we want to add 'old', 't', 'xt'?
my @files = all_pod_files('lib');

my $template_file = 'xt/data/07.2-license-and-copyright.template';
my $template_text = read_file($template_file)
    or die "Couldn't read template text from $template_file";
chomp $template_text;

foreach my $file(@files) {

    {
        my $todo;
        # Non-standard copyright section in this file
        if($file eq 'lib/LedgerSMB/Scripts/payment.pm') {
            $todo = todo "SKIPPING $file - non standard COPYRIGHT section";
        }

        my $file_text = get_raw_pod_section_from_file(
            $file,
            'LICENSE AND COPYRIGHT'
        );

        # Copyright years vary between files. We replace them
        # with a placeholder to allow comparison with the template.
        $file_text =~ s/\d{4}(-\d{4}){0,1}/YYYY/i;

        ok($file_text, "$file pod has LICENSE AND COPYRIGHT section");
        is(
            trim_raw_pod_section($file_text),
            $template_text,
            "pod LICENSE AND COPYRIGHT section in $file matches template"
        );
    }
}

done_testing;
