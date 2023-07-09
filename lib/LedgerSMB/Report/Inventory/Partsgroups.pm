
package LedgerSMB::Report::Inventory::Partsgroups;

=head1 NAME

LedgerSMB::Report::Inventory::Partsgroups - Partsgroup search

=head1 DESCRIPTION

Implements a listing of parts groups

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Inventory::Partsgroups->new(%$request);
 $report->render();

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';


=head1 CRITERIAL PROPERTIES

=over

=item partsgroup string

Prefix match on partsgroup name

=cut

has partsgroup => (is => 'ro', isa => 'Str', required => '0');

=back

=head1 INTERNALS

=head2 columns

=over

=item partsgroup

=back

=cut

sub columns {
    my ($self) = @_;
    return [{col_id => 'partsgroup',
               type => 'href',
          href_base => 'pe.pl?__action=edit&type=partsgroup&id=',
               name => $self->Text('Group') }];
}

=head2 header_lines

=over

=item partsgroup

=back

=cut

sub header_lines {
    my ($self) = @_;
    return [{value => $self->partsgroup,
             text => $self->Text('Partsgroup') }];
}

=head2 name

Partsgroups

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Partsgroups');
}

=head1 METHODS

=head2 run_report

Populates rows

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'partsgroup__search');
    $_->{row_id} = $_->{id} for (@rows);
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
