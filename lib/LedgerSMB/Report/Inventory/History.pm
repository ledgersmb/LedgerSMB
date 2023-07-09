
package LedgerSMB::Report::Inventory::History;

=head1 NAME

LedgerSMB::Report::Inventory::History - Sales/Purchase History for Goods

=head1 SYNPOSIS

 LedgerSMB::Report::Inventory::History->new(%$request)->render($request);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

This

=head1 CRITERIA PROPERTIES

In addition to standard dates, the following criteria are supported:

=over

=item partnumber string

Prefix search on partnumber.

=cut

has partnumber => (is => 'ro', isa => 'Str', required => 0);

=item description string

Full text search on description of part

=cut

has description => (is => 'ro', isa => 'Str', required => 0);

=item serial_number text

This is a serial number of the part, for a prefix search

=cut

has serialnumber => (is => 'ro', isa => 'Str', required => 0);

=item inc_is bool

If true, show parts attached to sales invoices in the specified period

=cut

has inc_is => (is => 'ro', isa => 'Bool', required => 0);

=item inc_ir bool

If true, show parts attached to purchase/vendor invoices in the specified
period.

=cut

has inc_ir => (is => 'ro', isa => 'Bool', required => 0);

=item inc_so

If true, search parts in sales orders in the specified period.

=cut

has inc_so => (is => 'ro', isa => 'Bool', required => 0);

=item inc_po

If true, search purchase orders in the specified period.

=cut

has  inc_po => (is => 'ro', isa => 'Bool', required => 0);

=item inc_quo

If true, search quotations in the specified period

=cut

has inc_quo => (is => 'ro', isa => 'Bool', required => 0);

=item inc_rfq

If true, search Requests for Quotations for the specified period

=cut

has inc_rfq => (is => 'ro', isa => 'Bool', required => 0);

=back

=head1 INTERNALS

=head2 columns

=cut

sub columns {
    my ($self) = @_;
   return [
    {col_id => 'id',
       type => 'href',
  href_base => 'ic.pl?__action=edit&id=',
       name => $self->Text('ID'),},

    {col_id => 'partnumber',
       type => 'href',
  href_base => 'ic.pl?__action=edit&id=',
       name => $self->Text('Part Number'),},

    {col_id => 'description',
       type => 'text',
       name => $self->Text('Description'),},

    {col_id => 'onhand',
       type => 'text',
       name => $self->Text('On Hand'),},

    {col_id => 'unit',
       type => 'text',
       name => $self->Text('Unit'),},

    {col_id => 'bin',
       type => 'text',
       name => $self->Text('Bin'),},

    {col_id => 'ordnumber',
       type => 'href',
       name => $self->Text('Order/Invoice'),},

    {col_id => 'transdate',
       type => 'href',
       name => $self->Text('Date'),},

    {col_id => 'oe_class',
       type => 'href',
       name => $self->Text('Type'),},

    {col_id => 'sellprice',
       type => 'text',
      money => 1,
       name => $self->Text('Sell Price'),},

    {col_id => 'qty',
       type => 'text',
       name => $self->Text('Qty'),},

    {col_id => 'linetotal',
       type => 'text',
      money => 1,
       name => $self->Text('Total'),},

    {col_id => 'serialnumber',
       type => 'text',
       name => $self->Text('Serial Number'),},

    ];
}

=head2 name

Goods and Services

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Goods and Services History');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'goods__history');
    return $self->rows(
        [  map { { (%$_, (row_id => $_->{id})) } } @rows ]
    );
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
