=head1 NAME

LedgerSMB::Report::Inventory::Search - Search for Goods and Services in
LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Inventory::Search->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Inventory::Search;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

This is the main inventory item search for goods and services in LedgerSMB
starting with version 1.4.  Compared to LedgerSMB 1.3 this has no summary
and details support and no searching for open vs closed invoices. The eqivalent
of a summary report is found in the inventory activities report instead.

The open/closed detection was omitted for performance reasons, and a search for
unused items may take a while on larger databases.

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

=item partsgroup_id int

Limit search to partsgroup specified

=cut

has partsgroup_id => (is => 'ro', isa => 'Int', required => 0);

=item serial_number text

This is a serial number of the part, for a prefix search

=cut

has serial_number => (is => 'ro', isa => 'Str', required => 0);

=item make

Prefix search for parts with a make (and model) specified

=cut

has make => (is => 'ro', isa => 'Str', required => 0);

=item model

Prefix search on the model of the part

=cut

has model => (is => 'ro', isa => 'Str', required => 0);

=item drawing

Prefix search for drawing field

=cut

has drawing => (is => 'ro', isa => 'Str', required => 0);

=item microfiche

Prefix search for microfiche field

=cut

has microfiche => (is => 'ro', isa => 'Str', required => 0);

=item status

An enumerated string, with the following significance

=over

=item active

Show non-obsolete parts

=item obsolete

Show obsolete parts

=item short

Show parts below their re-order point (ROP)

=item unused

Show parts with no invoices or orders attached (previously orphaned)

=back

=cut

has status => (is => 'ro', isa => 'Str', required => 0);

=item sales_invoices bool

If true, show parts attached to sales invoices in the specified period

=cut

has sales_invoices => (is => 'ro', isa => 'Bool', required => 0);

=item purchase_invoices bool

If true, show parts attached to purchase/vendor invoices in the specified
period.

=cut

has purchase_invoices => (is => 'ro', isa => 'Bool', required => 0);

=item sales_orders

If true, search parts in sales orders in the specified period.

=cut

has sales_orders => (is => 'ro', isa => 'Bool', required => 0);

=item purchase_orders

If true, search purchase orders in the specified period.

=cut

has purchase_orders => (is => 'ro', isa => 'Bool', required => 0);

=item quotations

If true, search quotations in the specified period

=cut

has quotations => (is => 'ro', isa => 'Bool', required => 0);

=item rfqs

If true, search Requests for Quotations for the specified period

=cut

has rfqs => (is => 'ro', isa => 'Bool', required => 0);

=back

=head1 INTERNALS

=head2 columns

=cut

sub columns {
   return [
    {col_id => 'id',
       type => 'href',
  href_base => 'ic.pl?action=edit&id=',
       name => LedgerSMB::Report::text('ID'),},

    {col_id => 'partnumber',
       type => 'href',
  href_base => 'ic.pl?action=edit&id=',
       name => LedgerSMB::Report::text('Part Number'),},

    {col_id => 'description',
       type => 'text',
       name => LedgerSMB::Report::text('Description'),},

    {col_id => 'onhand',
       type => 'text',
       name => LedgerSMB::Report::text('On Hand'),},

    {col_id => 'unit',
       type => 'text',
       name => LedgerSMB::Report::text('Unit'),},

    {col_id => 'rop',
       type => 'text',
       name => LedgerSMB::Report::text('ROP'),},

    {col_id => 'bin',
       type => 'text',
       name => LedgerSMB::Report::text('Bin'),},

    {col_id => 'weight',
       type => 'text',
       name => LedgerSMB::Report::text('Weight'),},

    {col_id => 'listprice',
       type => 'text',
      money => 1,
       name => LedgerSMB::Report::text('List Price'),},

    {col_id => 'sellprice',
       type => 'text',
      money => 1,
       name => LedgerSMB::Report::text('Sell Price'),},

    {col_id => 'lastcost',
       type => 'text',
      money => 1,
       name => LedgerSMB::Report::text('Last Cost'),},

    {col_id => 'avgcost',
       type => 'text',
      money => 1,
       name => LedgerSMB::Report::text('Avg. Cost'),},

    {col_id => 'markup',
       type => 'text',
       name => LedgerSMB::Report::text('Markup'),},

    {col_id => 'price_updated',
       type => 'text',
       name => LedgerSMB::Report::text('Price Updated'),},

    {col_id => 'make',
       type => 'text',
       name => LedgerSMB::Report::text('Make'),},

    {col_id => 'model',
       type => 'text',
       name => LedgerSMB::Report::text('Model'),},

    {col_id => 'image',
       type => 'href',
       name => LedgerSMB::Report::text('Image'),},

    {col_id => 'drawing',
       type => 'href',
       name => LedgerSMB::Report::text('Drawing'),},

    {col_id => 'microfiche',
       type => 'text',
       name => LedgerSMB::Report::text('Microfiche'),},

    {col_id => 'notes',
       type => 'text',
       name => LedgerSMB::Report::text('Notes'),},

    {col_id => 'partsgroup',
       type => 'text',
       name => LedgerSMB::Report::text('Partsgroup'),},

    {col_id => 'invnumber',
       type => 'href',
       name => LedgerSMB::Report::text('Invoice'),},

    {col_id => 'ordnumber',
       type => 'href',
       name => LedgerSMB::Report::text('Order'),},

    {col_id => 'quonumber',
       type => 'href',
       name => LedgerSMB::Report::text('Quotation'),},

    {col_id => 'curr',
       type => 'text',
       name => LedgerSMB::Report::text('Currency'),},

    {col_id => 'qty',
       type => 'text',
       name => LedgerSMB::Report::text('Qty'),},

    {col_id => 'linetotal',
       type => 'text',
      money => 1,
       name => LedgerSMB::Report::text('Total'),},

    {col_id => 'serialnumber',
       type => 'text',
       name => LedgerSMB::Report::text('Serial Number'),},

    ];
}

=head2 header_lines

None yet

=cut

sub header_lines {
   return [];
};

=head2 name

Goods and Services

=cut

sub name {
    return LedgerSMB::Report::text('Goods and Services');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'goods__search');
    for my $r (@rows){
        $r->{row_id} = $r->{id};

        for my $field (qw(image drawing microfiche)){
            $r->{"href_suffix_$field"} = $r->{field};
        }

    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
