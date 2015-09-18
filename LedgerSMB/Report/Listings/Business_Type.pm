=head1 NAME

LedgerSMB::Report::Listings::Business_Type - List the Business Types in
LedgerSMB

=head1 SYNPOPSIS

  my $report = LedgerSMB::Report::Listings::Business_Type->new(%$request);
  $report->render($request);

=head1 DESCRIPTION

This provides a simple list of business types, ordered alphabetically.

=head1 CRITERIA PROPERTIES

None

=cut

package LedgerSMB::Report::Listings::Business_Type;
use Moose;
extends 'LedgerSMB::Report';

=head1 STATIC METHODS

=over

=item columns

=over

=item description

=item discount

=back

=cut

sub columns {
    return [{
      col_id => 'description',
        type => 'href',
     p_width => '10',
        name => LedgerSMB::Report::text('Description'),
   href_base => 'am.pl?action=edit_business&id=',
    },
    {
      col_id => 'discount',
        type => 'text',
     p_width => '1',
        name => LedgerSMB::Report::text('Discount (%)'),
    }];
};

=item header_lines

None added

=cut

sub header_lines {
    return []
};

=item name

=cut

sub name {
    return LedgerSMB::Report::text('List of Business Types');
}

=back

=head1 METHODS

=head2 run_report()

Runs the report and returns the results for rendering.

=cut

sub run_report {
    my ($self) = @_;
    $self->manual_totals(1); #don't display totals
    my @rows = $self->call_dbmethod(funcname => 'business_type__list');
    for my $ref(@rows){
        $ref->{id} = $ref->{id};
        $ref->{discount} *= 100;
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
