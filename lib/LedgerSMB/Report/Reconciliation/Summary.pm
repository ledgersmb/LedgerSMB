
package LedgerSMB::Report::Reconciliation::Summary;

=head1 NAME

LedgerSMB::Report::Reconciliation::Summary - List of Reconciliation Reports for
LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Reconciliation::Summary->new(%$request);
 $report->render();

=cut

use Moose;
use namespace::autoclean;
use LedgerSMB::MooseTypes;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

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

=item balance_from

Only show reports where the statement ending balance is greater or equal
to this.

=cut

has balance_from => (is => 'ro', isa => 'LedgerSMB::PGNumber', required => 0);

=item balance_to

Only show reports where the statement ending balance is less than or equal
to this.

=cut

has balance_to => (is => 'ro', isa => 'LedgerSMB::PGNumber', required => 0);

=item account_id

Show reports only for this specific account

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

Note that approved being set to true and submitted being set to false will never
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
    my ($self) = @_;
    return [ {col_id => 'account',
                name => $self->Text('Account'),
                type => 'text', },
             {col_id => 'end_date',
                name => $self->Text('Statement Date'),
                type => 'href',
           href_base => 'recon.pl?__action=display_report&report_id=', },
             {col_id => 'their_total',
                name => $self->Text('Statement Balance'),
               money => 1,
                type => 'text', },
             {col_id => 'approved',
                name => $self->Text('Approved'),
                type => 'boolean_checkmark', },
             {col_id => 'submitted',
                name => $self->Text('Submitted'),
                type => 'boolean_checkmark', },
             {col_id => 'updated',
                name => $self->Text('Last Updated'),
                type => 'text', },
             {col_id => 'entered_username',
                name => $self->Text('Entered By'),
                type => 'text', },
             {col_id => 'approved_username',
                name => $self->Text('Approved By'),
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
    my ($self) = @_;
    return [{value => $self->date_from,
             text  => $self->Text('From Date')},
            {value => $self->date_to,
             text  => $self->Text('To Date') },
            {value => $self->account_name,
             text  => $self->Text('Account') },
            {value => $self->balance_from,
             text  => $self->Text('From Amount')},
            {value => $self->balance_to,
             text  => $self->Text('To Amount')}
     ];
}

=head2 name

"Reconciliation Reports"

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Reconciliation Reports');
}

=head2 account_name

=cut

sub account_name {
    my ($self) = @_;

    my $sth = $self->dbh->prepare('select accno, description from account where id = ?')
        or die $self->dbh->errstr;
    $sth->execute( $self->account_id )
        or die $sth->errstr;
    my ($accno, $desc) = $sth->fetchrow_array;

    $accno //= '';
    $desc //= '';

    return "$accno - $desc";
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    $self->manual_totals(1);
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
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
