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
use English qw(-no_match_vars);

=head2 die_pretty $line_1, $line_2, $line_N;

each $line_* is a string that will be output on a separate line:

=over

=item line_1

=item line_2

=item line_3

=item line_N

=back

=cut

sub die_pretty {
    my $dieHeader = '==============================================================================';
    my $msg = "== " . join("\n== ",@_);
    die("\n" . $dieHeader . "\n$msg\n" . $dieHeader . "\n" .' Stopped at '); # trailing "<space>" prevents the location hint from being lost when pushing it to a newline
}

my $cfg_file = $ENV{LSMB_CONFIG_FILE} // 'ledgersmb.conf';
my $cfg;
if (-r $cfg_file) {
    $cfg = Config::IniFiles->new( -file => $cfg_file ) || die @Config::IniFiles::errors;
}
else {
    warn "No configuration file; running with default settings\n";
    $cfg = Config::IniFiles->new();
}

our %config;
our %docs;

=head2 def $name, %args;

A function to define config keys and set their values on initialisation.

A value for the key will be sourced from the following with the first found having priority.

=over

=over

=item - ENV VAR

=item - Config File

=item - Default

=back

=back

=head2 keys in %args can be:

=over

=item section

section name

=item key

The key name

=item default

default value if otherwise not specified (no env var and no config file entry)

=item envvar

The name of an associated Environment Variable.
If the EnvVar is set it will be used to override the config file
Regardless, the EnvVar will be set based on the config file or coded default

=item suffix

If set specifies a suffix to be appended to any value provided via the config file, defaults, or ENV Var.
If used, often this would be configured as '-$EUID' or '-$PID'

=item doc

A description of the use of this key. Should normally be a scalar.

=back

=cut

