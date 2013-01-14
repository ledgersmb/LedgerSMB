#!/usr/bin/perl
#
# t/97-pod.t
#
# Checks POD syntax.
#

use strict;
use warnings;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok('LedgerSMB.pm', all_pod_files('LedgerSMB'));
