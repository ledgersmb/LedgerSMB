
package LedgerSMB::Report::Invoices::Payments;

=head1 NAME

LedgerSMB::Report::Invoices::Payments - Payment Search Report for LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Invoices::Payments->new(%$request);
 $report->render($request);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

This class provides routines for searching payments and displaying the report in
the standard supported reporting formats.

=head1 CRITERIA PROPERTIES

=over

=item entity_class

1 for vendor, 2 for customer.

=cut

has entity_class => (is => 'ro', isa => 'Int', required => 1);

=item meta_number

Customer or vendor account number, prefix search

=cut

has meta_number => (is => 'ro', isa => 'Str', required => '0');

=item cash_accno

Cash account number, exact match

=cut

has cash_accno => (is => 'ro', isa => 'Str');

=item source

Source field, prefix search

=cut

has source => (is => 'ro', isa => 'Str', required => '0');

=back

=head1 ACTION PROPERTIES

This report is sometimes used when searching for payments to reverse payments.
We allow related data to be set here.  This is to be passed on to the next
stage of the reversal process.

=over

=item batch_id

ID of batch used.  If this is not set we assume we are not reversing payments.

=cut

has batch_id => (is => 'ro', isa => 'Int', required => '0');

=item curr

Currency used.  If not set, we assume that this is the default currency (and
exchange rate of 1).

=cut

has curr => (is => 'ro', isa => 'Str', required => '0');

=item exchange_rate

Exchange rate for reversal.  If not set, we use 1 if the currency is the default
currency.  If not, we pull the existing exchange rate for the reversal date,
and if this is not set, an error will be returned during the reversal process.

=cut

has exchange_rate => (is => 'ro', isa => 'LedgerSMB::Moose::Number',
                required => 0, coerce => 1);

=back

=head1 INTERNALS

=head2 columns

=over

=back

=cut

sub columns {
    my ($self) = @_;
    my $meta_number;
    if ($self->entity_class == 1){
       $meta_number = $self->Text('Vendor Number');
    } elsif ($self->entity_class == 2){
       $meta_number = $self->Text('Customer Number');
    } else {
        die 'Invalid entity class';
    }
    my $cols =  [
        {col_id => 'select',
           name => $self->Text('Selected'),
           type => 'checkbox'},
        {col_id => 'credit_id',
           type => 'hidden', },
        {col_id => 'entity_class',
           type => 'hidden', },
        {col_id => 'voucher_id',
           type => 'hidden', },
        {col_id => 'source',
           type => 'hidden', },
        {col_id => 'date_paid',
           type => 'hidden', },
        {col_id => 'date_paid',
           type => 'text',
           name => $self->Text('Date Paid'), },
        {col_id => 'amount',
           type => 'text',
          money => 1,
           name => $self->Text('Total Paid'), },
        {col_id => 'source',
           type => 'text',
           name => $self->Text('Source'), },
        {col_id => 'meta_number',
           name => $meta_number,
           type => 'text', },
        {col_id => 'company_paid',
           type => 'text',
           name => $self->Text('Company Name'), },
        {col_id => 'batch_description',
           type => 'text',
           name => $self->Text('Batch Description'), },
        {col_id => 'batch_control',
           type => 'text',
           name => $self->Text('Batch'), },
    ];
    shift @$cols unless $self->batch_id;
    return $cols;
}

=head2 header_lines

=over

=item meta_number

Customer or vendor number

=item date_from

Start date

=item date_to

End date

=back

=cut

sub header_lines {
    my ($self) = @_;
    my $meta_number;
    if ($self->entity_class == 1){
       $meta_number = $self->Text('Vendor Number');
    } elsif ($self->entity_class == 2){
       $meta_number = $self->Text('Customer Number');
    } else {
        die 'Invalid entity class';
    }
    return [{name => 'meta_number', text => $meta_number },
            {name => 'cash_accno',
             text => $self->Text('Account Number') },
            {name => 'from_date',
             text => $self->Text('From Date')},
            {name => 'to_date',
             text => $self->Text('To Date')}
           ];
}

=head2 name

Either "Payment Results" or "Receipt Results" depending on entity_class

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Payment Results') if 1 == $self->entity_class;
    return $self->Text('Receipt Results') if 2 == $self->entity_class;
    die 'Invalid Entity Class';
}

=head1 METHODS

=over

=item run_report

Runs the report and sets $self->rows

=cut

sub run_report{
    my ($self) = @_;
    die $self->Text('Must have cash account in batch')
        if $self->batch_id and not defined $self->cash_accno;
    my @rows = $self->call_dbmethod(funcname => 'payment__search');
    my $count = 1;
    for my $r(@rows){
        $r->{row_id} = $count;
        $r->{entity_class} = $self->entity_class;
        ++$count;
    }
    $self->rows(\@rows);
    $self->buttons([{
        text => $self->Text('Reverse Payments'),
        name => 'action',
        type => 'submit',
       class => 'submit',
       value => 'reverse_payments',
    }]) if $self->batch_id;
    return;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
