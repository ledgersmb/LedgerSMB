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

=over invnumber

Invoice number

=cut

has invnumber => (is => 'rw', isa =>'Str');

=cut

=over transdate

Transaction Date

=cut

has transdate => (is => 'rw', isa =>'LedgerSMB::Moose::Date', coerce=> 1);

=over name

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

sub name { return LedgerSMB::Report::text('Invoice Profit/Loss') }

=item header_lines

=cut

sub header_lines {
    return [{name => 'name',
            text => LedgerSMB::Report::text('Name') },
            {name => 'invnumber',
            text => LedgerSMB::Report::text('Invoice Number') },
            {name => 'transdate',
            text => LedgerSMB::Report::text('Transaction Date') },
    ];
}

=item columns

=cut

sub columns { return []  }

=back

=head1 METHODS

=cut

# private method
# report_base($from, $to)
# returns an array of hashrefs of report results.  Used in adding comparison
# as well as the main report

sub report_base {
    my ($self) = @_;
    return $self->exec_method({funcname => 'pnl__invoice'});
}

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=item LedgerSMB::Report::PNL

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
