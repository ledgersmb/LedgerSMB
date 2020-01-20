#!/usr/bin/perl

use FindBin;
use strict;
use warnings;
use lib "$FindBin::Bin/../lib";
use 5.010; # say makes things easier
no lib '.'; # can run from anywhere

use LedgerSMB::Sysconfig;

=head1 NAME

makeblacklist.pl

=head1 DESCRIPTION

This script is used to generate the file sql/modules/BLACKLIST, which lists
all functions expected to exist in the database schema.  This file is is
used by tests to ensure that functions have not been overloaded (that there
are not multiple functions with the same name, but different parameters),
which our object mapper does not handle.

The list of functions is extracted from the sql module files listed in
C<sql/modules/LOADORDER>.

=head1 USAGE

To replace the current C</sql/modules/BLACKLIST> file with a new version,
run the following command from within the ledgersmb directory:

    perl -I lib -I old/lib utils/test/makeblacklist.pl --regenerate

Without the C<--regenerate> switch, output will be sent to stdout.

=head1 EXCLUSIONS

Two functions are explicity excluded from the output as they are known and
accepted to be overloaded, having one version that accepts an array parameter
and another which accepts a single value. They are:

=over

=item * in_tree

=item * lsmb__grant_perms

=back

=head1 OUTPUT

This script outputs a list of function names, one per line, sorted
alphabetically.

The file is intended for import into postgresql using the C<\copy> command
and therefore includes no header or comments.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


my $out;
if ( defined $ARGV[0] && $ARGV[0] eq '--regenerate') {
    my $out_file = "$FindBin::Bin/../../sql/modules/BLACKLIST";
    open $out, ">", $out_file
        or die "failed to open $out_file for writing $!";
}
else {
    $out = \*STDOUT;
}

my %func = (); # set of functions as keys

my $order;
my $order_file = "$FindBin::Bin/../../sql/modules/LOADORDER";
open ($order, '<', $order_file)
    or die "Cannot open $order_file $!";

for my $mod (<$order>) {
    chomp($mod);
    $mod =~ s/(\s+|#.*)//g;
    next unless $mod; # skipping comment-only, whitespace-only, and blank lines
    %func = (%func, process_mod($mod));
}

# Explicitly exclude two function names
# These are known to be overloaded. They have one version that takes an
# array parameter and another that takes a single value.
delete $func{in_tree};
delete $func{lsmb__grant_perms};

write_blacklist(sort keys %func);
close ($order);
close ($out) or die "failed to close output file after writing $!";


sub process_mod {
    my ($mod) = @_;

    my $mod_file = "$FindBin::Bin/../../sql/modules/$mod";
    open my $mod_h, '<', $mod_file
        or die "cannot open $mod_file $!";

    local $/ = undef;
    my $sql = <$mod_h>;
    my @function_names = $sql =~ m/CREATE (?:OR REPLACE )?FUNCTION\s*(\w+)\s*\(/ig;
    my %func =  map {$_ => 1} @function_names;
    close $mod_h;
    return %func;
}


sub write_blacklist {
    my @funcs = @_;

    # Output one function name per line.
    # Do not include comments, headers or blank lines as this file is
    # intended to be read by the psql `\copy` command.
    foreach my $function(@funcs) {
        say $out $function or die "failed write to output file $!";
    }
}
