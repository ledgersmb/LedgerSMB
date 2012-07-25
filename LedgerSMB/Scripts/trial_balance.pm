=head1 NAME

LedgerSMB::Scripts::trial_balance - Trial Balance logic for LedgerSMB

=head1 SYNOPSIS

To save a criteria set:

  LedgerSMB::Scripts::trial_balance::save($request);

To get a criteria set and run it:

  LedgerSMB::Scripts::trial_balance::get($request);

To list criteria sets:

  LedgerSMB::Scripts::trial_balance::list($request);

To run a trial balance:

  LedgerSMB::Scripts::trial_balance::run($request);

=cut

package LedgerSMB::Scripts::trial_balance;
use LedgerSMB::Report::Trial_Balance;


=head1 DESCRIPTION

This module provides workflow scripts for trial balance functionality.  The
filter screen is displayed by LedgerSMB::Scripts::reports.

Please see LedgerSMB::Report::Trial_Balance for a list of criteria
that the methods expect.

=head1 METHODS

=over

=item get 

Retrieves and runs a trial balance.  Only needs id to be set.

=cut

sub get {
    my ($request) = @_;
    $request->merge(LedgerSMB::Report::Trial_Balance->get($request->{id}));
    run($request);
}

=item save

Saves a trial balance.  All criteria are applicable.

=cut

sub save {
    my ($request) = @_;
    my $tb = LedgerSMB::Report::Trial_Balance->new(%$request);
    $tb->save;
    list($request);
}

=item list

Lists trial balances.  No criteria are applicable

=cut

sub list {
    my ($request) = @_;
    use LedgerSMB::Report::Trial_Balance::List;
    my $rpt = LedgerSMB::Report::Trial_Balance::List->new(%$request);
    $rpt->render($request);
}

=item run

Runs the trial balance. All criteria are applicable except id and desc.

=cut

sub run {
    my ($request) = @_;
    my $tb = LedgerSMB::Report::Trial_Balance->new(%$request);
    $tb->run_report;
    $tb->render($request);
}

=head1 SEE ALSO

=over

=item LedgerSMB::Scripts::reports

=item LedgerSMB::Report

=item LedgerSMB::Report::Trial_Balance

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
