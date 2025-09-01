#!/usr/bin/plackup
#                                                      -*- mode: perl; -*-



BEGIN {
    if ( $ENV{'LSMB_WORKINGDIR'}
         && -f "$ENV{'LSMB_WORKINGDIR'}/lib/LedgerSMB.pm" ) {
        chdir $ENV{'LSMB_WORKINGDIR'};
    }
}

package LedgerSMB::FCGI;

use v5.14.0;

no lib '.';

use FindBin;
use lib $FindBin::Bin . '/..'; # For our 'old code'-"require"s

use LedgerSMB::Locale;
use LedgerSMB::PSGI;
use LedgerSMB::PSGI::Preloads;
use LedgerSMB::Sysconfig;
use LedgerSMB::Middleware::RequestID;

use Beam::Wire;
use File::Spec;
use Log::Any::Adapter;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Layout::PatternLayout;
use Plack::Builder;
use Scalar::Util qw(reftype);
use YAML::PP;

sub merge_config_hashes {
    my ($left, $right, $relative_entry, $path) = @_;
    $path //= '';
    my $ref_left = reftype $left;
    my $ref_right = reftype $right;

    if (not $ref_right or not $ref_left) {
        return $right // $left;
    }
     elsif ($ref_right eq 'ARRAY' and $ref_left eq 'ARRAY') {
        return $relative_entry ? [ $left->@*, $right->@* ] : [ $right->@* ];
    }
    elsif ($ref_right ne $ref_left) {
        die "Unsupported merge combination at $path: $ref_left and $ref_right";
    }

    # 2 hashes remain; merging required...
    my %key_rel = (
        (map { $_ => 0 } keys $left->%*),
        (map {
            m/^([+])?([^+].*)$/; $2 => $1;
         } keys $right->%*));

    return {
        map {
            $_ => merge_config_hashes(
                $left->{$_},
                $key_rel{$_} ? $right->{"+$_"} : $right->{$_},
                $key_rel{$_},
                "$path/$_"
                )
        } keys %key_rel
    };
}

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

    my $config;
    if (not defined $config_file
        or $config_file =~ /[.]ya?ml$/) {
        my $yp = YAML::PP->new( header => 0 );
        my $base_config = $yp->load_string( do { local $/ = undef; <DATA> } );

        if (defined $config_file) {
            $config_file = File::Spec->rel2abs( $config_file );
            $config = merge_config_hashes( $base_config,
                                           $yp->load_file( $config_file ) );

            my ($vol, $dirs, $file) = File::Spec->splitpath( $config_file );
            my $dir = File::Spec->catpath( $vol, $dirs, '' );
            if (opendir my $dh, $dir) {
                my @files = sort readdir $dh;
                while (my $incremental = pop @files) {
                    next unless $file eq ($incremental =~ s/\.\d+\././r);

                    my $p = File::Spec->catpath( $vol, $dirs, $incremental );
                    $config = merge_config_hashes( $config,
                                                   $yp->load_file( $p ) );
                }

                closedir $dh
                    or warn "Unable to close directory $dir";
            }
            else {
                warn "Skipping incremental configuration files; unable to open directory '$dir': $!";
            }
        }
        else {
            $config = $base_config;
        }
    }
    else {
        $config = LedgerSMB::Sysconfig->ini2wire( $config_file );
        $config->{extra_middleware} = [];
    }
    $wire = Beam::Wire->new( config => $config );
};

LedgerSMB::Locale->initialize($wire);

my $path = $INC{"LedgerSMB.pm"};
my $version = $LedgerSMB::VERSION;
die "Library verification failed (found $version from '$path', expected 1.14)"
    unless $version =~ /^1\.14\./;

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

__DATA__
cookie:
  name: LedgerSMB
db:
  $class: LedgerSMB::Database::Factory
  connect_data:
    sslmode: prefer
  source_dir:
    $ref: paths/sql
default_locale:
  $class: LedgerSMB::LanguageResolver
  directory:
    $ref: paths/locale
extra_middleware: []
logging:
  level: ERROR
login_settings: {}
mail:
  transport:
    $class: Email::Sender::Transport::Sendmail
miscellaneous:
  $class: Beam::Wire
  config:
    backup_email_from: ''
    max_upload_size: 4194304
    proxy_ip: 127.0.0.1/8 ::1/128 ::ffff:127.0.0.1/108
output_formatter:
  $class: LedgerSMB::Template::Formatter
  plugins:
  - $class: LedgerSMB::Template::Plugin::LaTeX
    format: PDF
  - $class: LedgerSMB::Template::Plugin::LaTeX
    format: PS
  - $class: LedgerSMB::Template::Plugin::XLSX
    format: XLS
  - $class: LedgerSMB::Template::Plugin::XLSX
    format: XLSX
  - $class: LedgerSMB::Template::Plugin::ODS
  - $class: LedgerSMB::Template::Plugin::CSV
  - $class: LedgerSMB::Template::Plugin::TXT
  - $class: LedgerSMB::Template::Plugin::HTML
paths:
  $class: Beam::Wire
  config:
    locale: ./locale/po/
    sql: ./sql/
    templates: ./templates/
    UI: ./UI/
    UI_cache: lsmb_templates/
    workflows:
    - workflows/
    - custom_workflows/
printers:
  $class: LedgerSMB::Printers
  printers: {}
  fallback: null
reconciliation_importer:
  $class: LedgerSMB::Reconciliation::Parser
  configurations:
  - $class: LedgerSMB::Reconciliation::Parser::OFX
    name: OFX Bank statement
  - $class: LedgerSMB::Reconciliation::Parser::CAMT053
    name: ISO 20022 - CAMT.053 (Customer statement)
  - $class: LedgerSMB::Reconciliation::Parser::CSV
    name: Raw CSV (with column names)
    first_row: headers
    mapping:
      source:
        column: scn
      amount:
        column: amount
        format: '1000.00'
      type:
        column: type
      date:
        column: cleared_date
        format: YYYY-MM-DD
  - $class: LedgerSMB::Reconciliation::Parser::CSV
    name: PayPal (CSV / Column names)
    first_row: headers
    mapping:
      source:
        column: Transaction ID
      amount:
        column: Gross
        format: 1'000.00
      type:
        column: Type
      date:
        column: Date
        format: DD/MM/YYYY
  - $class: LedgerSMB::Reconciliation::Parser::CSV
    name: PayPal (CSV / Column numbers -- no headings)
    first_row: data
    mapping:
      source:
        column: 13
      amount:
        column: 8
        format: 1'000.00
      type:
        column: 5
      date:
        column: 1
        format: DD/MM/YYYY
setup_settings:
  admin_db: template1
  auth_db: postgres
ui:
  $class: LedgerSMB::Template::UI
  $method: new_UI
  $lifecycle: eager
  cache:
    $ref: paths/UI_cache
  root:
    $ref: paths/UI
workflows:
  $class: LedgerSMB::Workflow::Loader
  $lifecycle: eager
  $method: load
  directories:
    $ref: paths/workflows
  lifecycle: eager
