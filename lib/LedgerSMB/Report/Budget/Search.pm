=head1 NAME

LedgerSMB::Reports::Budget::Search - Search for Budgets

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Budget::Search->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This is a basic search report for budgets.

=cut

package LedgerSMB::Report::Budget::Search;
use Moose;
use LedgerSMB::MooseTypes;
extends 'LedgerSMB::Report';


=head1 PROPERTIES

=over

=item columns

Read only accessor.  This provides the columns for the report

=over

=item start_date

Start date of the budget

=item end_date

End date of the budget

=item reference

Reference/control code of the budget

=item description

Budget description

=item entered_by_name

Who entered the budget

=item approved_by_name

Who approved the budget

=item obsolete_by_name

Who marked the budget obsolete

=back

=cut

sub columns {
   return [ {col_id => 'start_date',
               type => 'href',
          href_base => 'budget_reports.pl?action=variance_report&id=',
               name => LedgerSMB::Report::text('Start Date') },

            {col_id => 'end_date',
               type => 'href',
          href_base => 'budget_reports.pl?action=variance_report&id=',
               name => LedgerSMB::Report::text('End Date') },

            {col_id => 'reference',
               type => 'href',
          href_base => 'budgets.pl?action=view_budget&id=',
               name => LedgerSMB::Report::text('Reference') },

            {col_id => 'description',
               type => 'href',
          href_base => 'budgets.pl?action=view_budget&id=',
               name => LedgerSMB::Report::text('Description') },

            {col_id => 'entered_by_name',
               type => 'text',
               name => LedgerSMB::Report::text('Entered By') },

            {col_id => 'approved_by_name',
               type => 'text',
               name => LedgerSMB::Report::text('Approved By') },

            {col_id => 'obsolete_by_name',
               type => 'text',
               name => LedgerSMB::Report::text('Obsolete By') },
   ];
}


=item name

Returns the localized name of the template

=cut

sub name {
   return LedgerSMB::Report::text('Budget Search Results');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'date_from',
             text => LedgerSMB::Report::text('Start Date')},
            {name => 'date_to',
             text => LedgerSMB::Report::text('End Date')},
            {name => 'accno',
             text => LedgerSMB::Report::text('Account Number')},
            {name => 'reference',
             text => LedgerSMB::Report::text('Reference')},
            {name => 'source',
             text => LedgerSMB::Report::text('Source')}];
}

=back

=head1 CRITERIA PROPERTIES

=over

=item reference

Matches the beginning of the reference of the budget

=cut

has 'reference' => (is=> 'rw', isa => 'Maybe[Str]');

=item description

Matched using full text rules against the description

=cut

has 'description' => (is=> 'rw', isa => 'Maybe[Str]');

=item start_date

Exact match for the start date

=cut

has 'start_date' => (is=> 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item end_date

Exact match for end date.

=cut

has 'end_date' => (is=> 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item buisness_units

This returns all budgets matching all business units listed here.

=cut

has 'business_units' => (is=> 'rw', isa => 'Maybe[ArrayRef[Int]]');

=back

=head1 METHODS

=over

=item prepare_criteria

Creates criteria from web input to types expected

=cut

sub prepare_criteria {
    my ($self, $request) = @_;
    my @business_units;
    for my $count(1 .. $request->{bclass_count}){
       push @business_units, $request->{"business_unit_$count"}
                 if defined $request->{"business_unit_$count"};
    }
    $request->{business_units} = \@business_units;
}

=item run_report

Runs the report

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'budget__search');
    for my $r(@rows){
        $r->{row_id} = $r->{id};
    }
    $self->rows(\@rows);
}


=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut

__PACKAGE__->meta->make_immutable;


1;
