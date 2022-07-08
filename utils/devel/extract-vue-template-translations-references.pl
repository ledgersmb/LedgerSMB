#!/usr/bin/perl

use strict;
use warnings;
use File::Find;
use File::Grep qw(fgrep);

my $location="UI/src";

my @files;
sub find_vue {
    my $F = $File::Find::name;

    if ($F =~ /\.(vue|js|html)$/ ) {
        push @files,$F;
    }
}

find({ wanted => \&find_vue, no_chdir=>1}, $location);

sub print_reference {
    my @matches = @_;
    foreach my $match (@matches) {
        if ( $match->{count}){
            for my $key (keys %{$match->{matches}}){
                print "#: " . $match->{filename} . ":" . $key . "\n";
            }
        }
    }
}

# Set references to help translators
my $skipping_header = 1;
my $in_msgstr = 0;
foreach my $line ( <STDIN> ) {

    $in_msgstr &&= ($line =~ /^"/);
    if ( $line =~ /^msgid.+"(.+)"$/ ) {
        my $id = $1;

        $skipping_header = '';

        # Use JSON key syntax instead of PO
        $id =~ s/##/./g
            if ( $id =~ /^i18n##.+/ );

        # Check methods
        my @matches;
        for (@files) {
            push @matches, fgrep { /(?:[\$\s.:"'`+\(\[\{]t[cm]?)\(\s*?(["'`])(\Q$id\E)\1\)/ } $_
        }

        # Check components
        for (@files) {
            push @matches, fgrep { /(?:<(?:i18n|Translation))(?:.|\n)*?(?:[^:]path=("|'))\Q$id\E\1/ } $_
        }

        # Check directives
        for (@files) {
            push @matches, fgrep { /v-t="'\Q$id\E'"/ } $_
        }

        print_reference(@matches);
    }
    elsif ( $line =~ /^msgstr\b/
            and not $skipping_header) {
        #BUG: multiline msgstrs?
        print qq|msgstr ""\n|;
        $in_msgstr = 1;
    }
    print $line unless $skipping_header or $in_msgstr;
}
