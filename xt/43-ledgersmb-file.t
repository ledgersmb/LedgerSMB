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


plan tests => (11);


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

SKIP: {
    eval{require Image::Size} or skip 'Image::Size not installed', 3;
    my $content;
    my @result;

    # Test private image size method with good data
    $content = slurp_file('t/data/8x8-image.png');
    @result = $file->_image_size($content);
    is_deeply(\@result, [8, 8, 'PNG'], '_image_size() correctly identified 8x8 PNG');

    # Test private image size method with bad data
    @result = $file->_image_size('BAD_IMAGE_DATA');
    is($result[0], undef, '_image_size() gives undefined x-dimension with bad data');
    is($result[1], undef, '_image_size() gives undefined y-dimension with bad data');
}



# Helper function to slurp contents of a file
sub slurp_file {
    my $filename = shift;
    open my $fh, '<', $filename
        or BAIL_OUT("error opening $filename for reading $!");
    local $/ = undef;
    return <$fh>;
}
