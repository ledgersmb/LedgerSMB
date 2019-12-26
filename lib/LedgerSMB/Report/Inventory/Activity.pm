
package LedgerSMB::Report::Inventory::Activity;

=head1 NAME

LedgerSMB::Report::Inventory::Activity - Inventory Activity reports

=head1 DESCRIPTION

Implements a listing of parts, reporting numbers in 4 categories of activity:

=over

=item Sold

=item Used

=item Assembled

=item Adjusted

=back

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Inventory::Activity->new(%$request);
 $report->render($request);

=cut

use Moose;
use namespace::autoclean;
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
        name => $self->Text('Partnumber'), },

     {col_id => 'description',
        type => 'text',
        name => $self->Text('Description'), },

     {col_id => 'sold',
        type => 'href',
        name => $self->Text('Sold'),
   href_base => "invoice.pl?&from_date=$from_date&to_date=$to_date"
                . '&open=1&closed=1&action=invoice_search&'
                . 'col_invnumber=1&col_transdate=1&col_entity_name=1&'
                . 'col_netamount=1&entity_class=2&partnumber=',
     },

     {col_id => 'revenue',
        type => 'text',
       money => 1,
        name => $self->Text('Revenue'), },

     {col_id => 'purchased',
        type => 'href',
        name => $self->Text('Purchased'),
   href_base => "invoice.pl?&date_from=$self->date_from&date_to=$self->date_to"
                . '&open=1&closed=1&action=invoice_search&'
                . 'col_invnumber=1&col_transdate=1&col_entity_name=1&'
                . 'col_netamount=1&entity_class=1&partnumber=',
     },

     {col_id => 'cost',
        type => 'text',
       money => 1,
        name => $self->Text('Cost'), },

     {col_id => 'used',
        type => 'text',
       money => 1,
        name => $self->Text('Used'), },

     {col_id => 'assembled',
        type => 'text',
       money => 1,
      name => $self->Text('Assembled'), },

     {col_id => 'adjusted',
        type => 'text',
       money => 1,
      name => $self->Text('Adjusted'), }
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
    my ($self) = @_;
    return [
      { name => 'partnumber',  text => $self->Text('Partnumber') },
      { name => 'description', text => $self->Text('Description') },
      { name => 'date_from',   text => $self->Text('From Date') },
      { name => 'date_to',     text => $self->Text('To Date') },
    ];
}


=head2 name

Inventory Activity Report

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Inventory Activity Report');
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
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
