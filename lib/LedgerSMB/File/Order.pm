=pod

=head1 NAME

LedgerSMB::File::Order - Manages attachments to orders.

=head1 SYNOPSIS

Manages attachments to orders (sales orders, purchase orders, quotations and
RFQ's).

=head1 INHERITS

=over

=item  LedgerSMB::File

Provides all properties and accessors.  This subclass provides additional
methods only

=back

=cut

package LedgerSMB::File::Order;
use strict;
use Moose;
extends 'LedgerSMB::File';

=head1 METHODS

=over

=item attach

Attaches or links a specific file to the given transaction.

=cut

sub attach {
    my ($self, $args) = @_;
    $self->call_dbmethod(funcname => 'file__attach_to_order');
}

=item attach_all_from_order({id = int})

Links all files to a specific transaction from a specific order.  Note this
only handles files that were attached to orders and transactions to start with.

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
        next if !($link->{src_class} == 2 || $link->{src_class} == 1);
        my $new_link = LedgerSMB::File::Transaction->new();
        $new_link->merge($link);
        $new_link->dbobject($self->dbobject);
        $new_link->attach;
    }
}

=item attach_all_from_transaction({id = int})

Links all files to a specific transaction from a specific transaction.  Note
this only handles files that were attached to orders and transactions to start
with.

=cut

sub attach_all_from_transaction {
    my ($self, $args) = @_;
    for my $attach ($self->list({ref_key => $args->{int}, file_class => 1})){
        my $new_link = LedgerSMB::File::Transaction->new();
        $new_link->merge($attach);
        $new_link->dbobject($self->dbobject);
        $new_link->attach;
    }
    for my $link ($self->list_links({ref_key => $args->{int}, file_class => 1})){
        next if !($link->{src_class} == 2 || $link->{src_class} == 1);
        my $new_link = LedgerSMB::File::Transaction->new();
        $new_link->merge($link);
        $new_link->dbobject($self->dbobject);
        $new_link->attach;
    }
}

=back

=head1 COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
