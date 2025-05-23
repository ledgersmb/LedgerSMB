#!/usr/bin/perl

=head1 UNIT TESTS FOR LedgerSMB::File::Internal

Partial tests for the LedgerSMB::Internal module, which subclasses
LedgerSMB::File.

=cut


use Test2::V0;

use DBI;
use LedgerSMB::File::Internal;
use LedgerSMB::Magic qw(FC_INTERNAL);
use PGObject::Util::DBAdmin;

#######################################
# Create test run conditions
my $file;
my $result;
my @files;
my $test_db = "$ENV{LSMB_NEW_DB}_lsmb_file_test";

# Connect to base template database
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$ENV{LSMB_NEW_DB}",
    undef,
    undef,
    { AutoCommit => 1, PrintError => 0 }
) or die "Can't connect to template database: " . DBI->errstr;

# Make a working copy of the template database
# We can't use a transation to make and rollback our changes as we
# need to test whether timestamps are updated between procedures.
# In a transaction, the timestamps will be identical.
$dbh->do(q{set client_min_messages = 'warning'});
$dbh->do("DROP DATABASE IF EXISTS $test_db");

my $count = 0;
while (not eval {
           $dbh->do("CREATE DATABASE $test_db WITH TEMPLATE $ENV{LSMB_NEW_DB}");
           1;
       }
       and $count < 3) {
    sleep rand(10);
}
die "Failed to create new database $test_db for tests" . DBI->errstr
    if $count > 2;

# Connect to the new working copy
$dbh = DBI->connect(
    "dbi:Pg:dbname=$test_db",
    undef,
    undef,
    { AutoCommit => 1, PrintError => 0 }
) or die "Can't connect to working database: " . DBI->errstr;
$dbh->{private_LedgerSMB} = { schema => 'xyz' };
$dbh->do(q{set search_path=xyz})
    or die "Can't set search path: " . $dbh->errstr;;

# Include plain text files in file output for invoice templates
$dbh->do("UPDATE mime_type SET invoice_include = TRUE WHERE mime_type='text/plain'")
    or die "Can't set mime type for inclusion on invoices";


#
#######################################


# Test that error is generated when storing a file without a valid lsmb user
$file = LedgerSMB::File::Internal->new(
    _dbh => $dbh,
    content => 'This is the file content',
    file_name => 'test_file.txt',
    description => 'This is the file description',
);
#TODO This test fails because of an SQL bug
#ok(!$file, 'error raised trying to store file without valid LedgerSMB user');


