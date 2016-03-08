=head1 NAME

LedgerSMB::Report::Invoices::Transactions - AR/AP Transactions Reports for
LedgerSMB

=head1 SYNOPSIS

  my $report = LedgerSMB::Report::Invoices::Transactions(%$request);
  $report->render($request);

=cut

package LedgerSMB::Report::Invoices::Transactions;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

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

has ornumber => (is => 'ro', isa => 'Str', required => 0);

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

=item open bool

If true, show open invoices

=item closed bool

If true, show closed invoices.  Naturally if neither open or closed is set, no
invoices will be shown.

=cut

has open => (is => 'ro', isa => 'Bool', required => 0);
has closed => (is => 'ro', isa => 'Bool', required => 0);


=back

=head1 INTERNLS

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

=item till text

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
       $meta_number_label = LedgerSMB::Report::text('Vendor Account');
       $entity_name_label = LedgerSMB::Report::text('Vendor');
    } elsif ($self->entity_class == 2){
       $meta_number_label = LedgerSMB::Report::text('Customer Account');
       $entity_name_label = LedgerSMB::Report::text('Customer');
    }

    return [
       { col_id => 'id',
           name => LedgerSMB::Report::text('ID'),
           type => 'text'},
       { col_id => 'transdate',
           name => LedgerSMB::Report::text('Date'),
           type => 'text'},
       { col_id => 'meta_number',
           name => $meta_number_label,
           type => 'text'},
       { col_id => 'entity_name',
           name => $entity_name_label,
       href_base =>"contact.pl?action=get&entity_class=".$self->entity_class,
           type => 'href', },
       { col_id => 'invnumber',
           name => LedgerSMB::Report::text('Invoice'),
           type => 'href'},
       { col_id => 'netamount',
           name => LedgerSMB::Report::text('Amount'),
           type => 'text'},
       { col_id => 'tax',
           name => LedgerSMB::Report::text('Tax'),
           type => 'text'},
       { col_id => 'amount',
           name => LedgerSMB::Report::text('Total'),
           type => 'text'},
       { col_id => 'paid',
           name => LedgerSMB::Report::text('Paid'),
           type => 'text'},
       { col_id => 'due',
           name => LedgerSMB::Report::text('Due'),
           type => 'text'},
       { col_id => 'last_payment',
           name => LedgerSMB::Report::text('Date Paid'),
           type => 'text'},
       { col_id => 'due_date',
           name => LedgerSMB::Report::text('Due Date'),
           type => 'text'},
       { col_id => 'notes',
           name => LedgerSMB::Report::text('Notes'),
           type => 'text'},
       { col_id => 'till',
           name => LedgerSMB::Report::text('Till'),
           type => 'text'},
       { col_id => 'salesperson',
           name => LedgerSMB::Report::text('Salesperson'),
           type => 'text'},
       { col_id => 'manager',
           name => LedgerSMB::Report::text('Manager'),
           type => 'text'},
       { col_id => 'shipping_point',
           name => LedgerSMB::Report::text('Shipping Point'),
           type => 'text'},
       { col_id => 'ship_via',
           name => LedgerSMB::Report::text('Ship Via'),
           type => 'text'},
    ];
}


=head2 header_lines

# TODO

=cut

sub header_lines {
    return [];
}

=head2 name

'Search AR' or 'Search AP' depending on entity_class

=cut

sub name {
    my $self = shift;
    return LedgerSMB::Report::text('Search AP') if $self->entity_class == 1;
    return LedgerSMB::Report::text('Search AR') if $self->entity_class == 2;
}

=head1 METHODS

=head2 run_report

This runs the report and sets the $report->rows.

=cut

sub run_report {
    my $self = shift;
    $ENV{LSMB_ALWAYS_MONEY} = 1;
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
        $r->{invnumber_href_suffix} = "$script?action=edit&id=$r->{id}";
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
