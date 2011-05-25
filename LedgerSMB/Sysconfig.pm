#  This is the new configuration file for LedgerSMB.  Eventually all system
# configuration directives will go here,  This will probably not fully replace
# the ledgersmb.conf until 1.3, however.

package LedgerSMB::Sysconfig;
use strict;
use warnings;
no strict qw(refs);
use Cwd;

# use LedgerSMB::Form;
use Config::Std;
use DBI qw(:sql_types);
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# For Win32, change $pathsep to ';';
our $pathsep = ':';

our $auth = 'DB';
our $logging = 0;      # No logging on by default
our $images = getcwd() . '/images'; 

our $force_username_case = undef; # don't force case

our @io_lineitem_columns = qw(unit onhand sellprice discount linetotal);

# Whitelist for redirect destination
our @scripts = (
    'aa.pl', 'admin.pl', 'am.pl',      'ap.pl',
    'ar.pl', 'arap.pl',  'arapprn.pl', 'bp.pl',
    'ca.pl', 'cp.pl',    'ct.pl',      'gl.pl',
    'hr.pl', 'ic.pl',    'io.pl',      'ir.pl',
    'is.pl', 'jc.pl',    'login.pl',   'menu.pl',
    'oe.pl', 'pe.pl',    'pos.pl',     'ps.pl',
    'pw.pl', 'rc.pl',    'rp.pl', 	'initiate.pl'
);

# if you have latex installed set to 1
our $latex = 1;

# Defaults to 1 megabyte
our $max_post_size = 1024 * 1024;

# defaults to 2-- default number of places to round amounts to
our $decimal_places = 2;

# defaults to LedgerSMB-1.3 - default spelling of cookie
our $cookie_name = "LedgerSMB-1.3";

# spool directory for batch printing
our $spool = "spool";

our $cache_templates = 0;
# path to user configuration files
our $userspath = "users";

# templates base directory
our $templates = "templates";

# Temporary files stored at"
our $tempdir = ( $ENV{TEMP} || '/tmp' );

our $cache_template_dir = "$tempdir/lsmb_templates";
# Backup path
our $backuppath = $tempdir;

# member file
our $memberfile = "users/members";

# location of sendmail
our $sendmail = "/usr/sbin/sendmail -t";

# SMTP settings
our $smtphost   = '';
our $smtptimout = 60;
our $smtpuser   = '';
our $smtppass   = '';
our $smtpauthmethod = '';

# set language for login and admin
our $language = "";

# Maximum number of invoices that can be printed on a check
our $check_max_invoices = 5;

# program to use for file compression
our $gzip = "gzip -S .gz";

# Path to the translation files
our $localepath = 'locale/po';

our $no_db_str = 'database';
our $log_level = 'ERROR';
# available printers
our %printer;

our %config;
read_config( 'ledgersmb.conf' => %config ) or die;
# Root variables
for my $var (
    qw(pathsep logging log_level check_max_invoices language auth latex
    db_autoupdate force_username_case max_post_size decimal_places cookie_name
    return_accno no_db_str tempdir cache_templates)
  )
{
    ${$var} = $config{''}{$var} if $config{''}{$var};
}

%printer = %{ $config{printers} } if $config{printers};

# ENV Paths
for my $var (qw(PATH PERL5LIB)) {
    if (ref $config{environment}{$var} eq 'ARRAY') {
        $ENV{$var} .= $pathsep . ( join $pathsep, @{ $config{environment}{$var} } );
    } elsif ($config{environment}{$var}) {
        $ENV{$var} .= $pathsep . $config{environment}{$var};
    }
}

# Application-specific paths
for my $var (qw(localepath spool templates images)) {
    ${$var} = $config{paths}{$var} if $config{paths}{$var};
}

# Programs
for my $var (qw(gzip)) {
    ${$var} = $config{programs}{$var} if $config{programs}{$var};
}

# mail configuration
for my $var (qw(sendmail smtphost smtptimeout smtpuser 
             smtppass smtpauthmethod)) 
{
    ${$var} = $config{mail}{$var} if $config{mail}{$var};
}

# We used to have a global dbconnect but have moved to single entries
for my $var (qw(DBhost DBport DBname DBUserName DBPassword)) {
    ${ "global" . $var } = $config{globaldb}{$var} if $config{globaldb}{$var};
}

#putting this in an if clause for now so not to break other devel users
#if ( $config{globaldb}{DBname} ) {
#    my $dbconnect = "dbi:Pg:dbname=$globalDBname host=$globalDBhost
#		port=$globalDBport user=$globalDBUserName
#		password=$globalDBPassword";    # for easier debugging
#    $GLOBALDBH = DBI->connect($dbconnect);
#    if ( !$GLOBALDBH ) {
#        $form = new Form;
#        $form->error("No GlobalDBH Configured or Could not Connect");
#    }
#    $GLOBALDBH->{pg_enable_utf8} = 1;
#}

# These lines prevent other apps in mod_perl from seeing the global db
# connection info

# Log4perl configuration
our $log4perl_config = qq(
    log4perl.rootlogger = $log_level, Screen, Basic
    log4perl.appender.Screen = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.layout = SimpleLayout
    # Filter for debug level
    log4perl.filter.MatchDebug = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchDebug.LevelToMatch = DEBUG
    log4perl.filter.MatchDebug.AcceptOnMatch = true

    # Filter for everything but debug level
    log4perl.filter.MatchRest = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchRest.LevelToMatch = DEBUG
    log4perl.filter.MatchRest.AcceptOnMatch = false

    # layout for DEBUG messages
    log4perl.appender.Debug = Log::Log4perl::Appender::Screen
    log4perl.appender.Debug.layout = PatternLayout
    log4perl.appender.Debug.layout.ConversionPattern = %d - %p - %l -- %m%n
    log4perl.appender.Debug.Filter = MatchDebug

    # layout for non-DEBUG messages
    log4perl.appender.Basic = Log::Log4perl::Appender::Screen
    log4perl.appender.Basic.layout = PatternLayout
    log4perl.appender.Basic.layout.ConversionPattern = %d - %p %m%n
    log4perl.appender.Basic.Filter = MatchRest

);

$ENV{PGHOST} = $config{database}{host};
$ENV{PGPORT} = $config{database}{port};
our $default_db = $config{database}{default_db};
our $db_namespace = $config{database}{db_namespace} || 'public';
$ENV{PGSSLMODE} = $config{database}{sslmode} if $config{database}{sslmode};
1;
