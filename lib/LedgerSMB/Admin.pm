
package LedgerSMB::Admin;

=head1 NAME

LedgerSMB::Admin -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use DBD::Pg;
use DBI;
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use Hash::Merge;
use List::Util qw(first);
use Log::Any::Adapter;
use Log::Any::Adapter::Log4perl;
use Log::Log4perl qw(:easy);
use Module::Runtime qw(use_module compose_module_name);
use Pod::Usage qw(pod2usage);
use YAML qw(LoadFile);

our $VERSION = '0.0.1';

use LedgerSMB::Admin::Configuration;

=head1 METHODS

=cut

my @potential_configs = (
    { path => '/usr/local/etc/ledgersmb-admin.conf',
      user => 0,
    },
    { path => '/etc/ledgersmb-admin.conf',
      user => 0,
    },
    );

my $merger = Hash::Merge->new();
$merger->set_behavior('LEFT_PRECEDENT');

sub _load_config {
    my $cfg_path = first { -f $_->{path} } (
        { path => "$ENV{HOME}/.ledgersmb-admin.conf",
          user => 1,
        },
        @potential_configs
        );
    return { connect_data => {} } unless $cfg_path;

    my $cfg = LoadFile($cfg_path->{path});
    ###TODO: check type of $cfg... we really need it to be a hash!

    my $sys_cfg;
    if ($cfg_path->{user}) {
        $cfg_path = first { -f $_->{path} } @potential_configs;
        if ($cfg_path) {
            ###TODO: check type of $cfg... we really need it to be a hash!
            $sys_cfg = LoadFile($cfg_path->{path});
        }
        else {
            $sys_cfg = {};
        }
    }
    else {
        $sys_cfg = $cfg;
    }
    # base configuration inherits into user configuration
    $merger->merge($cfg, $sys_cfg->{base}) if exists $sys_cfg->{base};
    delete $cfg->{base};

    return $cfg;
}

=head2 help

=cut

sub help {
    pod2usage(-verbose => 99, -noperldoc => 1,
        -sections => [ qw(SYNOPSIS DESCRIPTION OPTIONS COMMANDS
                       CONFIGURATION), 'EXIT STATUS' ]);
}

=head2 version

=cut

sub version {
    print <<EOF;
ledgersmb-admin version $VERSION

Dependency versions:
   DBI     $DBI::VERSION
   DBD::Pg $DBD::Pg::VERSION
EOF

    exit 1;
}

=head2 run_command

=cut

sub run_command {
    my (@args) = @_;
    my %options = ();

    Getopt::Long::Configure(qw(bundling require_order));
    GetOptionsFromArray(\@args, \%options, 'help', 'version', 'debug');

    Log::Log4perl->easy_init($options{debug} ? $DEBUG : $INFO);
    Log::Any::Adapter->set('Log4perl');
    my ($cmd, @cmd_args) = @args;
    return help() if $options{help};
    return version() if $options{version};
    return help() if not defined $cmd or $cmd eq 'help';


    Getopt::Long::Configure(qw(permute));
    my $class  = compose_module_name('LedgerSMB::Admin::Command', $cmd);
    my $config = LedgerSMB::Admin::Configuration->new(
        config => _load_config(),
        );

    return use_module($class)->new(
        config => $config
        )->run(@cmd_args);
}

1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

