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
    grep { ! m#^bin/# }
    grep { ! m#^lib/LedgerSMB/..\.pm# }
    grep { ! m#^lib/LedgerSMB/Form\.pm# }
    grep { ! m#^lib/LedgerSMB/Auth/# }
    @on_disk;


use Test::More;
eval "use Test::Pod::Coverage";
if ($@){
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
} else {
    plan tests => scalar(@on_disk);
}


my %also_private = (
    'LedgerSMB::Scripts::payment' => [ qr/^(p\_)/ ],
    'LedgerSMB::DBObject::Payment' => [ qr/^(format_ten_|num2text_)/ ],
    );

for my $f (@on_disk) {
    $f =~ s/\.pm//g;
    $f =~ s#lib/##g;
    $f =~ s#/#::#g;

    pod_coverage_ok($f, { also_private => $also_private{$f} });
}


