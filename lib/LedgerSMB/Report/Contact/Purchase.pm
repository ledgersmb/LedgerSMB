=head1 NAME

LedgerSMB::Report::Contact::Purchase - Search AR/AP Transactions and
generate Reports

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Contact::Purchase->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This report provides the capacity to generate reports equivalent to the AR and
AP transaction and outstanding reports in 1.3 and earlier.  General uses include
reviewing outstanding transactions, transactions that were outstanding at a
certain point, and locating specific transactions.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::Contact::Purchase;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=back

=cut

sub columns {
    return [
         {col_id => 'running_number',
            type => 'text',
            name => '' },

         {col_id => 'id',
            type => 'text',
            name => LedgerSMB::Report::text('ID') },
         {col_id => 'entity_name',
            type => 'text',
            name => LedgerSMB::Report::text('Name') },

         {col_id => 'invnumber',
            type => 'href',
       href_base => '',
            name => LedgerSMB::Report::text('Invoice Number') },

         {col_id => 'ordnumber',
            type => 'text',
            name => LedgerSMB::Report::text('Order Number') },

         {col_id => 'ponumber',
            type => 'text',
            name => LedgerSMB::Report::text('PO Number') },

         {col_id => 'curr',
            type => 'text',
            name => LedgerSMB::Report::text('Currency') },

         {col_id => 'amount',
            type => 'text',
           money => 1,
            name => LedgerSMB::Report::text('Amount') },

         {col_id => 'tax',
            type => 'text',
           money => 1,
            name => LedgerSMB::Report::text('Tax') },

         {col_id => 'paid',
            type => 'text',
           money => 1,
            name => LedgerSMB::Report::text('Paid') },

         {col_id => 'due',
            type => 'text',
           money => 1,
            name => LedgerSMB::Report::text('Due') },

         {col_id => 'date_paid',
            type => 'text',
            name => LedgerSMB::Report::text('Date Paid') },

         {col_id => 'due_date',
            type => 'text',
            name => LedgerSMB::Report::text('Due Date') },

         {col_id => 'notes',
            type => 'text',
            name => LedgerSMB::Report::text('Notes') },

         {col_id => 'shipping_point',
            type => 'text',
            name => LedgerSMB::Report::text('Shipping Point') },

         {col_id => 'ship_via',
            type => 'text',
            name => LedgerSMB::Report::text('Ship Via') },
    ];
}

=item name

=cut

sub name {
   my ($self) = @_;
   if ($self->entity_class == 1){
       return LedgerSMB::Report::text('AP Transactions');
   } elsif ($self->entity_class == 2){
       return LedgerSMB::Report::text('AR Transactions');
   }
}

=item header_lines

=cut

sub header_lines {
     return [
            {name => 'name_part',
             text => LedgerSMB::Report::text('Name')},
            {name => 'meta_number',
             text => LedgerSMB::Report::text('Account Number')}
       ];
}

=back

=head1 CRITERIA PROPERTIES

=over

=item entity_class

Must be 1 for vendor or 2 for customer.  No other values will return any values.

=cut

has entity_class => (is => 'ro', isa => 'Int');

=item accno

Account Number for search.  If set can be either in the form of the actual
account number itself or in the form of accno--description (returned by the
current ajaxselect implementation).

=cut

has accno => (is => 'rw', isa => 'Maybe[Str]');

=item name_part

Full text search on contact name.

=cut

has name_part => (is => 'ro', isa => 'Maybe[Str]');

=item meta_number

Matches the beginning of the meta_number for the entity credit account.

=cut

has meta_number => (is => 'ro', isa => 'Maybe[Str]');

=item invnumber

Invoice number.  Matches the beginning of the string.

=cut

has invnumber => (is => 'ro', isa => 'Maybe[Str]');

=item ordnumber

Order number.  Matches the beginning of the string.

=cut

has ordnumber => (is => 'ro', isa => 'Maybe[Str]');

=item ponumber

Purchas order number.  Matches the beginning of the string.

=cut

has ponumber => (is => 'ro', isa => 'Maybe[Str]');

=item source

Matches any source field in line item details.  This can be used to see which
invoices were paid by a specific payment.

=cut

has source => (is => 'ro', isa => 'Maybe[Str]');

=item description

Full text search on transaction description

=cut

has description => (is => 'ro', isa => 'Maybe[Str]');

=item notes

Full text search on notes of invoice

=cut

has notes => (is => 'ro', isa => 'Maybe[Str]');

=item ship_via

Full text search on ship_via field.

=cut

has ship_via => (is => 'ro', isa => 'Maybe[Str]');

=item as_of

Shows invoice balances as of this date.

=cut

has as_of => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item summarize

Tells whether to summarize the report (i.e. produce a summary report rather than
a detail report).

=cut

has summarize => (is => 'ro', isa => 'Bool');

=back

=head1 METHODS

=over

=item run_report

Runs the report, populates rows.

=cut

sub run_report {
    my ($self) = @_;
    my @rows;
    if ($self->summarize){
       @rows = $self->call_dbmethod(
               funcname => 'ar_ap__transaction_search_summary'
       );
    } else {
       @rows = $self->call_dbmethod(funcname => 'ar_ap__transaction_search');
       my $rn = 0;
       for my $r (@rows){
            $r->{running_number} = ++$rn;
            my $href;
            if ($r->{invoice}){
                if ($self->entity_class == 1) {
                    $href = 'ir.pl';
                } else {
                    $href = 'is.pl';
                }
            } else {
                if ($self->entity_class == 1) {
                    $href = 'ap.pl';
                } else {
                    $href = 'ar.pl';
                }
            }
            $r->{invnumber_href_suffix} = "$href?action=edit&id=$r->{id}";
       }
    }
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
