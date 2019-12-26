
package LedgerSMB::App_State;

=head1 NAME

LedgerSMB::App_State - Non-web application global state

=head1 DESCRIPTION

This is a generic container class for non-web-application related state
information.  It provides a central place to track such things as localization,
user, and other application state objects.

=cut

use strict;
use warnings;
use LedgerSMB::Sysconfig;
use LedgerSMB::User;
use LedgerSMB::Locale;

=head1 OBJECTS FOR STORAGE

The following are objects that are expected to be stored in this namespace:

=over

=cut

our $User;

=item User

Stores a LedgerSMB::User object for the currently logged in user.

=cut


=item DBH

Database handle for current connection

=cut

our $DBH;

=back

Each of the above has an accessor function of the same name which reads the
data, and a set_... function which writes it.  The set_ function should be
used sparingly.

The direct access approach is deprecated and is likely to go away in 1.5 with
the variables above given a "my" scope instead of an "our" one.

=over

=item User

=cut

sub User {
    return $User;
}

=item set_User

=cut

sub set_User {
    return $User = shift;
}

=item DBH

=cut

sub DBH {
    return $DBH;
}

=item set_DBH

=cut

sub set_DBH {
    return $DBH = shift;
}

=back

=head1 METHODS

=head2 run_with_state($state, &block)

Runs the block with the App_State parameters passed in C<$state>,
resetting the state after the block exits.

=cut

sub run_with_state {
    my $block = shift;
    my $state = { @_ };

    local ($DBH, $User) = (
        $state->{DBH} // $DBH,
        $state->{User} // $User,
        );

    return $block->();
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

