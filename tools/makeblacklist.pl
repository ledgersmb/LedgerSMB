#!/usr/bin/perl

use FindBin;
use strict;
use warnings;
use lib "$FindBin::Bin/../lib";
use 5.010; # say makes things easier
no lib '.'; # can run from anywhere

my %func = (); # set of functions as keys

my $order_file = "$FindBin::Bin/../sql/modules/LOADORDER";
my $order;
open ($order, '<', $order_file)
    or die "failed to open $order_file $!";

for my $mod (<$order>) {
    chomp($mod);
    $mod =~ s/(\s+|#.*)//g;
    next unless $mod; # skipping comment-only, whitespace-only, and blank lines
    %func = (%func, process_mod($mod));
    write_blacklist(sort keys %func); 
}
close ($order); ### return failure to execute the script?

sub process_mod {
    my ($mod) = @_;
    my $mod_file = "$FindBin::Bin/../sql/modules/$mod";
    open my $mod_h, '<', $mod_file
        or die "failed to open $mod_file $!";
    my %func =  map { /FUNCTION (\w+)\(/i; ($1 => 1) }
                grep { /CREATE (OR REPLACE )?FUNCTION \w+\(/i }  <$mod_h>;
    close $mod_h;
    return %func;
}

sub write_blacklist {
    my @funcs = @_;
    my $bl_file = "$FindBin::Bin/../sql/modules/BLACKLIST";
    open my $bl, '>', $bl_file
        or die "Failed to open $bl_file $!";
    say $bl $_ for @funcs;
    close $bl or die "failed to close $bl_file after writing $!";
}
