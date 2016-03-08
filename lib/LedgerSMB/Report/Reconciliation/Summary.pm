=head1 NAME

LedgerSMB::Report::Reconciliation::Summary - List of Reconciliation Reports for
LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Reconciliation::Summary->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Reconciliation::Summary;
use Moose;
use LedgerSMB::MooseTypes;
extends "LedgerSMB::Report";
with "LedgerSMB::Report::Dates";

=head1 DESCRIPTION

This report allows for searching reconciliation reports.  The reports are then
accessed by clicking on the hyperlinks and can be then approved or denied.

LedgerSMB follows a two-stage bank reconciliation process.  In the first stage,
the reconciliation data is entered, reviewed by the one who entered it, and
submitted for approval.  Prior to submission the data entry individual can
continue to work on the reconciliation report, entering missing items, etc.
After this is submitted, the only possible options are approval or removal.

This report is typically used in two contexts.  The first is in the approval
process, where this provides the basic search routines.  The second is in
checking past reconciliation report information to see what exactly was
reconciled in a specific report.

=head1 CRITERIA PROPERTIES

=over

=item amount_from

Only show reports where the amount is greater or equal to this

=cut

has amount_from => (is => 'ro', isa => 'LedgerSMB::Moose::Number',
              required => 0, coerce => 1);

=item amount_to

Only show reports where the amount is less than or equal to this

=cut

has amount_to => (is => 'ro', isa => 'LedgerSMB::Moose::Number', required => 0,
              coerce => 1);

=item account_id

Show repoirts only for this specific account

=cut

has account_id => (is => 'ro', isa => 'Int', required => 0);

=item approved

If undef, show all reports, if true, show approved ones and if false show
unapproved ones.

=cut

has approved => (is => 'ro', isa => 'Bool', required => 0);

=item submitted

If undef, show all reports, if true, show ones submitted for approval, and if
false only show reports in progress.

Note that approved being set to true and submitted bein set to false will never
match any reports.

=cut

has submitted => (is => 'ro', isa => 'Bool', required => 0);

=back

=head1 INTERNALS

=head2 columns

=over

=item account

This is the account label for recon purposes

=item end_date

This is the statement date.

=item their_total

The bank statement total.

=item approved

0 for not, 1 for approved

=item submitted

0 for not, 1 for approved

=item updated_timestamp

This is used to indicated when a reconciliation report was last updated for data
entry purposes.

=item entered_by

Username of the one who entered the report

=item approved_by

Username of the one who approved the report

=cut

sub columns {
    return [ {col_id => 'account',
                name => LedgerSMB::Report::text('Account'),
                type => 'text', },
             {col_id => 'end_date',
                name => LedgerSMB::Report::text('Statement Date'),
                type => 'href',
           href_base => "recon.pl?action=display_report&report_id=", },
             {col_id => 'their_total',
                name => LedgerSMB::Report::text('Statement Balance'),
               money => 1,
                type => 'text', },
             {col_id => 'approved',
                name => LedgerSMB::Report::text('Approved'),
                type => 'text', },
             {col_id => 'submitted',
                name => LedgerSMB::Report::text('Submitted'),
                type => 'text', },
             {col_id => 'updated',
                name => LedgerSMB::Report::text('Last Updated'),
                type => 'text', },
             {col_id => 'entered_by',
                name => LedgerSMB::Report::text('Entered By'),
                type => 'text', },
             {col_id => 'approved_by',
                name => LedgerSMB::Report::text('Approved By'),
                type => 'text', },
          ];
}



=back

=cut

=head2 header_lines

=over

=back

=cut

sub header_lines {
    return [{name => 'date_from',
             text => LedgerSMB::Report::text('From Date')},
            {name => 'date_to',
             text => LedgerSMB::Report::text('To Date') },
            {name => 'amount_from',
             text => LedgerSMB::Report::text('From Amount')},
            {name => 'amount_to',
             text => LedgerSMB::Report::text('To Amount')}
     ];
}

=head2 name

"Reconciliation Reports"

=cut

sub name {
    return LedgerSMB::Report::text('Reconciliation Reports');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'reconciliation__search');
    my @accounts = $self->call_dbmethod(
            funcname => 'reconciliation__account_list'
    );
    my $account = {};
    for my $a (@accounts){
       $account->{$a->{id}} = $a;
    }
    for my $r (@rows){
        $r->{account} = $account->{$r->{chart_id}}->{name};
        $r->{row_id} = $r->{id};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
