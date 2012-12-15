=head1 NAME

LedgerSMB::Scripts::invoice - Invoice Report Routines for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::invoice:invoices_outstanding($request)

or

 LedgerSMB::Scripts::invoice:invoice_search($request)

=cut

package LedgerSMB::Scripts::invoice;
use LedgerSMB::Template;
use LedgerSMB::Report::Invoices::Transactions;
use LedgerSMB::Report::Invoices::Outstanding;
use LedgerSMB::Scripts::reports;

=head1 DESCRIPTION

This module contains the invoice search routines.  In future versions this
module will probably also include various invoice creation routines.

=head1 FUNCTIONS

=over

=item begin_report

This is a specialized preprocessor for LedgerSMB::Scripts::Report::begin_report
which sets up various data structures for the report screens.

=cut

sub begin_report {
    my ($request) = @_;
    my $link;
    if ($request->{entity_class} == 1){
        $link = 'AP';
    } elsif ($request->{entity_class} == 2){
        $link = 'AR';
    } else {
        die 'Invalid Entity Class';
    }
    @{$request->{accounts}} = $request->call_procedure(
        procname => 'account__get_by_link_desc', args => [$link]);
    @{$request->{tax_accounts}} = $request->call_procedure(
        procname => 'account__get_by_link_desc', args => ["${link}_tax"]);
    LedgerSMB::Scripts::reports::begin_report($request);
}

=item invoices_outstanding

This produces the invoice outstanding report.  See
LedgerSMB::Report::Invoices::Outstanding for expected properties.

=cut

sub invoices_outstanding {
    my ($request) = @_;
    my $report = LedgerSMB::Reports::Invoices::Outstanding->new(%$request);
    $report->render($request);
}

=item search_transactions

This produces the transactions earch report.  See
LedgerSMB::Report::Invoices::Transactions for expected properties.

=cut

sub search_transactions {
    my ($request) = @_;
    my $report = LedgerSMB::Reports::Invoices::Transactions->new(%$request);
    $report->render($request);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
