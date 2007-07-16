#!/usr/bin/perl
#
# t/98-pod-coverage.t
#
# Checks POD coverage.
#

use strict;
use warnings;

use Test::More tests => 6;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

pod_coverage_ok("LedgerSMB");
pod_coverage_ok("LedgerSMB::Database");
pod_coverage_ok("LedgerSMB::Locale");
pod_coverage_ok("LedgerSMB::Log");
pod_coverage_ok("LedgerSMB::Template::HTML");
pod_coverage_ok("LedgerSMB::User");
