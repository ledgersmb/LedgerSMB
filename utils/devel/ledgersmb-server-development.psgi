#!/usr/bin/plackup

BEGIN {
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        $ENV{PLACK_SERVER}       = 'Standalone';
        $ENV{METACPAN_WEB_DEBUG} = 1;
    }
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
die "Library verification failed (found $version from '$path', expected 1.6)"
    unless $version =~ /^1\.6\./;

# Report to the console what type of dojo we are running
if ( $LedgerSMB::Sysconfig::dojo_built) {
    print "Starting Worker on PID $$ Using Built Dojo\n";
} else {
    print "Starting Worker on PID $$ Using Dojo Source\n";
}

Log::Log4perl::Layout::PatternLayout::add_global_cspec(
    'Z',
    sub { return $LedgerSMB::Middleware::RequestID::request_id.''; });

# Plack configuration
use Plack::Builder;

# Optimization
#use Plack::Middleware::TemplateToolkit;

# Development specific
sub check_config_option {
    my ($name,$module) = @_;
    return 0 if !eval "\$LedgerSMB::Sysconfig::$name";
    return 1 if !defined $module;
    unless (eval "require $module") {
        warn "$name requires $module";
        return 0;
    }
    return 1;
}
#TODO: Explore https://github.com/elindsey/Devel-hdb

Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);

builder {

    enable 'InteractiveDebugger'
        if check_config_option('InteractiveDebugger','Plack::Middleware::InteractiveDebugger');

    if ( $ENV{PLACK_ENV} =~ "development" ) {
        enable 'Debug', panels => [] ;
        for ( qw(Parameters Environment Response Session Timer Memory ModuleVersions PerlConfig)) {
            if ( check_config_option($_)) {
                enable "Debug::$_";
            }
        }
        for (qw(LazyLoadModules Log4perl)) {
            enable "Debug::$_"
                if check_config_option("$_","Plack::Middleware::Debug::$_");
        }
        enable 'Debug::W3CValidate', validator_uri => $LedgerSMB::Sysconfig::W3CValidate_uri
            if check_config_option('Log4perl','Plack::Middleware::Debug::W3CValidate');
        enable 'Debug::DBIProfile', profile => $LedgerSMB::Sysconfig::DBIProfile_profile
            if check_config_option('DBIProfile','Plack::Middleware::Debug::DBIProfile');
        enable 'Debug::DBITrace', level => $LedgerSMB::Sysconfig::DBITrace_level
            if check_config_option('DBITrace','Plack::Middleware::Debug::DBITrace');
        enable 'Debug::TraceENV', method => $LedgerSMB::Sysconfig::TraceENV_method
            if check_config_option('TraceENV','Plack::Middleware::Debug::TraceENV');
        enable 'Debug::Profiler::NYTProf', exclude => [$LedgerSMB::Sysconfig::NYTProf_exclude],
                                           minimal  => $LedgerSMB::Sysconfig::NYTProf_minimal
            if check_config_option('NYTProf','Plack::Middleware::Debug::Profiler::NYTProf');
    }
#   qw/Dancer::Settings Dancer::Logger Dancer::Version/

    LedgerSMB::PSGI::setup_url_space(
            development => ($ENV{PLACK_ENV} eq 'development'),
            coverage => $ENV{COVERAGE}
            );
};

# -*- perl-mode -*-

sub Plack::Loader::Restarter::valid_file {
    my($self, $file) = @_;

    # vim temporary file is  4913 to 5036
    # http://www.mail-archive.com/vim_dev@googlegroups.com/msg07518.html
    if ( $file->{path} =~ m{(\d+)$} && $1 >= 4913 && $1 <= 5036) {
        return 0;
    }
    my $ret = $file->{path} !~ m!\.(?:git|svn)[\/\\]|\.(?:bak|swp|swpx|swx)$|~$|_flymake\.p[lm]$|\.#!;
    $ret &= $file->{path} =~ m!\.(p[lm]|psgi)!;
    return $ret;
}
