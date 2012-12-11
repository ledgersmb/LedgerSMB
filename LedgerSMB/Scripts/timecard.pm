=head1 NAME

LedgerSMB::Scripts::timecard - LedgerSMB workflow routines for timecards.

=head1 SYNPOSIS

 LedgerSMB::Scripts::timecard::display($request)

=head1 DESCRIPTION

This module contains the basic workflow scripts for managing timecards for 
LedgerSMB.  Timecards are used to track time and materials consumed in the 
process of work, from professional services to payroll and manufacturing.

=head1 ROUTINES

=over

=item display

Displays a timecard.  LedgerSMB::Timecard properties set are treated as 
defaults.

=cut

sub display {
    my ($request) = @_;
}

=item save

=cut

sub save {
    my ($request) = @_;
    my $timecard = LedgerSMB::Timecard->new(%$request);
    $timecard->save;
    $request->{id} = $timecard->id;
    display($request);
}

=item print

=cut

sub print {
    my ($request) = @_;
}

=item timecard_report

This generates a report of timecards.

=cut

sub timecard_report{
    my ($request) = @_;
}

=item generate_order

This routine generates an order based on timecards

=cut

sub generate_order {
    my ($request) = @_;
}


=back

=head1 SEE ALSO

=over

=item LedgerSMB::Timecard

=item LedgerSMB::Timecard::Type

=item LedgerSMB::Report::Timecards

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
