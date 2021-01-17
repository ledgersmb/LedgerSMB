
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
use English;
use File::Find::Rule;
use String::Random;
use Symbol;
use Workflow::Factory qw(FACTORY);

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

=item doc

A description of the use of this key. Should normally be a scalar.

=back

=cut

my $cfg;
my @initializers;
sub def {
    my ($name, %args) = @_;
    my $sec = $args{section};
    my $key = $args{key} // $name;
    my $default = $args{default};
    my $envvar = $args{envvar};
    my $ref = qualify_to_ref $name;

    $default = $default->()
        if ref $default && ref $default eq 'CODE';



    my $var;
    push @initializers, sub {
        # get the value of config key $section.$key.
        #  If it doesn't exist use $default instead
        $var = $cfg->val($sec, $key, $default);

        # If an environment variable is associated and currently defined,
        #  override the configfile and default with the ENV VAR
        $var = $ENV{$envvar} if ( $envvar && defined $ENV{$envvar} );

        # If an environment variable is associated, set it  based on the
        # current value (taken from the config file, default, or
        # pre-existing env var.
        $ENV{$envvar} = $var    ## no critic (RequireLocalizedPunctuationVars)
            if $envvar && defined $var;
    };

    {
        no warnings 'redefine';     ## no critic ( ProhibitNoWarnings )
        # create a functional interface
        *{$ref} = sub {
            my ($nv) = @_; # new value to be assigned
            my $cv = $var;

            $var = $nv if scalar(@_) > 0;
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

def 'RefCounts',
    section => 'debug',
    default => 1,
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

def 'cookie_secret',
    section => 'main',
    default => sub { return String::Random->new->randpattern('.' x 50); },
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

def 'log_config',
    section => 'main',
    default => '',
    doc     => q{};

def 'cache_templates',
    section => 'main',
    default => 0,
    doc => q{};

### SECTION  ---   paths

# Path to the translation files
def 'localepath',
    section => 'paths',
    default => 'locale/po',
    doc => q{};


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

def 'workflows',
    section => 'paths',
    default => 'workflows',
    doc => q{directory where workflow files are stored;

defaults to './workflows'};

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

def 'smtpsender_hostname',
    section => 'mail',
    default => undef,
    doc => 'Sets the host name used to identify the host when connecting to the mail server (smtphost).';

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

def 'smtpauthmech',
    section => 'mail',
    default => 'PLAIN',
    doc => 'SASL mechanism to use for authentication

Note that the default (PLAIN) sends unencrypted passwords. Instead, use
of more secure mechanisms such as DIGEST-MD5, SRP or PASSDSS is highly
    recommended if the server supports it.';

def 'smtptls',
    section => 'mail',
    default => 'no',
    doc => q{Whether or not to use TLS to encrypt the connection for mail
submission; default (no) doesn't use TLS, 'yes' indicates STARTTLS, usually
used with a regular (25) or submission (587) port. 'tls' indicates "raw"
TLS, most often used with dedicated port 465.

When using PLAIN or LOGIN authentication, be sure to change this setting to
prevent publicly visible transmission of credentials.};

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

def 'auth_db',
    section => 'database',
    default => 'postgres',
    doc => q{Database used to log into when collecting information
    about the system, e.g. from the setup.pl status page.};

def 'admin_db',
    section => 'database',
    default => 'template1',
    doc => q{Database used to log into when authenticating setup.pl
admin users and determining the list of database names available for
administration};

### SECTION  ---   programs

def 'zip',
    section => 'programs',
    default => 'zip -r %dir %dir',
    doc => '';



# available printers
my $printer;
sub printer {
    $printer = { @_ } if @_;
    return $printer if $printer;

    my %printer;
    for ($cfg->Parameters('printers')){
        $printer{$_} = $cfg->val('printers', $_);
    }

    $printer = \%printer;
    return $printer;
}



# if you have latex installed set to 1
my $latex = 0;
sub latex {
    return $latex;
}

sub override_defaults {

    local $@ = undef; # protect existing $@

    # Check Latex
    $latex = eval {require Template::Plugin::Latex; 1;};

    # Check availability and loadability
    LedgerSMB::Sysconfig::template_latex(
        LedgerSMB::Sysconfig::template_latex() ne 'disabled' &&
        eval {require LedgerSMB::Template::LaTeX}
    );
    LedgerSMB::Sysconfig::template_xls(
        LedgerSMB::Sysconfig::template_xls() ne 'disabled' &&
        eval {require LedgerSMB::Template::XLS}
    );
    LedgerSMB::Sysconfig::template_xlsx(
        LedgerSMB::Sysconfig::template_xlsx() ne 'disabled' &&
        eval {require LedgerSMB::Template::XLSX}
    );
    LedgerSMB::Sysconfig::template_ods(
        LedgerSMB::Sysconfig::template_ods() ne 'disabled' &&
        eval {require LedgerSMB::Template::ODS}
    );

    return;
}


sub _workflow_factory_config {
    my ($wf_type) = @_;
    my %config;
    $wf_type = lc($wf_type // '');
    $wf_type .= '.' if $wf_type;

    my $wf_dir = LedgerSMB::Sysconfig::workflows();
    for my $config_type (qw(action condition persister validator workflow)) {
        $config{$config_type} = "$wf_dir/${wf_type}${config_type}s.xml"
            if -f "$wf_dir/${wf_type}${config_type}s.xml";
    }

    return \%config;
}

sub initialize {
    my ($module, $cfg_file, %args) = @_;

    if ($cfg_file and -r $cfg_file) {
        $cfg = Config::IniFiles->new( -file => $cfg_file )
            or die @Config::IniFiles::errors;
    }
    else {
        warn "No configuration file; running with default settings\n"
            if $cfg_file;  # no name provided? no need to warn...
        $cfg = Config::IniFiles->new();
    }
    $_->() for (@initializers);

    # ENV Paths
    for my $var (qw(PATH PERL5LIB)) {
        $ENV{$var} .=
            $Config{path_sep} .
            ( join $Config{path_sep}, $cfg->val('environment', $var, ''));
    }

    override_defaults();

    FACTORY()->add_config_from_file(_workflow_factory_config('')->%*);
    if ($args{disable_workflow_preload}) {
        FACTORY()->config_callback(\&_workflow_factory_config);
    }
    else {
        my $r   = sub { File::Find::Rule->new };
        my $wf_dir = LedgerSMB::Sysconfig::workflows();
        my %wf_config = (
            action    => [ $r->()->name( '*.actions.xml' )->in($wf_dir) ],
            condition => [ $r->()->name( '*.conditions.xml' )->in($wf_dir) ],
            persister => [ $r->()->name( '*.persisters.xml' )->in($wf_dir) ],
            validator => [ $r->()->name( '*.validators.xml' )->in($wf_dir) ],
            workflow  => [ $r->()->name( '*.workflow.xml' )->in($wf_dir) ],
            );
        FACTORY()->add_config_from_file(%wf_config);
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
