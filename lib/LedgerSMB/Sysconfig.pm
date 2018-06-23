
package LedgerSMB::Sysconfig;

=head1 NAME

LedgerSMB::Sysconfig - LedgerSMB configuration management

=head1 DESCRIPTION

LedgerSMB configuration management

=head1 METHODS

This module doesn't specify any methods.

=cut

use strict;
use warnings;

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
    my $msg = '== ' . join("\n== ",@_);
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

        ## no critic (ProhibitNoStrict)
        no strict 'refs';           ## no critic (ProhibitProlongedStrictureOverride ) # sniff  # needed as we use the contents of a variable as the main variable name
        no warnings 'redefine';     ## no critic ( ProhibitNoWarnings ) # sniff
        ${$name} = $cfg->val($sec, $key, $default);     # get the value of config key $section.$key.  If it doesn't exist use $default instead
        if (defined $suffix) {
            ${$name} = "${$name}$suffix";               # Append a value suffix if defined, probably something like $EUID or $PID etc
        }

        ${$name} = $ENV{$envvar} if ( $envvar && defined $ENV{$envvar} );  # If an environment variable is associated and currently defined, override the configfile and default with the ENV VAR

        # If an environment variable is associated, set it  based on the
        # current value (taken from the config file, default, or pre-existing
        #  env var.
        $ENV{$envvar} = ${$name}    ## no critic   # sniff
            if $envvar && defined ${$name};

        # create a functional interface
        *{$name} = sub {
            my ($nv) = @_; # new value to be assigned
            my $cv = ${$name};

            ${$name} = $nv if scalar(@_) > 0;
            return $cv;
        };
    }
    return;
}



### SECTION  ---   debug

def 'dojo_built',
    section => 'debug',
    default => 1,
    doc => q{};

    # Debug Panels

def 'DBIProfile',
    section => 'debug',
    default => 0,
    doc => q{};

def 'DBIProfile_profile',
    section => 'debug',
    default => 2,
    doc => q{};

def 'DBITrace',
    section => 'debug',
    default => 1,
    doc => q{};

def 'DBITrace_level',
    section => 'debug',
    default => 2,
    doc => q{};

def 'Environment',
    section => 'debug',
    default => 0,
    doc => q{};

def 'InteractiveDebugger',
    section => 'debug',
    default => 0,
    doc => q{};

def 'LazyLoadModules',
    section => 'debug',
    default => 1,
    doc => q{};

def 'Log4perl',
    section => 'debug',
    default => 1,
    doc => q{};

def 'Memory',
    section => 'debug',
    default => 0,
    doc => q{};

def 'ModuleVersions',
    section => 'debug',
    default => 0,
    doc => q{};

def 'NYTProf',
    section => 'debug',
    default => 1,
    doc => q{};

def 'NYTProf_exclude',
    section => 'debug',
    default => [qw(.*\.css .*\.png .*\.ico .*\.js .*\.gif .*\.html)],
    doc => q{};

def 'NYTProf_minimal',
    section => 'debug',
    default => 1,
    doc => q{};

def 'Parameters',
    section => 'debug',
    default => 0,
    doc => q{};

def 'PerlConfig',
    section => 'debug',
    default => 0,
    doc => q{};

def 'Response',
    section => 'debug',
    default => 0,
    doc => q{};

def 'Session',
    section => 'debug',
    default => 0,
    doc => q{};

def 'Timer',
    section => 'debug',
    default => 0,
    doc => q{};

def 'TraceENV',
    section => 'debug',
    default => 1,
    doc => q{};

def 'TraceENV_method',
    section => 'debug',
    default => [qw/fetch store exists delete clear scalar firstkey nextkey/],
    doc => q{};

def 'W3CValidate',
    section => 'debug',
    default => 1,
    doc => q{};

def 'W3CValidate_uri',
    section => 'debug',
    default => 'http://validator.w3.org/check',
    doc => q{};

### SECTION  ---   main


def 'auth',
    section => 'main',
    default => 'DB',
    doc => q{};

def 'dojo_theme',
    section => 'main',
    default => 'claro',
    doc => q{};

def 'force_username_case',
    section => 'main',
    default => undef,  # don't force case
    doc => q{};

def 'max_post_size',
    section => 'main',
    default => 4194304, ## no critic ( ProhibitMagicNumbers)
    doc => q{};

def 'cookie_name',
    section => 'main',
    default => 'LedgerSMB-1.3',
    doc => q{};

# Maximum number of invoices that can be printed on a check
def 'check_max_invoices',
    section => 'main',
    default => 5,
    doc => q{};

# set language for login and admin
def 'language',
    section => 'main',
    default => 'en',
    doc => q{};

def 'date_format',
    section => 'main',
    default => 'yyyy-mm-dd',
    dock => q{Specifies the date format to be used for the database
admin application (setup.pl).

Note that the browser locale (language) will be used when this value isn't set.
The default is to use the iso date format (yyyy-mm-dd).};

def 'log_level',
    section => 'main',
    default => 'ERROR',
    doc => q{};

def 'DBI_TRACE',
    section => 'main', # SHOULD BE 'debug' ????
    default => 0,
    doc => q{};

def 'cache_templates',
    section => 'main',
    default => 0,
    doc => q{};

