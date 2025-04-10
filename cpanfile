#!perl


requires 'perl', '5.32.0';

requires 'Archive::Zip';
recommends 'Authen::SASL';
requires 'Beam::Wire';
requires 'CGI::Emulate::PSGI';
requires 'CGI::Parse::PSGI';
requires 'Config::IniFiles';
requires 'Cookie::Baker', '0.10'; # for 'samesite' attribute
requires 'DBD::Pg', '3.3.0';
requires 'DBI', '1.635';
requires 'Data::UUID';
requires 'DateTime';
requires 'DateTime::Format::Duration::ISO8601', '0.008';
requires 'DateTime::Format::Strptime';
requires 'Email::MessageID';
requires 'Email::Sender::Simple';
requires 'Email::Sender::Transport::SMTP';
requires 'Email::Stuffer';
requires 'Feature::Compat::Try';
requires 'File::Find::Rule';
requires 'Hash::Merge';
requires 'HTML::Entities';
requires 'HTML::Escape';
requires 'HTTP::AcceptLanguage';
requires 'HTTP::Headers::Fast', '0.21'; # for content_is_text() method
requires 'HTTP::Negotiate', '6.01';
requires 'HTTP::Status';
requires 'IO::Scalar';
requires 'JSON::MaybeXS';
requires 'JSONSchema::Validator', '0.010';
recommends 'Cpanel::JSON::XS', '3.0206'; # 3.0206 adds 'allow_bignum' option
recommends 'JSON::PP', '2.00'; # 1.99_01 adds 'allow_bignum'
requires 'JSONSchema::Validator';
requires 'List::MoreUtils';
requires 'Locale::CLDR';
# Keep thoss in sync with the languages defined in Pg-database.sql
requires 'Locale::CLDR::Locales::Ar';
requires 'Locale::CLDR::Locales::Bg';
requires 'Locale::CLDR::Locales::Ca';
requires 'Locale::CLDR::Locales::Cs';
requires 'Locale::CLDR::Locales::Da';
requires 'Locale::CLDR::Locales::De';
requires 'Locale::CLDR::Locales::El';
requires 'Locale::CLDR::Locales::En';
requires 'Locale::CLDR::Locales::Es';
requires 'Locale::CLDR::Locales::Et';
requires 'Locale::CLDR::Locales::Fi';
requires 'Locale::CLDR::Locales::Fr';
requires 'Locale::CLDR::Locales::Hu';
requires 'Locale::CLDR::Locales::Id';
requires 'Locale::CLDR::Locales::Is';
requires 'Locale::CLDR::Locales::It';
requires 'Locale::CLDR::Locales::Lt';
requires 'Locale::CLDR::Locales::Ms';
requires 'Locale::CLDR::Locales::Nb';
requires 'Locale::CLDR::Locales::Nl';
requires 'Locale::CLDR::Locales::Pl';
requires 'Locale::CLDR::Locales::Pt';
requires 'Locale::CLDR::Locales::Ru';
requires 'Locale::CLDR::Locales::Sv';
requires 'Locale::CLDR::Locales::Tr';
requires 'Locale::CLDR::Locales::Uk';
requires 'Locale::CLDR::Locales::Zh';
requires 'Locale::Maketext::Lexicon', '0.62';
requires 'Locales';
requires 'Log::Any';
requires 'Log::Any::Adapter';
requires 'Log::Any::Adapter::Log4perl';
requires 'Log::Log4perl';
requires 'Log::Log4perl::Layout::PatternLayout';
requires 'LWP::Simple';
requires 'MIME::Types';
requires 'Module::Runtime';
requires 'Moo';                           # for Email::Sender::Transport::SMTP workaround
requires 'MooX::Types::MooseLike::Base';  # for Email::Sender::Transport::SMTP workaround
requires 'Moose';
requires 'Moose::Role';
requires 'Moose::Util::TypeConstraints';
# Locale::CLDR depends on MooX::ClassAttribute, but our classes are Moose
# classes which means MooX::* gets upgraded to MooseX::*
requires 'MooseX::ClassAttribute';
requires 'MooseX::NonMoose';
requires 'Number::Format';
requires 'PGObject', '2.3.2';
# PGObject::Simple 3.0.1 breaks our file uploads
requires 'PGObject::Simple', '3.1.0';
requires 'PGObject::Simple::Role', '2.1.1';
requires 'PGObject::Composite';
requires 'PGObject::Type::Registry';
requires 'PGObject::Type::BigFloat', '2.0.1';
requires 'PGObject::Type::DateTime', '2.0.2';
requires 'PGObject::Type::ByteString', '1.2.3';
requires 'PGObject::Util::DBMethod', '1.1.0';
requires 'PGObject::Util::DBAdmin', '1.6.1';
requires 'Plack', '1.0031';
requires 'Plack::App::File';
requires 'Plack::Builder';
requires 'Plack::Builder::Conditionals';
requires 'Plack::Middleware::ConditionalGET';
requires 'Plack::Middleware::ReverseProxy';
requires 'Plack::Request';
requires 'Plack::Request::WithEncoding';
requires 'Plack::Util';
requires 'Plack::Util::Accessor';
requires 'Pod::Find';
requires 'Scope::Guard', '0.10';
requires 'Session::Storage::Secure';
requires 'String::Random';
requires 'Template', '2.14';
requires 'Template::Parser';
requires 'Template::Provider';
requires 'Text::CSV';
requires 'Text::Markdown';
requires 'URI';
requires 'URI::Escape';
requires 'Workflow', '1.59';
requires 'Workflow::Context', '1.59';
requires 'Workflow::Exception', '1.59';
requires 'Workflow::Factory', '1.59';
requires 'Workflow::Persister::DBI', '1.59';
requires 'Workflow::Persister::DBI::ExtraData', '1.59';
requires 'XML::LibXML';
requires 'XML::LibXML::XPathContext';
requires 'YAML::PP';
requires 'namespace::autoclean';

