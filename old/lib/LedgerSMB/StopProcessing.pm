
package LedgerSMB::StopProcessing;

use Moo;
with 'Throwable';

=head1 NAME

LedgerSMB::StopProcessing - Non-local transfer of control stopping request handler

=head1 DESCRIPTION

An exception of this class is thrown to signal successful completion of a request,
transferring control (processing) back to the toplevel request handler immediately.

=head1 METHODS

None.

=head1 Copyright (C) 2025, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.



=cut

1;
