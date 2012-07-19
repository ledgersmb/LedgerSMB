=head1 NAME

LedgerSMB::Report::Inventory::Adj_Details - Inventory Adjustment
Details report for LedgerSMB

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
 $rpt->run_report;
 $rpt->render($request);

=cut

package LedgerSMB::Report::Inventory::Adj_Details;
use Moose;
use LedgerSMB::App_State;
use LedgerSMB::Report::Inventory::Search_Adj;
extends 'LedgerSMB::Report';

my $locale = $LedgerSMB::App_State::Locale;

=head1 DESCRIPTION

This report shows the details of an inventory adjustment report.

=head1 CRITERIA PROPERTIES

=over

=item id

This is the report id.

=cut

has id => (is => 'ro', isa => 'Int', required => 1);

=back

=head1 PROPERTIES FOR HEADER

=over

=item source 

Matches the beginning of the source string on the report source string

=cut

has source => (is => 'ro', isa => 'Maybe[Str]');

=back

=head1 REPORT CONSTANT FUNCTIONS

=over

=item name

=cut

sub name { return $locale->text('Inventory Adjustment Details') }

=item header_lines

=cut

sub header_lines {
    return [{name => 'source', text => $locale->text('Source') }];
}

=item columns

=cut

sub columns {
    return [
      {col_id => 'partnumber',
         type => 'href',
    href_base => 'ic.pl?action=edit&id='.
         name => $locale->text('Part Number') },
      {col_id => 'description',
         type => 'text',
         name => $locale->text('Description') },
      {col_id => 'counted',
         type => 'text',
         name => $locale->text('Counted') },
      {col_id => 'expected',
         type => 'text',
         name => $locale->text('Expected') },
      {col_id => 'variance',
         type => 'text',
         name => $locale->text('Variance') },
    ];
}

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;
    my ($rpt) = $self->exec_method({funcname => 'inventory_adj__get'});
    $self->source($rpt->source);
    my @rows = $self->exec_method({funcname => 'inventory_adj__details'});
    for my $row (@rows){
        $row->{row_id} = $row->{parts_id}; 
    }
    $self->rows(\@rows);
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Report;

=item LedgerSMB::Report::Inventory::Search_Adj;

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
1;
