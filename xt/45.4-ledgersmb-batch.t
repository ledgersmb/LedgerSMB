#!/usr/bin/perl

=head1 UNIT TESTS FOR LedgerSMB::Batch

Unit tests for the LedgerSMB::Batch module that exercise
interaction with a test database.

Currently tests only creation, retrieval and deletion.

=cut

use Test2::V0;

use DBI;
use LedgerSMB::Batch;


# Create test run conditions
my $batch;
my $id;
my $data;
my $result;
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$ENV{LSMB_NEW_DB}",
    undef,
    undef,
    { AutoCommit => 0, PrintError => 0 }
) or die "Can't connect to template database: " . DBI->errstr;
$dbh->{private_LedgerSMB} = { schema => 'xyz' };
$dbh->do(q{set search_path=xyz})
    or die "Can't set search path: " . $dbh->errstr;;


# The test database should already have batch classes defined
my $q = $dbh->prepare("SELECT id FROM batch_class WHERE class='ar'")
  or die 'Failed to prepare batch_class query: ' . DBI->errstr;
$q->execute
  or die 'Failed to execute batch_class query: ' . DBI->errstr;
my ($batch_class_id) = $q->fetchrow_array
  or die 'Failed to retrieve batch class "ap": ' . DBI->errstr;



# Create a batch
$data = {
    dbh => $dbh,
    batch_number => 'TEST-001',
    batch_class => 'ar',
    batch_date => '2018-09-08',
    description => 'Test Description',
};
$batch = LedgerSMB::Batch->new(%$data);
isa_ok($batch, ['LedgerSMB::Batch'], 'instantiated object with data');
$id = $batch->create;
ok($id, 'batch creation returns true');
like($id, qr/^\d+$/, 'batch creation returns numeric id');
is($id, $batch->{id}, 'id object property matches returned id');


# Retrieve a batch
$data = {
    dbh => $dbh,
    batch_id => $id,
};
$batch = LedgerSMB::Batch->new(%$data);
isa_ok($batch, ['LedgerSMB::Batch'], 'instantiated object');
$result = $batch->get;
isa_ok($result, ['LedgerSMB::Batch'], 'object returned after retrieving batch');
is($result->{id}, $id, 'retrieved batch id matches requested id');
is($result->{id}, $batch->{batch_id}, 'retrieved id property');
is($result->{description}, 'Test Description', 'retrieved description');
is($result->{batch_class_id}, $batch_class_id, 'retrieved batch_class_id');
is($result->{control_code}, 'TEST-001', 'retrieved control_code');
is($result->{default_date}, '2018-09-08', 'retrieved default_date');
ok(exists $result->{created_by}, 'retrieved created_by');
ok(exists $result->{approved_on}, 'retrieved approved_on');
is($result->{approved_on}, undef, 'retrieved approved_on is undef');
like($result->{created_on}, qr/^\d{4}-\d{2}-\d{2}$/, 'retrieved created on');
ok(exists $result->{locked_by}, 'retrieved locked_by');
is($result->{loked_by}, undef, 'retrieved locked_by is undef');
ok(exists $result->{approved_by}, 'retrieved approved_by');
is($result->{approved_by}, undef, 'retrieved approved_by is undef');


# Delete a batch
$data = {
    dbh => $dbh,
    batch_id => $id,
};
$batch = LedgerSMB::Batch->new(%$data);
isa_ok($batch, ['LedgerSMB::Batch'], 'instantiated object');
$result = $batch->delete;
ok($result, 'deleting a batch returns true');


# Retrieve a non-existent batch
$data = {
    dbh => $dbh,
    batch_id => $id,
};
$batch = LedgerSMB::Batch->new(%$data);
isa_ok($batch, ['LedgerSMB::Batch'], 'instantiated object');
$result = $batch->get;
isa_ok($result, ['LedgerSMB::Batch'], 'object returned after retrieving non-existent batch');
ok(exists $result->{id}, 'id property exists after retrieving non-existent batch');
is($result->{id}, undef, 'retrieved batch id undef after retrieving non-existent batch');


# Look up a batch class id
is($batch->get_class_id('ar'), $batch_class_id, 'batch class id lookup');


# Create and approve/post a batch
$data = {
    dbh => $dbh,
    batch_number => 'TEST-002',
    batch_class => 'ar',
    batch_date => '2018-09-08',
    description => 'Test Description',
};
$batch = LedgerSMB::Batch->new(%$data);
isa_ok($batch, ['LedgerSMB::Batch'], 'instantiated object with data');
like($id = $batch->create, qr/^\d+$/, 'batch creation returns numeric id');

$data = {
    dbh => $dbh,
    batch_id => $id,
};
$batch = LedgerSMB::Batch->new(%$data);
isa_ok($batch, ['LedgerSMB::Batch'], 'instantiated object');
$batch->get;
$result = $batch->post;
like($result, qr/^\d{4}-\d{2}-\d{2}$/, 'batch posting returns a date');


# Don't commit any of our changes
$dbh->rollback;


done_testing;
