#!/usr/bin/perl
#
# xt/07-pod.t
#
# Checks POD syntax.
#

use strict;
use warnings;

use Test2::V0; # for 'skip_all'
use Test2::Require::Module 'Test::Pod' => '1.00';
use Test::Pod;

if ($ENV{COVERAGE} && $ENV{CI}) {
    skip_all q{CI && COVERAGE excludes POD checks};
}

all_pod_files_ok(all_pod_files('old', 'lib', 't', 'xt'));
