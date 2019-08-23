#!perl


requires 'perl', '5.18.0';

requires 'CGI::Emulate::PSGI';
requires 'CGI::Parse::PSGI';
requires 'Config::IniFiles';
requires 'DBD::Pg', '3.3.0';
requires 'DBI', '1.635';
requires 'Data::UUID';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'File::Find::Rule';
requires 'HTML::Entities';
requires 'HTML::Escape';
requires 'HTTP::Headers::Fast'; # dependency of Plack too; don't need '::Fast'
requires 'HTTP::Status';
requires 'IO::Scalar';
requires 'JSON::MaybeXS';
recommends 'Cpanel::JSON::XS', '3.0206'; # 3.0206 adds 'allow_bignum' option
recommends 'JSON::PP', '2.00'; # 1.99_01 adds 'allow_bignum'
requires 'List::MoreUtils';
requires 'Locale::Maketext::Lexicon', '0.62';
requires 'Log::Log4perl';
requires 'Log::Log4perl::Layout::PatternLayout';
requires 'LWP::Simple';
requires 'MIME::Lite';
requires 'MIME::Types';
requires 'Module::Runtime';
requires 'Moose';
requires 'Moose::Role';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::NonMoose';
requires 'Number::Format';
requires 'PGObject', '1.403.2';
# PGObject::Simple 3.0.1 breaks our file uploads
requires 'PGObject::Simple', '>=3.0.2';
requires 'PGObject::Simple::Role', '2.0.2';
requires 'PGObject::Type::BigFloat', '1.0.0';
requires 'PGObject::Type::DateTime', '1.0.4';
requires 'PGObject::Type::ByteString', '1.1.1';
requires 'PGObject::Util::DBMethod';
requires 'PGObject::Util::DBAdmin', '1.0.1';
requires 'Plack', '1.0031';
requires 'Plack::App::File';
requires 'Plack::Builder';
requires 'Plack::Builder::Conditionals';
requires 'Plack::Middleware::ConditionalGET';
requires 'Plack::Middleware::ReverseProxy';
requires 'Plack::Request';
requires 'Plack::Request::WithEncoding';
requires 'Plack::Util';
requires 'Template', '2.14';
requires 'Text::CSV';
requires 'Template::Parser';
requires 'Template::Provider';
requires 'Try::Tiny';
requires 'Text::CSV';
requires 'Text::Markdown';
requires 'Version::Compare';
requires 'XML::Simple';
requires 'namespace::autoclean';

recommends 'Math::BigInt::GMP';

feature 'starman', "Standalone Server w/Starman" =>
    sub {
        requires "Starman";
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
        requires 'Template::Plugin::Latex', '3.08';
        requires 'TeX::Encode';
};

feature 'openoffice', "OpenOffice.org output" =>
    sub {
        requires "XML::Twig";
        requires "OpenOffice::OODoc";
        requires 'OpenOffice::OODoc::Styles';
};

feature 'xls', "Microsoft Excel" =>
    sub {
        requires 'Spreadsheet::WriteExcel';
        requires 'Excel::Writer::XLSX';
};

# Even with cpanm --notest, 'test' target of --installdeps
# will be included, so put our testing requirements in develop...
on 'develop' => sub {
    requires 'App::Prove', '3.41'; # parallel testing of pipe and socket sources
    requires 'Capture::Tiny';
    requires 'DBD::Mock';
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
    requires 'Pherkin::Extension::Weasel', '0.09';
    requires 'Plack::Middleware::Pod'; # YLA - Generate browseable documentation
    requires 'Selenium::Remote::Driver';
    requires 'TAP::Parser::SourceHandler::pgTAP', '3.33';
    requires 'Test::BDD::Cucumber', '0.58';
    requires 'Test::Dependencies', '0.20';
    requires 'Test::Harness', '3.41'; # parallel testing of pipe and socket sources
    requires 'Test::Pod', '1.00';
    requires 'Test::Pod::Coverage';
    requires 'Weasel', '0.21';
    requires 'Weasel::Driver::Selenium2', '0.07';
    requires 'Weasel::Session', '0.11';
    requires 'Weasel::Widgets::Dojo', '0.04';

    feature 'debug', "Debug pane" =>
        sub {
              # No explicit require for debug pane, handled internaly
            recommends 'Devel::NYTProf';
            recommends 'Module::Versions';
            recommends 'Plack::Middleware::Debug::DBIProfile';
            recommends 'Plack::Middleware::Debug::DBITrace';
            recommends 'Plack::Middleware::Debug::LazyLoadModules';
            recommends 'Plack::Middleware::Debug::Log4perl';
            recommends 'Plack::Middleware::Debug::Profiler::NYTProf';
            recommends 'Plack::Middleware::Debug::TraceENV';
            recommends 'Plack::Middleware::Debug::W3CValidate';
            recommends 'Plack::Middleware::InteractiveDebugger';
    };
};
