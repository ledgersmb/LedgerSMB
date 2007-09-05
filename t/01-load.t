#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 34;

use_ok('LedgerSMB');
use_ok('LedgerSMB::AA');
use_ok('LedgerSMB::AM');
use_ok('LedgerSMB::BP');
use_ok('LedgerSMB::CA');
use_ok('LedgerSMB::CP');
use_ok('LedgerSMB::CT');
use_ok('LedgerSMB::Form');
use_ok('LedgerSMB::GL');
use_ok('LedgerSMB::HR');
use_ok('LedgerSMB::IC');
use_ok('LedgerSMB::IR');
use_ok('LedgerSMB::IS');
use_ok('LedgerSMB::JC');
use_ok('LedgerSMB::Locale');
use_ok('LedgerSMB::Log');
use_ok('LedgerSMB::Mailer');
use_ok('LedgerSMB::Num2text');
use_ok('LedgerSMB::OE');
use_ok('LedgerSMB::OP');
use_ok('LedgerSMB::PE');
use_ok('LedgerSMB::PriceMatrix');
use_ok('LedgerSMB::RC');
use_ok('LedgerSMB::RP');
use_ok('LedgerSMB::Session');
use_ok('LedgerSMB::Sysconfig');
use_ok('LedgerSMB::Tax');
use_ok('LedgerSMB::Template');
use_ok('LedgerSMB::Template::HTML');
use_ok('LedgerSMB::Template::PDF');
use_ok('LedgerSMB::Template::PS');
use_ok('LedgerSMB::Template::TXT');
use_ok('LedgerSMB::User');

SKIP: {
	eval { require Net::TCLink };

	skip 'Net::TCLink not installed', 1 if $@;
	use_ok('LedgerSMB::CreditCard');
}
