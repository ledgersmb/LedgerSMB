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

my $locale = $LedgerSMB::App_State::Locale;

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

=item desc

Only used for saved criteria sets, is a human-readable description.

=cut

has desc => (is => 'rw', isa => 'Maybe[Str]');

=item yearend

This value holds information related to yearend handling.  It can be either
'all', 'none', or 'last' each of which describes which yearends to ignore.

=cut

has yearend => (is => 'rw', isa => 'Str');


=item heading

If set, only select accounts under this heading

=cut

has heading => (is => 'rw', isa => 'Maybe[Int]')l

=item accounts

If set, only include these accounts

=cut

has accounts => (is => 'rw', isa => 'Maybe[ArrayRef[Int]]');

=head1  REPORT CONSTANT FUNCTIONS

See the documentation for LedgerSMB::Report for details on these
methods.

=over

=item name

=cut

sub name {
    return $locale->text('Trial Balance');
};

=item columns

=cut

sub columns {
    return [
      {col_id => 'account_number',
         type => 'href',
    href_base => 'journal.pl?action=search&col_transdate=Y&col_reference=Y&col_description=Y&col_debits=Y&col_credits=Y&col_source=Y&col_accno=Y',
         name => $locale->text('Account Number') },

      {col_id => 'account_desc',
         type => 'href',
    href_base => 'journal.pl?action=search&col_transdate=Y&col_reference=Y&col_description=Y&col_debits=Y&col_credits=Y&col_source=Y&col_accno=Y',
         name => $locale->text('Account Description') },

      {col_id => 'gifi_accno',
         type => 'href',
    href_base => 'journal.pl?action=search&col_transdate=Y&col_reference=Y&col_description=Y&col_debits=Y&col_credits=Y&col_source=Y&col_accno=Y',
         name => $locale->text('GIFI') } ,

      {col_id => 'starting_balance',
         type => 'text',
         name => $locale->text('Starting Balance') } ,

      {col_id => 'debits',
         type => 'text',
         name => $locale->text('Debits') } ,

      {col_id => 'credits',
         type => 'text',
         name => $locale->text('Credits') } ,

      {col_id => 'ending_balance',
         type => 'text',
         name => $locale->text('Ending Balance') } ,

    ];
}

=item header_lines 

=cut

sub header_lines {
    return [{name => 'date_from'
             text => $locale->text('From date') },
            {name => 'date_to',
             text => $locale->text('To Date') },
            {name => 'yearend',
             text => $locale->text('Ignore Yearends') },
            ];
}

=back

=head1  METHODS

=over

=item get

Retrieves the trial balance for review and possibly running it.

=cut

sub get {
    my ($self) = @_;
    my $ref = __PACKAGE__->call_procedure(procname => 'trial_balance__get', 
                                              args => [$id]);
    return __PACKAGE__->new(%$ref);
}

=item save

Saves the trial balance to be run again with the same parameters another time

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'trial_balance__save'});
    $self->id(shift (values @$ref));
}

=item run_report

Runs the trial balance report.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method({funcname => 'report__gl'});
    my $total_debits;
    my $total_credits;
    for my $ref(@rows){
        my $href_suffix = "from_date=" . $self->from_date . 
                          "&to_date=" . $self->to_date .
                          "&accno=" . $ref->{account_number};
        $total_debits += $ref->{debits}; 
        $total_credits += $ref->{credits}; 
        $ref->{account_number_href_suffix} = $href_suffix;
        $ref->{account_desc_href_suffix} = $href_suffix;
        $ref->{gifi_accno_href_suffix} = $href_suffix;
        
    }
    push @rows {class => 'total', 
               debits => $total_debits,
              credits => $total_credits, };

    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
