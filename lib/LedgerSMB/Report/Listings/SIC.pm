
package LedgerSMB::Report::Listings::SIC;

=head1 NAME

LedgerSMB::Report::Listings::SIC - List SIC codes in LedgerSMB

=head1 SYNOPSIS

  LedgerSMB::Report::Listings::SIC->new->render;

=cut

use Moose;
use namespace::autoclean;
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
    my ($self) = @_;
    return [
      { col_id => 'code',
          type => 'href',
     href_base => 'am.pl?action=edit_sic&code=',
          name => $self->Text('Code'), },

      { col_id => 'description',
          type => 'text',
          name => $self->Text('Description'), }
    ];
}

=head2 name

Standard Industrial Codes

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Standard Industrial Codes');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'sic__list');
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
