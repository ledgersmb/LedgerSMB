=head1 NAME

LedgerSMB::Scripts::invoice - Invoice Report Routines for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::invoice:invoices_outstanding($request)

or

 LedgerSMB::Scripts::invoice:invoice_search($request)

=cut

package LedgerSMB::Scripts::invoice;

use strict;
use warnings;

use LedgerSMB::Template;
use LedgerSMB::Report::Invoices::Transactions;
use LedgerSMB::Report::Invoices::Outstanding;
use LedgerSMB::Scripts::reports;

=head1 DESCRIPTION

This module contains the invoice search routines.  In future versions this
module will probably also include various invoice creation routines.

=head1 FUNCTIONS

=over

=item start_report

This is a specialized preprocessor for LedgerSMB::Scripts::Report::begin_report
which sets up various data structures for the report screens.

=cut

sub start_report {
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
        funcname => 'account__get_by_link_desc', args => [$link]);
    @{$request->{tax_accounts}} = $request->call_procedure(
        funcname => 'account__get_by_link_desc', args => ["${link}_tax"]);
    @{$request->{employees}} =  $request->call_procedure(
        funcname => 'employee__all_salespeople'
    );
    LedgerSMB::Scripts::reports::start_report($request);
}

=item invoices_outstanding

This produces the invoice outstanding report.  See
LedgerSMB::Report::Invoices::Outstanding for expected properties.

=cut

sub invoices_outstanding {
    my ($request) = @_;
    # the line below is needed because we are using trinary boolean logic
    # which does not work well with Moose
    delete $request->{on_hold} if $request->{on_hold} eq 'on';
    my $report = LedgerSMB::Report::Invoices::Outstanding->new(%$request);
    $report->render($request);
}

=item invoice_search

This produces the transactions earch report.  See
LedgerSMB::Report::Invoices::Transactions for expected properties.

=cut

sub  invoice_search{
    my ($request) = @_;
    # the line below is needed because we are using trinary boolean logic
    # which does not work well with Moose
    delete $request->{on_hold} if $request->{on_hold} eq 'on';
    my $report = LedgerSMB::Report::Invoices::Transactions->new(%$request);
    $report->render($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
