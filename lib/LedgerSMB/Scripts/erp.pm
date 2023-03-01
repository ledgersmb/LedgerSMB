
package LedgerSMB::Scripts::erp;

=head1 NAME

LedgerSMB:Scripts::erp - web entry point to return the single page application

=head1 DESCRIPTION

This script contains the request handlers for returning the SPA.

=head1 METHODS

=over

=cut

use strict;
use warnings;


=item root

Displays the root document.

=cut

sub root {
    my ($request) = @_;

    $request->{title} = "LedgerSMB $request->{version} -- ".
    "$request->{login} -- $request->{company}";

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'main', $request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
