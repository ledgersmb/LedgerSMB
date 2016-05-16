#!perl


requires 'perl', '5.8.1';

requires 'CGI::Simple';
requires 'Carp::Always';
requires 'Config::IniFiles';
requires 'Cwd';
requires 'DBD::Pg';
requires 'DBI' => '1.00';
requires 'Data::Dumper';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'Digest::MD5';
requires 'Encode';
requires 'File::MimeInfo';
requires 'HTML::Entities';
requires 'IO::File';
requires 'IO::Scalar';
requires 'JSON';
requires 'Locale::Maketext';
requires 'Locale::Maketext::Lexicon' => '0.62';
requires 'Log::Log4perl';
requires 'MIME::Base64';
requires 'MIME::Lite';
requires 'Math::BigFloat';
requires 'Moose';
requires 'Number::Format';
requires 'TeX::Encode';
requires 'Template' => '2.14';
requires 'Time::Local';
requires 'Try::Tiny';
requires 'namespace::autoclean';

recommends 'Math::BigInt::GMP';

on 'develop' => sub {
    requires 'Test::More';
    requires 'Test::Trap';
    requires 'Test::Exception';

    # developer tools dependencies
    requires 'Getopt::Long';
    requires 'FileHandle';
    requires 'Locale::Country';
    requires 'Locale::Language';
};

feature 'rest', 'RESTful Web Services XML support' =>
    sub {
        requires 'XML::Simple';
};


feature 'starman', 'Standalone Server w/Starman' =>
    sub {
        requires 'Starman';
        requires 'CGI::Emulate::PSGI';
        requires 'Plack::Builder';
        requires 'Plack::Middleware::Static';
};


feature 'latex-pdf-images',
    'Size detection for images for embedding in LaTeX templates' =>
    sub {
        requires 'Image::Size';
};

feature 'script-engine', 'Experimental scripting engine' =>
    sub {
        requires 'Parse::RecDescent';
};


feature 'edi', 'X12 EDI support' =>
    sub {
        requires 'X12::Parser';
};

# Rendering options
feature 'latex-pdf-ps', 'PDF and Postscript output' =>
    sub {
        requires 'Template::Plugin::Latex';
        requires 'TeX::Encode';

};

feature 'openoffice', 'OpenOffice.org output' =>
    sub {
        requires 'XML::Twig';
        requires 'OpenOffice::OODoc';
};
