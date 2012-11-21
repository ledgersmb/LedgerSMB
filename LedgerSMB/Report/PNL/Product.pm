=head1 NAME

LedgerSMB::Report::PNL::Product - Profit/Loss reports on Products

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Product->new(%$request);
 $rpt->render($request);

=head1 DESCRIPTION

This provides the income statement-like report for products on LedgerSMB on 1.4 
and later.  This report gives decision-makers a general overview of what the 
actual profit and loss of a business is regarding historical performance of 
specific products.

This is only supported on products with inventory because otherwise there is no 
real way to track revenue vs loss, for example with the case of resold services.

=cut

package LedgerSMB::Report::PNL::Product;
use Moose;
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

=item template

=cut

sub template { return 'Reports/PNL' }

=item name

=cut

sub name { return LedgerSMB::Report::text('Proft/Loss on Inventory Sales') }

=item header_lines

=cut

sub header_lines {
    return [{name => 'partnumber',
            text => LedgerSMB::Report::text('Part Number') },
            {name => 'description',
            text => LedgerSMB::Report::text('Description') },
    ];
}

=item columns

=cut

sub columns { return []  }

=back

=head1 METHODS

=cut

# private method
# report_base($from, $to)
# returns an array of hashrefs of report results.  Used in adding comparison
# as well as the main report

sub report_base {
    my ($self, $from_date, $to_date) = @_;
    return $self->exec_method({funcname => 'pnl__product'});
}

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=item LedgerSMB::Report::PNL

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
