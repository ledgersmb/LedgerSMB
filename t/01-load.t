#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Find;

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    $module =~ s#^old/##g;
    $module =~ s#^lib/##g;
    $module =~ s#/#::#g;
    $module =~ s#\.pm$##g;
    push @on_disk, $module
}
find(\&collect, 'lib/LedgerSMB/', 'old/lib/LedgerSMB/');


my @exception_modules =
    (
     # Exclude because tested conditionally on Template::Plugin::Latex way below
     'LedgerSMB::Template::LaTeX',

     # Exclude because tested conditionally on XML::Twig way below
     'LedgerSMB::Template::ODS',

     # Exclude because tested conditionally on Excel::Writer::XLSX
     # and Spreadsheet::WriteExcel
     'LedgerSMB::Template::XLSX',

     # Exclude because tested conditionally on CGI::Emulate::PSGI way below
     'LedgerSMB::PSGI',
     # Exclude because tested conditionally on X12::Parser way below
     'LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894',

     # Exclude because tested first to see if tests can succeed at all
     'LedgerSMB::Sysconfig',

     # Exclude because currently broken
     #@@@TODO: 1.5 release blocker!
    );

# USE STATEMENTS BELOW AS HELPERS TO REFRESH THE TABLE
#use Data::Dumper;
#print STDERR Dumper(\@on_disk);
my @modules =
    (
          'LedgerSMB::App_State',
          'LedgerSMB::DBH', 'LedgerSMB::I18N',
          'LedgerSMB::Locale', 'LedgerSMB::Mailer',
          'LedgerSMB::User', 'LedgerSMB::Entity',
          'LedgerSMB::GL', 'LedgerSMB::Timecard',
          'LedgerSMB::PE', 'LedgerSMB::App_Module', 'LedgerSMB::Budget',
          'LedgerSMB::Business_Unit', 'LedgerSMB::Business_Unit_Class',
          'LedgerSMB::MooseTypes', 'LedgerSMB::PriceMatrix',
          'LedgerSMB::File', 'LedgerSMB::Report',
          'LedgerSMB::Template', 'LedgerSMB::Legacy_Util',
          'LedgerSMB::Company_Config', 'LedgerSMB::Database',
          'LedgerSMB::Database::ChangeChecks',
          'LedgerSMB::PGObject', 'LedgerSMB::Auth',
          'LedgerSMB::AA', 'LedgerSMB::AM', 'LedgerSMB::Batch',
          'LedgerSMB::IC', 'LedgerSMB::IR', 'LedgerSMB::PGDate',
          'LedgerSMB::PGNumber', 'LedgerSMB::PGOld',
          'LedgerSMB::Setting', 'LedgerSMB::Tax', 'LedgerSMB::Upgrade_Tests',
          'LedgerSMB::Upgrade_Preparation', 'LedgerSMB::Form', 'LedgerSMB::IS',
          'LedgerSMB::Num2text', 'LedgerSMB::OE', 'LedgerSMB::Auth::DB',
          'LedgerSMB::DBObject::Asset_Class', 'LedgerSMB::DBObject::Draft',
          'LedgerSMB::DBObject::EOY',
          'LedgerSMB::DBObject::Pricelist', 'LedgerSMB::DBObject::TaxForm',
          'LedgerSMB::DBObject::TransTemplate', 'LedgerSMB::DBObject::Menu',
          'LedgerSMB::DBObject::User', 'LedgerSMB::DBObject::Account',
          'LedgerSMB::DBObject::Admin', 'LedgerSMB::DBObject::Asset',
          'LedgerSMB::DBObject::Asset_Report', 'LedgerSMB::DBObject::Date',
          'LedgerSMB::DBObject::Reconciliation',
          'LedgerSMB::Report::Listings::TemplateTrans',
          'LedgerSMB::Report::Approval_Option',
          'LedgerSMB::DBObject::Payment', 'LedgerSMB::Entity::Contact',
          'LedgerSMB::Entity::Location', 'LedgerSMB::Entity::Note',
          'LedgerSMB::Entity::Bank', 'LedgerSMB::Entity::Company',
          'LedgerSMB::Entity::Credit_Account',
          'LedgerSMB::Entity::Person', 'LedgerSMB::Entity::User',
          'LedgerSMB::Entity::Payroll::Deduction',
          'LedgerSMB::Entity::Payroll::Wage',
          'LedgerSMB::Entity::Person::Employee',
          'LedgerSMB::File::ECA', 'LedgerSMB::File::Entity',
          'LedgerSMB::File::Incoming', 'LedgerSMB::File::Internal',
          'LedgerSMB::File::Order', 'LedgerSMB::File::Part',
          'LedgerSMB::File::Transaction',
          'LedgerSMB::Inventory::Adjust',
          'LedgerSMB::Inventory::Adjust_Line',
          'LedgerSMB::Middleware::AuthenticateSession',
          'LedgerSMB::Middleware::ClearDownloadCookie',
          'LedgerSMB::Middleware::DisableBackButton',
          'LedgerSMB::Middleware::DynamicLoadWorkflow',
          'LedgerSMB::Middleware::Log4perl',
          'LedgerSMB::Middleware::RequestID',
          'LedgerSMB::old_code', 'LedgerSMB::Part',
          'LedgerSMB::Payroll::Deduction_Type',
          'LedgerSMB::Payroll::Income_Type',
          'LedgerSMB::PSGI::Preloads', 'LedgerSMB::PSGI::Util',
          'LedgerSMB::Reconciliation::CSV',
          'LedgerSMB::Reconciliation::ISO20022',
          'LedgerSMB::FileFormats::ISO20022::CAMT053',
          'LedgerSMB::Report::Axis',
          'LedgerSMB::Report::File', 'LedgerSMB::Report::GL',
          'LedgerSMB::Report::Orders', 'LedgerSMB::Report::Timecards',
          'LedgerSMB::Report::Balance_Sheet', 'LedgerSMB::Report::Dates',
          'LedgerSMB::Report::Trial_Balance', 'LedgerSMB::Report::Aging',
          'LedgerSMB::Report::COA', 'LedgerSMB::Report::PNL',
          'LedgerSMB::Report::Assets::Net_Book_Value',
          'LedgerSMB::Report::Budget::Search',
          'LedgerSMB::Report::Budget::Variance',
          'LedgerSMB::Report::Contact::Purchase',
          'LedgerSMB::Report::Contact::History',
          'LedgerSMB::Report::Contact::Search',
          'LedgerSMB::Report::File::Incoming',
          'LedgerSMB::Report::File::Internal',
          'LedgerSMB::Report::Hierarchical',
          'LedgerSMB::Report::Inventory::Activity',
          'LedgerSMB::Report::Inventory::Partsgroups',
          'LedgerSMB::Report::Inventory::Pricegroups',
          'LedgerSMB::Report::Inventory::Search',
          'LedgerSMB::Report::Inventory::Search_Adj',
          'LedgerSMB::Report::Inventory::History',
          'LedgerSMB::Report::Inventory::Adj_Details',
          'LedgerSMB::Report::Invoices::Outstanding',
          'LedgerSMB::Report::Invoices::Payments',
          'LedgerSMB::Report::Invoices::COGS',
          'LedgerSMB::Report::Invoices::Transactions',
          'LedgerSMB::Report::Listings::Asset',
          'LedgerSMB::Report::Listings::Asset_Class',
          'LedgerSMB::Report::Listings::GIFI',
          'LedgerSMB::Report::Listings::Language',
          'LedgerSMB::Report::Listings::Overpayments',
          'LedgerSMB::Report::Listings::SIC',
          'LedgerSMB::Report::Listings::Templates',
          'LedgerSMB::Report::Listings::Warehouse',
          'LedgerSMB::Report::Listings::Business_Unit',
          'LedgerSMB::Report::Listings::Business_Type',
          'LedgerSMB::Report::PNL::ECA',
          'LedgerSMB::Report::PNL::Income_Statement',
          'LedgerSMB::Report::PNL::Invoice', 'LedgerSMB::Report::PNL::Product',
          'LedgerSMB::Report::Payroll::Deduction_Types',
          'LedgerSMB::Report::Payroll::Income_Types',
          'LedgerSMB::Report::Reconciliation::Summary',
          'LedgerSMB::Report::Taxform::Details',
          'LedgerSMB::Report::Taxform::Summary',
          'LedgerSMB::Report::Taxform::List',
          'LedgerSMB::Report::Unapproved::Batch_Overview',
          'LedgerSMB::Report::Unapproved::Batch_Detail',
          'LedgerSMB::Report::Unapproved::Drafts',
          'LedgerSMB::Report::co::Balance_y_Mayor',
          'LedgerSMB::Report::co::Caja_Diaria',
          'LedgerSMB::Scripts::budget_reports',
          'LedgerSMB::Scripts::parts',
          'LedgerSMB::Scripts::contact_reports', 'LedgerSMB::Scripts::file',
          'LedgerSMB::Scripts::inv_reports', 'LedgerSMB::Scripts::lreports_co',
          'LedgerSMB::Scripts::pnl', 'LedgerSMB::Scripts::report_aging',
          'LedgerSMB::Scripts::import_csv', 'LedgerSMB::Scripts::inventory',
          'LedgerSMB::Scripts::business_unit', 'LedgerSMB::Scripts::taxform',
          'LedgerSMB::Scripts::menu', 'LedgerSMB::Scripts::trial_balance',
          'LedgerSMB::Scripts::account', 'LedgerSMB::Scripts::admin',
          'LedgerSMB::Scripts::asset', 'LedgerSMB::Scripts::budgets',
          'LedgerSMB::Scripts::configuration', 'LedgerSMB::Scripts::goods',
          'LedgerSMB::Scripts::invoice', 'LedgerSMB::Scripts::journal',
          'LedgerSMB::Scripts::login', 'LedgerSMB::Scripts::order',
          'LedgerSMB::Scripts::payment', 'LedgerSMB::Scripts::payroll',
          'LedgerSMB::Scripts::reports', 'LedgerSMB::Scripts::setup',
          'LedgerSMB::Scripts::template', 'LedgerSMB::Scripts::transtemplate',
          'LedgerSMB::Scripts::user', 'LedgerSMB::Scripts::contact',
          'LedgerSMB::Scripts::drafts', 'LedgerSMB::Scripts::recon',
          'LedgerSMB::Scripts::timecard', 'LedgerSMB::Scripts::vouchers',
          'LedgerSMB::Scripts::employee::country',
          'LedgerSMB::Setting::Sequence',
          'LedgerSMB::Setup::SchemaChecks',
          'LedgerSMB::Taxes::Simple',
          'LedgerSMB::Template::DBProvider',
          'LedgerSMB::Template::TXT',
          'LedgerSMB::Template::HTML', 'LedgerSMB::Template::CSV',
          'LedgerSMB::Template::DB', 'LedgerSMB::Timecard::Type',
          'LedgerSMB::Database::Loadorder', 'LedgerSMB::Database::Change',
          'LedgerSMB::Magic',
    );

