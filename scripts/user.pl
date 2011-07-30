=pod

=head1 NAME

LedgerSMB::Scripts::user

=head1 SYNPOSIS

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
package LedgerSMB::Scripts::user;
use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::DBObject::User;
our $VERSION = 1.0;
use strict;

my $slash = "::";

=item preferences_screen

Displays the preferences screen.  No inputs needed.

=cut

sub preference_screen {
    my ($request) = @_;
    my $user = LedgerSMB::DBObject::User->new({base => $request});
    $user->get_option_data;

    for my $format(@{$user->{dateformats}}){
        $format->{id} = $format->{format};
        $format->{id} =~ s/\//$slash/g;
    }

    $user->{dateformat} = $user->{_user}->{dateformat};
    $user->{dateformat} =~ s/\//$slash/g;
     
    my $template = LedgerSMB::Template->new(
            user     =>$request->{_user}, 
            locale   => $request->{_locale},
            path     => 'UI/users',
            template => 'preferences',
	    format   => 'HTML'
    );
    $user->{user} = $request->{_user};
    $template->render($user);
}

=item save_preferences

Saves preferences from inputs on preferences screen and returns to the same
screen.

=cut

sub save_preferences {
    my ($request) = @_;
    my $user = LedgerSMB::DBObject::User->new({base => $request});
    $user->{dateformat} =~ s/$slash/\//g;
    if ($user->{confirm_password}){
        $user->change_my_password;
    }
    $user->save_preferences;
    preference_screen($user);
}

=item change_password

Changes the password, leaves other preferences in place, and returns to the
preferences screen

=cut

sub change_password {
    my ($request) = @_;
    my $user = LedgerSMB::DBObject::User->new({base => $request});
    $user->{dateformat} =~ s/$slash/\//g;
    if ($user->{confirm_password}){
        $user->change_my_password;
    }
    preference_screen($user);
}

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


