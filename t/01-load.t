#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 205;
use File::Find;

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    $module =~ s#/#::#g;
    $module =~ s#\.pm$##g;
    push @on_disk, $module
}
find(\&collect, 'LedgerSMB/');


my @exception_modules =
    (
     # Exclude because tested conditionally on Template::Plugin::Latex way below
     'LedgerSMB::Template::LaTeX',

     # Exclude because tested conditionally on XML::Twig way below
     'LedgerSMB::RESTXML::Document::Base',
     'LedgerSMB::RESTXML::Document::Customer',
     'LedgerSMB::RESTXML::Document::Customer_Search',
     'LedgerSMB::RESTXML::Document::Part',
     'LedgerSMB::RESTXML::Document::Part_Search',
     'LedgerSMB::RESTXML::Document::SalesOrder',
     'LedgerSMB::RESTXML::Document::Session',
     'LedgerSMB::Template::ODS',

     # Exclude because tested conditionally on XML::Simple way below
     'LedgerSMB::REST_Format::xml',

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
          'LedgerSMB::DBH', 'LedgerSMB::DBTest', 'LedgerSMB::I18N',
          'LedgerSMB::Locale', 'LedgerSMB::Mailer', 'LedgerSMB::Session',
          'LedgerSMB::User', 'LedgerSMB::Entity',
          'LedgerSMB::GL', 'LedgerSMB::Group', 'LedgerSMB::Timecard',
          'LedgerSMB::PE', 'LedgerSMB::App_Module', 'LedgerSMB::Budget',
          'LedgerSMB::Business_Unit', 'LedgerSMB::Business_Unit_Class',
          'LedgerSMB::MooseTypes', 'LedgerSMB::PriceMatrix',
          'LedgerSMB::File', 'LedgerSMB::Report',
          'LedgerSMB::Template', 'LedgerSMB::Company_Config',
          'LedgerSMB::Contact', 'LedgerSMB::Database',
          'LedgerSMB::PGObject', 'LedgerSMB::Auth',
          'LedgerSMB::AA', 'LedgerSMB::AM', 'LedgerSMB::Batch',
          'LedgerSMB::IC', 'LedgerSMB::IR', 'LedgerSMB::PGDate',
          'LedgerSMB::PGNumber', 'LedgerSMB::PGOld', 'LedgerSMB::Request',
          'LedgerSMB::Setting', 'LedgerSMB::Tax', 'LedgerSMB::Upgrade_Tests',
          'LedgerSMB::Form', 'LedgerSMB::IS',
          'LedgerSMB::Num2text', 'LedgerSMB::OE', 'LedgerSMB::Auth::DB',
          'LedgerSMB::DBObject::Asset_Class', 'LedgerSMB::DBObject::Draft',
          'LedgerSMB::DBObject::EOY', 'LedgerSMB::DBObject::Part',
          'LedgerSMB::DBObject::Pricelist', 'LedgerSMB::DBObject::TaxForm',
          'LedgerSMB::DBObject::TransTemplate', 'LedgerSMB::DBObject::Menu',
          'LedgerSMB::DBObject::User', 'LedgerSMB::DBObject::Account',
          'LedgerSMB::DBObject::Admin', 'LedgerSMB::DBObject::Asset',
          'LedgerSMB::DBObject::Asset_Report', 'LedgerSMB::DBObject::Date',
          'LedgerSMB::DBObject::Reconciliation',
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
          'LedgerSMB::Part',
          'LedgerSMB::Payroll::Deduction_Type',
          'LedgerSMB::Payroll::Income_Type',
          'LedgerSMB::REST_Format::json',
          'LedgerSMB::Reconciliation::CSV',
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
          'LedgerSMB::Setting::Sequence', 'LedgerSMB::Taxes::Simple',
          'LedgerSMB::Template::Elements',
          'LedgerSMB::Template::TTI18N', 'LedgerSMB::Template::TXT',
          'LedgerSMB::Template::HTML', 'LedgerSMB::Template::CSV',
          'LedgerSMB::Template::DB', 'LedgerSMB::Timecard::Type',
          'LedgerSMB::REST_Class::contact', 'LedgerSMB::Request::Error',
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

    skip 'XML::Twig not installed', 8 if $@;

    for ('LedgerSMB::RESTXML::Document::Base',
         'LedgerSMB::RESTXML::Document::Customer',
         'LedgerSMB::RESTXML::Document::Customer_Search',
         'LedgerSMB::RESTXML::Document::Part',
         'LedgerSMB::RESTXML::Document::Part_Search',
         'LedgerSMB::RESTXML::Document::SalesOrder',
         'LedgerSMB::RESTXML::Document::Session',
        ) {
        use_ok($_);
    }

    eval { require OpenOffice::OODoc };
    skip 'OpenOffice::OODoc not installed', 1 if $@;

    use_ok('LedgerSMB::Template::ODS');
}

SKIP: {
	eval { require XML::Simple };

	skip 'XML::Simple not installed', 1 if $@;
	use_ok('LedgerSMB::REST_Format::xml');
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
