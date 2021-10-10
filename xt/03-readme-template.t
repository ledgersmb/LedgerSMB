#!perl

use Test2::V0;

my $template = 'doc/sources/_README.md';
my $output   = 'README.md';

open my $t, '<:encoding(UTF-8)', $template
    or die "Failed to open README template: $!";
open my $o, '<:encoding(UTF-8)', $output
    or die "Failed to open README file: $!";

while (1) {
    my $in;
    my $cmp;

    while ($in = <$t>) {
        last unless $in =~ m/^\s*$|^\s*[|]|^\s*#|<<browser/;
    }
    while ($cmp = <$o>) {
        last unless $cmp =~ m/^\s*$|^\s*[|]|^\s*#/;
    }

    last unless defined $in or defined $cmp;

    die "$template reached EOF while $output didn't"
        if not defined $in;
    die "$output reached EOF while $template didn't"
        if not defined $cmp;

    if ($in ne $cmp) {
        my $t_line = $t->input_line_number;
        my $o_line = $o->input_line_number;

        die "$template and $output differ!\n Got($output:$o_line): $cmp\n Expected($template:$t_line): $in";
    }
}

ok "$template and $output are equal";
done_testing;
