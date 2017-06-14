#!perl


requires 'perl', '5.10.1';

requires 'CGI::Emulate::PSGI';
requires 'CGI::Simple';
requires 'CGI::Simple::Standard';
requires 'Config::IniFiles';
requires 'DBD::Pg', '3.3.0';
requires 'DBI';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'File::MimeInfo';
requires 'HTTP::Exception'; # YLA
requires 'JSON';
requires 'Locale::Maketext::Lexicon', '0.62';
requires 'Log::Log4perl';
requires 'MIME::Lite';
requires 'Module::Runtime';
requires 'Moose';
requires 'Moose::Role';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::NonMoose';
requires 'Number::Format';
requires 'PGObject', '1.403.2';

# cpanm doesn't handle our true dependency declaration correctly:
# PGObject::Simple 3.0.1 breaks our file uploads
#requires 'PGObject::Simple', '>=2.0.0, !=3.0.0, !=3.0.1';
#requires 'PGObject::Simple::Role', '1.13.2';

# so we use:
requires 'PGObject::Simple', '3.0.2';
requires 'PGObject::Simple::Role', '2.0.0';

requires 'PGObject::Type::BigFloat';
requires 'PGObject::Type::DateTime', '1.0.4';
requires 'PGObject::Type::ByteString', '1.1.1';
requires 'PGObject::Util::DBMethod';
requires 'PGObject::Util::DBAdmin', '0.09';
requires 'Plack::App::File';
requires 'Plack::Builder';
requires 'Plack::Middleware::ConditionalGET'; # YLA
requires 'Plack::Builder::Conditionals'; # YLA
requires 'Template', '2.14';
requires 'Template::Parser';
requires 'Template::Provider';
requires 'Try::Tiny';
requires "XML::Simple";
requires 'namespace::autoclean';

recommends 'Math::BigInt::GMP';

feature 'rest', "RESTful Web Service XML support" =>
    sub {
        # no dependencies which aren't already required above
};

feature 'starman', "Standalone Server w/Starman" =>
    sub {
        requires "Starman";
};

feature 'latex-pdf-images',
    "Size detection for images for embedding in LaTeX templates" =>
    sub {
        requires "Image::Size";
};

feature 'edi', "X12 EDI support" =>
    sub {
        requires 'X12::Parser';
        requires 'Path::Class';
};

feature 'latex-pdf-ps', "PDF and PostScript output" =>
    sub {
        requires 'LaTeX::Driver', '0.300.2';
        requires 'Template::Latex', '3.08';
        requires 'TeX::Encode';
};

feature 'openoffice', "OpenOffice.org output" =>
    sub {
        requires "XML::Twig";
        requires "OpenOffice::OODoc";
        requires 'OpenOffice::OODoc::Styles';
};

# Even with cpanm --notest, 'test' target of --installdeps
# will be included, so put our testing requirements in develop...
on 'develop' => sub {
    requires 'File::Util';
    requires 'Module::CPANfile'; # for 01.2-deps.t
    requires 'Perl::Critic';
    requires 'Pherkin::Extension::Weasel', '0.02';
    requires 'Test::BDD::Cucumber', '0.50';
    requires 'Test::Exception';
    requires 'Test::Trap';
    requires 'Test::Dependencies', '0.20';
    requires 'Test::Exception';
    requires 'Test::BDD::Cucumber', '0.50';
    requires 'Perl::Critic';
    requires 'Plack::Middleware::Pod'; # YLA - Generate browseable documentation
    requires 'Selenium::Remote::Driver';
    requires 'Weasel', '0.04';
    requires 'Weasel::Driver::Selenium2';
    requires 'Weasel::Widgets::Dojo';
};
