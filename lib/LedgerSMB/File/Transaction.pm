
package LedgerSMB::File::Transaction;

=head1 NAME

LedgerSMB::File::Transaction - Manages attachments to financial transactions.

=head1 DESCRIPTION

Manages attachments to financial transactions (in 1.3, AR, AP, and GL entries)

Derived from C<LedgerSMB::File>, this module stores attachments in the
C<file_transaction> table linked to the C<transactions> table (which
itself is linked to the C<AR>, C<AP> and C<GL> tables).


=head1 INHERITS

=over

=item  LedgerSMB::File

Provides all properties and accessors.  This subclass provides additional
methods only

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::File';

=back

=head1 METHODS

=over

=item attach()

Attaches or links a specific file to the given transaction.

=cut

sub attach {
    my ($self, $args) = @_;
    return $self->call_dbmethod(funcname => 'file__attach_to_tx');
}

=item attach_all_from_order({id = int})

Links all files to a specific transaction from a specific order.  Note this
only handles files that were attached to orders to start with.

=cut

sub attach_all_from_order {
    my ($self, $args) = @_;
    for my $attach ($self->list({ref_key => $args->{int}, file_class => 2})){
        my $new_link = LedgerSMB::File::Transaction->new();
        $new_link->merge($attach);
        $new_link->dbobject($self->dbobject);
        $new_link->attach;
    }
    for my $link ($self->list_links({ref_key => $args->{int}, file_class => 2})){
        next if $link->{src_class} != 2;
        my $new_link = LedgerSMB::File::Transaction->new();
        $new_link->merge($link);
        $new_link->dbobject($self->dbobject);
        $new_link->attach;
    }
    return;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
