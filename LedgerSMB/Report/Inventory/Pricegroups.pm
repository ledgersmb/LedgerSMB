=head1 NAME

LedgerSMB::Report::Inventory::Pricegroups - Pricegroup search for LedgerSMB

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Inventory::Pricegroups->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Inventory::Pricegroups;
use Moose;
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
    return [{col_id => 'pricegroup',
               type => 'href',
          href_base => 'pe.pl?action=edit&type=pricegroup&id=',
               name => LedgerSMB::Report::text('Price Group') }];
}

=head2 header_lines

=over

=item partsgroup

=back

=cut

sub header_lines {
    return [{name => 'partsgroup',
             text => LedgerSMB::Report::text('Price Group') }];
}

=head2 name

Price Groups

=cut

sub name {
    return LedgerSMB::Report::text('Price Groups');
}

=head1 METHODS

=head2 run_report

Populates rows

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'pricegroup__search');
    $_->{row_id} = $_->{id} for (@rows);
    $self->rows(\@rows);
}

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
