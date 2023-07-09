
package LedgerSMB::Report::Invoices::Outstanding;

=head1 NAME

LedgerSMB::Report::Invoices::Outstanding - Outstanding Invoice Reports for
LedgerSMB

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Invoices::Outstanding->new(%$request);
 $report->render();

=cut

use List::Util qw(pairgrep);

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

The Outstanding reports provide an ability to track the invoices outstanding at
a given date.  Summary reports return one line per customer or vendor, and
details reports return one line per invoice.

=head1 CRITERIA PROPERTIES

=over

=item is_detailed bool

If set true, return one line per invoice, if false set one line per entity
credit account

=cut

has is_detailed => (is => 'ro', isa => 'Bool', required => 1);

=item entity_class

1 for vendor, 2 for customer

=cut

has entity_class => (is => 'ro', isa => 'Int', required => 1);

=item account_id int

Only show invoices or totals for specified AR/AP account.

=cut

has account_id => (is => 'ro', isa => 'Int', required => 0);

=item entity_name

Show invoices for customers or vendors with a name like this, full text search

=cut

has entity_name => (is => 'ro', isa => 'Str', required => 0);

=item meta_number

Show invoices only for the control code of the entity credit account, search is
based on the beginning of the string.

=cut

has meta_number => (is => 'ro', isa => 'Str', required => 0);

=item employee_id

Only show invoices attached to the specified salespersln

=cut

has employee_id => (is => 'ro', isa => 'Int', required => '0');

=item business_ids

Only show invoices attached to all of these business ids

=cut

has business_ids => (is => 'rw', isa => 'ArrayRef[Int]', required => '0');

=item ship_via

Full text search on shipvia field

=cut

has ship_via => (is => 'ro', isa => 'Str', required => 0);

=item on_hold

Bool match for on-hold invoices.  1 shows only onhold, 0 active, and undef all.

=cut

has on_hold => (is => 'ro', isa => 'Bool', required => 0);

=item +order_by str

Inherited from C<LedgerSMB::Report>; adds default sorting by
transaction date.

=cut

has '+order_by' => (default => 'meta_number');

=back

=cut

=head1 INTERNALS

=head2 columns

=over

=item running_number

=item transdate

=item invoice

=item id

=item ordnumber

=item ponumber

=item meta_number

=item entity_name

=item amount

=item tax

=item total

=item paid

=item due

=item curr

=item last_paydate

=item due_date

=item notes

=item employee_name

=item manager_name

=item shipping_point

=item ship_via

=back

=cut

sub columns {
    my ($self) = @_;
    my ($inv_label, $inv_href_base);
    if ($self->is_detailed){
        $inv_label = $self->Text('Invoice');
        $inv_href_base = '';
    }
    else {
        $inv_label = $self->Text('# Invoices');
        my $details_url = $self->relative_url;
        $details_url->query_form(
            (pairgrep {
                $a ne 'meta_number' and $a ne 'is_detailed'
             } $details_url->query_form),
            is_detailed => 1,
            meta_number => ''
            );
        $inv_href_base = $details_url->as_string;
    }
    my $entity_label;
    if ($self->entity_class == 1){
       $entity_label = $self->Text('Vendor');
    } elsif ($self->entity_class == 2){
       $entity_label = $self->Text('Customer');
    } else {
       die 'invalid entity class';
    }
    return [
        {col_id => 'running_number',
           name => '#',
           type => 'text',
         pwidth => 1, },
        {col_id => 'transdate',
           name => $self->Text('Date'),
           type => 'text',
         pwidth => 4, },
        {col_id => 'id',
           name => $self->Text('ID'),
           type => 'text',
         pwidth => 2, },
        {col_id => 'invnumber',
           name => $inv_label,
           type => 'href',
      href_base => $inv_href_base,
         pwidth => 10, },
        {col_id => 'ordnumber',
           name => $self->Text('Order'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'ponumber',
           name => $self->Text('PO Number'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'meta_number',
           name => $self->Text('Account'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'entity_name',
           name => $entity_label,
           type => 'href',
      href_base => 'contact.pl?__action=edit&',
         pwidth => 15, },
        {col_id => 'netamount',
           name => $self->Text('Amount'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'tax',
           name => $self->Text('Tax'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'amount',
           name => $self->Text('Total'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'paid',
           name => $self->Text('Paid'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'due',
           name => $self->Text('Amount Due'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'curr',
           name => $self->Text('Curr'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'last_payment',
           name => $self->Text('Date Paid'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'due_date',
           name => $self->Text('Due Date'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'notes',
           name => $self->Text('Notes'),
           type => 'text',
         pwidth => 15, },
        {col_id => 'salesperson',
           name => $self->Text('Salesperson'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'manager',
           name => $self->Text('Manager'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'shipping_point',
           name => $self->Text('Shipping Point'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'ship_via',
           name => $self->Text('Ship Via'),
           type => 'text',
         pwidth => 10, },
    ];
}

=head2 name

Returns either the localized strings for "AR Outstanding" or "AP Outstanding"

=cut

sub name {
    my $self = shift;
    if ($self->entity_class == 1) {
        return $self->Text('AP Outstanding');
    } elsif ($self->entity_class == 2) {
        return $self->Text('AR Outstanding');
    }
}

=head1 METHODS

=over

=item run_report

=back

=cut

sub run_report {
    my ($self) = @_;
    my $procname = 'report__aa_outstanding';
    if ($self->is_detailed){
       $procname .= '_details';
    }
    my @rows = $self->call_dbmethod(funcname => $procname);
    for my $r(@rows){
        my $script;
        if ($self->entity_class == 2) {
             $script = ($r->{invoice}) ? 'is.pl' : 'ar.pl';
        } else {
             $script = ($r->{invoice}) ? 'ir.pl' : 'ap.pl';
        }
        #tshvr4 avoid 'Use of uninitialized value in concatenation (.) or string at LedgerSMB/Report/Invoices/Outstanding.pm'
        if($r->{id}){
            $r->{invnumber_href_suffix} = "$script?__action=edit&id=$r->{id}";
        } else {
            $r->{invnumber_href_suffix} = $r->{meta_number};
        }
        $r->{entity_name_href_suffix} = 'entity_class=' . $self->entity_class
                         . "&entity_id=$r->{entity_id}&".
                         "meta_number=$r->{meta_number}";
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
