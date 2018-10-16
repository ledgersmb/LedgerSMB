
package LedgerSMB::Report::Listings::Language;

=head1 NAME

LedgerSMB::Report::Listings::Language - List languages for LedgerSMB

=head1 SYNOPSIS

  LedgerSMB::Report::Listings::Language->new->render;

=cut

use Moose;
use namespace::autoclean;
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
    my ($self) = @_;
    return [{
      col_id => 'code',
        type => 'href',
   href_base => 'am.pl?action=edit_language&code=',
        name => $self->Text('Code'), },

    { col_id => 'description',
        type => 'text',
        name => $self->Text('Description'), },
    ];
}

=head2 name

Languages

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Language');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'person__list_languages');
    for my $row(@rows){
        $row->{row_id} = $row->{code};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
