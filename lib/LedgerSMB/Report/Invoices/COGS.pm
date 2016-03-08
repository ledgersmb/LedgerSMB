=head1 NAME

LedgerSMB::Report::Invoices::COGS - FIFO COGS Reports for LedgerSMB

=head1 SYNOPSIS

   LedgerSMB::Report::Invoices::COGS->new(%$request)->render($request);

=cut

package LedgerSMB::Report::Invoices::COGS;
use namespace::autoclean;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

LedgerSMB inventory is calculated (assuming no customizations here) using the
FIFO or First In, First Out method.  The first inventory in the system which
is unallocated is the first inventory used for costs.

This report provides useful support for verifying and controlling for the
FIFO COGS and inventoy numbers.

=head1 REPORT CRITERIA

=head2 date_from

Start date of the report (inclusive). Includes all dates if undefined.

=head2 date_to

End date of the report (inclusive). Includes all dates if undefined.

=head2 partnumber

Prefix search on part number.

=head2 description

Description of the part includes this string, or properly finds it with full
text search.

=cut

has partnumber => (is => 'ro', isa => 'Str', required => 0);
has description => (is => 'ro', isa => 'Str', required => 0);

=head1 REPORT CONSTANTS

=head2 columns

This report supports the following columns:

=over

=item invnumber - Invoice Number

=item transdate - Purchase Invoice Date

=item partnumber - Part Number

=item description - Invoice line item description

=item qty - Quantity purchased

=item allocated - Quantity allocated for purcases

=item onhand - Number of parts on hand currently of this type

=item sellprice - Per item sell price

=item total_value - Total inventory value purchased

=item cogs_sold - Total value of items allocated for COGS

=back

=cut

sub columns {
    return [
      { col_id => 'invnumber',
          type => 'href',
        pwidth => 1,
          name => LedgerSMB::Report::text('Invoice Number'),
     href_base => 'ir.pl?action=edit&id=', },

      { col_id => 'transdate',
          type => 'text',
        pwidth => 1,
          name => LedgerSMB::Report::text('Invoice Date'), },

      { col_id => 'partnumber',
          type => 'href',
        pwidth => 1,
          name => LedgerSMB::Report::text('Part Number'),
     href_base => 'ic.pl?action=edit&id=', },

      { col_id => 'description',
          type => 'text',
        pwidth => 3,
          name => LedgerSMB::Report::text('Part'), },

      { col_id => 'onhand',
          type => 'text',
        pwidth => 1,
          name => LedgerSMB::Report::text('On Hand'), },

      { col_id => 'qty',
          type => 'text',
        pwidth => 1,
          name => LedgerSMB::Report::text('Quantity'), },

      { col_id => 'total_value',
          type => 'text',
        pwidth => 1,
          name => LedgerSMB::Report::text('Total'), },

      { col_id => 'allocated',
          type => 'text',
        pwidth => 1,
          name => LedgerSMB::Report::text('Allocated'), },

      { col_id => 'cogs_sold',
          type => 'text',
        pwidth => 1,
          name => LedgerSMB::Report::text('COGS'), },

    ];
}


=head2 header_lines

=over

=item date_from - Start Date

=item date_to - End Date

=item partnumber - Part Number

=item description - Part Description

=back

=cut

sub header_lines {
    return [
       { name => 'from_date',
         text => LedgerSMB::Report::text('Start Date'), },
       { name => 'to_date',
         text => LedgerSMB::Report::text('End Date'), },
       { name => 'partnumber',
         text => LedgerSMB::Report::text('Part Number'), },
       { name => 'description',
         text => LedgerSMB::Report::text('Part Description'), },
    ];
}

=head2 name

Line Item COGS Report

=cut

sub name { LedgerSMB::Report::text('Line Item COGS Report'); }

=head1 METHODS

=head2 run_report

Populates and returns $report->rows.

=cut

sub run_report {
    my $self = shift;
    my @rows = $self->call_dbmethod(funcname => 'report__incoming_cogs_line');
    for my $row (@rows){
        $row->{partnumber_href_suffix} = $row->{parts_id};
        $row->{invnumber_href_suffix} = $row->{trans_id};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file may be reused under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.TXT for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;
