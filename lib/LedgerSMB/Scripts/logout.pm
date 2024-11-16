
package LedgerSMB::Scripts::logout;

=head1 NAME

LedgerSMB:Scripts::logout - web entry points for session termination

=head1 DESCRIPTION

This script contains the request handlers for logging out of LedgerSMB.

=head1 METHODS

=over

=cut

use strict;
use warnings;

our $VERSION = 1.0;

=item logout

Logs the user out.  Handling of HTTP browser credentials is browser-specific.

Firefox, Opera, and Internet Explorer are all supported.  Not sure about Chrome

=cut

sub logout {
    my ($request) = @_;
    $request->{callback}   = '';

    $request->{_logout}->();
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'logout', $request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
