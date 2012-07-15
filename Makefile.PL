#!/usr/bin/perl

use strict;
use warnings;
use inc::Module::Install 0.65;

name 'LedgerSMB';
version 1.3.20;
license 'GPL';

perl_version '5.8.1';

requires 'Data::Dumper';
requires 'Log::Log4perl';
requires 'Locale::Maketext';
requires 'DateTime';
requires 'Locale::Maketext::Lexicon' => '0.62';
requires 'DBI' => '1.00';
requires 'MIME::Base64';
requires 'Digest::MD5';
requires 'HTML::Entities';
requires 'DBD::Pg';
requires 'Math::BigFloat';
requires 'IO::File';
requires 'IO::Scalar';
requires 'Encode';
requires 'Time::Local';
requires 'Cwd';
requires 'Config::Std';
requires 'MIME::Lite';
requires 'Template' => '2.14';
requires 'Error';
requires 'CGI::Simple';
requires 'File::MimeInfo';

recommends 'perl-Math-BigInt-GMP';

test_requires 'Test::More';
test_requires 'Test::Trap';
test_requires 'Test::Exception';

feature 'Size detection for images for embedding in LaTeX templates',
    -default => 0,
    'Image::Size' => 0;

feature 'POS module credit card processing support',
    -default => 0,
    'Net::TCLink' => 0;

feature 'Experimental scripting engine',
    -default => 0,
    'Parse::RecDescent' => 0;

feature 'Developer tool dependencies',
    -default => 0,
    'Getopt::Long' => 0,
    'FileHandle' => 0,
    'Locale::Country' => 0,
    'Locale::Language' => 0;

# Rendering options
feature 'PDF and Postscript output',
    -default => 0,
    'Template::Plugin::Latex' => 1;

feature 'OpenOffice.org output',
    -default => 0,
    'XML::Twig' => 0,
    'OpenOffice::OODoc' => 0;

Makefile->postamble(
     qq{installdb :: \n\tLSMB_INSTALL_DB=1 LSMB_TEST_DB=1 make test\n}
);

Makefile->postamble(
     qq{installdb_interactive :: \n\tperl install_interactive.pl\n}
);


auto_install; # remove this line for 2.0
WriteAll;
