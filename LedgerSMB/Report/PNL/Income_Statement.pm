=head1 NAME

LedgerSMB::Report::PNL::Income_Statement - Basic Income Statement for LedgerSMB

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(%$request);
 $rpt->render($request);

=head1 DESCRIPTION

This provides the income statement report for LedgerSMB on 1.4 and later.

=cut

package LedgerSMB::Report::PNL::Income_Statement;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

Standard dates plus

=over

=item basis

This is either 'cash' or 'accrual' 

=cut

has basis => (is => 'ro', isa =>'Str', required => 1);


has '_cols' => (is => 'rw', isa => 'ArrayRef[Any]', required => 0);

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

=cut

sub template { return 'PNL' }

=item name

=cut

sub name { return text('Income Statement') }

=item header_lines

=cut

sub header_lines {
    return [{name => 'basis',
            text => text('Reporting Basis') }];
}

=item columns

=cut

sub columns { return $_[0]->_cols  }

=back

=head1 METHODS

=cut

# private method
# report_base($from, $to)
# returns an array of hashrefs of report results.  Used in adding comparison
# as well ans the main report

sub report_base {
    my ($self, $from_date, $to_date) = @_;
    die text('Invalid Reporting Basis') 
           if ($self->basis ne 'accrual') and ($self->basis ne 'cash');
    my $procname = 'pnl__income_statement_' . $self->basis;
    return $self->call_procedure(
             procname => $procname, args => [$from_date, $to_date]
    );
}

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->report_base($self->from_date, $self->to_date);
    $self->rows(\@rows);
}

=item add_comparison($from, $to)

TODO

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
