=head1 NAME

LedgerSMB::Report::Listings::Language - List languages for LedgerSMB

=head1 SYNOPSIS

  LedgerSMB::Report::Listings::Language->new->render;

=cut

package LedgerSMB::Report::Listings::Language;
use Moose;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

The language list is used in a number of places for manual and automatic
translation.  Note the same listing is used for both manual and .po-based
translation so if you add new languages, you may have to add new translations
to make them work in the UI.

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
    return [{
      col_id => 'code',
        type => 'href',
   href_base => 'am.pl?action=edit_language&code=',
        name => LedgerSMB::Report::text('Code'), },

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

Languages

=cut

sub name { return LedgerSMB::Report::text('Language'); }

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'person__list_languages');
    for my $row(@rows){
        $row->{row_id} = $row->{code};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright(C) 2013 The LedgerSMB Core Team.  This file may be reused in
accordance with the GNU General Public License (GNU GPL) version 2.0 or, at your
option, any later version.  Please see the LICENSE.TXT included.

=cut

__PACKAGE__->meta->make_immutable;

1;
