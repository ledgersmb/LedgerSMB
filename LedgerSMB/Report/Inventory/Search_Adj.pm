=head1 NAME

LedgerSMB::Report::Inventory::Search_Adj - LedgerSMB report of
inventory adjustments

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::Inventory::Search_Adj->new(%$request);
 $rpt->run_report;
 $rpt->render($request);

=cut

package LedgerSMB::Report::Inventory::Search_Adj;
use Moose;
use LedgerSMB::MooseTypes;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

This is the report that searches for and displays inventory adjustments based
on set criteria.

=head1 CRITERIA PROPERTIES

=over

=item from_date

Standard start date

=item to_date

Standard to date

=cut

has 'from_date' => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');
has 'to_date' => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item partnumber

Part number.  This is a full text search, in order to allow for space-separated
alternatives

=cut

has partnumber => (is => 'ro', isa => 'Maybe[Str]');

=item source

Matches the beginning of the source string on the report source string

=cut

has source => (is => 'ro', isa => 'Maybe[Str]');

=back

=head1 REPORT-RELATED CONSTANT FUNCTIONS

=over

=item name

=cut

sub name { return LedgerSMB::Report::text('Inventory Adjustments') };

=item header_lines

=cut

sub header_lines {
    return [{name => 'from_date',
             text => LedgerSMB::Report::text('Start Date') },
            {name => 'to_date',
             text => LedgerSMB::Report::text('End Date') },
            {name => 'partnumber',
             text => LedgerSMB::Report::text('Including partnumber') },
            {name => 'source',
             text => LedgerSMB::Report::text('Source starting with') },
           ];
}

=item columns

=cut

sub columns {
    return [{col_id => 'transdate',
               type => 'href',
          href_base => 'inv_reports.pl?action=adj_detail&id=',
               name => LedgerSMB::Report::text('Date')},
            {col_id => 'source',
               type => 'href',
          href_base => 'inv_reports.pl?action=adj_detail&id=',
               name => LedgerSMB::Report::text('Reference')},
            {col_id => 'ar_invnumber',
               type => 'href',
               name => LedgerSMB::Report::text('AR Invoice'),
          href_base => 'is.pl?action=edit&id='},
            {col_id => 'ap_invnumber',
               type => 'href',
               name => LedgerSMB::Report::text('AP Invoice'),
          href_base => 'ir.pl?action=edit&id='},
      ];
}

=back

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'inventory_adj__search');
    for my $row (@rows) {
        $row->{ar_invnumber_suffix} = $row->{ar_invoice_id};
        $row->{ap_invnumber_suffix} = $row->{ap_invoice_id};
        $row->{row_id} = $row->{id};
    }
    $self->rows(\@rows);
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Report;

=item LedgerSMB::Report::Inventory::Adj_Details;

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
1;
