=head1 NAME

LedgerSMB::Report::Inventory::Activity - Inventory Activity reports for
LedgerSMB

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Inventory::Activity->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Inventory::Activity;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

Standard dates plus:

=over

=item partnumber

Prefix search on partnumber

=cut

has partnumber => (is => 'ro', isa => 'Str', required => 0);

=item description

Full text search on description

=cut

has description  => (is => 'ro', isa => 'Str', required => 0);

=back

=head1 INTERNALS

=head2 columns

=over

=item partnumber

=item description

=item sold

=item receivable

=item purchased

=item payable

=back

=cut

sub columns {
    my $self = shift;
    my $from_date = $self->from_date;
    $from_date = $from_date->to_db if $from_date;
    $from_date ||= '';
    my $to_date = $self->to_date;
    $to_date = $to_date->to_db if $to_date;
    $to_date ||= '';
    return [
     {col_id => 'partnumber',
        type => 'text',
        name => LedgerSMB::Report::text('Partnumber'), },

     {col_id => 'description',
        type => 'text',
        name => LedgerSMB::Report::text('Description'), },

     {col_id => 'sold',
        type => 'href',
        name => LedgerSMB::Report::text('Sold'),
   href_base => "invoice.pl?&from_date=$from_date&to_date=$to_date"
                . "&open=1&closed=1&action=invoice_search&"
                . 'col_invnumber=1&col_transdate=1&col_entity_name=1&'
                . 'col_netamount=1&entity_class=2&partnumber=',
     },

     {col_id => 'receivable',
        type => 'text',
       money => 1,
        name => LedgerSMB::Report::text('Receivable'), },

     {col_id => 'purchased',
        type => 'href',
        name => LedgerSMB::Report::text('Purchased'),
   href_base => "invoice.pl?&date_from=$self->date_from&date_to=$self->date_to"
                . "&open=1&closed=1&action=invoice_search&"
                . 'col_invnumber=1&col_transdate=1&col_entity_name=1&'
                . 'col_netamount=1&entity_class=1&partnumber=',
     },

     {col_id => 'payable',
        type => 'text',
       money => 1,
        name => LedgerSMB::Report::text('Payable'), }
    ];
}

=head2 header_lines

=over

=item partnumber

=item description

=item date_from

=item date_to

=back

=cut

sub header_lines {
    return [
      { name => 'partnumber',  text => LedgerSMB::Report::text('Partnumber') },
      { name => 'description', text => LedgerSMB::Report::text('Description') },
      { name => 'date_from',   text => LedgerSMB::Report::text('From Date') },
      { name => 'date_to',     text => LedgerSMB::Report::text('To Date') },
    ];
}


=head2 name

Inventory Activity Report

=cut

sub name {
    return LedgerSMB::Report::text('Inventory Activity Report');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'inventory__activity');
    for my $r (@rows) {
       $r->{row_id} = $r->{partnumber};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
