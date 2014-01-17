=head1 NAME

LedgerSMB::Scripts::trial_balance - Trial Balance logic for LedgerSMB

=head1 SYNOPSIS

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

=item run

Runs the trial balance. All criteria are applicable except id and desc.

=cut

sub run {
    my ($request) = @_;
    LedgerSMB::Report::Trial_Balance->new(%$request)->render($request);
}

=back

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
