#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use File::Temp qw(tempdir);
use Test2::V0;
use lib "$Bin/../utils/devel";
use LedgerSMB::TranslationWorkbench;

my $root = tempdir(CLEANUP => 1);
mkdir "$root/lib";
open my $fh, '>', "$root/lib/LedgerSMB.pm" or die $!;
print {$fh} "our \$VERSION = '1.2.3';\n";
close $fh;

my $workbench = LedgerSMB::TranslationWorkbench->new(root => $root);
is $workbench->version, '1.2.3', 'detects version';
like $workbench->header('2020-01-01 00:00+0000'), qr/Project-Id-Version: LedgerSMB 1\.2\.3/;

mkdir "$root/utils";
mkdir "$root/utils/devel";
open $fh, '>', "$root/utils/devel/excluded.pm" or die $!;
close $fh;
mkdir "$root/lib/ignored";
open $fh, '>', "$root/lib/a.pm" or die $!;
close $fh;
open $fh, '>', "$root/lib/ignored/b.pm" or die $!;
close $fh;
is $workbench->collect_perl_sources, [qw(lib/LedgerSMB.pm lib/a.pm lib/ignored/b.pm)],
    'collects Perl sources';

my $executor = LedgerSMB::TranslationWorkbench::Executor->new;
like dies { $executor->run([$^X, '-e', 'exit 3']) }, qr/Command failed/,
    'reports command failures';

my $dry = LedgerSMB::TranslationWorkbench->new(root => $root, dry_run => 1);
$dry->rebuild;
ok !-e "$root/locale/LedgerSMB.pot", 'dry run does not write catalogs';

done_testing;
