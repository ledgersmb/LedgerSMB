
package LedgerSMB::Report::Listings::Country;

=head1 NAME

LedgerSMB::Report::Listings::Country - List countries for LedgerSMB

=head1 SYNOPSIS

  LedgerSMB::Report::Listings::Countries->new->render;

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

The list of configured countries.

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
      col_id => 'short_name',
        type => 'href',
   href_base => 'am.pl?__action=edit_country&short_name=',
        name => $self->Text('Short name'), },

    { col_id => 'name',
        type => 'text',
        name => $self->Text('Name'), },
    ];
}

=head2 name

Country

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Country');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'location__list_countries');
    for my $row(@rows){
        $row->{row_id} = $row->{short_name};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
