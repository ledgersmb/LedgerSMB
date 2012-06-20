#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 49;

use_ok('LedgerSMB::Sysconfig') 
    || BAIL_OUT('System Configuration could be loaded!');
use_ok('LedgerSMB');
use_ok('LedgerSMB::AA');
use_ok('LedgerSMB::AM');
use_ok('LedgerSMB::Auth');
use_ok('LedgerSMB::BP');
use_ok('LedgerSMB::CP');
use_ok('LedgerSMB::DBObject');
use_ok('LedgerSMB::DBObject::Account');
use_ok('LedgerSMB::DBObject::Admin');
use_ok('LedgerSMB::DBObject::Date');
use_ok('LedgerSMB::DBObject::Draft');
use_ok('LedgerSMB::DBObject::EOY');
use_ok('LedgerSMB::DBObject::Location');
use_ok('LedgerSMB::DBObject::Menu');
use_ok('LedgerSMB::DBObject::Payment');
use_ok('LedgerSMB::DBObject::Reconciliation');
use_ok('LedgerSMB::DBObject::TaxForm');
use_ok('LedgerSMB::DBObject::User');
use_ok('LedgerSMB::Form');
use_ok('LedgerSMB::GL');
use_ok('LedgerSMB::IC');
use_ok('LedgerSMB::IR');
use_ok('LedgerSMB::IS');
use_ok('LedgerSMB::JC');
use_ok('LedgerSMB::Locale');
use_ok('LedgerSMB::Mailer');
use_ok('LedgerSMB::Num2text');
use_ok('LedgerSMB::OE');
use_ok('LedgerSMB::PE');
use_ok('LedgerSMB::PriceMatrix');
use_ok('LedgerSMB::RP');
use_ok('LedgerSMB::Auth');
use_ok('LedgerSMB::DBObject::Reconciliation');
use_ok('LedgerSMB::Tax');
use_ok('LedgerSMB::Template');
use_ok('LedgerSMB::Template::Elements');
use_ok('LedgerSMB::Template::CSV');
use_ok('LedgerSMB::Template::HTML');
use_ok('LedgerSMB::File');
use_ok('LedgerSMB::File::Transaction');
use_ok('LedgerSMB::File::Order');
use_ok('LedgerSMB::DBObject::Asset');
use_ok('LedgerSMB::DBObject::Asset_Report');
use_ok('LedgerSMB::DBObject::Asset_Class');
SKIP: {
    eval{ require Template::Plugin::Latex} ||
    skip 'Template::Plugin::Latex not installed';
    eval{ require Template::Latex} ||
    skip 'Template::Latex not installed';

    use_ok('LedgerSMB::Template::LaTeX');
}
use_ok('LedgerSMB::Template::TXT');
use_ok('LedgerSMB::User');

SKIP: {
	eval { require Net::TCLink };

	skip 'Net::TCLink not installed', 1 if $@;
	use_ok('LedgerSMB::CreditCard');
}