# Set up database environment for tests with valid LedgerSMB user
$dbh->do("
    INSERT INTO entity(
        name,
        control_code,
        country_id
    ) VALUES (
        'LSMB-FILE-TEST',
        'LSMB-FILE-TEST',
        1  -- Ascension Island
    )
") or die "Failed to insert test entity: " . DBI->errstr;

$dbh->do("
    INSERT INTO users(
        username,
        entity_id
    )
    SELECT SESSION_USER, id FROM entity
    WHERE name = 'LSMB-FILE-TEST'
") or die "Failed to insert test user: " . DBI->errstr;


# Store a new 'internal' file
$file = LedgerSMB::File::Internal->new(
    _dbh => $dbh,
    content => 'This is the file content',
    file_name => 'test_file.txt',
    description => 'This is the file description',
);
ok($file, 'LedgerSMB::File::Internal object created');
is($file->get_mime_type(), 'text/plain', 'MIME type set based on file extension');

$result = $file->attach;
ok($result && ref $result, 'stored new file');
is($result->{file_name}, 'test_file.txt', 'file name set correctly for new file');
is($result->{description}, 'This is the file description', 'description name set correctly for new file');
is(${$result->{content}}, 'This is the file content', 'file content set correctly for new file');
is($result->{file_class}, FC_INTERNAL, 'file class set to FC_INTERNAL for new file');
is($result->{ref_key}, 0, 'ref_key set to 0 for new file');
is($result->{mime_type_id}, 153, 'mime_type_id represents text/plain for new file');
like($result->{id}, qr/^\d+$/, 'id is numeric for new file');
like($result->{uploaded_by}, qr/^\d+$/, 'uploaded_by is numeric for new file');
like($result->{uploaded_at}, qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'uploaded_at is correct format for new file');


# Overwrite an existing 'internal' file
my $old_result = $result;
$file = LedgerSMB::File::Internal->new(
    _dbh => $dbh,
    content => 'New file content',
    file_name => 'test_file.txt',
    description => 'New description',
);
ok($file, 'LedgerSMB::File::Internal object created');

$result = $file->attach;
ok($result && ref $result, 'overwritten an existing file');

#TODO These tests are broken because of an SQL bug - nothing is returned after an update
#is($result->{file_name}, 'test_file.txt', 'file name set correctly when overwriting file');
#is($result->{description}, 'New description', 'description name set correctly when overwriting file');
#is(${$result->{content}}, 'New file content', 'file content set correctly when overwriting file');
#is($result->{file_class}, FC_INTERNAL, 'file class set to FC_INTERNAL when overwriting file');
#is($result->{ref_key}, 0, 'ref_key set to 0 when overwriting file');
#is($result->{mime_type_id}, 153, 'mime_type_id represents text/plain when overwriting file');
#is($result->{id}, $old_result->{id}, 'id remains the same when overwriting file');
#like($result->{uploaded_by}, qr/^\d+$/, 'uploaded_by is numeric for new file');
#like($result->{uploaded_at}, qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'uploaded_at is correct format when overwriting file');
#isnt($result->{uploaded_at}, $old_result->{uploaded_at}, 'uploaded_at changes when overwriting file');


# Retrieve the file
$file = LedgerSMB::File::Internal->new(
    _dbh => $dbh,
    id => $old_result->{id},
    file_class => FC_INTERNAL,
);
$file->get;
is($file->{file_name}, 'test_file.txt', 'file_name correct when retrieving file');
is($file->{description}, 'This is the file description', 'description correct when retrieving file');
is(${$file->{content}}, 'New file content', 'file content correct when retrieving file');
is($file->{file_class}, FC_INTERNAL, 'file class correct when overwriting file');
is($file->{ref_key}, 0, 'ref_key set to 0 when retrieving file');
is($file->{mime_type_id}, 153, 'mime_type_id represents text/plain when retrieving file');
is($file->{id}, $old_result->{id}, 'correct id when retrieving file');
is($file->{uploaded_by}, $old_result->{uploaded_by}, 'correct uploaded_by when retrieving file');
like($file->{uploaded_at}, qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'uploaded_at is correct format when retrieving file');
isnt($file->{uploaded_at}, $old_result->{uploaded_at}, 'uploaded_at has been changed by overwriting file');
is($file->{file_path}, undef, 'file_path is undef when retrieving file');
is($file->{reference}, undef, 'reference is undef when retrieving file');
is($file->{src_class}, undef, 'src_class is undef when retrieving file');

#TODO - These tests fail because the properties are not set, but are expected to pass
#is($file->{mime_type_text}, 'text/plain', 'mime_type_text set correctly when retrieving file');
#is($file->{uploaded_by_name}, 'LSMB-FILE-TEST', 'correct uploaded_by_name when retrieving file');


# Add another file of type 'text/x-uri'
# This isn't really a file, but the file storage mechanism is coerced
# to store uris, which are then given special treatment by retrieval methods
my $uri = LedgerSMB::File::Internal->new(
    _dbh => $dbh,
    content => 'https://ledgersmb.org',
    mime_type_text => 'text/x-uri',
    file_name => 'i-am-a-uri',  # cannot be null, must be unique, though it has no meaning for uri
    description => 'Link description',
);
ok($uri, 'LedgerSMB::File::Internal object created for uri');
is($uri->get_mime_type, 'text/x-uri', 'set mime type for uri');
ok($uri = $uri->attach, 'attached uri');


# List files
@files = $file->list({
    file_class => FC_INTERNAL,
    ref_key => 0,
});
is(scalar(@files), 2, 'list method returned correct number of files');

# Check results for uri. Content should be set
# Return order is not deterministic, so find the uri text file record to test
$result = $files[0]->{mime_type} eq 'text/x-uri' ? $files[0] : $files[1];

# Can't use is_deeply() as it won't handle content reference,
# so test each key/value separately
is(scalar(keys %{$result}), 10, 'get_for_template uri result has correct number of hash keys');
is($result->{id}, $uri->{id}, 'file list id is correct for uri');
is($result->{uploaded_by_id}, $uri->{uploaded_by}, 'file list uploaded_by_id is correct for uri');
is($result->{uploaded_by_name}, 'LSMB-FILE-TEST', 'file list uploaded_by_name is correct for uri');
is($result->{file_name}, 'i-am-a-uri', 'file list file_name is correct for uri');
is($result->{description}, 'Link description', 'file list description is correct for uri');
is(${$result->{content}}, 'https://ledgersmb.org', 'file list content is defined correctly for uri');
is($result->{mime_type}, 'text/x-uri', 'file list mime_type is correct for uri');
is($result->{file_class}, FC_INTERNAL, 'file list file_class is correct for uri');
is($result->{ref_key}, 0, 'file list ref_key is correct for uri');
is($result->{uploaded_at}, $uri->{uploaded_at}, 'file list uploaded_at is correct for uri');

# Check results for 'normal' file. Content should be undef
# Return order is not deterministic, so find the plain text file record to test
$result = $files[0]->{mime_type} eq 'text/plain' ? $files[0] : $files[1];

# Can't use is_deeply() as it won't handle content reference,
# so test each key/value separately.
is(scalar(keys %{$result}), 10, 'get_for_template file result has correct number of hash keys');
is($result->{id}, $file->{id}, 'file list id is correct for file');
is($result->{uploaded_by_id}, $file->{uploaded_by}, 'file list uploaded_by_id is correct for file');
is($result->{uploaded_by_name}, 'LSMB-FILE-TEST', 'file list uploaded_by_name is correct for file');
is($result->{file_name}, 'test_file.txt', 'file list file_name is correct for file');
is($result->{description}, 'This is the file description', 'file list description is correct for file');
is(${$result->{content}}, undef, 'file list content is undef for file');
is($result->{mime_type}, 'text/plain', 'file list mime_type is correct for file');
is($result->{file_class}, FC_INTERNAL, 'file list file_class is correct for file');
is($result->{ref_key}, 0, 'file list ref_key is correct for file');
is($result->{uploaded_at}, $file->{uploaded_at}, 'file list uploaded_at is correct for file');


# List links method
# Internal file class does not support links, so this should return no results
@files = $file->list_links({
    file_class => FC_INTERNAL,
    ref_key => 0,
});
is(scalar(@files), 0, 'list links method returns empty list');


# Get for template method
# Should only return one of the files we've added according to mime_type
@files = $file->get_for_template({
    file_class => FC_INTERNAL,
    ref_key => 0,
});
is(scalar(@files), 1, 'get_for_template method returned correct number of files');
$result = $files[0];

# Can't use is_deeply() as it won't handle content reference,
# so test each key/value separately
is(scalar(keys %{$result}), 10, 'get_for_template result has correct number of hash keys');
is($result->{description}, 'This is the file description', 'get_for_template result has correct description');
is($result->{file_class}, FC_INTERNAL, 'get_for_template result has correct file_class');
is($result->{ref_key}, 0, 'get_for_template result has correct ref_key');
is($result->{uploaded_at}, $file->{uploaded_at}, 'get_for_template result has correct uploaded_at');
is($result->{uploaded_by_id}, $file->{uploaded_by}, 'get_for_template result has correct uploaded_by');
is($result->{uploaded_by_name}, 'LSMB-FILE-TEST', 'get_for_template result has correct file_name');
is($result->{id}, $file->{id}, 'get_for_template result has correct id');
is($result->{mime_type}, 'text/plain', 'get_for_template result has correct mime_type');
is($result->{file_name}, 'testfile.txt', 'get_for_template result has correct file_name');
is(${$result->{content}}, 'New file content', 'get_for_template result has correct content');

# Check temporary directory
my $directory_path = $file->file_path;
ok(-d $directory_path, 'file_path temporary directory exists');

# Check written file
my $full_path = $directory_path . '/' . $result->{file_name};
my $fh;
ok(-f $full_path, 'extracted file exists in filesystem');
ok(open($fh, '<', $full_path), 'opened extracted file for reading');
local $/ = undef;
is(<$fh>, 'New file content', 'extracted file contains correct content');
ok(close $fh, 'closed extracted file after reading');

# Check temporary file clean up once out-of-scope
undef $result;
undef @files;
undef $file;
undef $uri;
ok(!-e $directory_path, 'temporary directory deleted once out-of-scope');


# Drop our working database
$dbh->disconnect;
$dbh = DBI->connect(
    "dbi:Pg:dbname=$ENV{LSMB_NEW_DB}",
    undef,
    undef,
    { AutoCommit => 1, PrintError => 0 }
) or die "Can't reconnect to template database: " . DBI->errstr;

$dbh->do("DROP DATABASE $test_db")
    or die "Can't drop test database: " . DBI->errstr;

done_testing;
