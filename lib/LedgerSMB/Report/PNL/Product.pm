
package LedgerSMB::Report::PNL::Product;

=head1 NAME

LedgerSMB::Report::PNL::Product - Profit/Loss reports on Products

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Product->new(%$request);
 $report->render();

=head1 DESCRIPTION

This provides the income statement-like report for products on LedgerSMB on 1.4
and later.  This report gives decision-makers a general overview of what the
actual profit and loss of a business is regarding historical performance of
specific products.

This is only supported on products with inventory because otherwise there is no
real way to track revenue vs loss, for example with the case of resold services.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report::PNL';

=head1 CRITERIA PROPERTIES

Standard dates plus

=over

=item id

This is the id of the good or service

=cut

has id => (is => 'ro', isa =>'Int', required => 1);

=item partnumber

=cut

has partnumber => (is => 'rw', isa =>'Str');


=item description

=cut

has description  => (is => 'rw', isa =>'Str');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item name

=cut

sub name { my ($self) = @_;
           return $self->Text('Proft/Loss on Inventory Sales');
}

=item header_lines

=cut

sub header_lines {
    my ($self) = @_;
    return [{value => $self->partnumber,
            text => $self->Text('Part Number') },
            {value => $self->description,
            text => $self->Text('Description') },
    ];
}

=back

=head1 METHODS

=over

=item $self->report_base($from_date, $to_date)

Implement query protocol from parent class.

=cut


sub report_base {
    my ($self, $from_date, $to_date) = @_;
    return $self->call_dbmethod(funcname => 'pnl__product');
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=item LedgerSMB::Report::PNL

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
