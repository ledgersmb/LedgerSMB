
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
use Beam::Wire;
use Config;
use Config::IniFiles;
use English;
use List::Util qw(pairmap);

sub initialize {
    my ($module, $cfg_file, %args) = @_;

    my $cfg;
    if ($cfg_file and -r $cfg_file) {
        $cfg = Config::IniFiles->new( -file => $cfg_file )
            or die @Config::IniFiles::errors;
    }
    else {
        warn "No configuration file; running with default settings\n"
            if $cfg_file;  # no name provided? no need to warn...
        $cfg = Config::IniFiles->new();
    }

    # ENV Paths
    for my $var (qw(PATH PERL5LIB)) {
        $ENV{$var} .=
            $Config{path_sep} .
            ( join $Config{path_sep}, $cfg->val('environment', $var, ''));
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

    if ($value = $cfg->val( 'main', 'log_config' )) {
        $wire->set( 'logging', { config => $value } );
    }
    else {
        $value = $cfg->val( 'main', 'log_level', 'ERROR' );
        $wire->set( 'logging', { level => $value } );
    }

    $wire->set('miscellaneous', Beam::Wire->new );

    $wire->set(
        'miscellaneous/max_upload_size',
        $wire->create_service(
            'max_post_size',
            value => $cfg->val( 'main', 'max_post_size', 4194304 ) ) );
    $wire->set(
        'miscellaneous/backup_email_from',
        $wire->create_service(
            'backup_email_from',
            value => $cfg->val( 'mail', 'backup_email_from', '' ) ) );
    $wire->set(
        'miscellaneous/proxy_ip',
        $wire->create_service(
            'proxy_ip',
            value => $cfg->val(
                'proxy',
                'proxy_ip',
                '127.0.0.1/8 ::1/128 ::ffff:127.0.0.1/108'
            ) ) );

    $wire->set(
        'cookie',
        {
            name => $cfg->val( 'main', 'cookie_name' ),
            secret => $cfg->val( 'main', 'cookie_secret' )
        });

    $wire->set(
        'default_locale',
        $wire->create_service(
            'default_locale' => (
                class => 'LedgerSMB::LanguageResolver',
                args => {
                    directory => './locale/po/'
                }
            )));

    $wire->set('paths', Beam::Wire->new );
    $wire->set('paths/locale',
               $cfg->val( 'paths', 'localepath', './locale/po/' ) );
    $wire->set('paths/templates',
               $cfg->val( 'paths', 'templates', './templates/' ) );
    $wire->set('ui',
               $wire->create_service(
                   'ui',
                   class => 'LedgerSMB::Template::UI',
                   lifecycle => 'eager',
                   method => 'new_UI',
                   args => {
                       cache => $cfg->val( 'paths', 'templates_cache',
                                           'lsmb_templates/' )
                   }) );

    $wire->set(
        'db' => $wire->create_service(
            'db',
            class => 'LedgerSMB::Database::Factory',
            args => {
                connect_data => {
                    host => $cfg->val( 'database', 'host', 'localhost'),
                    port => $cfg->val( 'database', 'port', 5432),
                    sslmode => $cfg->val( 'database', 'sslmode', 'prefer'),
                },
                schema => $cfg->val( 'database', 'db_namespace', 'public' )
            }));

    $wire->set(
        'login_settings' => {
            default_db => $cfg->val( 'database', 'default_db' )
        });

    $wire->set(
        'setup_settings' => {
            auth_db  => $cfg->val( 'database', 'admin_db', 'postgres' ),
            admin_db => $cfg->val( 'database', 'admin_db', 'template1' ),
        });

    $wire->set(
        'workflows' => $wire->create_service(
            workflows => (
                class => 'LedgerSMB::Workflow::Loader',
                lifecycle => 'eager',
                method => 'load',
                args => {
                    lifecycle => 'eager',
                    directories => [
                        $cfg->val( 'paths', 'workflows', 'workflows'),
                        $cfg->val( 'paths', 'custom_workflows', 'custom_workflows'),
                        ],
                },
                )))
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
