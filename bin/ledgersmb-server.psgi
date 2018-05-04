#!/usr/bin/plackup



BEGIN {
    if ( $ENV{'LSMB_WORKINGDIR'}
         && -f "$ENV{'LSMB_WORKINGDIR'}/lib/LedgerSMB.pm" ) {
        chdir $ENV{'LSMB_WORKINGDIR'};
    }
}

package LedgerSMB::FCGI;

no lib '.';

use FindBin;
use lib $FindBin::Bin . '/..'; # For our 'old code'-"require"s
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../old/lib';
use LedgerSMB::PSGI;
use LedgerSMB::PSGI::Preloads;
use LedgerSMB::Sysconfig;
use Log::Log4perl;
use Log::Log4perl::Layout::PatternLayout;
use LedgerSMB::Middleware::RequestID;

require Plack::Middleware::Pod
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' );

my $path = $INC{"LedgerSMB.pm"};
my $version = $LedgerSMB::VERSION;
die "Library verification failed (found $version from '$path', expected 1.7)"
    unless $version =~ /^1\.7\./;

# Report to the console what type of dojo we are running
if ( $LedgerSMB::Sysconfig::dojo_built) {
    print "Starting Worker on PID $$ Using Built Dojo\n";
} else {
    print "Starting Worker on PID $$ Using Dojo Source\n";
}

Log::Log4perl::Layout::PatternLayout::add_global_cspec(
    'Z',
    sub { return $LedgerSMB::Middleware::RequestID::request_id.''; });
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);


LedgerSMB::PSGI::setup_url_space(
        development => ($ENV{PLACK_ENV} eq 'development'),
        coverage => $ENV{COVERAGE}
        );


# -*- perl-mode -*-
