#!/usr/bin/perl

use FindBin;
use strict;
use warnings;
use lib "$FindBin::Bin/../lib";
use File::Temp;
use 5.010; # say makes things easier
no lib '.'; # can run from anywhere

use LedgerSMB::Sysconfig;

my $out;
if ( defined $ARGV[1] && $ARGV[1] eq '--regenerate') {
    open $out, ">", "$FindBin::Bin/../sql/modules/BLACKLIST";
}
else {
    $out = \*STDOUT;
}

my %func = (); # set of functions as keys

my $order;
open ($order, '<', "$FindBin::Bin/../sql/modules/LOADORDER")
    or die "Cannot open LOADORDER";
for my $mod (<$order>) {
    chomp($mod);
    $mod =~ s/(\s+|#.*)//g;
    next unless $mod; # skipping comment-only, whitespace-only, and blank lines
    %func = (%func, process_mod($mod));
}
write_blacklist(sort keys %func);
close ($order); ### return failure to execute the script?
close ($out);

sub process_mod {
    my ($mod) = @_;
    open my $mod_h, '<', "$FindBin::Bin/../sql/modules/$mod";
    my %func =  map { /FUNCTION (\w+)\(/i; ($1 => 1) }
                grep { /CREATE (OR REPLACE )?FUNCTION \w+\(/i }  <$mod_h>;
    close $mod_h;
    return %func;
}

sub write_blacklist {
    my @funcs = @_;
    say $out $_ for @funcs;
}
