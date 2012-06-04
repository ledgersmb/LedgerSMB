=head1 NAME

LedgerSMB::DBObject::Report::Contact::History - Purchase history reports
and more.

=head1 SYNPOSIS

  my $report = LedgerSMB::DBObject::Report::Contact::History->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This report provides purchase history reports.  It can be used to search for 
both customers and vendors.

=head1 INHERITS

=over

=item LedgerSMB::DBObject::Report;

=back

=cut

package LedgerSMB::DBObject::Report::Contact::Search;
use Moose;
extends 'LedgerSMB::DBObject::Report';
use LedgerSMB::App_State;
use LedgerSMB::PGDate;

my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=back

=cut

sub columns {
    my ($self) = @_;
    my $script = 'contacts.pl';
    return [
         {col_id => 'name',
            type => 'text',
            name => $locale->text('Name') },

         {col_id => 'meta_number',
            type => 'text',
            name => $locale->text('Account Number') },

         {col_id => 'invnumber',
            type => 'href',
       href_base => 'is.pl?action=edit&id=',
            name => $locale->text('Account Number') },

         {col_id => 'curr',
            type => 'text',
            name => $locale->text('Currency') },

         {col_id => 'partnumber',
            type => 'text',
            name => $locale->text('Part Number') },

         {col_id => 'description',
            type => 'text',
            name => $locale->text('Description') },

         {col_id => 'qty',
            type => 'text',
            name => $locale->text('Qty') },

         {col_id => 'unit',
            type => 'text',
            name => $locale->text('Unit') },

         {col_id => 'sellprice',
            type => 'text',
            name => $locale->text('Sell Price') },

         {col_id => 'discount',
            type => 'text',
            name => $locale->text('Disc') },

         {col_id => 'delivery_date',
            type => 'text',
            name => $locale->text('Delivery Date') },

         {col_id => 'serialnumber',
            type => 'text',
            name => $locale->text('Serial Number') },

         {col_id => 'exchangerate',
            type => 'text',
            name => $locale->text('Exchange Rate') },

         {col_id => 'salesperson_name',
            type => 'text',
            name => $locale->text('Salesperson') },

    ];
}

=item name

=cut

sub name { return $locale->text('Purchase History') }

=item header_lines

=cut

sub header_lines {
     return [
            {name => 'name',
             text => $locale->text('Name')},
      
            {name => 'meta_number',
             text => $locale->text('Account Number')},
            {name => 'from_date',
             text => $locale->text('Start Date')},

            {name => 'to_date',
             text => $locale->text('End Date')},

      
      ];
}

=back

=head1 CRITERIA PROPERTIES

=over

=item account_class

The account/entity class of the contact.  Required and an exact match.

=cut

has account_class => (is => 'ro', isa => 'Int');

=item name

This is the name of the customer or vendor.  It is an exact match.

=cut

has name => (is => 'ro', isa => 'Maybe[Str]');

=item meta_number

Partial match on account number

=cut

has meta_number => (is => 'ro', isa => 'Maybe[Str]');

=item contact_info

Phone, email, etc to select on.  Partial match

=cut

has contact_info => (is => 'ro', isa => 'Maybe[Str]');

=item address_line

Partial match on any address line

=cut

has address_line => (is => 'ro', isa => 'Maybe[Str]');

=item city

Partial match on city name

=cut

has city => (is => 'ro', isa => 'Maybe[Str]');

=item state

Partial match on name of state or probince 

=cut

has state => (is => 'ro', isa => 'Maybe[Str]');

=item zip

Partial match on zip/mail_code

=cut

has zip => (is => 'ro', isa => 'Maybe[Str]');

=item salesperson

Partial match on salesperson name

=cut

has salesperson => (is => 'ro', isa => 'Maybe[Str]');

=item notes

Full text search on notes

=cut

has notes => (is => 'ro', isa => 'Maybe[Str]');

=item country_id

country id of customer

=cut

has country_id => (is => 'ro', isa => 'Maybe[Int]');

=item from_date

Include only invoices starting on this date

=cut

has from_date => (is => 'ro', isa => 'Maybe[LedgerSMB::PGDate]');

=item to_date

Include only invoices before this date

=cut

has to_date => (is => 'ro', isa => 'Maybe[LedgerSMB::PGDate]');

=item type

This is the type of document to be returned:

=over

=item i

Invoices

=item o

Orders

=item q

Quotations

=back

=cut

has type => (is => 'ro', isa =>'Str');

=item start_from

Include only customers active starting this date.

=cut

has start_from => (is => 'ro', isa => 'Maybe[LedgerSMB::PGDate]');

=item start_to

Include only customers becoming active no later than this date

=cut

has start_to => (is => 'ro', isa => 'Maybe[LedgerSMB::PGDate]');

=item inc_open

Include open invoices/orders/etc.

=cut

has inc_open => (is => 'ro', isa => 'Bool');

=item inc_closed

Include closed invoices/orders/etc.

=cut

has inc_closed => (is => 'ro', isa => 'Bool');


=item is_summary

If this is true it is a summary report.  Otherwise full details shown.

=cut

has is_summary => (is => 'ro', isa => 'Bool');

=back

=head1 METHODS

=over 

=item prepare_criteria

Converts inputs to PgDate where needed

=cut

sub prepare_criteria {
    my ($self, $request) = @_;
    $request->{start_from} = LedgerSMB::PGDate->from_input(
               $request->{start_from}
    );
    $request->{start_to} = LedgerSMB::PGDate->from_input(
               $request->{start_to}
    );
    $request->{from_date} = LedgerSMB::PGDate->from_input(
               $request->{from_date}
    );
    $request->{to_date} = LedgerSMB::PGDate->from_input(
               $request->{to_date}
    );
}

=item run_report

Runs the report, populates rows.

=cut

sub run_report {
    my ($self) = @_;
    my $proc = 'company__history';
    $proc .= '_summary' if $self->is_summary; 
    my @rows = $self->exec_method({funcname => $proc});
    for my $r(@rows){
        $r->{invnumber_href_suffix} = $r->{invoice_id};
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
return 1;
