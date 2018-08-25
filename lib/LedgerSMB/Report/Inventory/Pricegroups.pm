
package LedgerSMB::Report::Inventory::Pricegroups;

=head1 NAME

LedgerSMB::Report::Inventory::Pricegroups - Pricegroup search for LedgerSMB

=head1 DESCRIPTION

Implements a listing of price groups.

=head1 SYNOPSIS

  my $report = LedgerSMB::Report::Inventory::Pricegroups->new(%$request);
  $report->render($request);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';


=head1 CRITERIAL PROPERTIES

=over

=item pricegroup string

Prefix match on pricegroup name

=cut

has pricegroup => (is => 'ro', isa => 'Str', required => '0');

=back

=head1 INTERNALS

=head2 columns

=over

=item pricegroup

=back

=cut

sub columns {
    my ($self) = @_;
    return [{col_id => 'pricegroup',
               type => 'href',
          href_base => 'pe.pl?action=edit&type=pricegroup&id=',
               name => $self->Text('Price Group') }];
}

=head2 header_lines

=over

=item partsgroup

=back

=cut

sub header_lines {
    my ($self) = @_;
    return [{name => 'partsgroup',
             text => $self->Text('Price Group') }];
}

=head2 name

Price Groups

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Price Groups');
}

=head1 METHODS

=head2 run_report

Populates rows

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'pricegroup__search');
    $_->{row_id} = $_->{id} for (@rows);
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