recommends 'Math::BigInt::GMP';

feature 'starman', 'Standalone Server w/Starman' =>
    sub {
        requires 'Starman';
};

feature 'edi', 'X12 EDI support' =>
    sub {
        requires 'X12::Parser';
        requires 'Path::Class';
};

feature 'latex-pdf-ps', 'PDF and PostScript output' =>
    sub {
        # 1.0.0 reports much better errors than 0.300.2 in case of
        # missing executables
        requires 'LaTeX::Driver', '1.0.0';
        requires 'Template::Latex', '3.08';
        requires 'Template::Plugin::Latex', '3.08';
        # 2.007 contains a fix for two characters we used to have
        # a work-around for in our code base.
        requires 'TeX::Encode', '2.007';
};

feature 'openoffice', 'OpenOffice.org output' =>
    sub {
        requires 'XML::Twig';
        requires 'OpenOffice::OODoc';
        requires 'OpenOffice::OODoc::Styles';
};

feature 'xls', 'Microsoft Excel' =>
    sub {
        requires 'Spreadsheet::WriteExcel';
        requires 'Excel::Writer::XLSX';
};

# Even with cpanm --notest, 'test' target of --installdeps
# will be included, so put our testing requirements in develop...
on 'develop' => sub {
    requires 'App::Prove', '3.41'; # parallel testing of pipe and socket sources
    requires 'Capture::Tiny';
    requires 'DBD::Mock', '1.58';
    requires 'File::Grep';
    requires 'File::Util';
    requires 'HTML::Lint';
    requires 'HTML::Lint::Parser', '2.26';
    requires 'HTML::Lint::Pluggable';
    requires 'HTML::Lint::Pluggable::HTML5';
    requires 'HTML::Lint::Pluggable::WhiteList';
    recommends 'Linux::Inotify2';
    requires 'Module::CPANfile'; # for 01.2-deps.t
    requires 'Perl::Critic';
    requires 'Perl::Critic::Moose';
    requires 'Perl::Critic::Policy::Modules::RequireExplicitInclusion';
    requires 'Pherkin::Extension::Weasel', '0.15';
    requires 'Pod::ProjectDocs';
    requires 'Selenium::Remote::Driver';
    requires 'TAP::Parser::SourceHandler::pgTAP', '3.33';
    requires 'Test::BDD::Cucumber', '0.79';
    if ($ENV{CI}) {
        # Required to suppress a variable re-definition
        requires 'Test::Dependencies', '0.30';
    }
    else {
        requires 'Test::Dependencies', '0.25';
    }
    requires 'Test::Harness', '3.41'; # parallel testing of pipe and socket sources
    requires 'Test::Pod', '1.00';
    requires 'Test::Pod::Coverage';
    requires 'Test2::Harness';
    requires 'Test2::V0';
    requires 'Test2::Plugin::Feature', '0.001112';
    requires 'Test2::Plugin::pgTAP';
    requires 'Text::Diff';
    requires 'Weasel', '0.29';
    requires 'Weasel::Driver::Selenium2', '0.12';
    requires 'Weasel::Session', '0.11';
    requires 'Weasel::Widgets::Dojo', '0.07';

    feature 'debug', 'Debug pane' =>
        sub {
              # No explicit require for debug pane, handled internaly
            recommends 'Devel::NYTProf';
            recommends 'Module::Versions';
            recommends 'Plack::Middleware::Debug::DBIProfile';
            recommends 'Plack::Middleware::Debug::DBITrace';
            recommends 'Plack::Middleware::Debug::LazyLoadModules';
            recommends 'Plack::Middleware::Debug::Log4perl';
            recommends 'Plack::Middleware::Debug::Profiler::NYTProf';
            recommends 'Plack::Middleware::Debug::RefCounts';
            recommends 'Plack::Middleware::Debug::TraceENV';
            recommends 'Plack::Middleware::Debug::W3CValidate';
            recommends 'Plack::Middleware::InteractiveDebugger';
    };
};
