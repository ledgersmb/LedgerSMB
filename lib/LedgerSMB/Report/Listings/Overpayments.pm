
package LedgerSMB::Report::Listings::Overpayments;

=head1 NAME

LedgerSMB::Report::Listings::Overpayments - Overpayments Search Results for
LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Report::Listings::Overpayments->new(%$request)->render($request);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

This report provides a general listing of overpayments for reversal or
reporting.


=head1 CRITERIA PROPERTIES

In addition to standard dates, we also have:

=over

=item name_part

=item control_code

=item meta_number

=back

=cut

has name_part => (is => 'ro', isa => 'Str', required => 0);

has control_code => (is => 'ro', isa => 'Str', required => 0);

has meta_number => (is => 'ro', isa => 'Str', required => 0);

=head1 PASSTHROUGH PROPERTIES

These properties are there specifically to pass through to the form for
submission.

=over

=item batch_id

=item post_date

=item batch_number

=cut

has batch_id => (is => 'ro', isa => 'Int', required => 0);
has post_date => (is => 'ro', isa => 'LedgerSMB::Moose::Date',
                required => 0, coerce => 1);

has batch_number => (is => 'ro', isa => 'Str', required => 0);

=back

=head1 REPORT CONSTANTS

=head2 name

localized string 'Overpayments'

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Overpayments');
}

=head2 header_lines

=over

=item meta_number

=item date_from

=item date_to

=item amount_from

=item amount_to

=back

=cut

sub header_lines {
    my ($self) = @_;
    return [
      {name => 'meta_number', text => $self->Text('Counterparty Code')}.
      {name => 'date_from',   text => $self->Text('Date From')},
      {name => 'date_to',     text => $self->Text('Date To')},
      {name => 'amount_from', text => $self->Text('Amount From')},
      {name => 'amount_to',   text =>  $self->Text('Amount To')},
    ];
}

=head2 columns

=over

=item select

=item entity_name

=item transdate

=item amount

=item available

=cut

sub columns {
    my ($self) = @_;
    return [{
        col_id => 'select',
          name => '',
          type => 'checkbox',
    },
    {   col_id => 'entity_name',
          name => $self->Text('Counterparty'),
          type => 'text',
    },
    {   col_id => 'transdate',
          name => $self->Text('Date'),
          type => 'text',
    },
    {   col_id => 'amount',
          name => $self->Text('Paid'),
          type => 'text',
    },
    {   col_id => 'available',
          name => $self->Text('Available'),
          type => 'text',
    }];
}

=item set_buttons

If there is a batch_id, returns the the set of buttons.  Otherwise not.

=cut

sub set_buttons {
   my $self = shift;
   return [
          { name => 'action',
            text => $self->Text('Reverse'),
           value => 'reverse_overpayment',
            type => 'submit',
           class => 'submit'
          },
   ] if $self->batch_id;
   return [];
}

=back

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'payment__overpayments_list');
    for my $r (@rows){
       $r->{row_id} = $r->{payment_id};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
