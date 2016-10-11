#!/usr/bin/plackup



BEGIN {
    if ( $ENV{'LSMB_WORKINGDIR'}
         && -f "$ENV{'LSMB_WORKINGDIR'}/lib/LedgerSMB.pm" ) {
        chdir $ENV{'LSMB_WORKINGDIR'};
    }
}

package LedgerSMB::FCGI;

use FindBin;
use lib $FindBin::Bin . "/../lib";
use CGI::Emulate::PSGI;
use LedgerSMB;
use LedgerSMB::Auth;
use LedgerSMB::PSGI;
use LedgerSMB::Sysconfig;
use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::Redirect;
# Optimization
use Plack::Middleware::ConditionalGET;
use Plack::Builder::Conditionals;

require Plack::Middleware::Pod
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' );

my $path = $INC{"LedgerSMB.pm"};
my $version = $LedgerSMB::VERSION;
die "Library verification failed (found $version from '$path', expected 1.6)"
    unless $version =~ /^1\.6\./;

# # Lets report to the console what type of dojo we are running with
if ( $LedgerSMB::Sysconfig::dojo_built) {
    print "Starting Worker on PID $$ Using Built Dojo\n";
} else {
    print "Starting Worker on PID $$ Using Dojo Source\n";
}

my $old_app = LedgerSMB::PSGI::old_app();
my $new_app = LedgerSMB::PSGI::new_app();
my $psgi_app = \&LedgerSMB::PSGI::psgi_app;


builder {

    enable 'Redirect', url_patterns => [
        qr/^\/?$/ => ['/login.pl',302]
    ];

    enable match_if path(qr!.+\.(css|js|png|ico|jp(e)?g|gif)$!),
        'ConditionalGET';

    enable 'Plack::Middleware::Pod',
        path => qr{^/pod/},
        root => './',
        pod_view => 'Pod::POM::View::HTMl' # the default
    if $ENV{PLACK_ENV} =~ "development";

    mount '/rest/' => LedgerSMB::PSGI::rest_app();

    # not using @LedgerSMB::Sysconfig::scripts: it has not only entry-points
    mount "/$_" => $old_app
        for ('aa.pl', 'am.pl', 'ap.pl',
             'ar.pl', 'gl.pl', 'ic.pl', 'ir.pl',
             'is.pl', 'oe.pl', 'pe.pl');

    mount "/$_" => $psgi_app
          for ('account.pl', 'admin.pl', 'asset.pl', 'budget_reports.pl',
               'business_unit.pl', 'configuration.pl', 'contact_reports.pl',
               'file.pl', 'inv_reports.pl', 'journal.pl', 'login.pl',
               'lreports_co.pl', 'menu.pl',
               'parts.pl', 'payroll.pl', 'pnl.pl',
               'setup.pl', 'template.pl', 'user.pl' );

    mount "/$_" => $new_app
        for  (@LedgerSMB::Sysconfig::newscripts);

    mount '/stop.pl' => sub { exit; }
        if $ENV{COVERAGE};

    mount '/' => Plack::App::File->new( root => 'UI' )->to_app;
};

# -*- perl-mode -*-
