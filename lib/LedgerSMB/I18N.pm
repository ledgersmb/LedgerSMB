
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

    return ($locale) ? $locale : LedgerSMB::App_State->Locale;
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

=back

=head1 LICENSE AND COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
