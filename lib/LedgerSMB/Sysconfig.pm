
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

use Authen::SASL;
use Config;
use Config::IniFiles;
use English;
use File::Find::Rule;
use String::Random;
use Symbol;
use List::Util qw(pairmap);
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
    default => 'LedgerSMB-1.10',
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

def 'custom_workflows',
    section => 'paths',
    default => 'custom_workflows',
    doc => q{directory where custom workflow files are stored;

custom workflows are used to override behaviour of the default workflows by
providing actions/conditions/etc by the same name and type or by providing workflows
of the same type with e.g. additional states and actions.

defaults to './custom_workflows'};

### SECTION  ---   reverse proxy

def 'proxy_ip',
    section => 'proxy',
    default => '127.0.0.1/8 ::1/128 ::ffff:127.0.0.1/108',
    doc => 'The space separated list of IP addresses (or ranges, using CIDR notation) of acceptable reverse proxies';


### SECTION  ---   mail

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


sub _workflow_factory_config {
    my ($wf_type) = @_;
    my %config;
    $wf_type = lc($wf_type // '');
    $wf_type .= '.' if $wf_type;

    my @wf_dirs = (LedgerSMB::Sysconfig::workflows());
    push @wf_dirs, LedgerSMB::Sysconfig::custom_workflows()
        if -d LedgerSMB::Sysconfig::custom_workflows();

    for my $config_type (qw(action condition persister validator workflow)) {
        my @configs;
        $config{$config_type} = \@configs;
        for my $wf_dir (@wf_dirs) {
            push @configs, "$wf_dir/${wf_type}${config_type}s.xml"
                if -f "$wf_dir/${wf_type}${config_type}s.xml";
        }
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

    FACTORY()->add_config_from_file(_workflow_factory_config('')->%*);
    if ($args{disable_workflow_preload}) {
        FACTORY()->config_callback(\&_workflow_factory_config);
    }
    else {
        my $r   = sub { File::Find::Rule->new };
        for my $wf_dir (LedgerSMB::Sysconfig::workflows(),
                        LedgerSMB::Sysconfig::custom_workflows()) {
            next if not -d $wf_dir;

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

    return $cfg;
}


sub ini2wire {
    my ($wire, $cfg) = @_;

    my @printer_names = $cfg->Parameters( 'printers' );
    my $fallback_printer =
        $cfg->val( 'main', 'fallback_printer', $printer_names[0] );

    $wire->set(
        printers => $wire->create_service(
            printers => (
                class => 'LedgerSMB::Printers',
                args  => {
                    printers => {
                        map { $_ => $cfg->val( printers => $_ ) }
                        $cfg->Parameters( 'printers' )
                    },
                    fallback => $fallback_printer
                }
            ))
        );

    my @formats = (
        { class => 'LedgerSMB::Template::Plugin::CSV' },
        { class => 'LedgerSMB::Template::Plugin::TXT' },
        { class => 'LedgerSMB::Template::Plugin::HTML' },
        );
    my @optionals = (
        template_latex => { class => 'LedgerSMB::Template::Plugin::LaTeX',
                            args => { format => 'PDF' } },
        template_latex => { class => 'LedgerSMB::Template::Plugin::LaTeX',
                            args => { format => 'PS' } },
        template_xlsx  => { class => 'LedgerSMB::Template::Plugin::XLSX',
                            args => { format => 'XLSX' } },
        template_xls   => { class => 'LedgerSMB::Template::Plugin::XLSX',
                            args => { format => 'XLS' } },
        template_ods   => { class => 'LedgerSMB::Template::Plugin::ODS' },
        );
    pairmap {
        if ($cfg->val( 'template_format', $a, 'enabled' ) ne 'disabled') {
            if (eval { "require $b->{class}; 1;" }) {
                push @formats, $b;
            }
        }
    } @optionals;
    $wire->set(
        'output_plugins' => $wire->create_service(
            'output_plugins',
            class => 'LedgerSMB::Template::Plugins',
            args => {
                plugins => [
                    map { $wire->create_service( '', %$_ ) }
                    @formats
                ]
            }
        ));

    my $value;
    if (my $value = $cfg->val( 'mail', 'smtphost' )) {
        my @options;

        push @options, host => $value;

        if ($value = $cfg->val( 'mail', 'smtpport' )) {
            push @options, port => $value;
        }

        if ($value = $cfg->val( 'mail', 'smtpuser' )) {
            my $auth = Authen::SASL->new(
                mechanism => $cfg->val( 'mail', 'smtpauthmech' ),
                callback => {
                    user => $value,
                    pass => $cfg->val( 'mail', 'smtppass' ),
                });
            push @options,
                # the SMTP transport checks that 'sasl_password' be
                # defined; however, its implementation (Net::SMTP) allows
                # the 'sasl_username' to be an Authen::SASL instance which
                # means the password is already embedded in sasl_username.
                sasl_username => $auth,
                sasl_password => '';
        }

        if ($value = $cfg->val( 'mail', 'smtptimeout')) {
            push @options, timeout => $value;
        }

        my $tls = $cfg->val( 'mail', 'smtptls' );
        if ($tls and $tls ne 'no') {
            if ($tls eq 'yes') {
                push @options, ssl => 'starttls';
            }
            elsif ($tls eq 'tls') {
                push @options, ssl => 'ssl';
            }
        }

        if ($value = $cfg->val( 'mail', 'smtpsender_hostname' )) {
            push @options, helo => $value;
        }
        $wire->set(
            'mail' => {
                transport =>
                    $wire->create_service(
                        transport => (
                            class => 'LedgerSMB::Mailer::TransportSMTP',
                            args  => \@options,
                        ))
            });
    }
    else {
        my @options;
        if ($value = $cfg->val( 'mail', 'sendmail' )) {
            @options = ( path => $value );
        }
        $wire->set(
            'mail' => {
                transport =>
                    $wire->create_service(
                        transport => (
                            class => 'Email::Sender::Transport::Sendmail',
                            args  => \@options,
                        ))
            });
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
