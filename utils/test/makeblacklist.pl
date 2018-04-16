#!/usr/bin/perl

use FindBin;
use strict;
use warnings;
use lib "$FindBin::Bin/../lib";
use 5.010; # say makes things easier
no lib '.'; # can run from anywhere

use LedgerSMB::Sysconfig;

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

write_blacklist(sort keys %func);
close ($order);
close ($out) or die "failed to close output file after writing $!";


sub process_mod {
    my ($mod) = @_;

    my $mod_file = "$FindBin::Bin/../../sql/modules/$mod";
    open my $mod_h, '<', $mod_file
        or die "cannot open $mod_file $!";

    my %func =  map { /FUNCTION (\w+)\(/i; ($1 => 1) }
                grep { /CREATE (OR REPLACE )?FUNCTION \w+\(/i }  <$mod_h>;
    close $mod_h;
    return %func;
}


sub write_blacklist {
    my @funcs = @_;
    foreach my $function(@funcs) {
        say $out $function or die "failed write to output file $!";
    }
}
