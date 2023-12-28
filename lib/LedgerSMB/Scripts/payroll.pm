
package LedgerSMB::Scripts::payroll;

=head1 NAME

LedgerSMB::Scripts::payroll - Payroll workflows for LedgerSMB

=head1 DESCRIPTION

This module handles the workflow routines for payroll management.  These are
divided into three areas, namely income types, deduction types, and full payroll
workflows.

=head1 SYNPOSIS

 LedgerSMB::Scripts::payroll::new_income_type($request);

=cut

use strict;
use warnings;

use LedgerSMB::I18N;
use LedgerSMB::Payroll::Income_Type;
use LedgerSMB::Report::Payroll::Income_Types;

=head1 METHODS

This module doesn't specify any methods.

=head1 ROUTINES

=head2 Income Types

=over

=item show_income_type

Displays the form for entering a new income type.  Update returns to this form
with different inputs.

=cut

sub show_income_type {
    my ($request) = @_;
    my @country_list = $request->enabled_countries->@*;
    @{$request->{pics}} = $request->call_procedure(
       funcname => 'payroll_pic__list', args => [$request->{country_id}]
    ) if $request->{country_id};

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'payroll/income', $request);
}

=item save_income_type

Saves the resulting income type.

=cut

sub save_income_type {
    my ($request) = @_;
    my $itype = LedgerSMB::Payroll::Income_Type->new(%$request);
    $itype->save;
    return show_income_type($request);
}

=item get_income_type

Gets an income type and shows it

=cut

sub get_income_type {
    my ($request) = @_;
    my $itype = LedgerSMB::Payroll::Income_Type->get($request->{id});
    return show_income_type($itype);
}


=item search_income_type

Displays the income type search screen

=cut

sub search_income_type {
    my ($request) = @_;
    my @country_list = $request->enabled_countries->@*;

    return $request->{_wire}->get('ui')
        ->render($request, 'payroll/income_search', $request);
}

=item income_type_results

Displays income type search results

=cut

sub income_type_results {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Payroll::Income_Types->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=back

=head2 Deduction Types

=over

=item new_deduction_type

=item save_deduction_type

=item show_deduction_type

=item search_deduction_type

=item deduction_type_results

=back

=head2 Payroll Entry

=head2 Approval and Check Printing

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
