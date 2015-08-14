#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 61;
use File::Find;
use Data::Dumper;

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    $module =~ s#/#::#g;
    $module =~ s#\.pm$##g;
    push @on_disk, $module
}
find(\&collect, 'LedgerSMB/');
# print STDERR Dumper(\@on_disk);


my @exception_modules = 
    ('LedgerSMB::Template::LaTeX', 'LedgerSMB::CreditCard',
     'LedgerSMB::Sysconfig');

my @modules =
    ('LedgerSMB', 'LedgerSMB::App_State',
     'LedgerSMB::AA', 'LedgerSMB::AM', 'LedgerSMB::Auth', 'LedgerSMB::CP',
     'LedgerSMB::DBObject::Account', 'LedgerSMB::DBObject::Admin',
     'LedgerSMB::DBObject::Date', 'LedgerSMB::DBObject::Draft',
     'LedgerSMB::DBObject::EOY', 'LedgerSMB::DBObject::Menu',
     'LedgerSMB::DBObject::Payment', 'LedgerSMB::DBObject::TaxForm',
     'LedgerSMB::Report', 'LedgerSMB::Form', 'LedgerSMB::GL', 'LedgerSMB::IC',
     'LedgerSMB::IR', 'LedgerSMB::IS', 'LedgerSMB::Timecard',
     'LedgerSMB::Timecard::Type', 'LedgerSMB::Report::Timecards',
     'LedgerSMB::Scripts::timecard', 'LedgerSMB::Locale', 'LedgerSMB::Mailer',
     'LedgerSMB::Num2text', 'LedgerSMB::OE', 'LedgerSMB::PE',
     'LedgerSMB::PriceMatrix', 'LedgerSMB::Auth',
     'LedgerSMB::DBObject::Reconciliation', 'LedgerSMB::Tax',
     'LedgerSMB::Template', 'LedgerSMB::Template::Elements',
     'LedgerSMB::Template::CSV', 'LedgerSMB::Template::HTML',
     'LedgerSMB::File', 'LedgerSMB::File::Transaction',
     'LedgerSMB::File::Order', 'LedgerSMB::DBObject::Asset',
     'LedgerSMB::DBObject::Asset_Report', 'LedgerSMB::DBObject::Asset_Class',
     'LedgerSMB::Entity', 'LedgerSMB::Entity::Company',
     'LedgerSMB::Entity::Person', 'LedgerSMB::Entity::User',
     'LedgerSMB::Entity::Person::Employee', 'LedgerSMB::Entity::Contact',
     'LedgerSMB::Entity::Bank', 'LedgerSMB::Entity::Location',
     'LedgerSMB::Entity::Note', 'LedgerSMB::Entity::Payroll::Deduction',
     'LedgerSMB::Entity::Payroll::Wage', 'LedgerSMB::Scripts::setup',
     'LedgerSMB::Template::TXT', 'LedgerSMB::User',
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
    or diag ('Failing: ', explain \@untested_modules);

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
	eval { require Net::TCLink };

	skip 'Net::TCLink not installed', 1 if $@;
	use_ok('LedgerSMB::CreditCard');
}
