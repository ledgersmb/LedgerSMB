=head1 NAME

LedgerSMB::Report::PNL - Profit and Loss Reporting Base Class for LedgerSMB

=head1 SYNPOSIS

 use Moose;
 extends LedgerSMB::Report::PNL;

=head1 DESCRIPTION

This provides the common profit and loss reporting functions for LedgerSMB 1.4
and later.

=cut

package LedgerSMB::Report::PNL;
use Moose;
extends 'LedgerSMB::Report::Hierarchical';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

Standard dates.  Additional fields can be added by child reports.

=cut

=head1 Datastore Properties

=over


=item gifi

Boolean, true if it is a gifi report.

=cut

has gifi => (is => 'rw', isa => 'Bool');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

This may be overridden by child reports.

=cut

sub template { return 'Reports/PNL' }

=item columns

=cut

sub columns {
    return [];
}


=back

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;

    my @lines = $self->report_base();

    for my $line (@lines) {
        ###TODO-REPORT-HEADINGS: map GIFI differently
        my $row_id = $self->rheads->map_path([ ( @{$line->{heading_path}},
                                               $line->{account_number})
                                             ]);
        my $col_id = $self->cheads->map_path([ 1 ]);
        $self->cell_value($row_id, $col_id, $line->{amount});
        $self->rheads->id_props($row_id, $line);
        $self->cheads->id_props($col_id, { description =>
                                               $self->to_date });
    }
    $self->rows([]);
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
