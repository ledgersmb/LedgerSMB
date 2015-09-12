=head1 NAME

LedgerSMB::Report::Listings::Warehouse - List warehouses in LedgerSMB

=head1 SYNOPSIS

Since no parameters are required:

  LedgerSMB::Report::Listings::Warehouse->new()->render;

=cut

package LedgerSMB::Report::Listings::Warehouse;
use Moose;
extends 'LedgerSMB::Report';

=head1 REPORT CRITERIA

None

=head1 REPORT CONSTANTS

=head2 columns

=over

=item Description

=back

=cut

sub columns {
    return [{
       col_id => 'description',
        type  => 'href',
   href_base  => 'am.pl?action=edit_warehouse&id=',
        name  => LedgerSMB::Report::text('Description'),
    }];
}

=head2 header_lines

None

=cut

sub header_lines { return []; }

=head2 name

Warehouses

=cut

sub name { return LedgerSMB::Report::text('Warehouses'); }

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'warehouse__list');
    for my $row(@rows){
        $row->{row_id} = $row->{id};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright(C) 2013 The LedgerSMB Core Team.  This file may be used in accordance
with the GNU General Public License version 2 or at your option any later
version.  Please see the included License.txt for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
