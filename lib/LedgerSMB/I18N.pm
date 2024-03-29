
package LedgerSMB::I18N;

=head1 NAME

LedgerSMB::I18N - Translation role for LedgerSMB Moose classes

=head1 SYNPOSIS

  text('text to translate')

=head1 DESCRIPTION

This adds two methods, Text() and Maketext() to a role, creating a locale
object from the 'language' property.

=cut

#use v5.24.0;

use Locale::CLDR;
use Locales unicode => 1;
use Moose::Role;
use namespace::autoclean;
use LedgerSMB::Locale;


has 'language' => (is => 'ro', isa => 'Maybe[Str]');

has 'locale' => (is => 'ro',
                 lazy => 1,
                 builder => '_build_locale');

sub _build_locale {
    my ($self) = @_;

    my $locale;
    if ($self->language) {
        $locale = LedgerSMB::Locale->get_handle($self->language);
    }

    return $locale // $self->{_locale};
}

=head1 METHODS

=over

=item $self->Text(@args)

Instance method, uses the locale object from the 'locale' attribute
to call its maketext() function, passing all @args forward.

Note: The first argument must be a string constant for
 PO file extraction; in case of dynamic string arguments, use
 the C<Maketext> method

=cut

sub Text {
    my $self = shift;

    return $self->locale->maketext(@_);
}



=item $self->Maketext(@args)

Instance method, uses the locale object from the 'locale' attribute
to call its maketext() function, passing all @args forward.

Note: In order for the first string (if it is an inline constant string)
 to be detected for translation and included in PO files, the C<Text>
 method should be used.

=cut

sub Maketext {
    my $self = shift;

    return $self->locale->maketext(@_);
}


=item get_country_list($language)

Get a country localized list to allow user selection

=cut

sub get_country_list {
    my $language = shift;
    my %regions = Locale::CLDR->new($language)->all_regions->%*;
    return [
        sort { $a->{text} cmp $b->{text} }
        map { +{ value => uc($_),
                 text  => $regions{$_} }
        } (keys %regions)
    ];
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
