=head1 NAME

LedgerSMB::Report::Balance_Sheet - The LedgerSMB Balance Sheet Report

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Balance_Sheet->new(%$request);
 $report->render($request);

=head1 DESCRIPTION

This report class defines the balance sheet functionality for LedgerSMB.   The
primary work is done in the database procedures, while this module largely translates data structures for the report.

=cut

package LedgerSMB::Report::Balance_Sheet;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

=over

=item to_date LedgerSMB::PGDate

=back

=head1 INTERNAL PROPERTIES

=head2 headings

This stores the account headings for handling the hierarchy in a single hashref

=cut

has 'headings' => (is => 'rw', isa => 'HashRef[Any]', required => 0);

=head1 STATIC METHODS

=over

=item columns

Returns no columns since this is hardwired into the template

=cut

sub columns {
    return [];
};

=item heading_lines

Returns none since this is not applicable to this.

=cut 

sub heading_lines {
    return [];
}

=item name

Returns the localized string 'Balance Sheet'

=cut

sub name {
    return LedgerSMB::Report::text('Balance Sheet');
}

=item template

Returns 'Reports/balance_sheet'

=cut

sub templates {
    return 'Reports/balance_sheet';
}

=back

=head1 SEMI-PUBLIC METHODS

=head2 run_report()

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
