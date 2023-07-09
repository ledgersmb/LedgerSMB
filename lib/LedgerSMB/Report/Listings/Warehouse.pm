
package LedgerSMB::Report::Listings::Warehouse;

=head1 NAME

LedgerSMB::Report::Listings::Warehouse - List warehouses in LedgerSMB

=head1 DESCRIPTION

Implements an unfiltered listing of warehouses.

=head1 SYNOPSIS

Since no parameters are required:

  LedgerSMB::Report::Listings::Warehouse->new()->render;

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 REPORT CRITERIA

None

=head1 REPORT CONSTANTS

=head2 columns

=over

=item Description

=back

=cut

sub columns {
    my ($self) = @_;
    return [{
       col_id => 'description',
        type  => 'href',
   href_base  => 'am.pl?__action=edit_warehouse&id=',
        name  => $self->Text('Description'),
    }];
}

=head2 name

Warehouses

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Warehouses');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'warehouse__list');
    for my $row(@rows){
        $row->{row_id} = $row->{id};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
