
package LedgerSMB::Report::PNL::Income_Statement;

=head1 NAME

LedgerSMB::Report::PNL::Income_Statement - Basic Income Statement for LedgerSMB

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(%$request);
 $rpt->render($request);

=head1 DESCRIPTION

This provides the income statement report for LedgerSMB on 1.4 and later.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report::PNL';

=head1 CRITERIA PROPERTIES

Standard dates plus

=over

=item basis

This is either 'cash' or 'accrual'

=cut

has basis => (is => 'ro', isa =>'Str', required => 1);

=item ignore_yearend

This is 'none', 'all', or 'last'

=cut

has ignore_yearend => (is => 'ro', 'isa' =>'Str', required =>1);

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

=cut

sub template { return 'Reports/PNL' }

=item name

=cut

sub name { my ($self) = @_; return $self->Text('Income Statement') }

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'basis',
            text => $self->Text('Reporting Basis') }];
}

=back

=head1 METHODS

=over

=item $self->report_base($from_date, $to_date)

Implement query protocol from parent class.

=cut



sub report_base {
    my ($self, $from_date, $to_date) = @_;
    die $self->Text('Invalid Reporting Basis')
           if ($self->basis ne 'accrual') and ($self->basis ne 'cash');
    die $self->Text('Required period type')
           if $self->comparison_periods and $self->interval eq 'none';
    my $procname = 'pnl__income_statement_' . $self->basis;
    return $self->call_dbmethod(funcname => $procname);
}


=back

=head1 SEE ALSO

=over

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=item LedgerSMB::Report::PNL

=back

=head1 LICENSE AND COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
1;
