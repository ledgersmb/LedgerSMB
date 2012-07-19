=head1 NAME

LedgerSMB::Report::Margin::ECA - Report for profit vs COGS per ECA

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Margin::ECA->new(%$request);
 $report->run_report;
 $report->render($request);

=cut

package LedgerSMB::Report::Margin::ECA;
use Moose;
use LedgerSMB::App_State;
extends 'LedgerSMB::Report';

my $locale = LedgerSMB::App_State::Locale;

=head1 DESCRIPTION

This report provides a comparison of income vs direct expenses (COGS) for a
given entity credit account (usually a customer).  Note that at present, unlike
the income statement, this does not support clicking through to view
transaction history.

=head1 CRITERIA PROPERTIES

=over 

=item id

The id of the customer

=cut

has id => (is => 'ro', isa => 'Maybe[Int]');

=item meta_number

The customer number

=cut

has meta_number => (is => 'ro', isa => 'Maybe[Str]');

=item from_date

standard start date attribute

=item to_date

Standard end date attribute

=cut

has 'from_date' => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');
has 'to_date' => (is => 'ro', coerce => 1, isa => 'LedgerSMB::Moose::Date');

=back

=head1 REPORT CONSTANT FUNCTIONS

=over

=item name

=cut

sub name { return $locale->text('Margin Report for Customer'); }

=item columns

=cut 

# We don't need to return anything here because we have our own template.

sub columns {  return [] }

=item header_lines

=cut

sub header_lines {
    return [{ name => 'meta_number', 
              text => $locale->text('Customer Number')}
          ];
}

=item template

=cut

sub template { return 'Reports/PNL' };

=back

=head1 METHODS

=over

=item run_report

Runs the report.  Takes either id or meta_number, but not both.  Dates are
recognized

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method->({funcname => 'pnl__customer' });
    $self->rows(\@rows);
    return;
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Report

=item LedgerSMB::Report::Margin::Invoice

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

1;
