
package LedgerSMB::File::Email;

=head1 NAME

LedgerSMB::File::Email - Manages attachments to e-mails.

=head1 DESCRIPTION

Manages attachments to e-mails.

Derived from C<LedgerSMB::File>, stores its data in the C<file_email>
table, linked to the C<email> table.

=head1 INHERITS

=over

=item  LedgerSMB::File

Provides all properties and accessors.  This subclass provides additional
methods only

=back

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::File';

=head1 METHODS

=over

=item attach

Attaches or links a specific file to the given email.

=cut

sub attach {
    my ($self, $args) = @_;
    return $self->call_dbmethod(funcname => 'file__attach_to_email');
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
