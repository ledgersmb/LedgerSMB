=head1 NAME

LedgerSMB::Report::Contact::History - Purchase history reports
and more.

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Contact::History->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This report provides purchase history reports.  It can be used to search for
both customers and vendors.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::Contact::History;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

use LedgerSMB::PGDate;
use LedgerSMB::MooseTypes;

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
    my $cols = [
         {col_id => 'name',
            type => 'text',
            name => LedgerSMB::Report::text('Name') },

         {col_id => 'meta_number',
            type => 'text',
            name => LedgerSMB::Report::text('Account Number') }];

    if (!$self->is_summary){

      push @$cols,
         {col_id => 'invnumber',
            type => 'href',
       #href_base => 'is.pl?action=edit&id=',
            name => LedgerSMB::Report::text('Invoice Number') },

         {col_id => 'curr',
            type => 'text',
            name => LedgerSMB::Report::text('Currency') };
    }

      push @$cols,

         {col_id => 'partnumber',
            type => 'text',
            name => LedgerSMB::Report::text('Part Number') },

         {col_id => 'description',
            type => 'text',
            name => LedgerSMB::Report::text('Description') },

         {col_id => 'qty',
            type => 'text',
            name => LedgerSMB::Report::text('Qty') },

         {col_id => 'unit',
            type => 'text',
            name => LedgerSMB::Report::text('Unit') };

   push @$cols,
         {col_id => 'sellprice',
            type => 'text',
           money => 1,
            name => LedgerSMB::Report::text('Sell Price') };

   push @$cols,
         {col_id => 'discount',
            type => 'text',
            name => LedgerSMB::Report::text('Disc') },

         {col_id => 'delivery_date',
            type => 'text',
            name => LedgerSMB::Report::text('Delivery Date') },

         {col_id => 'serialnumber',
            type => 'text',
            name => LedgerSMB::Report::text('Serial Number') }
          unless $self->is_summary;

    push @$cols,
         {col_id => 'exchangerate',
            type => 'text',
            name => LedgerSMB::Report::text('Exchange Rate') },

         {col_id => 'salesperson_name',
            type => 'text',
            name => LedgerSMB::Report::text('Salesperson') };

    return $cols;
}

=item name

=cut

sub name { return LedgerSMB::Report::text('Purchase History') }

=item header_lines

=cut

sub header_lines {
     return [
            {name => 'name',
             text => LedgerSMB::Report::text('Name')},

            {name => 'meta_number',
             text => LedgerSMB::Report::text('Account Number')},
            {name => 'from_date',
             text => LedgerSMB::Report::text('Start Date')},

            {name => 'to_date',
             text => LedgerSMB::Report::text('End Date')},


      ];
}

=back

=head1 CRITERIA PROPERTIES

=over

=item account_class

The account/entity class of the contact.  Required and an exact match.

=cut

has entity_class => (is => 'ro', isa => 'Int');

=item name_part

This is the name of the customer or vendor.  It is an exact match.

=cut

has name_part => (is => 'ro', isa => 'Maybe[Str]');

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

has start_from => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item start_to

Include only customers becoming active no later than this date

=cut

has start_to => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');

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

=item run_report

Runs the report, populates rows.

=cut

sub run_report {
    my ($self) = @_;
    my $proc = 'eca__history';
    $proc .= '_summary' if $self->is_summary;
    my @rows = $self->call_dbmethod(funcname => $proc);
    for my $r(@rows){
     my $script;
     if($self->entity_class == 1){
      $script = 'ir.pl';
     }
     else{
      $script = 'is.pl';
     }
     #$r->{invnumber_href_suffix} = $r->{invoice_id};
     $r->{invnumber_href_suffix} = "$script?action=edit&id=$r->{inv_id}";
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
