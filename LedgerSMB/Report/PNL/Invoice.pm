=head1 NAME

LedgerSMB::Report::PNL::Invoice - Provides an Income Statement-like report on
invoices

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Invoice->new(%$request);
 $rpt->render($request);

=head1 DESCRIPTION

This provides the income statement-like report for invoices on LedgerSMB on
1.4 and later.  This report is designed to give a business an ability to look
profit margins of specific invoices.

=cut

package LedgerSMB::Report::PNL::Invoice;
use Moose;
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

has transdate => (is => 'rw', isa =>'LedgerSMB::Moose::Date', coerce=> 1);

=item name

Customer/vendor name

=cut

has invnumber => (is => 'rw', isa =>'Str');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

=cut

sub template { return 'Reports/PNL' }

=item name

=cut

sub name { my ($self) = @_; return $self->Text('Invoice Profit/Loss') }

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'name',
            text => $self->Text('Name') },
            {name => 'invnumber',
            text => $self->Text('Invoice Number') },
            {name => 'transdate',
            text => $self->Text('Transaction Date') },
    ];
}

=back

=head1 METHODS

=cut

# private method
# report_base($from, $to)
# returns an array of hashrefs of report results.  Used in adding comparison
# as well as the main report

sub report_base {
    my ($self) = @_;
    return $self->call_dbmethod(funcname => 'pnl__invoice');
}

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=item LedgerSMB::Report::PNL

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
