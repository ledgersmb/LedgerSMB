=head1 NAME

LedgerSMB::Report::COA - Chart of Accounts List for LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::COA->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This module provides a Chart of Account report for LedgerSMB.  This account is
useful regarding checking on current balances and managing the accounts.
Typically columns are displayed based on the permissions of the user.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::COA;
use Moose;
extends 'LedgerSMB::Report';

use LedgerSMB::App_State;


=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.  Unless otherwise noted, each
column is intended to be visible to all who have permissions to run the report.

=over

=item accno

Displays the account number.

=item description

Account description.

=item gifi_accno

This is the GIFI account number.

=item debit_balance

This is the debit balance (or blank if none or balance is credit).

=item credit_balance

This is the credit balance (or blank if none or balance is debit)

=item link

This lists the link descriptions.  Each represents a group of drop-downs the
user has access to.  This should be visible only to admin users.

=item edit

Link to edit the account.  Should be visible only to admin users.

=item delete

Link to delete the account if it has no transactions.  Should be visible only to
admin users.

=back

=cut

sub columns {
    my ($self) = @_;
    return [
    {col_id => 'accno',
       name => $self->Text('Account Number'),
       type => 'href',
   href_base => '',
     pwidth => '2', },

    {col_id => 'description',
       name => $self->Text('Description'),
       type => 'href',
  href_base => '',
     pwidth => '6', },

    {col_id => 'gifi',
       name => $self->Text('GIFI'),
       type => 'text',
     pwidth => '1', },

    {col_id => 'debit_balance',
       name => $self->Text('Debits'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'credit_balance',
       name => $self->Text('Credits'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'link',
       name => $self->Text('Dropdowns'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'edit',
       name => $self->Text('Edit'),
       type => 'href',
  href_base => '',
  html_only => 1, },

    {col_id => 'delete',
       name => $self->Text('Delete'),
       type => 'href',
  href_base => '',
  html_only => '1', },
  ];
}

=item name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Chart of Accounts');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [];
}

=item subtotal_cols

Returns list of columns for subtotals

=cut

sub subtotal_cols {
    return [];
}

=back

=head2 Criteria Properties

No criteria required.

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'report__coa');
    for my $r(@rows){
        my $ct;
        if ($r->{is_heading}){
           $ct = 'H';
        } else {
           $ct = 'A';
        }
        $r->{edit} = '['.$self->Text('Edit').']';
        $r->{delete} = '['.$self->Text('Delete').']'
                  if !$r->{rowcount};
        $r->{edit_href_suffix} = 'account.pl?action=edit&id='.$r->{id} .
           "&charttype=$ct";
        $r->{delete_href_suffix} = 'journal.pl?action=delete_account&id='
        . $r->{id} . "&charttype=$ct";
        $r->{accno_href_suffix} =
                'reports.pl?action=start_report&module_name=gl&report_name=gl' .
                "&accno=$r->{accno}--$r->{description}"
                     unless $r->{is_heading};
        $r->{description_href_suffix} = $r->{accno_href_suffix};
        $r->{html_class} = 'listheading' if $r->{is_heading};
        $r->{link} =~ s/:/\n/g if $r->{link};
    }
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
