=head1 NAME

LedgerSMB::Report::Inventory::Partsgroups - Partsgroup search for LedgerSMB

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Inventory::Partsgroups->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Inventory::Partsgroups;
use Moose;
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
    return [{col_id => 'partsgroup',
               type => 'href',
          href_base => 'pe.pl?action=edit&type=partsgroup&id=',
               name => LedgerSMB::Report::text('Group') }];
}

=head2 header_lines

=over

=item partsgroup

=back

=cut

sub header_lines {
    return [{name => 'partsgroup',
             text => LedgerSMB::Report::text('Partsgroup') }];
}

=head2 name

Partsgroups

=cut

sub name {
    return LedgerSMB::Report::text('Partsgroups');
}

=head1 METHODS

=head2 run_report

Populates rows

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'partsgroup__search');
    $_->{row_id} = $_->{id} for (@rows);
    $self->rows(\@rows);
}

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;

1;
