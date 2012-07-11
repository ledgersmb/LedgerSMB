=head1 NAME

LedgerSMB::DBObject::Report::Budget::Variance - Variance Report per Budget

=head1 SYNPOSIS

  my $report = LedgerSMB::DBObject::Report::Budget::Variance->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This is a basic variance report for budgets.  A variance report shows budgetted
debits and credits along with those actually accrued during the stated period.
It thus provides a way of measuring both current and historical expenditures
against what was budgetted.

=cut

package LedgerSMB::DBObject::Report::Budget::Variance;
use Moose;
extends 'LedgerSMB::DBObject::Report';
use LedgerSMB::App_State;
my $locale = $LedgerSMB::App_State::Locale;

=head1 PROPERTIES

=over

=item columns

Read only accessor.  This provides the columns for the report

=over 

=item budget_description

Description of he budget line item

=item accno

Account number budgetted

=item account_label

Account name

=item budget_amount

Amount (normalized left or right) budgetted

=item used_amount

Amount (normalized left or right) used

=item variance

Difference between budgetted and used.

=back

=cut

sub columns {
   return [
      {col_id => 'budget_description', 
         type => 'text', 
         name => $locale->text('Description')},

      {col_id => 'accno', 
         type => 'text', 
         name => $locale->text('Account Number')},

      {col_id => 'account_label', 
         type => 'text', 
         name => $locale->text('Account Label')},

      {col_id => 'budget_amount', 
         type => 'text', 
         name => $locale->text('Amount Budgetted')},

      {col_id => 'used_amount', 
         type => 'text', 
         name => '- ' . $locale->text('Used')},

      {col_id => 'variance', 
         type => 'text', 
         name => '= ' . $locale->text('Variance')},
   ];
}

=item name

Returns name of report

=cut

sub name {
    return $locale->text('Budget Variance Report');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'reference',
             text => $locale->text('Budget Number')},
            {name => 'description',
             text => $locale->text('Description')},
            {name => 'start_date',
             text => $locale->text('Start Date')},
            {name => 'end_date',
             text => $locale->text('End Date')},];
}

=back

=head1 CRITERIA PROPERTIES

=over

=item id

Budget id for variance report.  This is the only search criteria currently 
supported.

=cut

has id => (is => 'ro', isa => 'Int');

=back

=head1 HEADER PROPERTIES

These are used to generate the header as displayed and are typically pulled in 
from a budget object.

=over

=item reference

=cut

has  reference => (is => 'ro', isa => 'Str');

=item description

=cut

has description => (is => 'ro', isa => 'Str');

=item start_date

=cut

has start_date => (is => 'ro', builder => '_date');

=item end_date

=cut

has end_date => (is => 'ro', builder => '_date');

=back 

=head1 METHODS

=over

=item for_budget_id

Retrieves budget info and creates variance report object for it.

=cut

sub for_budget_id {
    my ($self, $id) = @_;
    use LedgerSMB::DBObject::Budget;

    my $budget = LedgerSMB::DBObject::Budget->get($id);
    my $report = $self->new(%$budget); 
    return $report;
}

=item run_report

Runs the report, setting rows for rendering.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method({funcname => 'budget__variance_report'});
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