sub def {
    my ($name, %args) = @_;
    my $sec = $args{section};
    my $key = $args{key} // $name;
    my $default = $args{default};
    my $envvar = $args{envvar};
    my $suffix = $args{suffix};

    $default = $default->()
        if ref $default && ref $default eq 'CODE';

    $docs{$sec}->{$key} = $args{doc};
    {
        ## no critic (strict);
        no strict 'refs';                               # needed as we use the contents of a variable as the main variable name
        no warnings 'redefine';
        ${$name} = $cfg->val($sec, $key, $default);     # get the value of config key $section.$key.  If it doesn't exist use $default instead
        if (defined $suffix) {
            ${$name} = "${$name}$suffix";               # Append a value suffix if defined, probably something like $EUID or $PID etc
        }

        ${$name} = $ENV{$envvar} if ( $envvar && defined $ENV{$envvar} );  # If an environment variable is associated and currently defined, override the configfile and default with the ENV VAR
        $ENV{$envvar} = ${$name}                                # If an environment variable is associated Set it based on the current value (taken from the config file, default, or pre-existing env var.
            if $envvar && defined ${$name};

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
    default => sub { $ENV{TEMP} && "$ENV{TEMP}/ledgersmb" || '/tmp/ledgersmb' }, # We can't specify envvar=>'TEMP' as that would overwrite TEMP with anything set in ledgersmb.conf. Conversely we need to use TEMP as the prefix for the default
    suffix => "-$EUID",
    doc => qq||;

# Backup files stored at"
def 'backupdir',
    section => 'paths',
    default => sub { $ENV{BACKUP} || "/tmp/ledgersmb-backups" },
    doc => qq||;

# Path to the translation files
def 'localepath',
    section => 'paths',
    default => 'locale/po',
    doc => '';


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

def 'templates_cache',
    section => 'paths',
    default => 'lsmb_templates',
    doc => qq|this is a subdir of tempdir, unless it's an absolute path|;

### SECTION  ---   Template file formats

def 'template_latex',
    section => 'template_format',
    default => 0,
    doc => qq||;

def 'template_xls',
    section => 'template_format',
    default => 0,
    doc => qq||;

def 'template_xlsx',
    section => 'template_format',
    default => 0,
    doc => qq||;

def 'template_ods',
    section => 'template_format',
    default => 0,
    doc => qq||;


### SECTION  ---   mail

def 'sendmail',
    section => 'mail',
    default => '/usr/sbin/sendmail -t',
    doc => qq|location of sendmail|;


def 'smtphost',
    section => 'mail',
    default => '',
    doc => '';

def 'smtptimeout',
    section => 'mail',
    default => 60,
    doc => '';

def 'smtpuser',
    section => 'mail',
    default => '',
    doc => '';

def 'smtppass',
    section => 'mail',
    default => '',
    doc => '';

def 'smtpauthmethod',
    section => 'mail',
    default => '',
    doc => '';

def 'backup_email_from',
    section => 'mail',
    default => '',
    doc => '';


### SECTION  ---   database

def 'db_host',
    key => 'host',
    section => 'database',
    envvar => 'PGHOST',
    default => 'localhost',
    doc => '';

def 'db_port',
    key => 'port',
    section => 'database',
    envvar => 'PGPORT',
    default => '5432',
    doc => '';

def 'default_db',
    section => 'database',
    default => undef,
    doc => '';

def 'db_namespace',
    section => 'database',
    default => 'public',
    doc => '';

def 'db_sslmode',
    section => 'database',
    default => 'prefer',
    envvar => 'PGSSLMODE',
    doc => '';

### SECTION  ---   debug

def 'dojo_built',
    section => 'debug',
    default => 1,
    doc => qq||;




### WHAT DOES THIS DO???
our @io_lineitem_columns = qw(unit onhand sellprice discount linetotal);





# available printers
our %printer;
for ($cfg->Parameters('printers')){
     $printer{$_} = $cfg->val('printers', $_);
}


# Programs
our $zip = $cfg->val('programs', 'zip', 'zip -r %dir %dir');
our $gzip = $cfg->val('programs', 'gzip', "gzip -S .gz");



# Whitelist for redirect destination / this isn't really configuration.
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

# ENV Paths
for my $var (qw(PATH PERL5LIB)) {
     $ENV{$var} .= $Config{path_sep} . ( join $Config{path_sep}, $cfg->val('environment', $var, ''));
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

    log4perl.appender.DebugPanel              = Log::Log4perl::Appender::TestBuffer
    log4perl.appender.DebugPanel.name         = psgi_debug_panel
    log4perl.appender.DebugPanel.mode         = append
    log4perl.appender.DebugPanel.layout       = PatternLayout
    log4perl.appender.DebugPanel.layout.ConversionPattern = %r >> %p >> %m >> %c >> at %F line %L%n
    log4perl.appender.DebugPanel.Threshold = TRACE
);
#some examples of loglevel setting for modules
#FATAL, ERROR, WARN, INFO, DEBUG, TRACE
#log4perl.logger.LedgerSMB = DEBUG
#log4perl.logger.LedgerSMB.DBObject = INFO
#log4perl.logger.LedgerSMB.DBObject.Employee = FATAL
#log4perl.logger.LedgerSMB.Handler = ERROR
#log4perl.logger.LedgerSMB.User = WARN
#log4perl.logger.LedgerSMB.ScriptLib.Company=TRACE


if(!(-d LedgerSMB::Sysconfig::tempdir())){
     my $rc;
     if ($Config{path_sep} eq ';'){ # We need an actual platform configuration variable
         $rc = system("mkdir " . LedgerSMB::Sysconfig::tempdir());
     } else {
         $rc=system("mkdir -p " . LedgerSMB::Sysconfig::tempdir());
     }
}

sub check_permissions {
    use English qw(-no_match_vars);

    if($EUID == 0){
        die_pretty( "Running a Web Service as root is a security problem",
                    "If you are starting LedgerSMB as a system service",
                    "please make sure that you drop privlidges as per README.md",
                    "and the example files in conf/",
                    "This makes it difficult to run on a privlidged port (<1024)",
                    "In theory you can pass the --user argument to starman,",
                    "However starman drops privlidges too late, starting us as root."
        )
    }


    my $tempdir = LedgerSMB::Sysconfig::tempdir();
    # commit 6978b88 added this line to resolve issues if HOME isn't set
    $ENV{HOME} = $tempdir;


    if(!(-d "$tempdir")){
        die_pretty( "$tempdir wasn't created.",
                    "Does UID $EUID have access to $tempdir\'s parent?"
        );
    }

    if(!(-r "$tempdir")){
        die_pretty(" $tempdir can't be read from.",
                    "Does UID $EUID have read permission?"
        );
    }

    if(!(-w "$tempdir")){
        die_pretty( "$tempdir can't be written to.",
                    "Does UID $EUID have write permission?"
        );
    }

    if(!(-x "$tempdir")){
        die_pretty( "$tempdir can't be listed.",
                    "Does UID $EUID have execute permission?"
        );
    }
}

# if you have latex installed set to 1
###TODO-LOCALIZE-DOLLAR-AT
our $latex = 0;


sub override_defaults {

    local $@; # protect existing $@

    # Check Latex
    $latex = eval {require Template::Plugin::Latex; 1;};

    # Check availability and loadability
    $LedgerSMB::Sysconfig::template_latex = eval {require LedgerSMB::Template::LaTeX; 1}
        if $LedgerSMB::Sysconfig::template_latex ne 'disabled';
    $LedgerSMB::Sysconfig::template_xls   = eval {require LedgerSMB::Template::XLS; 1}
        if $LedgerSMB::Sysconfig::template_xls ne 'disabled';
    $LedgerSMB::Sysconfig::template_xlsx  = eval {require LedgerSMB::Template::XLSX; 1}
        if $LedgerSMB::Sysconfig::template_xlsx ne 'disabled';
    $LedgerSMB::Sysconfig::template_ods   = eval {require LedgerSMB::Template::ODS; 1}
        if $LedgerSMB::Sysconfig::template_ods ne 'disabled';
}

override_defaults;
check_permissions;

1;
