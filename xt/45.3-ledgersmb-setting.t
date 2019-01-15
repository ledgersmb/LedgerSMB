#!/usr/bin/perl

=head1 UNIT TESTS FOR LedgerSMB::Setting

Unit tests for the LedgerSMB::Setting module that exercise
interaction with a test database.

=cut

use strict;
use warnings;

use DBI;
use Test::More;
use LedgerSMB::Setting;
use LedgerSMB::App_State;


# Create test run conditions
my $setting;
my $accounts;
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$ENV{LSMB_NEW_DB}",
    undef,
    undef,
    { AutoCommit => 0, PrintError => 0 }
) or BAIL_OUT "Can't connect to template database: " . DBI->errstr;

# Needed until LedgerSMB::Setting->get() is refactored to use its
# class dbh, rather than App_State
LedgerSMB::App_State::set_DBH($dbh);

# Add some sample accounts
$dbh->do("INSERT INTO account_heading (accno) VALUES ('0000')")
   or BAIL_OUT 'Failed to insert test account: ' . DBI->errstr;

my $heading_id = $dbh->last_insert_id(
    undef,
    undef,
    'account_heading',
    undef,
);

my $q = $dbh->prepare("
    INSERT INTO account (accno, description, category, heading)
    VALUES (?, ?, 'A', ?)
") or BAIL_OUT 'Failed to prepare query to insert accounts: ' . DBI->errstr;

$q->execute('1001', 'ACCOUNT-1001', $heading_id)
   or BAIL_OUT 'Failed to insert test account: ' . DBI->errstr;
$q->execute('1002', 'ACCOUNT-1002', $heading_id)
   or BAIL_OUT 'Failed to insert test account: ' . DBI->errstr;

# Add sample account link
$dbh->do("
    INSERT INTO account_link_description (description, summary, custom)
    VALUES ('TEST_DESCRIPTION', FALSE, FALSE)
") or BAIL_OUT 'Failed to insert account_link_description: ' . DBI->errstr;

$dbh->do("
    INSERT INTO account_link (account_id, description)
    SELECT MAX(id), 'TEST_DESCRIPTION' FROM account
") or BAIL_OUT 'Failed to insert account_link: ' . DBI->errstr;


plan tests => 16;

# Initialise Object
$setting = LedgerSMB::Setting->new();
isa_ok($setting, 'LedgerSMB::Setting', 'instantiated object');
ok($setting->set_dbh($dbh), 'set dbh');

# Getting/Setting keys in the defaults table
is($setting->get('TEST_SETTING_KEY'), undef, 'getting non-existent setting key returns undef');
ok($setting->set('TEST_SETTING_KEY', 'test-value'), 'set new setting key');
is($setting->get('TEST_SETTING_KEY'), 'test-value', 'retrieved new setting key');
ok($setting->set('TEST_SETTING_KEY', 'new-test-value'), 'updated existing setting key');
is($setting->get('TEST_SETTING_KEY'), 'new-test-value', 'retrieved updated setting key');

# Getting/Setting currencies
# Order of returned list is important as first element indicates default
$dbh->do(q{INSERT INTO currency (curr, description)
             VALUES ('EUR','EUR'),
                    ('CAD','CAD'),
                    ('SEK','SEK'),
                    ('GBP','GBP');
         INSERT INTO defaults VALUES ('curr', 'EUR'); });
#ok($setting->set('curr', 'EUR:CAD:SEK:GBP'), 'set currencies');
my @currencies = $setting->get_currencies;
is_deeply(\@currencies, [qw( EUR CAD GBP SEK )], 'get currencies ok');

# Getting all accounts
$accounts = $setting->all_accounts;
is(ref $accounts, 'ARRAY', 'all_accounts method returns arrayref');
is(scalar @{$accounts}, 2, 'all_accounts returns correct number of accounts');

# Get accounts with a particular link description
$accounts = $setting->accounts_by_link('TEST_DESCRIPTION');
is(ref $accounts, 'ARRAY', 'all_accounts method returns arrayref');
is(scalar @{$accounts}, 1, 'all_accounts returns correct number of accounts');
is($$accounts[0]->{accno}, '1002', 'accounts_by_link returns correct account');

# Increment a field
ok($setting->set('TEST_SETTING_KEY', 'A-123-1234-B'), 'set increment test key');
is($setting->increment(undef, 'TEST_SETTING_KEY'), 'A-123-1235-B', 'increment returned ok');
is($setting->get('TEST_SETTING_KEY'), 'A-123-1235-B', 'increment round-trip from database');


# Don't commit any of our changes
$dbh->rollback;
