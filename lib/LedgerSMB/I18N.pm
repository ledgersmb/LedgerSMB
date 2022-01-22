
package LedgerSMB::I18N;

=head1 NAME

LedgerSMB::I18N - Translation role for LedgerSMB Moose classes

=head1 SYNPOSIS

  text('text to translate')

=head1 DESCRIPTION

This adds a single method, text() to a role.  This maps to the current
LedgerSMB::App_State::Locale's text method.  This is safe for cached code since
we look only to the current locale.

=cut

#use v5.24.0;

use Locales unicode => 1;
use Moose::Role;
use namespace::autoclean;
use LedgerSMB::App_State;
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


=item LedgerSMB::I18N::text(@args)

Translates the string using the arguments passed.

Wrapper around the MakeText::maketext function; uses the locale object
stored in LedgerSMB::App_State->Locale.

Note: The first argument must be a string constant for
 PO file extraction; in case of dynamic string arguments, use
 the C<maketext> method

=cut

sub text {
    return LedgerSMB::App_State->Locale->maketext(@_);
}


=item $self->maketext(@args)

Translates the string using the arguments passed.

Wrapper around the MakeText::maketext function; uses the locale object
stored in LedgerSMB::App_State->Locale.

Note: In order for the first string (if it is an inline constant string)
 to be detected for translation and included in PO files, the C<Maketext>
 method should be used.

=cut

sub maketext {
    return LedgerSMB::App_State->Locale->maketext(@_);
}

=item get_country_list($language)

Get a country localized list to allow user selection

=cut

sub get_country_list {
    my $language = shift;
    my $locale = Locales->new($language);
    my %regions = $locale->get_territory_lookup();
    return [
        sort { $a->{text} cmp $b->{text} }
        map { +{ value => uc($_),
                 text  => $regions{lc($_)} }
        } (keys %regions)
    ];
}

=item get_language_list($request, $language)

Get a language localized list to allow user selection

=cut

sub get_language_list {
    my ($request, $language) = @_;
    my $locale = Locales->new($language);
    my @rows = $request->call_dbmethod(funcname => 'person__list_languages');
    my @languages;
    for (@rows) {
        my $text = $locale->get_language_from_code(lc($_->{code}));
        push @languages, {
            value => $_->{code},
            text => ucfirst($text // $_->{description})
        }
    }
    @languages = sort { $a->{text} cmp $b->{text} } @languages;
    return @languages;
}

=item location_list_country_localized($request, $language)

Get the country list, localized according to the desired language

Use the provided language of default to user

=cut

sub location_list_country_localized {
    my $request = shift;
    my $language = shift // $request->{_user}->{language};
    my @country_list = $request->call_procedure(
                     funcname => 'location_list_country'
    );
    my $locale = Locales->new($language);
    my %regions = $locale->get_territory_lookup();
    foreach (@country_list) {
      $_->{name} = $regions{lc($_->{short_name})}
        if defined $regions{lc($_->{short_name})};
    }
    return @country_list;
}
=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
