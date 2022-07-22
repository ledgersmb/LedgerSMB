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

my $wire;
do {
    my $config_file;
    if ($ENV{LSMB_CONFIG_FILE}
        and -e $ENV{LSMB_CONFIG_FILE}) {
        $config_file = $ENV{LSMB_CONFIG_FILE};
    }
    elsif (-f 'ledgersmb.yaml') {
        $config_file = 'ledgersmb.yaml';
    }
    elsif (-f 'ledgersmb.yml') {
        $config_file = 'ledgersmb.yml';
    }
    elsif (-f 'ledgersmb.conf') {
        $config_file = 'ledgersmb.conf';
    }

    if ($config_file =~ /[.]ya?ml$/) {
        $wire = Beam::Wire->new( file => $config_file);
    }
    else {
        my $cfg = LedgerSMB::Sysconfig->ini2wire( $config_file );
        $wire = Beam::Wire->new( config => { extra_middleware => [], %$cfg });
    }
};

LedgerSMB::Locale->initialize($wire);

my $path = $INC{"LedgerSMB.pm"};
my $version = $LedgerSMB::VERSION;
die "Library verification failed (found $version from '$path', expected 1.10)"
    unless $version =~ /^1\.10\./;

Log::Log4perl::Layout::PatternLayout::add_global_cspec(
    'Z',
    sub { return $LedgerSMB::Middleware::RequestID::request_id.''; });

my $log_config = $wire->get( 'logging' )->{file};
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
    my $log_level = $wire->get( 'logging' )->{level};
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
