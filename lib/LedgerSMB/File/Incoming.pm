=pod

=head1 NAME

LedgerSMB::File::Incoming - Incoming queue for not-yet-associated file
attachments

=head1 SYNOPSIS

TODO

=head1 INHERITS

=over

=item  LedgerSMB::File

Provides all properties and accessors.  This subclass provides additional
methods only

=back

=cut

package LedgerSMB::File::Incoming;
use Moose;
use namespace::autoclean;
extends 'LedgerSMB::File';

=head1 METHODS

=over

=item attach

Attaches or links a specific file to the given transaction.

=cut

sub attach {
    my ($self, $args) = @_;
    return $self->call_dbmethod(funcname => 'file__save_incoming');
}

=back

=head1 COPYRIGHT

Copyright (C) 2011-2014 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
