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
    plan tests => 26;
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
pod_coverage_ok("LedgerSMB::DBObject::Date");
pod_coverage_ok("LedgerSMB::DBObject::Draft");
pod_coverage_ok("LedgerSMB::DBObject::Company");
pod_coverage_ok("LedgerSMB::Company_Config");
pod_coverage_ok("LedgerSMB::DBObject::Admin");
pod_coverage_ok("LedgerSMB::ScriptLib::Company");
pod_coverage_ok("LedgerSMB::DBObject::Employee");
pod_coverage_ok("LedgerSMB::File");
pod_coverage_ok("LedgerSMB::DBObject");
pod_coverage_ok("LedgerSMB::Batch");
pod_coverage_ok("LedgerSMB::DBObject::Payment", 
               {also_private => [qr/^(format_ten_|num2text_)/]}
);

