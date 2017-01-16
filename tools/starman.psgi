#!/usr/bin/plackup



BEGIN {
    if ( $ENV{'LSMB_WORKINGDIR'}
         && -f "$ENV{'LSMB_WORKINGDIR'}/lib/LedgerSMB.pm" ) {
        chdir $ENV{'LSMB_WORKINGDIR'};
    }
}

package LedgerSMB::FCGI;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../old/lib';
use LedgerSMB::PSGI;
use LedgerSMB::PSGI::Preloads;
use LedgerSMB::Sysconfig;
use Log::Log4perl;

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

Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);

LedgerSMB::PSGI::setup_url_space(
        development => ($ENV{PLACK_ENV} eq 'development'),
        coverage => $ENV{COVERAGE}
        );


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
