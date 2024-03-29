
package LedgerSMB::Report::PNL::ECA;

=head1 NAME

LedgerSMB::Report::PNL::ECA - Income Statement-like Reports for Customers

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::ECA->new(%$request);
 $report->render();

=head1 DESCRIPTION

This provides the income statement-like report for customers on LedgerSMB 1.4
and higher.  The format is identical to that of an income statement and allows
businesses to address the profitability of specific customer accounts.

This can also be run against vendors, but it will only show purchases of
services and other non-inventory purchases.  Inventory purchases will not show
up since they are treated as an expense only on sale.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report::PNL';

=head1 CRITERIA PROPERTIES

Standard dates plus

=over

=item id

This is the id of the customer account.

=cut

has id => (is => 'rw', isa =>'Int');

=item legal_name

Name of the customer

=cut

has 'legal_name' => (is => 'rw', isa =>'Str');

=item meta_number

Account number of customer

=cut

has 'meta_number' => (is => 'rw', isa =>'Str');

=item control_code

Control code of customer's entity

=cut

has 'control_code' => (is => 'rw', isa =>'Str');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item name

=cut

sub name { my ($self) = @_; return $self->Text('ECA Income Statement') }

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [{value => $self->legal_name,
            text => $self->Text('Name') },
            {value => $self->meta_number,
            text => $self->Text('Account Number')},
            {value => $self->control_code,
            text => $self->Text('Control Code')}
          ];
}

=back

=head1 METHODS

=over

=item $self->report_base($from_date, $to_date)

Implement query protocol from parent class.

=cut


sub report_base {
    my ($self, $from_date, $to_date) = @_;
    return $self->call_dbmethod(funcname => 'pnl__customer');
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=item LedgerSMB::Report::PNL

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
