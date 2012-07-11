#  This is the new configuration file for LedgerSMB.  Eventually all system
# configuration directives will go here,  This will probably not fully replace
# the ledgersmb.conf until 1.3, however.

package LedgerSMB::Sysconfig;
use strict;
use warnings;
no strict qw(refs);
use Cwd;

# use LedgerSMB::Form;
use Config::IniFiles;
use DBI qw(:sql_types);
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# For Win32, change $pathsep to ';';
our $pathsep = ':';

our $auth = 'DB';
our $images = getcwd() . '/images'; 
our $cssdir = 'css/';
our $fs_cssdir = 'css/';

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
our $latex = eval {require Template::Plugin::Latex}; 

# Defaults to 1 megabyte
our $max_post_size = 1024 * 1024;

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
our $language = "en";

# Maximum number of invoices that can be printed on a check
our $check_max_invoices = 5;

# program to use for file compression
our $gzip = "gzip -S .gz";

# Path to the translation files
our $localepath = 'locale/po';

our $no_db_str = 'database';
our $log_level = 'ERROR';
our $DBI_TRACE=0;
# available printers
our %printer;

my $cfg = Config::IniFiles->new( -file => "ledgersmb.conf" ) || die @Config::IniFiles::errors;

# Root variables
for my $var (
    qw(pathsep log_level cssdir DBI_TRACE check_max_invoices language auth
    db_autoupdate force_username_case max_post_size cookie_name
    return_accno no_db_str tempdir cache_templates fs_cssdir)
  )
{
    ${$var} = $cfg->val('main', $var) if $cfg->val('main', $var);
}


if ($cssdir !~ m|/$|){
    $cssdir = "$cssdir/";
}

for ($cfg->Parameters('printers')){
     $printer{$_} = $cfg->val('printers', $_);   
}

# ENV Paths
for my $var (qw(PATH PERL5LIB)) {
     $ENV{$var} .= $pathsep . ( join $pathsep, $cfg->val('environment', $var));
}

# Application-specific paths
for my $var (qw(localepath spool templates images)) {
    ${$var} = $cfg->val('paths', $var) if $cfg->val('paths', $var);
}

# Programs
for my $var (qw(gzip)) {
    ${$var} = $cfg->val('prigrams', $var) if $cfg->val('prigrams', $var);
}

# mail configuration
for my $var (qw(sendmail smtphost smtptimeout smtpuser 
             smtppass smtpauthmethod backup_email_from)) 
{
    ${$var} = $cfg->val('mail', $var) if $cfg->val('mail', $var);
}

my $modules_loglevel_overrides='';

for (sort $cfg->Parameters('log4perl_config_modules_loglevel')){
  $modules_loglevel_overrides.='log4perl.logger.'.$_.'='.
        $cfg->val('log4perl_config_modules_loglevel', $_)."\n";
}
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
    log4perl.appender.Basic.layout.ConversionPattern = %d - %p - %M -- %m%n
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

$ENV{PGHOST} = $cfg->val('database', 'host');
$ENV{PGPORT} = $cfg->val('database', 'port');
our $default_db = $cfg->val('database', 'default_db');
our $db_namespace = $cfg->val('database', 'db_namespace') || 'public';
$ENV{PGSSLMODE} = $cfg->val('database', 'sslmode') 
    if $cfg->val('database', 'sslmode');
$ENV{PG_CONTRIB_DIR} = $cfg->val('database', 'contrib_dir');

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
}

1;
