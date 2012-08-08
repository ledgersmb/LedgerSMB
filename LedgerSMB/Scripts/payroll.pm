=head1 NAME

LedgerSMB::Scripts::payroll - Payroll workflows for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::payroll::new_income_type($request);

=cut

package LedgerSMB::Scripts::payroll;
use LedgerSMB::Payroll::Income_Type;
use LedgerSMB::Template;

=head1 DESCRIPTION

This module handles the workflow routines for payroll management.  These are 
divided into three areas, namely income types, deduction types, and full payroll
workflows.

=head1 ROUTINES

=head2 Income Types

=over

=item new_income_type

Displays the form for entering a new income type.  Update returns to this form
with different inputs.

=cut

sub new_income_type {
    my ($request) = @_;
    @{$request->{countries}} = $request->call_procedure(
       procname => 'location_list_country'
    );
    @{$request->{pics}} = $request->call_procedure(
       procname => 'payroll_pic__list', args => [$request->{country_id}]
    ) if $request->{country_id};

    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/payroll',
        template => 'income_type',
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
    new_income_type($request);
}

=item show_income_type

Gets an income type and shows it

=cut

sub show_income_type {
    my ($request) = @_;
    my $itype = LedgerSMB::Payroll::Income_Type->get($request->{id});
    new_income_type($itype);
}


=item search_income_type

=item income_type_results

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
