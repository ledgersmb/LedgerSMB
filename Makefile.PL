#!/usr/bin/perl

use strict;
use warnings;
use inc::Module::Install 0.65;
use File::Copy;

copy ('conf/ledgersmb.conf.default', 'ledgersmb.conf') unless -f 'ledgersmb.conf';

name 'LedgerSMB';
version_from 'LedgerSMB.pm';
license 'GPL';

perl_version '5.10.1';

requires 'App::LedgerSMB::Admin' => 0.04;
requires 'CGI::Simple';
requires 'Carp::Always';
requires 'Config::IniFiles';
requires 'DBD::Pg';
requires 'DBI' => '1.00';
requires 'Data::Dumper';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'Digest::MD5';
requires 'File::MimeInfo';
requires 'JSON';
requires 'Locale::Maketext';
requires 'Locale::Maketext::Lexicon' => '0.62';
requires 'Log::Log4perl';
requires 'MIME::Base64';
requires 'MIME::Lite';
requires 'Math::BigFloat';
requires 'Moose';
requires 'Number::Format';
requires 'PGObject';
requires 'PGObject::Simple';
requires 'PGObject::Simple::Role';
requires 'PGObject::Type::BigFloat';
requires 'PGObject::Type::DateTime';
requires 'PGObject::Util::DBMethod';
requires 'PGObject::Util::DBAdmin' => '0.08';
requires 'TeX::Encode';
requires 'Template' => '2.14';
requires 'namespace::autoclean';


recommends 'Math::BigInt::GMP';

test_requires 'Test::More';
test_requires 'Test::Trap';
test_requires 'Test::Exception';
test_requires 'Test::BDD::Cucumber';
test_requires 'Perl::Critic';

feature 'RESTful Web Services XML support',
    -default => 0,
    'XML::Simple' => 0;

feature 'Standalone Server w/Starman',
    -default => 0,
    'Starman' => 0,
    'CGI::Emulate::PSGI' => 0,
    'Plack::Builder' => 0,
    'Plack::Middleware::Static' => 0;


feature 'Size detection for images for embedding in LaTeX templates',
    -default => 0,
    'Image::Size' => 0;

feature 'X12 EDI support',
    -default => 0,
    'X12::Parser' => 0;

# Rendering options
feature 'PDF and Postscript output',
    -default => 0,
    'Template::Plugin::Latex' => 0,
    'TeX::Encode' => 0;

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
