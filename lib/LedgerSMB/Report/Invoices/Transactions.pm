
package LedgerSMB::Report::Invoices::Transactions;

=head1 NAME

LedgerSMB::Report::Invoices::Transactions - AR/AP Transactions Reports for
LedgerSMB

=head1 SYNOPSIS

  my $report = LedgerSMB::Report::Invoices::Transactions(%$request);
  $report->render();

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with
    'LedgerSMB::Report::Dates',
    'LedgerSMB::Report::Approval_Option',
    'LedgerSMB::Report::OpenClosed_Option',
    'LedgerSMB::Report::Voided_Option';

=head1 DESCRIPTION

The AR/AP transaction reports provide basic search capabilities for AR and AP
transactions and invoices.

=head1 CRITERIA PROPERTIES

=over

=item entity_class int

1 for vendor, 2 for customer

=cut

has entity_class => (is => 'ro', isa => 'Int', required => 1);

=item account_id

This is the account id of the AR or AP account

=cut

has account_id => (is => 'ro', isa => 'Int', required => 0);

=item entity_name text

Full text search of entity name

=cut

has entity_name => (is => 'ro', isa => 'Str', required => 0);

=item meta_number

Prefix search on entity_credit_account.meta_number

=cut

has meta_number => (is => 'ro', isa => 'Str', required => 0);

=item employee_id int

The id of the employee entity

=cut

has employee_id => (is => 'ro', isa => 'Int', required => 0);

=item manager_id

entity id of the manager

=cut

has manager_id => (is => 'ro', isa => 'Int', required => 0);

=item invnumber string

Prefix search on invoice number

=cut

has invnumber => (is => 'ro', isa => 'Str', required => 0);

=item ordnumber string

Prefix search on noted order number

=cut

has ordnumber => (is => 'ro', isa => 'Str', required => 0);

=item ponumber string

Prefix search on PO number

=cut

has ponumber => (is => 'ro', isa => 'Str', required => 0);

=item partnumber string

If set only include invoices including the relevant part number (prefix search)

=cut

has partnumber => (is => 'ro', isa => 'Str', required => 0);

=item parts_id int

If set only include invoices including the specified part (exact match_

=cut

has parts_id => (is => 'ro', isa => 'Int', required => 0);

=item source string

Prefix string on source number

=cut

has source => (is => 'ro', isa => 'Str', required => 0);

=item description string

Full text search on transaction description

=cut

has description => (is => 'ro', isa => 'Str', required => 0);

=item notes

Full text search on notes field

=cut

has notes => (is => 'ro', isa => 'Str', required => 0);

=item ship_via

Full text search on shipvia column

=cut

has ship_via => (is => 'ro', isa => 'Str', required => 0);

=item on_hold bool

1 matches on-hold, 0 matches active, undef matches all.

=cut

has on_hold => (is => 'ro', isa => 'Bool', required => 0);

=item taxable bool

1 matches sales with taxes (of specified account), 0 matches non-taxable, and
undef matches all.

=cut

has taxable => (is => 'ro', isa => 'Bool', required => 0);

=item tax_account_id int

If taxable is set this filters only transactions of a specific tax account.

=cut

has tax_account_id => (is => 'ro', isa => 'Int', required => 0);

=item +order_by str

Inherited from C<LedgerSMB::Report>; adds default sorting by
transaction date.

=cut

has '+order_by' => (default => 'transdate');


=back

=head1 INTERNALS

=head2 columns

=over

=item id int

=item transdate date

=item meta_number text

This is the customer or vendor account number

=item entity_name text

This is the customer or vendor name

=item invnumber text

=item amount numeric

=item tax numeric

=item netamount numeric

=item paid numeric

=item due numeric

=item last_payment date

=item due_date date

=item notes text

=item salesperson text

=item manager text

=item shpping_point text

=item ship_via text


=back

=cut


sub columns {
    my $self = shift;
    my $meta_number_label;
    my $entity_name_label;
    if ($self->entity_class == 1){
       $meta_number_label = $self->Text('Vendor Account');
       $entity_name_label = $self->Text('Vendor');
    } elsif ($self->entity_class == 2){
       $meta_number_label = $self->Text('Customer Account');
       $entity_name_label = $self->Text('Customer');
    }

    return [
       { col_id => 'id',
           name => $self->Text('ID'),
           type => 'href'},
       { col_id => 'transdate',
           name => $self->Text('Date'),
           type => 'text'},
       { col_id => 'meta_number',
           name => $meta_number_label,
           type => 'text'},
       { col_id => 'entity_name',
           name => $entity_name_label,
       href_base =>'contact.pl?__action=get&entity_class='.$self->entity_class,
           type => 'href', },
       { col_id => 'invnumber',
           name => $self->Text('Invoice'),
           type => 'href'},
       { col_id => 'ordnumber',
           name => $self->Text('Order'),
           type => 'text'}, ### TODO: link to order...
       { col_id => 'ponumber',
           name => $self->Text('PO Number'),
           type => 'text'},
       { col_id => 'curr',
           name => $self->Text('Curr'),
           type => 'text'},
       { col_id => 'netamount',
           name => $self->Text('Amount'),
           type => 'text',
           money => 1},
       { col_id => 'tax',
           name => $self->Text('Tax'),
           type => 'text',
           money => 1},
       { col_id => 'amount',
           name => $self->Text('Total'),
           type => 'text',
           money => 1},
       { col_id => 'paid',
           name => $self->Text('Paid'),
           type => 'text',
           money => 1},
       { col_id => 'due',
           name => $self->Text('Due'),
           type => 'text',
           money => 1},
       { col_id => 'last_payment',
           name => $self->Text('Date Paid'),
           type => 'text'},
       { col_id => 'due_date',
           name => $self->Text('Due Date'),
           type => 'text'},
       { col_id => 'notes',
           name => $self->Text('Notes'),
           type => 'text'},
       { col_id => 'salesperson',
           name => $self->Text('Salesperson'),
           type => 'text'},
       { col_id => 'manager',
           name => $self->Text('Manager'),
           type => 'text'},
       { col_id => 'shipping_point',
           name => $self->Text('Shipping Point'),
           type => 'text'},
       { col_id => 'ship_via',
           name => $self->Text('Ship Via'),
           type => 'text'},
    ];
}

=head2 name

'Search AR' or 'Search AP' depending on entity_class

=cut

sub name {
    my $self = shift;
    return $self->Text('Search AP') if $self->entity_class == 1;
    return $self->Text('Search AR') if $self->entity_class == 2;
    return;
}

=head1 METHODS

=head2 run_report

This runs the report and sets the $report->rows.

=cut


sub run_report {
    my ($self) = @_;
    $self->approved;
    my @rows = $self->call_dbmethod(funcname => 'report__aa_transactions');
    for my $r(@rows){
        my $script;
        if ($self->entity_class == 2) {
             $script = ($r->{invoice}) ? 'is.pl' : 'ar.pl';
        } else {
             $script = ($r->{invoice}) ? 'ir.pl' : 'ap.pl';
        }
        $r->{entity_name_href_suffix} =
               "&entity_id=$r->{entity_id}&meta_number=$r->{meta_number}";
        $r->{invnumber_href_suffix} = "$script?__action=edit&id=$r->{id}";
        $r->{id_href_suffix} = "$script?__action=edit&id=$r->{id}";
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
