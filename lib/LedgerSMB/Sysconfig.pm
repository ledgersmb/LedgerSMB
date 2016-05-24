#  This is the new configuration file for LedgerSMB.  Eventually all system
# configuration directives will go here,  This will probably not fully replace
# the ledgersmb.conf until 1.3, however.

package LedgerSMB::Sysconfig;
use strict;
use warnings;
use Cwd;

use Config;
use Config::IniFiles;
use DBI qw(:sql_types);
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $cfg = Config::IniFiles->new( -file => "ledgersmb.conf" ) || die @Config::IniFiles::errors;


our %config;
our %docs;

sub def {
    my ($name, %args) = @_;
    my $sec = $args{section};
    my $key = $args{key} // $name;
    my $default = $args{default};

    $default = $default->()
        if ref $default && ref $default eq 'CODE';

    $docs{$sec}->{$key} = $args{doc};
    {
        no strict 'refs';
        # $name = "LedgerSMB::Sysconfig::" . $name;
        ${$name} = $cfg->val($sec, $key, $default);

        # create a functional interface
        *{$name} = sub {
            my ($nv) = @_; # new value to be assigned
            my $cv = ${$name};

            ${$name} = $nv if scalar(@_) > 0;
            return $cv;
        };
    }
}



### SECTION  ---   main


def 'auth',
    section => 'main',
    default => 'DB',
    doc => qq||;

def 'dojo_theme',
    section => 'main',
    default => 'claro',
    doc => qq||;

def 'force_username_case',
    section => 'main',
    default => undef,  # don't force case
    doc => qq||;

def 'max_post_size',
    section => 'main',
    default => 1024 * 1024,
    doc => qq||;

def 'cookie_name',
    section => 'main',
    default => "LedgerSMB-1.3",
    doc => qq||;

# Maximum number of invoices that can be printed on a check
def 'check_max_invoices',
    section => 'main',
    default => 5,
    doc => qq||;

# set language for login and admin
def 'language',
    section => 'main',
    default => 'en',
    doc => qq||;

def 'log_level',
    section => 'main',
    default => 'ERROR',
    doc => qq||;

def 'DBI_TRACE',
    section => 'main', # SHOULD BE 'debug' ????
    default => 0,
    doc => qq||;

def 'no_db_str',
    section => 'main',
    default => 'database',
    doc => qq||;

def 'db_autoupdate',
    section => 'main',
    default => undef,
    doc => qq||;

def 'return_accno',
    section => 'main',
    default => undef,
    doc => qq||;

def 'cache_templates',
    section => 'main',
    default => 0,
    doc => qq||;


### SECTION  ---   paths

def 'pathsep',
    section => 'main', # SHOULD BE 'paths' ????
    default => ':',
    doc => qq|
The documentation for the 'main.pathsep' key|;

def 'cssdir',
    section => 'main', # SHOULD BE 'paths' ????
    default => 'css/',
    doc => qq||;

def 'fs_cssdir',
    section => 'main', # SHOULD BE 'paths' ????
    default => 'css/',
    doc => qq||;

# Temporary files stored at"
def 'tempdir',
    section => 'main', # SHOULD BE 'paths' ????
    default => sub { $ENV{TEMP} || '/tmp' },
    doc => qq||;

# spool directory for batch printing
def 'spool',
    section => 'paths',
    default => 'spool',
    doc => qq||;

# templates base directory
def 'templates',
    section => 'paths',
    default => 'templates',
    doc => qq||;




### WHAT DOES THIS DO???
our @io_lineitem_columns = qw(unit onhand sellprice discount linetotal);

# location of sendmail
our $sendmail = "/usr/sbin/sendmail -t";

# SMTP settings
our $smtphost   = '';
our $smtptimeout = 60;
our $smtpuser   = '';
our $smtppass   = '';
our $smtpauthmethod = '';
our $zip = 'zip -r %dir %dir';


