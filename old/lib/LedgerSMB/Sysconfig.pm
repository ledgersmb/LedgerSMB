
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
use List::Util qw(pairmap);


sub ini2wire {
    my ($module, $cfg_file) = @_;

    unless ($ENV{LSMB_FORCE_LEDGERSMB_CONF}) {
        die <<~'ERR';
           The 'ledgersmb.conf' configuration file has been deprecated
           over the new 'ledgersmb.yaml' system. To convert your existing
           configuration to the YAML system, run the command:

              $ utils/migration/convert-ini-to-di ledgersmb.conf > ledgersmb.yaml

           To force the use of 'ledgersmb.conf', please set the environment
           variable LSMB_FORCE_LEDGERSMB_CONF=Y -- this is guaranteed to work for 1.13
           but will be dropped in 1.14. After that, only the YAML configuration will
           be supported.
           ERR
    }

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

    my %wire_config;

    my @printer_names = $cfg->Parameters( 'printers' );
    my $fallback_printer =
        scalar $cfg->val( 'main', 'fallback_printer', $printer_names[0] );

    $wire_config{printers} = {
        class => 'LedgerSMB::Printers',
        args  => {
            printers => {
                map { $_ => scalar $cfg->val( printers => $_ ) }
                $cfg->Parameters( 'printers' )
            },
            fallback => $fallback_printer
        }
    };

    my @formats = (
        { '$class' => 'LedgerSMB::Template::Plugin::CSV', args => [] },
        { '$class' => 'LedgerSMB::Template::Plugin::TXT', args => [] },
        { '$class' => 'LedgerSMB::Template::Plugin::HTML', args => [] },
        );
    my @optionals = (
        template_latex => { '$class' => 'LedgerSMB::Template::Plugin::LaTeX',
                            format => 'PDF' },
        template_latex => { '$class' => 'LedgerSMB::Template::Plugin::LaTeX',
                            format => 'PS' },
        template_xlsx  => { '$class' => 'LedgerSMB::Template::Plugin::XLSX',
                            format => 'XLSX' },
        template_xls   => { '$class' => 'LedgerSMB::Template::Plugin::XLSX',
                            format => 'XLS' },
        template_ods   => { '$class' => 'LedgerSMB::Template::Plugin::ODS' },
        );
    pairmap {
        if ($cfg->val( 'template_format', $a, 'enabled' ) ne 'disabled') {
            if (eval { "require $b->{'$class'}; 1;" }) {
                push @formats, $b;
            }
        }
    } @optionals;

    $wire_config{output_formatter} = {
        class => 'LedgerSMB::Template::Formatter',
        lifecycle => 'eager',
        args => { plugins => \@formats }
    };

    my $value;
    if (my $value = $cfg->val( 'mail', 'smtphost' )) {
        my @options;

        push @options, host => $value;

        if ($value = $cfg->val( 'mail', 'smtpport' )) {
            push @options, port => $value;
        }

        if ($value = $cfg->val( 'mail', 'smtpuser' )) {
            push @options,
                # the SMTP transport checks that 'sasl_password' be
                # defined; however, its implementation (Net::SMTP) allows
                # the 'sasl_username' to be an Authen::SASL instance which
                # means the password is already embedded in sasl_username.
                sasl_username => {
                    '$class' => 'Authen::SASL',
                    mechanism => scalar $cfg->val( 'mail', 'smtpauthmech' ),
                    callback => {
                        user => $value,
                        pass => scalar $cfg->val( 'mail', 'smtppass' ),
                    }
                },
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

        $wire_config{mail} = {
            transport => {
                '$class' => 'Email::Sender::Transport::SMTP',
                @options,
            }
        };
    }
    else {
        my @options;
        if ($value = $cfg->val( 'mail', 'sendmail' )) {
            @options = ( path => $value );
        }
        $wire_config{mail} = {
            transport => {
                '$class' => 'Email::Sender::Transport::Sendmail',
                @options,
            }
        };
    }

    if ($value = $cfg->val( 'main', 'log_config' )) {
        $wire_config{logging} = { file => $value };
    }
    else {
        $value = $cfg->val( 'main', 'log_level', 'ERROR' );
        $wire_config{logging} = { level => $value };
    }

    $wire_config{miscellaneous} = {
        '$class' => 'Beam::Wire',
        config => {
            max_upload_size => scalar $cfg->val(
                'main', 'max_post_size', 4194304 ),
            backup_email_from => scalar $cfg->val(
                'mail', 'backup_email_from', '' ),
            proxy_ip => scalar $cfg->val(
                'proxy',
                'proxy_ip',
                '127.0.0.1/8 ::1/128 ::ffff:127.0.0.1/108'
                ),
        }
    };

    $wire_config{cookie} = {
        name => scalar $cfg->val( 'main', 'cookie_name', 'LedgerSMB' ),
    };
    if ( $cfg->exists( 'main', 'cookie_secret') ) {
        $wire_config{cookie}->{secret} =
            scalar $cfg->val( 'main', 'cookie_secret' )
    }

    $wire_config{default_locale} = {
        '$class' => 'LedgerSMB::LanguageResolver',
        directory => './locale/po/'
    };

    $wire_config{paths} = {
        '$class' => 'Beam::Wire',
        config => {
            locale => scalar $cfg->val( 'paths', 'localepath', './locale/po/' ),
            sql => scalar $cfg->val( 'paths', 'sql', './sql/'),
            templates => scalar $cfg->val( 'paths', 'templates', './templates/' ),
            UI => scalar $cfg->val( 'paths', 'UI', './UI/' ),
            UI_cache => scalar $cfg->val( 'paths', 'UI_cache', 'lsmb_templates/' ),
        }
    };

    $wire_config{ui} = {
        class => 'LedgerSMB::Template::UI',
        lifecycle => 'eager',
        method => 'new_UI',
        args => {
            cache => { '$ref' => 'paths/UI_cache' },
            root  => { '$ref' => 'paths/UI' },
            stylesheet => (
                $cfg->val( 'main', 'suppress_tooltips', '' ) ? 'ledgersmb-test.css' : 'ledgersmb.css'
            )
        }
    };

    $wire_config{db} = {
        class => 'LedgerSMB::Database::Factory',
        args => {
            connect_data => {
                host => scalar $cfg->val( 'database', 'host', 'localhost'),
                port => scalar $cfg->val( 'database', 'port', 5432),
                sslmode => scalar $cfg->val( 'database', 'sslmode', 'prefer'),
            },
            schema => scalar $cfg->val( 'database', 'db_namespace', 'public' )
        }
    };

    $wire_config{login_settings} = {
        default_db => scalar $cfg->val( 'database', 'default_db' )
    };

    $wire_config{reconciliation_importer} = {
        class => 'LedgerSMB::Reconciliation::Parser',
    };

    $wire_config{setup_settings} = {
        auth_db  => scalar $cfg->val( 'database', 'auth_db', 'postgres' ),
        admin_db => scalar $cfg->val( 'database', 'admin_db', 'template1' ),
    };

    $wire_config{workflows} = {
        class => 'LedgerSMB::Workflow::Loader',
        lifecycle => 'eager',
        method => 'load',
        args => {
            lifecycle => 'eager',
            directories => [
                scalar $cfg->val( 'paths', 'workflows', 'workflows'),
                scalar $cfg->val( 'paths', 'custom_workflows', 'custom_workflows'),
                ],
        },
    };

    $wire_config{environment_variables} = {
        class => 'LedgerSMB::EnvVarSetter',
        lifecycle => 'eager',
        method => 'set',
        args => {
            map { $_ => join($Config{path_sep}, '+',
                             $cfg->val('environment', $_, '')) }
            grep { scalar $cfg->val('environment', $_, '') }
            qw( PATH PERL5LIB )
        }
    };

    return \%wire_config;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
