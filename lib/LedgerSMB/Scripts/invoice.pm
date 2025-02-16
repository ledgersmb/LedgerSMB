
package LedgerSMB::Scripts::invoice;

=head1 NAME

LedgerSMB::Scripts::invoice - Invoice Report Routines for LedgerSMB

=head1 DESCRIPTION

This module contains the invoice search routines.  In future versions this
module will probably also include various invoice creation routines.

=head1 SYNPOSIS

 LedgerSMB::Scripts::invoice:invoices_outstanding($request)

or

 LedgerSMB::Scripts::invoice:invoice_search($request)

=cut

use strict;
use warnings;

use LedgerSMB::Report::Invoices::Transactions;
use LedgerSMB::Report::Invoices::Outstanding;
use LedgerSMB::Scripts::reports;

=head1 METHODS

This module doesn't specify any methods.

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
    return LedgerSMB::Scripts::reports::start_report($request);
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
    return $request->render_report(
        LedgerSMB::Report::Invoices::Outstanding->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
        ));
}

=item invoice_search

This produces the transactions search report.  See
LedgerSMB::Report::Invoices::Transactions for expected properties.

=cut

sub invoice_search {

    my ($request) = @_;
    $request->{is_approved} //= 'Y'; # backwards-compatibility to 1.4

    # the line below is needed because we are using trinary boolean logic
    # which does not work well with Moose
    delete $request->{on_hold} if $request->{on_hold} eq 'on';

    return $request->render_report(
        LedgerSMB::Report::Invoices::Transactions->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
            interval => $request->{interval},
            from_month => $request->{from_month},
            from_year => $request->{from_year},
        )
    );
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
