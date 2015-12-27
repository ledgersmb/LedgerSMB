
=head1 NAME

LedgerSMB::Template::TTI18N - Template Toolkit i18n support functions

=head1 SYNOPSIS

Various functions for Template Toolkit templates for internationalisation
support.

=head1 METHODS

=over

=item <?lsmb gettext(locale, 'string [_1]', param) ?>

Output the gettext translation for the string in the given locale.  If
locale is a LedgerSMB::Locale object, it uses it.  If it is a string, the
locale is loaded, cached, and used.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This work contains copyrighted information from a number of sources all used
with permission.

It is released under the GNU General Public License Version 2 or, at your
option, any later version.  See COPYRIGHT file for details.  For a full list
including contact information of contributors, maintainers, and copyright
holders, see the CONTRIBUTORS file.
=cut

package LedgerSMB::Template::TTI18N;

use strict;
use warnings;
use LedgerSMB::Locale;

my %locales; # Cache string-loaded locales
our $ttfuncs = {};

$ttfuncs->{gettext} = sub {
    my $locale = shift;
    if (ref $locale) {
        return $locale->maketext(@_);
    } elsif ($locales{$locale}) {
        return $locales{$locale}->maketext(@_);
    } else {
        $locales{$locale} = LedgerSMB::Locale->get_handle($locale);
        return $locales{$locale}->maketext(@_);
    }
};

1;
