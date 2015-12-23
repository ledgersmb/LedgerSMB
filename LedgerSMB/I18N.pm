=head1 NAME

LedgerSMB::I18N - Translation role for LedgerSMB Moose classes

=head1 SYNPOSIS

  text('text to translate')

=head1 DESCRIPTION

This adds a single method, text() to a role.  This maps to the current
LedgerSMB::App_State::Locale's text method.  This is safe for cached code since
we look only to the current locale.

=cut

package LedgerSMB::I18N;
use Moose::Role;
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

sub Text {
    my $self = shift;

    return $self->locale->maketext(@_);
}

sub text {
    return LedgerSMB::App_State->Locale->maketext(@_);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
