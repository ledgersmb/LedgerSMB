#!/usr/bin/perl
#
# t/98-pod-coverage.t
#
# Checks POD coverage.
#

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage";
if ($@){
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
} else {
    plan tests => 18;
}
pod_coverage_ok("LedgerSMB");
pod_coverage_ok("LedgerSMB::Form");
pod_coverage_ok("LedgerSMB::AM");
pod_coverage_ok("LedgerSMB::Database");
pod_coverage_ok("LedgerSMB::Locale");
pod_coverage_ok("LedgerSMB::Log");
pod_coverage_ok("LedgerSMB::Mailer");
pod_coverage_ok("LedgerSMB::Template");
pod_coverage_ok("LedgerSMB::Template::CSV");
pod_coverage_ok("LedgerSMB::Template::HTML");
pod_coverage_ok("LedgerSMB::Template::LaTeX");
pod_coverage_ok("LedgerSMB::Template::ODS");
pod_coverage_ok("LedgerSMB::Template::TXT");
pod_coverage_ok("LedgerSMB::Template::XLS");
pod_coverage_ok("LedgerSMB::User");
pod_coverage_ok("LedgerSMB::::DBObject::Date");
pod_coverage_ok("LedgerSMB::::DBObject::Draft");
pod_coverage_ok("LedgerSMB::DBObject::Company");
