
package LedgerSMB::Scripts::user;

=head1 NAME

LedgerSMB::Scripts::user - web entry points for user self-administration

=head1 DESCRIPTION

User preferences and password setting routines for LedgerSMB.  These are all
accessible to all users and do not perform administrative functions.

=head1 DIFFERENCES FROM ADMIN MODULE

Although there is some overlap between this module and that of the admin module,
particularly regarding the setting of passwords, there are subtle differences as
well.  Most notably an administrative password reset is valid by default for
only one day, while the duration of a user password change is fully configurable
and defaults to indefinite validity.

=head1 METHODS

=over

=cut

use strict;
use warnings;
use feature 'fc';

use DateTime::Format::Duration::ISO8601;
use File::Spec;
use Locale::CLDR;

use LedgerSMB::Locale;
use LedgerSMB::User;

our $VERSION = 1.0;


my $slash = '::';
my $format = DateTime::Format::Duration::ISO8601->new;


=item preference_screen

Displays the preferences screen.  No inputs needed.

=cut


my $dateformats = [
    { format => 'mm-dd-yyyy' },
    { format => 'mm/dd/yyyy' },
    { format => 'dd-mm-yyyy' },
    { format => 'dd/mm/yyyy' },
    { format => 'dd.mm.yyyy' },
    { format => 'yyyy-mm-dd' },
    ];

my $numberformats = [
    { format => '1,000.00' },
    { format => '1000.00' },
    { format => '1.000,00' },
    { format => '1000,00' },
    { format => q|1'000.00| },
    ];

sub _css_options {
    my ($wire) = shift;

    my $ui_root = $wire->get('ui')->{root} // './UI';
    opendir CSS, File::Spec->catdir($ui_root, 'css')
        or die "can't open css directory: $!";
    my @cssfiles =
        map { +{ file => $_ } }
        grep { /.*\.css$/ }
        sort { fc($a) cmp fc($b) }
        readdir CSS;
    closedir CSS;

    return \@cssfiles;
}

sub _language_options {
    my ($request, $locale) = @_;
    my %regions = %{$locale->all_regions}; # Localized countries
    my %languages = %{$locale->all_languages()}; # Localized languages

    # Pull languages codes are of the form
    # 'Language(_country)?' where country is set when there is a variant
    # for a specific country.

    # Locale::CLDR defines all language and country codes and some variants
    # have their name defined in specific
    # For example, fr_CA (French Canadian) has a translation available in
    # Spanish and French languages but nowhere else, so we need to compose
    # one for those others.
    # Use the language_country localized version if available
    return [
        sort { $a->{label} cmp $b->{label} }
        map {
            my $row = $_;
            my ($language, $region) = split /_/, $row->{code}, 2;
            my $label = $languages{$row->{code}} // $languages{$language};
            if ($region and not $languages{$row->{code}}) {
                $label .= ' - ' . $regions{$region};
            }

            { label => $label, id => $row->{code} }
        } $request->call_procedure(funcname => 'person__list_languages')
        ];
}

sub preference_screen {
    my ($request) = @_;
    my ($prefs)         = $request->call_procedure(
        funcname => 'user__get_preferences',
        args     => [$request->{_user}->{id}]);
    my ($pw_expiration) = $request->call_procedure(
        funcname => 'user__check_my_expiration'
        );
    my $pwe = $format->parse_duration(
        $pw_expiration->{user__check_my_expiration});
    my $login = $request->{_req}->env->{'lsmb.session'}->{login};
    my $template = $request->{_wire}->get('ui');
    return $template->render(
        $request,
        'users/preferences',
        {
            request => $request,
            user => {
                cssfiles         => _css_options($request->{_wire}),
                dateformats      => $dateformats,
                language_codes   => _language_options(
                    $request,
                    Locale::CLDR->new( $prefs->{language} )),
                login            => $login,
                numberformats    => $numberformats,
                password_expires => {
                    years  => $pwe->years,
                    months => $pwe->months,
                    weeks  => $pwe->weeks,
                    days   => $pwe->days,
                },
                prefs            => $prefs,
            },
        });
}

=item save_preferences

Saves preferences from inputs on preferences screen and returns to the same
screen.

=cut

sub save_preferences {
    my ($request) = @_;
    $request->{action} = 'save_preferences';
    $request->{_user}->{language} = $request->{language};
    my $locale =  LedgerSMB::Locale->get_handle($request->{_user}->{language});
    $request->{_locale} = $locale;

    LedgerSMB::User->save_preferences( $request );
    return preference_screen($request);
}

=item change_password

Changes the password, leaves other preferences in place, and returns to the
preferences screen

=cut

sub change_password {
    my ($request) = @_;
    if ($request->{confirm_password}){
        LedgerSMB::User->change_my_password($request);
    }
    ###TODO we're breaking the separation of concerns here!
    $request->{_req}->env->{'lsmb.session'}->{password} =
        $request->{new_password};
    return preference_screen($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
