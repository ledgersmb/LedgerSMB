#!/usr/bin/plackup 

BEGIN {
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        $ENV{PLACK_SERVER}       = 'Standalone';
        $ENV{METACPAN_WEB_DEBUG} = 1;
    }
}

package LedgerSMB::FCGI;

# Local packages
use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../old/lib';
use CGI::Emulate::PSGI;
use LedgerSMB;
use LedgerSMB::Auth;
use LedgerSMB::PSGI;
use LedgerSMB::Sysconfig;

use Log::Log4perl;

# Plack configuration
use Plack::Builder;
use Plack::App::File;
use Plack::App::URLMap;
use Plack::Middleware::Redirect;

# Optimization
use Plack::Middleware::ConditionalGET;
use Plack::Builder::Conditionals;
#use Plack::Middleware::TemplateToolkit;
use Plack::Middleware::ComboLoader;

# Development specific
use Plack::Middleware::Debug::Log4perl;
use Plack::Middleware::InteractiveDebugger;
#use Plack::Middleware::Debug::TemplateToolkit;

my $old_app = LedgerSMB::PSGI::old_app();
my $psgi_app = \&LedgerSMB::PSGI::psgi_app;


Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);

builder {

    enable 'InteractiveDebugger';

    enable 'Redirect', url_patterns => [
        qr/^\/?$/ => ['/login.pl',302]
    ];

    enable 'ContentLength';

    enable match_if path(qr!.+\.(css|js(-src)|png|ico|jp(e)?g|gif)$!),
        'ConditionalGET';

#    enable 'Debug',  panels => [
#            qw(Parameters Environment Response Log4perl Session),   # Timer Memory ModuleVersions PerlConfig
#              [ 'DBITrace', level => 2 ],
#              [ 'Profiler::NYTProf', exclude => [qw(.*\.css .*\.png .*\.ico .*\.js .*\.gif)], minimal => 1 ],
#           qw/Dancer::Settings Dancer::Logger Dancer::Version/
#    ] if $ENV{PLACK_ENV} =~ "development";

#    enable 'Debug::TemplateToolkit';    # enable debug panel
#    enable 'Log4perl', category => 'plack';

#    enable 'TemplateToolkit',
#        INCLUDE_PATH => 'UI',     # required
#        pass_through => 1;        # delegate missing templates to $app

    enable 'Plack::Middleware::Pod',
        path => qr{^/pod/},
        root => './',
        pod_view => 'Pod::POM::View::HTMl' # the default
    if $ENV{PLACK_ENV} =~ "development";

    mount '/rest/' => LedgerSMB::PSGI::rest_app();

    # not using @LedgerSMB::Sysconfig::scripts: it has not only entry-points
    mount "/$_.pl" => $old_app
        for ('aa', 'am', 'ap', 'ar', 'gl', 'ic', 'ir', 'is', 'oe', 'pe');

     mount "/$_" => $psgi_app
        for  (@LedgerSMB::Sysconfig::newscripts);

    mount '/stop.pl' => sub { exit; }
        if $ENV{COVERAGE};

    mount '/' => Plack::App::File->new( root => 'UI' )->to_app;
};

# -*- perl-mode -*-
