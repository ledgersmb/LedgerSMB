#!/usr/bin/perl

=head1 UNIT TESTS FOR LedgerSMB::Report::Unapproved::Batch_Overview

Unit tests for the LedgerSMB::Report::Unapproved::Batch_Overview module
that exercise interaction with a test database.

=cut

use Test2::V0;

use DBI;
use URI;

use LedgerSMB::Batch;
use LedgerSMB::Report::Unapproved::Batch_Overview;

# Create test run conditions
my $report;
my $rows;
my $row;
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$ENV{LSMB_NEW_DB}",
    undef,
    undef,
    { AutoCommit => 0, PrintError => 0 }
) or die q{Can't connect to template database: } . DBI->errstr;
$dbh->{private_LedgerSMB} = { schema => 'xyz' };
$dbh->do(q{set search_path=xyz})
    or die "Can't set search path: " . $dbh->errstr;;


# Create test batches in database for us to query
my @test_batches = (
    {
        batch_number => 'TEST-001',
        batch_class => 'ap',
        batch_date => '2018-09-08',
        description => 'Test AP batch Description',
        __POST => 1,
    },
    {
        batch_number => 'TEST-BATCH-100',
        batch_class => 'ar',
        batch_date => '2017-09-08',
        description => 'Test AR batch description',
    },
    {
        batch_number => 'TEST-101',
        batch_class => 'ar',
        batch_date => '2017-09-08',
        description => 'Test AR batch description',
    },
    {
        batch_number => 'TEST-102',
        batch_class => 'payment',
        batch_date => '2017-11-08',
        description => 'Test Payment batch description',
    },

);

foreach my $batch_data(@test_batches) {
    my $batch = LedgerSMB::Batch->new(%$batch_data);
    $batch->set_dbh($dbh);
    my $batch_id = $batch->create or die 'Failed to create test batch';

    if($batch_data->{__POST}) {
        $batch = LedgerSMB::Batch->new(
            dbh => $dbh,
            batch_id => $batch_id,
            );
        $batch->get;
        $batch->post or die 'Failed to post/approve test batch';
    }
}



# Initialise Object
$report = LedgerSMB::Report::Unapproved::Batch_Overview->new(
    _uri => URI->new,
    );
isa_ok($report, ['LedgerSMB::Report::Unapproved::Batch_Overview'], 'instantiated object');
ok($report->set_dbh($dbh), 'set dbh');

# Query with no filter
ok($rows = $report->get_rows, 'get_rows() called ok');
is(ref $rows, 'ARRAY', 'get_rows() returns an arrayref');
is($rows, $report->rows, 'rows property is set by run_report()');
is(ref $report->rows, 'ARRAY', 'rows property is an arrayref');
is(scalar @{$report->rows}, scalar @test_batches, 'returned all rows');

# Query description - should return just 1 row
ok($report->description('AP batch'), 'set description');
ok($rows = $report->get_rows, 'get_rows() with description');
is(scalar @{$rows}, 1, 'querying description returned 1 row');
$row = $$rows[0];
is(ref $row, 'HASH', 'first returned element is a hashref');
ok($row->{id}, 'row id field is defined');
is($row->{id}, $row->{row_id}, 'row_id field matches id field');
is($row->{batch_class}, 'ap', 'row batch_class field is correct');
is($row->{control_code}, 'TEST-001', 'row control_code field is correct');
is($row->{description}, 'Test AP batch Description', 'row payment field is correct');
is($row->{default_date}, '2018-09-08', 'row default_date field is correct');
is($row->{transaction_total}, 0, 'row transaction_total field is correct');
is($row->{payment_total}, 0, 'row payment_total field is correct');
like($row->{created_on}, qr/\d{4}-\d{2}-\d{2}/, 'row created_on field is of expected format');
ok(exists $row->{created_by}, 'row created_by field exists');
ok(exists $row->{lock_success}, 'row lock_success field exists');
is($report->description(undef), undef, 'reset description filter');

# Query class_id
ok($report->class_id(3), 'set class_id filter');
ok($rows = $report->get_rows, 'get_rows() with batch_class');
is(scalar @{$rows}, 1, 'querying with class_ids returned 1 row');
$row = $$rows[0];
is($row->{description}, 'Test Payment batch description', 'row control_code field is correct');
is($report->class_id(undef), undef, 'reset class_id filter');

# Query approved
is($report->approved(1), 1, 'set approved filter = true');
ok($rows = $report->get_rows, 'get_rows() with approved_filter = true');
is(scalar @{$rows}, 1, 'querying with approved=true returned 1 row');
is($report->approved(undef), undef, 'reset approved filter');

# Query unapproved
is($report->approved(0), 0, 'set approved filter = false');
ok($rows = $report->get_rows, 'get_rows() with approved_filter = false');
is(scalar @{$rows}, 3, 'querying with approved=false returned 3 rows');
is($report->approved(undef), undef, 'reset approved filter');


#TODO Query Amount
# This needs test transactions added into the database.
# That will change when multi-currency is merged.


# Don't commit any of our changes
$dbh->rollback;

done_testing;
