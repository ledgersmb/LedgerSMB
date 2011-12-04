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
#
our @newscripts = qw(
     account.pl  customer.pl  inventory.pl  payment.pl  user.pl
admin.pl    drafts.pl    journal.pl    recon.pl    vendor.pl
asset.pl    employee.pl  login.pl      setup.pl    vouchers.pl
file.pl      menu.pl       taxform.pl);

our @scripts = (
    'aa.pl', 'am.pl',      'ap.pl',
    'ar.pl', 'arap.pl',  'arapprn.pl', 'bp.pl',
    'ca.pl', 'gl.pl',
    'ic.pl',  'ir.pl',
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

my $modules_loglevel_overrides='';
my %tmp=%{$config{log4perl_config_modules_loglevel}} if $config{log4perl_config_modules_loglevel};
for(sort keys %tmp)
{
 #print STDERR "Sysconfig key=$_ value=$tmp{$_}\n";
 $modules_loglevel_overrides=$modules_loglevel_overrides.'log4perl.logger.'.$_.'='.$tmp{$_}."\n";
}
#print STDERR localtime()." Sysconfig \$modules_loglevel_overrides=$modules_loglevel_overrides\n";
# Log4perl configuration
our $log4perl_config = qq(
    log4perl.rootlogger = $log_level, Basic, Debug
    )
    .
    $modules_loglevel_overrides
    .
    qq(
    log4perl.appender.Screen = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.layout = SimpleLayout
    # Filter for debug level
    log4perl.filter.MatchDebug = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchDebug.LevelToMatch = INFO
    log4perl.filter.MatchDebug.AcceptOnMatch = false

    # Filter for everything but debug,trace level
    log4perl.filter.MatchRest = Log::Log4perl::Filter::LevelMatch
    log4perl.filter.MatchRest.LevelToMatch = INFO
    log4perl.filter.MatchRest.AcceptOnMatch = true

    # layout for DEBUG,TRACE messages
    log4perl.appender.Debug = Log::Log4perl::Appender::Screen
    log4perl.appender.Debug.layout = PatternLayout
    log4perl.appender.Debug.layout.ConversionPattern = %d - %p - %l -- %m%n
    log4perl.appender.Debug.Filter = MatchDebug

    # layout for non-DEBUG messages
    log4perl.appender.Basic = Log::Log4perl::Appender::Screen
    log4perl.appender.Basic.layout = PatternLayout
    log4perl.appender.Basic.layout.ConversionPattern = %d - %p - %C -- %m%n
    log4perl.appender.Basic.Filter = MatchRest
);
#some examples of loglevel setting for modules
#FATAL, ERROR, WARN, INFO, DEBUG, TRACE
#log4perl.logger.LedgerSMB = DEBUG
#log4perl.logger.LedgerSMB.DBObject = INFO
#log4perl.logger.LedgerSMB.DBObject.Employee = FATAL
#log4perl.logger.LedgerSMB.Handler = ERROR
#log4perl.logger.LedgerSMB.User = WARN
#log4perl.logger.LedgerSMB.ScriptLib.Company=TRACE
#print STDERR localtime()." Sysconfig log4perl_config=$log4perl_config\n";

$ENV{PGHOST} = $config{database}{host};
$ENV{PGPORT} = $config{database}{port};
our $default_db = $config{database}{default_db};
our $db_namespace = $config{database}{db_namespace} || 'public';
$ENV{PGSSLMODE} = $config{database}{sslmode} if $config{database}{sslmode};
$ENV{PG_CONTRIB_DIR} = $config{database}{contrib_dir};

$ENV{HOME} = $tempdir;

our $cache_template_dir = "$tempdir/lsmb_templates";
# Backup path
our $backuppath = $tempdir;

if(!(-d "$tempdir")){
     my $rc;
     if ($pathsep eq ';'){ # We need an actual platform configuration variable
        $rc = system("mkdir $tempdir");
     } else {
         $rc=system("mkdir -p $tempdir");#TODO what if error?
     #$logger->info("created tempdir \$tempdir rc=\$rc"); log4perl not initialised yet!
     }
 print STDERR localtime()." Sysconfig.pm created tempdir $tempdir rc=$rc\n";
}
1;
