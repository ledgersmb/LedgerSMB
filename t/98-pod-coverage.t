#!/usr/bin/perl
#
# t/98-pod-coverage.t
#
# Checks POD coverage.
#

use strict;
use warnings;

use LedgerSMB::Locale;
my $locale =  LedgerSMB::Locale->get_handle('en');
$LedgerSMB::App_State::Locale = $locale;
## Prevent "name referenced once" warning by repeating the same assignment again
$LedgerSMB::App_State::Locale = $locale;

use Test::More;
eval "use Test::Pod::Coverage";
if ($@){
    plan skip_all => "Test::Pod::Coverage required for testing POD coverage";
} else {
    plan tests => 63;
}
pod_coverage_ok("LedgerSMB");
pod_coverage_ok("LedgerSMB::Form");
pod_coverage_ok("LedgerSMB::AM");
pod_coverage_ok("LedgerSMB::Database");
pod_coverage_ok("LedgerSMB::Locale");
pod_coverage_ok("LedgerSMB::Mailer");
pod_coverage_ok("LedgerSMB::Template");
pod_coverage_ok("LedgerSMB::Template::CSV");
pod_coverage_ok("LedgerSMB::Template::HTML");
pod_coverage_ok("LedgerSMB::Template::TXT");
pod_coverage_ok("LedgerSMB::User");
pod_coverage_ok("LedgerSMB::DBObject::Date");
pod_coverage_ok("LedgerSMB::DBObject::Draft");
pod_coverage_ok("LedgerSMB::Company_Config");
pod_coverage_ok("LedgerSMB::DBObject::Admin");
pod_coverage_ok("LedgerSMB::Scripts::contact");
pod_coverage_ok("LedgerSMB::Scripts::account");
pod_coverage_ok("LedgerSMB::Scripts::admin");
pod_coverage_ok("LedgerSMB::Scripts::asset");
pod_coverage_ok("LedgerSMB::Scripts::budget_reports");
pod_coverage_ok("LedgerSMB::Scripts::budgets");
pod_coverage_ok("LedgerSMB::Scripts::business_unit");
pod_coverage_ok("LedgerSMB::Scripts::configuration");
pod_coverage_ok("LedgerSMB::Scripts::contact");
pod_coverage_ok("LedgerSMB::Scripts::contact_reports");
pod_coverage_ok("LedgerSMB::Scripts::drafts");
pod_coverage_ok("LedgerSMB::Scripts::file");
pod_coverage_ok("LedgerSMB::Scripts::goods");
pod_coverage_ok("LedgerSMB::Scripts::import_csv");
pod_coverage_ok("LedgerSMB::Scripts::inventory");
pod_coverage_ok("LedgerSMB::Scripts::invoice");
pod_coverage_ok("LedgerSMB::Scripts::inv_reports");
pod_coverage_ok("LedgerSMB::Scripts::journal");
pod_coverage_ok("LedgerSMB::Scripts::login");
pod_coverage_ok("LedgerSMB::Scripts::lreports_co");
pod_coverage_ok("LedgerSMB::Scripts::menu");
pod_coverage_ok("LedgerSMB::Scripts::order");
pod_coverage_ok("LedgerSMB::Scripts::payment",
               {also_private => [qr/^(p\_)/]}
);
pod_coverage_ok("LedgerSMB::Scripts::payroll");
pod_coverage_ok("LedgerSMB::Scripts::pnl");
pod_coverage_ok("LedgerSMB::Scripts::recon");
pod_coverage_ok("LedgerSMB::Scripts::report_aging");
pod_coverage_ok("LedgerSMB::Scripts::reports");
pod_coverage_ok("LedgerSMB::Scripts::setup");
pod_coverage_ok("LedgerSMB::Scripts::taxform");
pod_coverage_ok("LedgerSMB::Scripts::timecard");
pod_coverage_ok("LedgerSMB::Scripts::transtemplate");
pod_coverage_ok("LedgerSMB::Scripts::trial_balance");
pod_coverage_ok("LedgerSMB::Scripts::user");
pod_coverage_ok("LedgerSMB::Scripts::vouchers");
pod_coverage_ok("LedgerSMB::Entity::Person::Employee");
pod_coverage_ok("LedgerSMB::File");
pod_coverage_ok("LedgerSMB::File::ECA");
pod_coverage_ok("LedgerSMB::File::Entity");
pod_coverage_ok("LedgerSMB::File::Order");
pod_coverage_ok("LedgerSMB::File::Part");
pod_coverage_ok("LedgerSMB::File::Transaction");
pod_coverage_ok("LedgerSMB::Batch");
pod_coverage_ok("LedgerSMB::DBObject::Payment", 
               {also_private => [qr/^(format_ten_|num2text_)/]}
);
pod_coverage_ok("LedgerSMB::DBObject::Reconciliation");
pod_coverage_ok("LedgerSMB::DBObject::TaxForm");
pod_coverage_ok("LedgerSMB::DBObject::Menu");
pod_coverage_ok("LedgerSMB::DBObject::EOY");