# program to use for file compression
our $gzip = "gzip -S .gz";

# Path to the translation files
our $localepath = 'locale/po';



def 'dojo_built',
    section => 'debug',
    default => 1,
    doc => qq||;


# available printers
our %printer;




# Whitelist for redirect destination
#
our @newscripts = qw(
   account.pl admin.pl asset.pl budget_reports.pl budgets.pl business_unit.pl
   configuration.pl contact.pl contact_reports.pl drafts.pl
   file.pl goods.pl import_csv.pl inventory.pl invoice.pl inv_reports.pl
   journal.pl login.pl lreports_co.pl menu.pl order.pl parts.pl payment.pl
   payroll.pl pnl.pl recon.pl report_aging.pl reports.pl setup.pl taxform.pl
   template.pl timecard.pl transtemplate.pl trial_balance.pl user.pl vouchers.pl
);

our @scripts = (
    'aa.pl', 'am.pl',    'ap.pl',
    'ar.pl', 'arap.pl',  'arapprn.pl', 'gl.pl',
    'ic.pl', 'ir.pl',
    'is.pl', 'oe.pl',    'pe.pl',
);

# if you have latex installed set to 1
###TODO-LOCALIZE-DOLLAR-AT
our $latex = eval {require Template::Plugin::Latex};


for ($cfg->Parameters('printers')){
     $printer{$_} = $cfg->val('printers', $_);
}

# ENV Paths
for my $var (qw(PATH PERL5LIB)) {
     $ENV{$var} .= $Config{path_sep} . ( join $Config{path_sep}, $cfg->val('environment', $var, ''));
}

# Application-specific paths
for my $var (qw(localepath spool templates)) {
    no strict 'refs';
    ${$var} = $cfg->val('paths', $var) if $cfg->val('paths', $var);
}

# Programs
for my $var (qw(gzip zip)) {
    no  strict 'refs';
    ${$var} = $cfg->val('programs', $var) if $cfg->val('programs', $var);
}

# mail configuration
for my $var (qw(sendmail smtphost smtptimeout smtpuser
             smtppass smtpauthmethod backup_email_from))
{
    no strict 'refs';
    ${$var} = $cfg->val('mail', $var) if $cfg->val('mail', $var);
}

my $modules_loglevel_overrides='';

for (sort $cfg->Parameters('log4perl_config_modules_loglevel')){
  $modules_loglevel_overrides.='log4perl.logger.'.$_.'='.
        $cfg->val('log4perl_config_modules_loglevel', $_)."\n";
}
# Log4perl configuration
our $log4perl_config = qq(
    log4perl.rootlogger = $LedgerSMB::Sysconfig::log_level, Basic, Debug
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

our $db_host = $cfg->val('database', 'host');
our $db_port = $cfg->val('database', 'port');

$ENV{PGHOST} = $db_host;
$ENV{PGPORT} = $db_port;
our $default_db = $cfg->val('database', 'default_db');
our $db_namespace = $cfg->val('database', 'db_namespace') || 'public';
$ENV{PGSSLMODE} = $cfg->val('database', 'sslmode')
    if $cfg->val('database', 'sslmode');

$ENV{HOME} = LedgerSMB::Sysconfig::tempdir();

our $cache_template_dir =
    LedgerSMB::Sysconfig::tempdir() . "/lsmb_templates";
# Backup path
our $backuppath = LedgerSMB::Sysconfig::tempdir();

if(!(-d LedgerSMB::Sysconfig::tempdir())){
     my $rc;
     if ($Config{path_sep} eq ';'){ # We need an actual platform configuration variable
         $rc = system("mkdir " . LedgerSMB::Sysconfig::tempdir());
     } else {
         $rc=system("mkdir -p " . LedgerSMB::Sysconfig::tempdir());
     #$logger->info("created tempdir \$tempdir rc=\$rc"); log4perl not initialised yet!
     }
}

1;
