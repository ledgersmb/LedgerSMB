=head1 NAME

LedgerSMB::DBObject::Budget_Report

=cut

package LedgerSMB::DBObject::Budget_Report;
use strict;

=head1 SYNOPSIS

Reporting routines for budgets.  Currently only displays a variance report.

=head1 INHERITANCE

=cut

=over

=item LedgerSMB

=item LedgerSMB::DBObject

=back

=cut

use base qw(LedgerSMB::DBObject);

=head1 PROPERTIES

=over

=item id
The id of the budget

=item start_date
The start date of the budget, inclusive

=item end_date
The end date of the budget, inclusive

=item reference
The reference or control code of the budget

=item description
Description of the budget

=item entered_by
entity id of the one who entered the budget

=item approved_by
entity id of the one who approved the budget

=item obsolete_by
entity id of the one who marked the budget obsolete

=item entered_at
Timestamp when the budget was saved

=item approved_at
Timestamp when the budget was approved

=item obsolete_at
Timestamp when the budget was marked obsolete

=item entered_by_name
Name of the entity who entered the budget

=item approved_by_name
Name of the entity who approved the budget

=item obsolete_by_name
Name of the entity who marked the budget obsolete

=item department_id
The ID of the department for which this budget was written

=item department_name
Name of the department for which this budget was written

=item project_id
ID of project for which this budget was written

=item projectnumber
Project number for which this budget was written

=item lines
Lines of the report.  Each line is a hashref containing:

=over

=item accno
Account number for the account in question

=item account_label
Description for the account in question

=item account_id
ID for the account in question

=item budget_description
Description for the line item of the budget

=item budget_amount
The amount budgetted

=item used_amount
The amount actually used

=item variance
budgetted - used

=back

=back

=head1 METHODS

=over

=item run_report($id);

Takes a blank (base) object and populates with the variance report data provided
by the id argument.

=cut

sub run_report {
    my ($self) =  @_;
   my ($info) = $self->call_procedure(
          procname => 'budget__get_info', args => [$self->{id}]
   );
   $self->merge($info);
   @{$self->{lines}} = $self->exec_method(
          {funcname => 'budget__variance_report'}
   );

   return @{$self->{lines}};
}

1;

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.
