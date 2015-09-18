=head1 NAME

LedgerSMB::Scripts::payroll - Payroll workflows for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::payroll::new_income_type($request);

=cut

package LedgerSMB::Scripts::payroll;

use strict;
use warnings;

use LedgerSMB::Payroll::Income_Type;
use LedgerSMB::Template;

=head1 DESCRIPTION

This module handles the workflow routines for payroll management.  These are
divided into three areas, namely income types, deduction types, and full payroll
workflows.

=head1 ROUTINES

=head2 Income Types

=over

=item show_income_type

Displays the form for entering a new income type.  Update returns to this form
with different inputs.

=cut

sub show_income_type {
    my ($request) = @_;
    @{$request->{countries}} = $request->call_procedure(
       funcname => 'location_list_country'
    );
    @{$request->{pics}} = $request->call_procedure(
       funcname => 'payroll_pic__list', args => [$request->{country_id}]
    ) if $request->{country_id};

    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payroll',
        template => 'income',
        format   => 'HTML'
    );
    $template->render($request);
}

=item save_income_type

Saves the resulting income type.

=cut

sub save_income_type {
    my ($request) = @_;
    my $itype = LedgerSMB::Payroll::Income_Type->new(%$request);
    $itype->save;
    show_income_type($request);
}

=item get_income_type

Gets an income type and shows it

=cut

sub get_income_type {
    my ($request) = @_;
    my $itype = LedgerSMB::Payroll::Income_Type->get($request->{id});
    show_income_type($itype);
}


=item search_income_type

Displays the income type search screen

=cut

sub search_income_type {
    my ($request) = @_;
    @{$request->{countries}} = $request->call_procedure(
       funcname => 'location_list_country'
    );

    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payroll',
        template => 'income_search',
        format   => 'HTML'
    )->render($request);
}

=item income_type_results

Displays income type search results

=cut

sub income_type_results {
    my ($request) = @_;
    use LedgerSMB::Report::Payroll::Income_Types;
    LedgerSMB::Report::Payroll::Income_Types->new(%$request)->render($request);
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

=head1 COPYRIGHT

=cut

1;
