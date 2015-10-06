=pod

=head1 NAME

LedgerSMB::File::Part - Manages attachments to goods and services.

=head1 SYNOPSIS

Manages attachments to goods and services.

=head1 INHERITS

=over

=item  LedgerSMB::File

Provides all properties and accessors.  This subclass provides additional
methods only

=back

=cut

package LedgerSMB::File::Part;
use Moose;
extends 'LedgerSMB::File';

=head1 METHODS

=over

=item attach

Attaches or links a specific file to the given transaction.

=cut

sub attach {
    my ($self, $args) = @_;
    $self->call_dbmethod(funcname => 'file__attach_to_part');
}

=back

=head1 COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
