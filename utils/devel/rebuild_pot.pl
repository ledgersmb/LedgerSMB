#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use lib $Bin;
use LedgerSMB::TranslationWorkbench;

my ($root, $dry_run, $verbose);
my @skip;
GetOptions(
    'root=s'  => \$root,
    'dry-run' => \$dry_run,
    verbose   => \$verbose,
    'skip=s@' => \@skip,
) or die "Usage: $0 [--root DIR] [--dry-run] [--verbose] [--skip STAGE]\n";

$root //= "$Bin/../..";
my $workbench = LedgerSMB::TranslationWorkbench->new(
    root => $root, dry_run => $dry_run, verbose => $verbose, skip => \@skip);
$workbench->rebuild;