my %modules;
$modules{$_} = 1 for @modules;
$modules{$_} = 1 for @exception_modules;

my @untested_modules;
for (@on_disk) {
    push @untested_modules, $_
        if ! defined($modules{$_});
}

ok(scalar(@untested_modules) eq 0, 'All on-disk modules are tested')
    or diag ('Missing in test: ', explain \@untested_modules);

use_ok('LedgerSMB::Sysconfig')
    || BAIL_OUT('System Configuration could be loaded!');
my @to_sort = map { rand() } 0 .. $#modules;
@modules = @modules[ sort { $to_sort[$a] <=> $to_sort[$b] } 0 .. $#modules  ];
for my $module (@modules) {
    use_ok($module);
}
SKIP: {
    eval{ require Template::Plugin::Latex} ||
    skip 'Template::Plugin::Latex not installed', 1;
    eval{ require Template::Latex} ||
    skip 'Template::Latex not installed', 1;

    use_ok('LedgerSMB::Template::LaTeX');
}

SKIP: {
    eval { require XML::Twig };
    skip 'XML::Twig not installed', 1 if $@;

    eval { require OpenOffice::OODoc };
    skip 'OpenOffice::OODoc not installed', 1 if $@;

    use_ok('LedgerSMB::Template::ODS');
}

SKIP: {
        eval { require CGI::Emulate::PSGI };

        skip 'CGI::Emulate::PSGI not installed', 1 if $@;
        use_ok('LedgerSMB::PSGI');
}

SKIP: {
    eval { require X12::Parser };

    skip 'X12::Parser not installed', 3 if $@;
    for ('LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894') {
        use_ok($_);
    }
}

SKIP: {
    eval { require Excel::Writer::XLSX };
    skip 'Excel::Writer::XLSX not installed', 1 if $@;


    eval { require Spreadsheet::WriteExcel };
    skip 'Spreadsheet::WriteExcel not installed', 1 if $@;

    for ('LedgerSMB::Template::XLSX') {
        use_ok($_);
    }
}

done_testing;
