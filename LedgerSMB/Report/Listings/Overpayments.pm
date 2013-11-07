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

=item amount_from

=item amount_to

=item control_code

=item meta_number

=back

=cut

has amount_from => (is => 'ro', isa => 'LedgerSMB::Moose::Number', coerce=> 1,
              required => 0);

has amount_to => (is => 'ro', isa => 'LedgerSMB::Moose::Number', coerce=> 1,
            required => 0);

has control_code => (is => 'ro', isa => 'Str', required => 0);

has meta_number => (is => 'ro', isa => 'Str', required => 0);

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

=back

=cut

sub columns {
    return [{
        col_id => 'select',
          name => '',
          type => 'select',
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

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self, $request) = @_;
    if (ref $request){
       $self->buttons([
          { name => 'action',
            text => LedgerSMB::Report::text('Reverse'),
           value => 'reverse',
            type => 'submit',
           class => 'submit'
          },
       ]) if $request->is_allowed_role('overpayments_reverse');
    }
    my @rows = $self->exec_method({funcname => 'payment__overpayments_list'});
    for my $r (@rows){
       $r->{row_id} = $r->{payment_id};
    }
    $self->rows(@rows);
}

=head1 COPYRIGHT

COPYRIGHT(C) 2013 The LedgerSMB Core Team.  This file may be reused under the terms
of the GNU General Public License, versin 2 or at your option any later version.
Please see the included LICENSE.txt for more details.

=cut

__PACKAGE__->meta->make_immutable;
