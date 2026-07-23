
use v5.38;

package LedgerSMB::Num2text;

=head1 NAME

LedgerSMB::Num2text - Conversion of integer numbers to words

=head1 DESCRIPTION

This module specifically converts integers to their textual representation.

=head1 SYNOPSIS

  use LedgerSMB::Num2text;

  my $str = LedgerSMB::Num2text::cardinal( $locale, 1234 );

=head1 FUNCTIONS

=cut

use Lingua::Num2Word;
use Locale::Codes::Language qw/ language_code2code /;

# Fix the mismatch between Locale::Codes and Lingua::Num2Word
my %misnomers = (
    'cze' => 'ces',
    'ger' => 'due',
    'gre' => 'ell',
    'per' => 'far',
    'fre' => 'fra',
    'ice' => 'isl',
    'nob' => 'nor',
    'dut' => 'nld',
    'chi' => 'zho'
    );

=head2 cardinal

  my $textual = cardinal( $locale, $number );

The C< $locale > parameter is an instance of L<LedgerSMB::Locale>; the
C< $number > parameter will be truncated, if not an integer.

Returns the textual representation of the number in the language indicated
by C< $locale >, if supported. Otherwise falls back to English.

=cut

sub cardinal($locale, $num) {
    my ($tag) = split(/-/, $locale->language_tag);
    my ($lang) = language_code2code( $tag, 'alpha-2', 'alpha-3' );

    $lang = $misnomers{$lang} // $lang;
    my $rv = (Lingua::Num2Word::cardinal( $lang, int($num) )
              // Lingua::Num2Word::cardinal( 'eng', int($num) ));
    $rv =~ s/\b(\w)/\U$1/g if $rv;
    $rv =~ s/,//g if $rv;
    return $rv;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
