=head1 NAME

LedgerSMB::Report::Invoices::Payments - Payment Search Report for LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Invoices::Payments->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Invoices::Payments;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

This class provides routines for searching payments and displaying the report in
the standard supported reporting formats.

=head1 CRITERIA PROPERTIES

=over

=item meta_number

Customer or vendor account number, prefix search

=cut

has meta_number => (is => 'ro', isa => 'Str', required => '0');

=item cash_account_id

Account id, exact match

=cut

has cash_account_id => (is => 'ro', isa => 'Int', required => 1);

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

=head2 header_lines

=head2 name

=head1 METHODS

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;
