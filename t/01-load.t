#!/usr/bin/perl

use strict;
use warnings;

use File::Find;

use Test2::V0;
use Test2::Tools::Spec;


####### Test setup

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

my %tested = ( 'LedgerSMB::Sysconfig' => 1 );
my %on_disk;
sub module_loads {
    my ($module, @required_modules) = @_;

    return if $tested{$module}; # don't test twice

    $tested{$module} = 1;
    delete $on_disk{$module};

    tests modules_loadable => { iso => 1, async => (! $ENV{COVERAGE}) }, sub {
        for (@required_modules) {
            eval "require $_"
                or skip_all "Test missing required module '$_'";
        }

        ok eval("require $module"), $@;
    };
}


my @modules =
    (
     'LedgerSMB::Sysconfig',
     'LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894',
     'LedgerSMB::Template::Formatter',
     'LedgerSMB::Template::Plugin::XLSX',
     'LedgerSMB::Template::Plugin::ODS',
     'LedgerSMB::Template::Plugin::LaTeX',
     'LedgerSMB::Template::Sink',
     'LedgerSMB::Template::Sink::Email',
     'LedgerSMB::Template::Sink::Printer',
     'LedgerSMB::Template::Sink::Screen',
     'LedgerSMB::Admin', 'LedgerSMB::Admin::Command',
     'LedgerSMB::Admin::Command::backup',
     'LedgerSMB::Admin::Command::copy',
     'LedgerSMB::Admin::Command::create',
     'LedgerSMB::Admin::Command::destroy',
     'LedgerSMB::Admin::Command::rename',
     'LedgerSMB::Admin::Command::restore',
     'LedgerSMB::Admin::Command::setup',
     'LedgerSMB::Admin::Command::template',
     'LedgerSMB::Admin::Command::user',
     'LedgerSMB::Admin::Command::upgrade',
     'LedgerSMB::Admin::Configuration',
     'LedgerSMB::Company',
     'LedgerSMB::Company::Configuration',
     'LedgerSMB::Company::Configuration::Collection',
     'LedgerSMB::Company::Configuration::COANodes',
     'LedgerSMB::Company::Configuration::Currencies',
     'LedgerSMB::Company::Configuration::Currency',
     'LedgerSMB::Company::Configuration::Account',
     'LedgerSMB::Company::Configuration::Heading',
     'LedgerSMB::Company::Configuration::GIFI',
     'LedgerSMB::Company::Configuration::GIFIs',
     'LedgerSMB::Company::Configuration::SIC',
     'LedgerSMB::Company::Configuration::SICs',
     'LedgerSMB::App_State',
     'LedgerSMB::I18N',
     'LedgerSMB::Locale',
     'LedgerSMB::LanguageResolver',
     'LedgerSMB::Mailer',
     'LedgerSMB::User', 'LedgerSMB::Entity',
     'LedgerSMB::EnvVarSetter',
     'LedgerSMB::GL', 'LedgerSMB::Timecard',
     'LedgerSMB::PE', 'LedgerSMB::App_Module', 'LedgerSMB::Budget',
     'LedgerSMB::Business_Unit', 'LedgerSMB::Business_Unit_Class',
     'LedgerSMB::MooseTypes', 'LedgerSMB::PriceMatrix',
     'LedgerSMB::Printers',
          'LedgerSMB::File', 'LedgerSMB::Report',
          'LedgerSMB::Request::Helper::ParameterMap',
          'LedgerSMB::Template', 'LedgerSMB::Template::UI',
          'LedgerSMB::Legacy_Util',
          'LedgerSMB::Company_Config',
          'LedgerSMB::Currency', 'LedgerSMB::Database',
     'LedgerSMB::Database::ChangeChecks', 'LedgerSMB::Database::Config',
     'LedgerSMB::Database::Factory',
          'LedgerSMB::Database::Upgrade',
          'LedgerSMB::Exchangerate', 'LedgerSMB::Exchangerate_Type',
          'LedgerSMB::PGObject', 'LedgerSMB::Auth',
          'LedgerSMB::IIAA',
          'LedgerSMB::AA', 'LedgerSMB::AM', 'LedgerSMB::Batch',
          'LedgerSMB::IC', 'LedgerSMB::IR', 'LedgerSMB::PGDate',
          'LedgerSMB::PGNumber', 'LedgerSMB::PGOld',
          'LedgerSMB::PGTimestamp',
          'LedgerSMB::Setting', 'LedgerSMB::Tax', 'LedgerSMB::Upgrade_Tests',
          'LedgerSMB::Database::SchemaChecks::JSON',
          'LedgerSMB::Form', 'LedgerSMB::IS',
          'LedgerSMB::Num2text', 'LedgerSMB::OE', 'LedgerSMB::Auth::DB',
          'LedgerSMB::DBObject::Asset_Class', 'LedgerSMB::DBObject::Draft',
          'LedgerSMB::DBObject::EOY',
          'LedgerSMB::DBObject::Pricelist', 'LedgerSMB::DBObject::TaxForm',
          'LedgerSMB::DBObject::TransTemplate', 'LedgerSMB::DBObject::Menu',
          'LedgerSMB::DBObject::User', 'LedgerSMB::DBObject::Account',
          'LedgerSMB::DBObject::Admin', 'LedgerSMB::DBObject::Asset',
          'LedgerSMB::DBObject::Asset_Report',
          'LedgerSMB::DBObject::Reconciliation',
          'LedgerSMB::Report::Listings::TemplateTrans',
          'LedgerSMB::Report::Approval_Option',
          'LedgerSMB::Report::OpenClosed_Option',
          'LedgerSMB::DBObject::Payment', 'LedgerSMB::Entity::Contact',
          'LedgerSMB::Entity::Location', 'LedgerSMB::Entity::Note',
          'LedgerSMB::Entity::Bank', 'LedgerSMB::Entity::Company',
          'LedgerSMB::Entity::Credit_Account',
          'LedgerSMB::Entity::Person', 'LedgerSMB::Entity::User',
          'LedgerSMB::Entity::Payroll::Deduction',
          'LedgerSMB::Entity::Payroll::Wage',
          'LedgerSMB::Entity::Person::Employee',
     'LedgerSMB::File::ECA', 'LedgerSMB::File::Email',
     'LedgerSMB::File::Entity',
          'LedgerSMB::File::Incoming', 'LedgerSMB::File::Internal',
          'LedgerSMB::File::Order', 'LedgerSMB::File::Part',
     'LedgerSMB::File::Reconciliation',
          'LedgerSMB::File::Transaction',
          'LedgerSMB::Inventory::Adjust',
          'LedgerSMB::Inventory::Adjust_Line',
          'LedgerSMB::Mailer::TransportSMTP',
          'LedgerSMB::Middleware::Authenticate::Company',
          'LedgerSMB::Middleware::DisableBackButton',
          'LedgerSMB::Middleware::DynamicLoadWorkflow',
          'LedgerSMB::Middleware::Log4perl',
          'LedgerSMB::Middleware::MainAppConnect',
          'LedgerSMB::Middleware::RequestID',
          'LedgerSMB::Middleware::SessionStorage',
          'LedgerSMB::Middleware::SetupAuthentication',
          'LedgerSMB::old_code', 'LedgerSMB::oldHandler',
          'LedgerSMB::Part',
          'LedgerSMB::Payroll::Deduction_Type',
     'LedgerSMB::Payroll::Income_Type',
     'LedgerSMB::PGObject::Role',
          'LedgerSMB::PSGI',
          'LedgerSMB::PSGI::Preloads', 'LedgerSMB::PSGI::Util',
          'LedgerSMB::Reconciliation::CSV',
          'LedgerSMB::Reconciliation::ISO20022',
          'LedgerSMB::FileFormats::ISO20022::CAMT053',
          'LedgerSMB::FileFormats::OFX::BankStatement',
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
          'LedgerSMB::Router',
          'LedgerSMB::Routes::ERP::API',
          'LedgerSMB::Routes::ERP::API::Accounts',
          'LedgerSMB::Routes::ERP::API::Contacts',
          'LedgerSMB::Routes::ERP::API::GeneralLedger',
          'LedgerSMB::Routes::ERP::API::Goods',
          'LedgerSMB::Routes::ERP::API::Invoices',
          'LedgerSMB::Routes::ERP::API::Languages',
          'LedgerSMB::Routes::ERP::API::MenuNodes',
          'LedgerSMB::Routes::ERP::API::Products',
          'LedgerSMB::Routes::ERP::API::Session',
          'LedgerSMB::Routes::ERP::API::Templates',
          'LedgerSMB::Scripts::budget_reports',
          'LedgerSMB::Scripts::currency',
          'LedgerSMB::Scripts::contact_reports', 'LedgerSMB::Scripts::file',
          'LedgerSMB::Scripts::inv_reports', 'LedgerSMB::Scripts::lreports_co',
          'LedgerSMB::Scripts::pnl', 'LedgerSMB::Scripts::report_aging',
          'LedgerSMB::Scripts::import_csv', 'LedgerSMB::Scripts::inventory',
          'LedgerSMB::Scripts::business_unit', 'LedgerSMB::Scripts::taxform',
          'LedgerSMB::Scripts::trial_balance',
          'LedgerSMB::Scripts::account', 'LedgerSMB::Scripts::admin',
          'LedgerSMB::Scripts::asset', 'LedgerSMB::Scripts::budgets',
     'LedgerSMB::Scripts::configuration',
     'LedgerSMB::Scripts::email',
     'LedgerSMB::Scripts::erp',
          'LedgerSMB::Scripts::goods',
          'LedgerSMB::Scripts::invoice', 'LedgerSMB::Scripts::journal',
          'LedgerSMB::Scripts::login', 'LedgerSMB::Scripts::order',
          'LedgerSMB::Scripts::payment', 'LedgerSMB::Scripts::payroll',
          'LedgerSMB::Scripts::reports', 'LedgerSMB::Scripts::setup',
          'LedgerSMB::Scripts::template', 'LedgerSMB::Scripts::transtemplate',
          'LedgerSMB::Scripts::user', 'LedgerSMB::Scripts::contact',
          'LedgerSMB::Scripts::drafts', 'LedgerSMB::Scripts::recon',
          'LedgerSMB::Scripts::timecard', 'LedgerSMB::Scripts::vouchers',
          'LedgerSMB::Setting::Sequence',
          'LedgerSMB::Setup::SchemaChecks',
          'LedgerSMB::Taxes::Simple',
          'LedgerSMB::Template::DBProvider',
          'LedgerSMB::Template::Plugin::TXT',
          'LedgerSMB::Template::Plugin::HTML', 'LedgerSMB::Template::Plugin::CSV',
          'LedgerSMB::Template::DB', 'LedgerSMB::Timecard::Type',
          'LedgerSMB::Database::Loadorder', 'LedgerSMB::Database::Change',
     'LedgerSMB::Magic',
     'LedgerSMB::Workflow::Action',
     'LedgerSMB::Workflow::Action::Email',
     'LedgerSMB::Workflow::Action::Null',
     'LedgerSMB::Workflow::Action::RecordSpawnedWorkflow',
     'LedgerSMB::Workflow::Action::SpawnWorkflow',
     'LedgerSMB::Workflow::Email',
     'LedgerSMB::Workflow::Loader',
     'LedgerSMB::Workflow::Persister',
     'LedgerSMB::Workflow::Persister::Email',
     'LedgerSMB::Workflow::Persister::ExtraData',
     'LedgerSMB::Workflow::Persister::JournalEntry',
     'LedgerSMB::Workflow::Persister::Order',
    );

%on_disk = map { $_ => 1 } @on_disk;


########### The actual tests


use Test2::Require::Module 'LedgerSMB::Sysconfig';
delete $on_disk{'LedgerSMB::Sysconfig'};

module_loads
    'LedgerSMB::Template::Plugin::ODS' => qw( XML::Twig OpenOffice::OODoc );

module_loads
    'LedgerSMB::Template::Plugin::LaTeX' =>
    qw( Template::Plugin::Latex Template::Latex );

module_loads
    'LedgerSMB::Template::Plugin::XLSX' =>
    qw( Excel::Writer::XLSX Spreadsheet::WriteExcel );

for ('LedgerSMB::X12', 'LedgerSMB::X12::EDI850', 'LedgerSMB::X12::EDI894') {
    module_loads $_ => qw( X12::Parser );
}

for my $module (@modules) {
    module_loads $module;
}

is([ keys %on_disk ], [], 'All on-disk modules have been tested');

done_testing;
