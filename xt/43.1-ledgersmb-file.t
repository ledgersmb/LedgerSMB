#!/usr/bin/perl

=head1 UNIT TESTS FOR LedgerSMB::File

Partial tests for the LedgerSMB::File module, currently testing
just the mime type functionality.

=cut


use strict;
use warnings;

use DBI;
use Test::More;
use LedgerSMB::File;


# Create test run conditions
my $file;
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$ENV{LSMB_NEW_DB}",
    undef,
    undef,
    { AutoCommit => 1, PrintError => 0 }
) or BAIL_OUT "Can't connect to template database: " . DBI->errstr;


plan tests => (14);


# Test detection of mime type from file extension
$file = LedgerSMB::File->new(
    _dbh => $dbh,
);
ok($file, 'LedgerSMB::File object created');
$file->file_name('index.html');
is($file->get_mime_type, 'text/html', q{automatically set mime type 'text/html' for filename 'index.html'});
is($file->mime_type_text, 'text/html', q{correct mime_type_text property after for filename 'index.html'});
like($file->mime_type_id, qr/^[1-9]\d*$/, q{valid mime_type_id property for filename 'index.html'});


# Test setting explicit mime type
$file = LedgerSMB::File->new(
    _dbh => $dbh,
);
ok($file, 'LedgerSMB::File object created');
$file->mime_type_text('image/png');
is($file->get_mime_type, 'image/png', q{returned 'image/png' after explicitly setting mime type});
is($file->mime_type_text, 'image/png', q{correct mime_type_text property after explicitly setting 'image/png' mime type});
like($file->mime_type_id, qr/^[1-9]\d*$/, q{valid mime_type_id property after explicitly setting 'image/png' mime type});


# Test scalar content is coerced into a reference
$file = LedgerSMB::File->new(
    _dbh => $dbh,
);
ok($file, 'LedgerSMB::File object created');
ok(ref $file->content('This is plain string content.'), 'Plain string content coerced into a reference');
is(${$file->content}, 'This is plain string content.', 'Plain string content returned ok');


# Test scalar reference content is accepted
$file = LedgerSMB::File->new(
    _dbh => $dbh,
);
ok($file, 'LedgerSMB::File object created');
my $content = 'This is scalar reference content.';
ok(ref $file->content(\$content), 'Scalar reference content accepted');
is(${$file->content}, 'This is scalar reference content.', 'Scalar reference content returned ok');

