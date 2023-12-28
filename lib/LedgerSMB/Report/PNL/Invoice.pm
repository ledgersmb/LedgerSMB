
package LedgerSMB::Report::PNL::Invoice;

=head1 NAME

LedgerSMB::Report::PNL::Invoice - Provides an Income Statement-like report on
invoices

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Invoice->new(%$request);
 $report->render();

=head1 DESCRIPTION

This provides the income statement-like report for invoices on LedgerSMB on
1.4 and later.  This report is designed to give a business an ability to look
profit margins of specific invoices.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report::PNL';

=head1 CRITERIA PROPERTIES

=over

=item id

This is the id of the invoice

=cut

has id => (is => 'ro', isa =>'Int', required => 1);

=item invnumber

Invoice number

=cut

has invnumber => (is => 'rw', isa =>'Str');

=item transdate

Transaction Date

=cut

has transdate => (is => 'rw', isa =>'LedgerSMB::PGDate');

=item name

Customer/vendor name

=cut

has invnumber => (is => 'rw', isa =>'Str');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item name

=cut

sub name { my ($self) = @_; return $self->Text('Invoice Profit/Loss') }

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [{value => $self->invnumber,
            text => $self->Text('Invoice Number') },
            {value => $self->transdate,
            text => $self->Text('Transaction Date') },
    ];
}

=back

=head1 METHODS

=over

=item $self->report_base($from_date, $to_date)

Implement query protocol from parent class.

=cut

sub report_base {
    my ($self) = @_;
    return $self->call_dbmethod(funcname => 'pnl__invoice');
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
