=head1 NAME

LedgerSMB::Report::Trial_Balance - Trial Balance report for LedgerSMB

=head1 SYNOPSYS

Unlike other reports, trial balance reports can be saved:

 my $report = LedgerSMB::Report::Trial_Balance->new(%$request);
 $report->save;

We can then run it:

 $report->run_report;
 $report->render($request);

We can also retrieve a previous report from the database and run it:

 my $report = LedgerSMB::Report::Trial_Balance->get($id);
 $report->run_report;
 $report->render($request);

=cut

package LedgerSMB::Report::Trial_Balance;
use Moose;
use LedgerSMB::App_State;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

The trial balance is a report used to test the books and whether they balance 
in paper accounting systems.  In digital systems it tends to also be repurposed
also as a general, quick look at accounting activity.  For this reason it is
probably the second most important report in the system, behind only the GL
reports.

Unlike other reports, trial balance reports can be saved:

=head1 	CRITERIA PRPERTIES

Criteria sets can also be saved/loaded.

=over

=item id

This is the id of the trial balance, only used to save over an existing 
criteria set.

=cut

has id => (is => 'rw', isa => 'Maybe[Int]');

=item date_from

Standard start date for trial balance.

=item date_to

Standard end date for report.

=cut

has date_from => (is => 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Date');
has date_to => (is => 'rw', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=item description

Only used for saved criteria sets, is a human-readable description.

=cut

has description => (is => 'rw', isa => 'Str', required => 0);

=item yearend

This value holds information related to yearend handling.  It can be either
'all', 'none', or 'last' each of which describes which yearends to ignore.

=cut

has ignore_yearend => (is => 'rw', isa => 'Str');

=item balance_sign

Either 1, 0, or -1.  1 for credit, -1 for debit, 0 for normal balances (i.e 
credit balances except for asset and expense accounts).

=cut

has balance_sign => (is => 'rw', isa => 'Int');


=item heading

If set, only select accounts under this heading

=cut

has heading => (is => 'rw', isa => 'Maybe[Int]');

=item accounts

If set, only include these accounts

=cut

has accounts => (is => 'rw', isa => 'Maybe[ArrayRef[Int]]');

=item business_units

A list of business account ids

=cut

has business_units => (is => 'ro', isa => 'ArrayRef[Int]', required => 0);

=back

=head1  REPORT CONSTANT FUNCTIONS

See the documentation for LedgerSMB::Report for details on these
methods.

=over

=item name

=cut

sub name {
    return LedgerSMB::Report::text('Trial Balance');
};

=item columns

=cut

sub columns {
    return [
      {col_id => 'account_number',
         type => 'href',
    href_base => 'journal.pl?action=search&col_transdate=Y&col_reference=Y&col_description=Y&col_debits=Y&col_credits=Y&col_source=Y&col_accno=Y',
         name => LedgerSMB::Report::text('Account Number'),
       pwidth => 1,},

      {col_id => 'account_desc',
         type => 'href',
    href_base => 'journal.pl?action=search&col_transdate=Y&col_reference=Y&col_description=Y&col_debits=Y&col_credits=Y&col_source=Y&col_accno=Y',
         name => LedgerSMB::Report::text('Account Description'),
       pwidth => 3,},

      {col_id => 'gifi_accno',
         type => 'href',
    href_base => 'journal.pl?action=search&col_transdate=Y&col_reference=Y&col_description=Y&col_debits=Y&col_credits=Y&col_source=Y&col_accno=Y',
         name => LedgerSMB::Report::text('GIFI'),
       pwidth => 1, } ,

      {col_id => 'starting_balance',
         type => 'text',
         money => 1,
         name => LedgerSMB::Report::text('Starting Balance'),
       pwidth => 1,} ,

      {col_id => 'debits',
         type => 'text',
         money => 1,
         name => LedgerSMB::Report::text('Debits'),
       pwidth => 1} ,

      {col_id => 'credits',
         type => 'text',
         money => 1,
         name => LedgerSMB::Report::text('Credits'),
       pwidth => 1} ,

      {col_id => 'ending_balance',
         type => 'text',
         money => 1,
         name => LedgerSMB::Report::text('Ending Balance'),
        pwidth => 1} ,

    ];
}

=item header_lines 

=cut

sub header_lines {
    return [{name => 'date_from',
             text => LedgerSMB::Report::text('From date') },
            {name => 'date_to',
             text => LedgerSMB::Report::text('To Date') },
            {name => 'yearend',
             text => LedgerSMB::Report::text('Ignore Yearends') },
            ];
}

=back

=head1  METHODS

=over

=item run_report

Runs the trial balance report.

=cut

sub run_report {
    my ($self) = @_;
    $self->manual_totals('1');
    my @rawrows = $self->call_dbmethod(funcname => 'trial_balance__generate');
    my $total_debits;
    my $total_credits;
    my @rows = ();
    for my $ref(@rawrows){
        next if (($ref->{starting_balance} == 0)
                        and ($ref->{credits} == 0) and ($ref->{debits} == 0));
        my $href_suffix = "&accno=" . $ref->{account_number};
        $href_suffix .= "&from_date=" . $self->date_from->to_db 
              if defined $self->date_from;
        $href_suffix .= "&to_date=" . $self->date_to->to_db
              if defined $self->date_to;
               
        $total_debits += $ref->{debits}; 
        $total_credits += $ref->{credits}; 
        $ref->{account_number_href_suffix} = $href_suffix;
        $ref->{account_desc_href_suffix} = $href_suffix;
        $ref->{gifi_accno_href_suffix} = $href_suffix;
        push @rows, $ref;
    }
    push @rows, {class => 'total', 
               debits => $total_debits,
              credits => $total_credits, 
            html_class => 'listtotal'};
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
