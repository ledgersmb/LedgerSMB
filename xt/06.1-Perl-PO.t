#!/usr/bin/perl

=description

This script scans various Perl files for translatable strings.

The scanner uses the Perl Pattern Recognizer to find text() or marktext()
translation routines, either in code or comments, because they sometimes
intentionally contain translatable strings.

This script exists because xgettext and xgettext.pl don't allow us to
extract a sub-set of strings from our SQL files.

=cut

use strict;
use warnings;

use PPR;
use utf8;
use Test::More;
use File::Find;

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.(pm|t|tex)$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/LedgerSMB/', 'old/lib/LedgerSMB/');

plan tests => scalar @on_disk;

sub slurp{ local (*ARGV, $/); @ARGV = shift; readline; }

my @lines;        # To record line numbers
my $line;

for my $file (@on_disk) {

    subtest $file => sub {
        my $source = slurp($file);
        my $errors = 0;

        my (@lines,$line);  # Record line numbers
        $line = 1;
        my @text = grep {defined}
            $source =~
            m{
               ((?&PerlEndOfLine) (??{ ++$line }))*?     # Count the lines
               (?: (?:[Mm]ark)?[Tt]ext\b                 # Introducer
                   (?&PerlOWS) [\(\s] (?&PerlOWS))       # '(' or ' '
               ((?&PerlString)) (?{ push @lines,$line }) # string and line
               $PPR::GRAMMAR                             # Preload our grammar
             }gmx;

        # Deduplicate, standardize and pack line references
        my %text;
        for (@text) {
            my $string = $_;

            # @lines must follow @text
            my $line = shift @lines;

            my $type = $string =~ m/^('|q\b|<<\s*')/  ?  "Q"
                     : $string =~ m/^("|qq\b|<<\s*")/ ? "DQ"
                                                      :  "-";
            # Prevent unwanted interpolations
            if ( $type ne "Q" && $string =~ m( .* ((?&PerlVariable)) .* $PPR::GRAMMAR)x ) {
                ok(0, "$file:$line: Direct variable interpolation not supported; use bracketed ([_1]) syntax to replace <$1>");
                $errors++;
                next;
            }

            # Remove beginning and end delimitors
            # The following doesn't work yet
            #$string = $2
            #    if $string =~ m( .* ((?&PerlString)) .* $PPR::GRAMMAR);
            #TODO: Replace by the above once PPR has added support
            if    ( $string =~ /^(["'])(.*)\1$/s )       { $string = $2 ;} # "string"
            elsif ( $string =~ /^q{1,2}\((.*)\)$/s)      { $string = $1 ;} # q() or qq()
            elsif ( $string =~ /^<<(['"\b])([a-z0-9_])\1;
                                 \s*(?:\#[^\n]*)
                                 (.*)\n\2$/mxi)          { $string = $3 ;} # heredoc
            else {
                ok(0, "$file:$line: Unsupported string delimiters in <$string>");
                $errors++;
                next;
            }
        }
        ok(!$errors,$file) if !$errors;
    };
}
