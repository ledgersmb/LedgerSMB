
package LedgerSMB::Report::Inventory::Adj_Details;

=head1 NAME

LedgerSMB::Report::Inventory::Adj_Details - Inventory Adjustment
Details report for LedgerSMB

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
 $rpt->run_report;
 $rpt->render($request);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

use LedgerSMB::Inventory::Adjust;
use LedgerSMB::Report::Inventory::Search_Adj;

=head1 DESCRIPTION

This report shows the details of an inventory adjustment report.

THIS IS NOT SAFE TO CACHE UNTIL THE FINANCIAL LOGIC IS IN THE NEW FRAMEWORK.

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

has source => (is => 'rw', isa => 'Maybe[Str]');

=back

=head1 REPORT CONSTANT FUNCTIONS

=over

=item name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Inventory Adjustment Details');
}

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'source', text => $self->Text('Source') }];
}

=item columns

=cut

sub columns {
    my ($self) = @_;
    return [
      {col_id => 'partnumber',
         type => 'href',
    href_base => 'ic.pl?action=edit&id=',
         name => $self->Text('Part Number') },
      {col_id => 'description',
         type => 'text',
         name => $self->Text('Description') },
      {col_id => 'counted',
         type => 'text',
         name => $self->Text('Counted') },
      {col_id => 'expected',
         type => 'text',
         name => $self->Text('Expected') },
      {col_id => 'variance',
         type => 'text',
         name => $self->Text('Variance') },
    ];
}

=back

=head2 set_buttons

This sets buttons relevant to approving the adjustments.

=cut

sub set_buttons {
    my ($self) = @_;
    return [{
       name => 'action',
       type => 'submit',
      value => 'approve',
       text => $self->Text('Approve'),
      class => 'submit',
    },{
       name => 'action',
       type => 'submit',
      value => 'delete',
       text => $self->Text('Delete'),
      class => 'submit',
    }];
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my ($rpt) = $self->call_dbmethod(funcname => 'inventory_adjust__get');
    $self->source($rpt->{source});
    my @rows = $self->call_dbmethod(funcname => 'inventory_adjust__get_lines');
    for my $row (@rows){
        $row->{row_id} = $row->{parts_id};
    }
    return $self->rows(\@rows);
}

=head2 approve

Approves the report.  This currently goes through the legacy code and is the
point where caching becomes unsafe.

=cut

sub approve {
    my ($self) = @_;

    my $adjust = LedgerSMB::Inventory::Adjust->get( key => { id => $self->id } );
    return $adjust->approve;
}

=head2 delete

Deletes the inventory report

=cut

sub delete {
    my ($self) = @_;

    my $adjust = LedgerSMB::Inventory::Adjust->get( key => { id => $self->id } );
    return $adjust->delete;
}

=head1 SEE ALSO

=over

=item LedgerSMB::Report;

=item LedgerSMB::Report::Inventory::Search_Adj;

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
