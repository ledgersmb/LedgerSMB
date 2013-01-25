=head1 NAME

LedgerSMB::Report::Orders - Search for Orders and Quotations in LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Orders->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Orders;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';
use LedgerSMB::MooseTypes;

=head1 DESCRIPTION

This module produces a search report for LedgerSMB.  This differs very slightly
from some other reports in that the buttons are typically assigned by controller
scripts as this report serves number of different roles.

=head1 CRITERIA PROPERTIES

=over

=item oe_class_id int

This is the ID of the order entry class.  Valid values are:
 
  id |    oe_class    
 ----+----------------
   1 | Sales Order
   2 | Purchase Order
   3 | Quotation
   4 | RFQ

=cut

has oe_class_id => (is => 'ro', isa => 'Int', required => 1);

=item open bool

If set, show open orders in the report

=cut

has open => (is => 'ro', isa => 'Bool', required => 0);

=item closed bool

If set show closed orders in report.  Note that if both open and closed are
unset, the report will not return any results.

=cut

has closed  => (is => 'ro', isa => 'Bool', required => 0);

=item shippable bool

If set only show orders which can be shipped or received

=cut

has shippable => (is => 'ro', isa => 'Bool', required => 0);

=item meta_number string

This is a prefix search for the customer or vendor number.

=cut

has meta_number => (is => 'ro', isa => 'Str', required => '0');

=item legal_name string

This is a full text search for customer or vendor entity name

=cut

has legal_name => (is => 'ro', isa => 'Str', required => '0');

=item ponumber string

Prefix search on the ponumber field

=cut

has ponumber => (is => 'ro', isa => 'Str', required => '0');

=item ordnumber string

Prefix search on order number field

=cut

has ordnumber => (is => 'ro', isa => 'Str', required => '0');

=item shipvia string

Full text on ship via field

=cut

has shipvia => (is => 'ro', isa => 'Str', required => '0');

=item description text

Full text search on line item description

=cut

has description => (is => 'ro', isa => 'Str', required => '0');

=item href_action string

Sets the href action for the ordnumber field

=cut

has href_action => (is => 'ro', isa => 'Str', required => '0');

=item selectable bool 

If set true, then the display will include a checkbox for each order and a 
hidden id field.

=cut

has selectable => (is => 'ro', isa => 'Bool', required => 0);

=back

=head1 INTERNALS

=head2 columns

=over

=item id

=item ordnumber

=item transdate

=item reqdate

=item amount

=item legal_name

=item closed

=item quonumber

=item shippingpoint

=item exchangerate

=item shipvia

=item employee

=item manager

=item curr

=item ponumber

=item meta_number

=item entity_id

=back

If $self->selectable is set, we also prepend a selected field to the front, and an id hidden field.

=cut

sub columns {
    my ($self) = @_;
    my $ORDNUMBER;
    my $METANUMBER;
    if (1 == $self->oe_class_id){ 
       $ORDNUMBER = LedgerSMB::Report::text('Sales Orders');
       $METANUMBER = LedgerSMB::Report::text('Customer');
    } elsif (2 == $self->oe_class_id){
       $ORDNUMBER = LedgerSMB::Report::text('Purchase Orders');
       $METANUMBER = LedgerSMB::Report::text('Vendor');
    } elsif (3 == $self->oe_class_id){
       $ORDNUMBER = LedgerSMB::Report::text('Quotations');
       $METANUMBER = LedgerSMB::Report::text('Customer');
    } elsif (4 == $self->oe_class_id){
       $ORDNUMBER = LedgerSMB::Report::text('RFQs');
       $METANUMBER = LedgerSMB::Report::text('Vendor');
    } else {
        die 'Unsupported OE Class Type';
    }
    my $HREF_ACTION = 'edit';
    $HREF_ACTION = $self->href_action if $self->href_action;
    my $cols = [
        {col_id => 'select',
           name => '',
           type => 'checkbox' },

       {col_id => 'id',
          name => LedgerSMB::Report::text('ID'),
          type => 'text', },

       {col_id => 'transdate',
          name => LedgerSMB::Report::text('Date'),
          type => 'text', },

       {col_id => 'ordnumber',
          name => $ORDNUMBER,
          type => 'href',
     href_base => "oe.pl?action=$HREF_ACTION&id=", },

       {col_id => 'reqdate',
          name => LedgerSMB::Report::text('Required Date'),
          type => 'text', },

       {col_id => 'meta_number',
          name => $METANUMBER,
          type => 'text', } ,

       {col_id => 'legal_name',
          name => LedgerSMB::Report::text('Name'),
          type => 'text', },

       {col_id => 'amount',
          name => LedgerSMB::Report::text('Amount'),
         money => 1,
          type => 'text', },

       {col_id => 'curr',
          name => LedgerSMB::Report::text('Currency'),
          type => 'text', },

       {col_id => 'Closed',
          name => LedgerSMB::Report::text('Closed'),
          type => 'text', },

       {col_id => 'ponumber',
          name => LedgerSMB::Report::text('PO Number'),
          type => 'text', },

       {col_id => 'quonumber',
          name => LedgerSMB::Report::text('Quotation'),
          type => 'text', },

       {col_id => 'shippingpoint',
          name => LedgerSMB::Report::text('Shipping Point'),
          type => 'text', },

       {col_id => 'shipvia',
          name => LedgerSMB::Report::text('Ship Via'),
          type => 'text', },

       {col_id => 'employee',
          name => LedgerSMB::Report::text('Employee'),
          type => 'text', },

       {col_id => 'manager',
          name => LedgerSMB::Report::text('Manager'),
          type => 'text', },
    ];
    return $cols;
}

=head2 header_lines

=cut 

sub header_lines {
    return [];
}

=head2 name 

=cut

sub name {
    my ($self) = @_;
    if (1 == $self->oe_class_id){ 
       return LedgerSMB::Report::text('Sales Orders');
    } elsif (2 == $self->oe_class_id){
       return LedgerSMB::Report::text('Purchase Orders');
    } elsif (3 == $self->oe_class_id){
       return LedgerSMB::Report::text('Quotations');
    } elsif (4 == $self->oe_class_id){
       return LedgerSMB::Report::text('RFQs');
    } else {
        die 'Unsupported OE Class Type';
    }
};

=head1 METHODS

=head2 run_report

This sets the $report->rows attribute but does not set buttons.  The calling 
script should do that separately.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method({funcname => 'order__search'});
    for my $r(@rows){
       $r->{row_id} = $r->{id};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
