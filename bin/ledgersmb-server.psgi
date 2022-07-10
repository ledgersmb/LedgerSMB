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

use LedgerSMB::Locale;
use LedgerSMB::PSGI;
use LedgerSMB::PSGI::Preloads;
use LedgerSMB::Sysconfig;

use Beam::Wire;
use Plack::Builder;
use Log::Any::Adapter;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Layout::PatternLayout;
use LedgerSMB::Middleware::RequestID;

LedgerSMB::Sysconfig->initialize( $ENV{LSMB_CONFIG_FILE} // 'ledgersmb.conf' );
my $wire;
if (-f 'ledgersmb.yaml') {
    $wire = Beam::Wire->new( file => 'ledgersmb.yaml');
}
else {
    $wire = Beam::Wire->new(
        config => {
            extra_middleware => []
        } );
}

LedgerSMB::Locale->initialize;

require Plack::Middleware::Pod
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' );

my $path = $INC{"LedgerSMB.pm"};
my $version = $LedgerSMB::VERSION;
die "Library verification failed (found $version from '$path', expected 1.10)"
    unless $version =~ /^1\.10\./;

# Report to the console what type of dojo we are running
if ( LedgerSMB::Sysconfig::dojo_built() ) {
    print "Starting Worker on PID $$ Using Built Dojo\n";
} else {
    print "Starting Worker on PID $$ Using Dojo Source\n";
}

Log::Log4perl::Layout::PatternLayout::add_global_cspec(
    'Z',
    sub { return $LedgerSMB::Middleware::RequestID::request_id.''; });

my $log_config = LedgerSMB::Sysconfig::log_config();
if ($log_config) {
    Log::Log4perl->init($log_config);
}
else {
    my %log_levels = (
        OFF   => $OFF,
        FATAL => $FATAL,
        ERROR => $ERROR,
        WARN  => $WARN,
        INFO  => $INFO,
        DEBUG => $DEBUG,
        TRACE => $TRACE,
        );
    my $log_level = LedgerSMB::Sysconfig::log_level();
    die "Invalid log level: $log_level" unless exists $log_levels{$log_level};
    Log::Log4perl->easy_init($log_levels{$log_level});
}
Log::Any::Adapter->set('Log4perl');

# Make sure to get the correct logging order on console logging
# (which mixes request logging with Log4perl logging)
STDOUT->autoflush(1);
STDERR->autoflush(1);


my $builder = Plack::Builder->new();
for my $mw ($wire->get( 'extra_middleware' )->@*) {
    $builder->add_middleware( $mw->{name}, $mw->{args}->@* );
}

# THIS HAS TO BE THE LAST THING IN THE FILE, EXCEPT FOR COMMENTS!
$builder->to_app(
    LedgerSMB::PSGI::setup_url_space(
        wire        => $wire,
        development => ($ENV{PLACK_ENV} eq 'development'),
    ));


# -*- perl-mode -*-
