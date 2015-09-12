=head1 NAME

LedgerSMB::Report::Listings::GIFI - List GIFI for accounts in LedgerSMB

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Listings::GIFI->new()
 $report->render;

No $request is needed since there are no criteria.

=cut

package LedgerSMB::Report::Listings::GIFI;
use Moose;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

GIFI is the Generalized Index of Financial Information that the Canadian tax
authorities use in tax reporting.  LedgerSMB allows you to map accounts to GIFI
codes for tax reporting.  Non-Canadian users can use this to group accounts
together for other reporting uses.

=head1 REPORT CONSTANTS

=head2 columns

=over

=item accno

=item description

=back

=cut

sub columns {
    return [
    { col_id => 'accno',
        type => 'href',
   href_base => 'am.pl?action=edit_gifi&coa=1&accno=',
        name => LedgerSMB::Report::text('GIFI'), },

    { col_id => 'description',
        type => 'text',
        name => LedgerSMB::Report::text('Description'), },

    ];
}

=head2 header_lines

None

=cut

sub header_lines { return []; }

=head2 name

GIFI

=cut

sub name { return LedgerSMB::Report::text('GIFI'); }

=head1 REPORT CRITERIA

None

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'gifi__list');
    for my $row (@rows){
        $row->{row_id} = $row->{accno};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team

This file may be used in accordance with the GNU General Public License version
2 or at your option any later version.  Please see the included LICENSE.TXT.

=cut

__PACKAGE__->meta->make_immutable;

1;
