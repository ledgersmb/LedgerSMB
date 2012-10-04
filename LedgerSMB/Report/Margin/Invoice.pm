=head1 NAME

LedgerSMB::Report::Margin::Invoice - Report for profit vs COGS per 
Invoice

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Margin::ECA->new(%$request);
 $report->run_report;
 $report->render($request);

=cut

package LedgerSMB::Report::Margin::Invoice;
use Moose;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

This report provides a comparison of income vs direct expenses (COGS) for a
given invoice.

=head1 CRITERIA PROPERTIES

=over 

=item id

The id of the invoice

=cut

has id => (is => 'ro', isa => 'Maybe[Int]');

=item invnumber

The invoice  number

=cut

has invnumber => (is => 'ro', isa => 'Maybe[Str]');

=back

=head1 REPORT CONSTANT FUNCTIONS

=over

=item name

=cut

sub name { return LedgerSMB::Report::text('Margin Report for Invoice') };

=item columns

=cut

# No need to return anything due to custom template

sub columns { return [] }

=item header_lines

=cut

sub header_lines {
    return [{ name => 'invnumber',
              text => LedgerSMB::Report::text('Invoice Number')}
          ];
}


=item template

=cut

sub template { return 'Reports/PNL' }

=back

=head1 METHODS

=over

=item run_report

Runs the report.  Takes either id or invnumber, but not both.

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method->({funcname => 'pnl__invoice' });
    $self->rows(\@rows);
    return;
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Report

=item LedgerSMB::Report::Margin::ECA

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

1;
