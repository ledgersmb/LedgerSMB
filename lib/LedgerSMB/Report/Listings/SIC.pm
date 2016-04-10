=head1 NAME

LedgerSMB::Report::Listings::SIC - List SIC codes in LedgerSMB

=head1 SYNOPSIS

  LedgerSMB::Report::Listings::SIC->new->render;

=cut

package LedgerSMB::Report::Listings::SIC;
use Moose;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

This provides a listing of SIC (or NAICS or similar) listings used in LedgerSMB
for categorizing customers.

=head1 REPORT CRITERIA

None

=head1 REPORT CONSTANTS

=head2 columns

=over

=item code

=item description

=back

=cut

sub columns {
    return [
      { col_id => 'code',
          type => 'href',
     href_base => 'am.pl?action=edit_sic&code=',
          name => LedgerSMB::Report::text('Code'), },

      { col_id => 'description',
          type => 'text',
          name => LedgerSMB::Report::text('Description'), }
    ];
}

=head2 header_lines

None

=cut

sub header_lines { return []; }

=head2 name

Standard Industrial Codes

=cut

sub name { return LedgerSMB::Report::text('Standard Industrial Codes'); }

=head1 METHODS

=head2 run_report

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'sic__list');
    for my $row(@rows){
        $row->{row_id} = $row->{code};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright(C) 2013 The LedgerSMB Core Team.  This file may be reused in
accordance with the GNU General Public License version 2 or at your option any
later version.  Please see the included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