### SECTION  ---   paths

# Path to the translation files
def 'localepath',
    section => 'paths',
    default => 'locale/po',
    doc => '';


# spool directory for batch printing
def 'spool',
    section => 'paths',
    default => 'spool',
    doc => q{};

# templates base directory
def 'templates',
    section => 'paths',
    default => 'templates',
    doc => q{};

def 'templates_cache',
    section => 'paths',
    default => 'lsmb_templates',
    doc => q{this is a subdir of tempdir, unless it's an absolute path};

### SECTION  ---   Template file formats

def 'template_latex',
    section => 'template_format',
    default => 0,
    doc => q{Set to 'disabled' to prevent LaTeX output formats (Postscript and PDF) being made available};

def 'template_xls',
    section => 'template_format',
    default => 0,
    doc => q{Set to 'disabled' to prevent XLS output formats being made available};

def 'template_xlsx',
    section => 'template_format',
    default => 0,
    doc => q{Set to 'disabled' to prevent XLSX output formats being made available};

def 'template_ods',
    section => 'template_format',
    default => 0,
    doc => q{Set to 'disabled' to prevent ODS output formats being made available};


### SECTION  ---   mail

def 'sendmail',
    section => 'mail',
    default => '/usr/sbin/sendmail -t',
    doc => q{The sendmail command used for sending e-mail. Applies only when smtphost is not defined.};

def 'smtphost',
    section => 'mail',
    default => undef,
    doc => 'Connect to this SMTP host to send e-mails. If defined, used instead of sendmail.';

def 'smtpport',
    section => 'mail',
    default => 25,
    doc => 'Connect to the smtp host using this port.';

def 'smtptimeout',
    section => 'mail',
    default => 60,
    doc => 'Timeout in seconds for smtp connections.';

def 'smtpuser',
    section => 'mail',
    default => undef,
    doc => 'Optional username used when connecting to smtp server.';

def 'smtppass',
    section => 'mail',
    default => undef,
    doc => 'Optional password used when connecting to smtp server.';

def 'backup_email_from',
    section => 'mail',
    default => undef,
    doc => 'The e-mail address from which backups are sent.';


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


# available printers
our %printer;
for ($cfg->Parameters('printers')){
     $printer{$_} = $cfg->val('printers', $_);
}


# Programs
our $zip = $cfg->val('programs', 'zip', 'zip -r %dir %dir');


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
    log4perl.rootlogger = $LedgerSMB::Sysconfig::log_level, Basic, Debug, DebugPanel
    )
    .
    $modules_loglevel_overrides
    .
    q(
    log4perl.appender.Screen = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.layout = PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = Req:%Z %p - %m%n
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
    log4perl.appender.Debug.layout.ConversionPattern = Req:%Z %d - %p - %l -- %m%n
    log4perl.appender.Debug.Filter = MatchDebug

    # layout for non-DEBUG messages
    log4perl.appender.Basic = Log::Log4perl::Appender::Screen
    log4perl.appender.Basic.layout = PatternLayout
    log4perl.appender.Basic.layout.ConversionPattern = Req:%Z %d - %p - %M -- %m%n
    log4perl.appender.Basic.Filter = MatchRest

    log4perl.appender.DebugPanel              = Log::Log4perl::Appender::TestBuffer
    log4perl.appender.DebugPanel.name         = psgi_debug_panel
    log4perl.appender.DebugPanel.mode         = append
    log4perl.appender.DebugPanel.layout       = PatternLayout
    log4perl.appender.DebugPanel.layout.ConversionPattern = %r >> %p >> %m >> %c >> at %F line %L%n
    #log4perl.appender.DebugPanel.Threshold = TRACE

    );
#some examples of loglevel setting for modules
#FATAL, ERROR, WARN, INFO, DEBUG, TRACE
#log4perl.logger.LedgerSMB = DEBUG
#log4perl.logger.LedgerSMB.DBObject = INFO
#log4perl.logger.LedgerSMB.DBObject.Employee = FATAL
#log4perl.logger.LedgerSMB.Handler = ERROR
#log4perl.logger.LedgerSMB.User = WARN
#log4perl.logger.LedgerSMB.ScriptLib.Company=TRACE


# if you have latex installed set to 1
our $latex = 0;


sub override_defaults {

    local $@ = undef; # protect existing $@

    # Check Latex
    $latex = eval {require Template::Plugin::Latex; 1;};

    # Check availability and loadability
    $LedgerSMB::Sysconfig::template_latex = (
        $LedgerSMB::Sysconfig::template_latex ne 'disabled' &&
        eval {require LedgerSMB::Template::LaTeX}
    );
    $LedgerSMB::Sysconfig::template_xls = (
        $LedgerSMB::Sysconfig::template_xls ne 'disabled' &&
        eval {require LedgerSMB::Template::XLS}
    );
    $LedgerSMB::Sysconfig::template_xlsx = (
        $LedgerSMB::Sysconfig::template_xlsx ne 'disabled' &&
        eval {require LedgerSMB::Template::XLSX}
    );
    $LedgerSMB::Sysconfig::template_ods = (
        $LedgerSMB::Sysconfig::template_ods ne 'disabled' &&
        eval {require LedgerSMB::Template::ODS}
    );

    return;
}

override_defaults;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
