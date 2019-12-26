
package LedgerSMB::Report::Budget::Search;

=head1 NAME

LedgerSMB::Reports::Budget::Search - Search for Budgets

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Budget::Search->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This is a basic search report for budgets.

=cut

use Moose;
use namespace::autoclean;
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
    my ($self) = @_;
    return [ {col_id => 'start_date',
               type => 'href',
          href_base => 'budget_reports.pl?action=variance_report&id=',
               name => $self->Text('Start Date') },

            {col_id => 'end_date',
               type => 'href',
          href_base => 'budget_reports.pl?action=variance_report&id=',
               name => $self->Text('End Date') },

            {col_id => 'reference',
               type => 'href',
          href_base => 'budgets.pl?action=view_budget&id=',
               name => $self->Text('Reference') },

            {col_id => 'description',
               type => 'href',
          href_base => 'budgets.pl?action=view_budget&id=',
               name => $self->Text('Description') },

            {col_id => 'entered_by_name',
               type => 'text',
               name => $self->Text('Entered By') },

            {col_id => 'approved_by_name',
               type => 'text',
               name => $self->Text('Approved By') },

            {col_id => 'obsolete_by_name',
               type => 'text',
               name => $self->Text('Obsolete By') },
   ];
}


=item name

Returns the localized name of the template

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Budget Search Results');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'date_from',
             text => $self->Text('Start Date')},
            {name => 'date_to',
             text => $self->Text('End Date')},
            {name => 'accno',
             text => $self->Text('Account Number')},
            {name => 'reference',
             text => $self->Text('Reference')},
            {name => 'source',
             text => $self->Text('Source')}];
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
    return $request->{business_units} = \@business_units;
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
    return $self->rows(\@rows);
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;


1;
