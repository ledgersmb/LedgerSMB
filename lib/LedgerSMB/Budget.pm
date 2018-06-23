
package LedgerSMB::Budget;

=head1 NAME

LedgerSMB::Budget - Managing budgets stored in the database

=head1 DESCRIPTION

This module provides budget management routines, such as entering budgets,
approving or rejecting them, and marking them obsolete.  It does not include
more free-form areas like reporting.  For those, see
LedgerSMB::Budget_Report.

=cut

use LedgerSMB::PGDate;
use strict;
use warnings;

our $VERSION = 0.1;


use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item   $id INT
   The id of the budget

=cut

has 'id' => (is => 'rw', isa => 'Maybe[Int]');

=item   $start_date date
   The start date of the budget, inclusive

=cut

has 'start_date' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item   $end_date date
   The end date of the budget, inclusive

=cut

has 'end_date' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item   $reference text
   This is a text reference identifier for the budget

=cut

has 'reference' => (is => 'rw', isa => 'Maybe[Str]');

=item   $description text
   This is a text field for the budget description.  It is searchable.

=cut

has 'description' => (is => 'rw', isa => 'Maybe[Str]');

=item   $entered_by int
   Entity id of the employee or contractor who entered the budget

=cut

has 'entered_by' => (is => 'rw', isa => 'Maybe[Int]');

=item   $approved_by int
   Entity id of the employee or contractor who approved the budget

=cut

has 'approved_by' => (is => 'rw', isa => 'Maybe[Int]');

=item   $obsolete_by int
   Entity id for the employee or contractor who marked the budget obsolete

=cut

has 'obsolete_by' => (is => 'rw', isa => 'Maybe[Int]');

=item   $entered_at timestamp
   Time the budget was entered

=cut

has 'entered_at' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item   $approved_at timestamp
   Time the budget was approved

=cut

has 'approved_at' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item   $obsolete_at timestamp
   Time the budget was deleted

=cut

has 'obsolete_at' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item   $entered_by_name text
   Name of entity who entered the budget.

=cut

has 'entered_by_name' => (is => 'rw', isa => 'Maybe[Str]');

=item   $approved_by_name text
   Name of entity who approved the budget

=cut

has 'approved_by_name' => (is => 'rw', isa => 'Maybe[Str]');

=item   $obsolete_by_name text
   Name of entity who obsoleted the budget

=cut

has 'obsolete_by_name' => (is => 'rw', isa => 'Maybe[Str]');

=item @business_unit_ids

List of id's of business units which the budget covers

=cut

has 'business_unit_ids' => (is => 'rw', isa => 'Maybe[ArrayRef[Int]]');

=item   @lines
   These are the actual lines of the budget.  Each one is a hashref containing

=cut

has 'lines' => (is => 'rw', isa => 'Maybe[ArrayRef[HashRef[Any]]]');
=over

=item $budget_id int
   Optional.  Don't use.  Use the $id field of the parent instead.

=item $account_id int
   The id of the chart of accounts entry

=item $accno text
   The account number for the coa entry

=item $acc_desc text
   Description of COA entry.

=item $amount numeric
   The amount budgetted

=item $description text
   Description of line item

=back

=item @notes
Where each note is a hashref containing

=over

=item $subject string
   Subject of note

=item $note string
   The body of the note.

=item $created timestamp
   This is when the note was created

=item $created_by string
   Username of the individual who created the note at the time of its creation.

=back

=back

=head1 METHODS

=over

=item save

Saves the current budget.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'budget__save_info');
    $self->id($ref->{id});
    $self->{details} = [];
    return unless $self->lines;
    for my $line (@{$self->lines}){
       my $l_info = [$line->{account_id},
                     $line->{description},
                     $line->{amount},
       ];
       push @{$self->{details}}, $l_info;
    }
    $self->call_dbmethod(funcname => 'budget__save_details');
    return $self->get($ref->{id});
}

=item search
This method uses the object as the search criteria.  Nulls/undefs match all
values.  The properties used are:

=over

=item start_date
Matches the start date of the budget.  Full match only.

=item end_date
Matches the end date of the budget.  Full match only

=item includes_date
This date is between start date and end date of budget, inclusive.

=item reference
Partial match on budget reference

=item description
Full text search against description

=item entered_by
Exact match of entered by.

=item approved_by
Exact match of approved by

=item department_id
Exact match of department_id

=item project_id
Exact match of project_id

=item is_approved
true lists approved budgets, false lists unapproved budgets.  null/undef lists
all.

=item is_obsolete
true lists obsolete budgets. False lists non-obsolete budgets.  null/undef lists
all.

=back

=cut

sub search {
    my ($self) = @_; # self is search criteria here.
    @{$self->{search_results}}
       = $self->call_dbmethod(funcname => 'budget__search');
    return @{$self->{search_results}};
}

=item get(id)
takes a new (base) object and populates with info for the budget.

=cut

sub get {
   my ($self, $id) = @_;
   my ($info) = $self->call_procedure(
          funcname => 'budget__get_info', args => [$id]
   );
   $self = $self->new(%$info);
   my @lines = $self->call_dbmethod(funcname => 'budget__get_details');
   $self->lines(\@lines);
   @{$self->{notes}} = $self->call_dbmethod(funcname => 'budget__get_notes');
   return $self;
}

=item approve
Marks the budget as approved.

=cut

sub approve {
   my ($self) = @_;
   return $self->call_dbmethod(funcname => 'budget__approve');
}

=item reject
Reject and deletes the budget.

=cut

sub reject {
   my ($self) = @_;
   return $self->call_dbmethod(funcname => 'budget__reject');
}

=item obsolete
Marks the budget as obsolete/superceded.

=cut

sub obsolete {
   my ($self) = @_;
   return $self->call_dbmethod(funcname => 'budget__mark_obsolete');
}

=item save_note(subject string, note string)
Attaches a note with this subject and content to the budget.

=cut

sub save_note {
   my ($self, $subject, $note) = @_;
   my ($info) = $self->call_procedure(
          funcname => 'budget__save_note',
           args => [$self->{id}, $subject, $note]
   );
   return;
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;
