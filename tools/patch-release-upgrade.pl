#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use LedgerSMB::Database;

my $user;
my $script_name = `basename $0`; chomp $script_name;
my $usage = qq|
usage: $script_name [ OPTION... ] database

This script upgrades your database when moving from one patchlevel
to another, e.g. 1.3.15 to 1.3.18.


Options:
  --user <user>     This option names the user to be used for logging in.
                     The name of the current user is the default value.
  --help            Prints this help screen.

Note:
  If the user (implied or explicitly specified) requires a password, it
will be asked for explicitly unless it's specified in an environment variable.
This is to prevent passwords being saved into the history file.

|;

sub rebuild_modules {

    my $database = LedgerSMB::Database->new(
        {
            username => $ENV{PGUSER},
            company_name => $ENV{PGDATABASE},
            password => $ENV{PGPASSWORD},
        })
        or die "No database connection.";

    $database->upgrade_modules('LOADORDER', $LedgerSMB::VERSION)
        or die "Upgrade failed.";
    
    return 1;
};


sub usage { print $usage; exit; }


GetOptions(
    'help'      => \&usage,
    'user=s'    => \$user,
    );

if (scalar(@ARGV) != 1) {
    my $argnum = scalar(@ARGV);
    print STDERR "$script_name: Incorrect number of arguments ($argnum found; 1 expected)";
    &usage;
}

$ENV{PGUSER} = $user if $user;
$ENV{PGDATABASE} = $ARGV[0];
&rebuild_modules;


print "Database upgraded to $LedgerSMB::VERSION.\n";
exit 0;
