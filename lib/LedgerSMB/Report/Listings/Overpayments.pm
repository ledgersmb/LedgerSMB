=head1 NAME

LedgerSMB::Report::Listings::Overpayments - Overpayments Search Results for
LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Report::Listings::Overpayments->new(%$request)->render($request);

=cut

package LedgerSMB::Report::Listings::Overpayments;
use Moose;
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
    return LedgerSMB::Report::text('Overpayments');
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
    return [
      {name => 'meta_number', text => LedgerSMB::Report::text('Counterparty Code')}.
      {name => 'date_from',   text => LedgerSMB::Report::text('Date From')},
      {name => 'date_to',     text => LedgerSMB::Report::text('Date To')},
      {name => 'amount_from', text => LedgerSMB::Report::text('Amount From')},
      {name => 'amount_to',   text =>  LedgerSMB::Report::text('Amount To')},
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
    return [{
        col_id => 'select',
          name => '',
          type => 'checkbox',
    },
    {   col_id => 'entity_name',
          name => LedgerSMB::Report::text('Counterparty'),
          type => 'text',
    },
    {   col_id => 'transdate',
          name => LedgerSMB::Report::text('Date'),
          type => 'text',
    },
    {   col_id => 'amount',
          name => LedgerSMB::Report::text('Paid'),
          type => 'text',
    },
    {   col_id => 'available',
          name => LedgerSMB::Report::text('Available'),
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
            text => LedgerSMB::Report::text('Reverse'),
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
    my ($self, $request) = @_;
    my @rows = $self->call_dbmethod(funcname => 'payment__overpayments_list');
    for my $r (@rows){
       $r->{row_id} = $r->{payment_id};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT(C) 2013 The LedgerSMB Core Team.  This file may be reused under the terms
of the GNU General Public License, versin 2 or at your option any later version.
Please see the included LICENSE.txt for more details.

=cut

__PACKAGE__->meta->make_immutable;

1;
