
package LedgerSMB::Report::Listings::Business_Type;

=head1 NAME

LedgerSMB::Report::Listings::Business_Type - List the Business Types in
LedgerSMB

=head1 SYNPOPSIS

  my $report = LedgerSMB::Report::Listings::Business_Type->new(%$request);
  $report->render();

=head1 DESCRIPTION

This provides a simple list of business types, ordered alphabetically.

=head1 CRITERIA PROPERTIES

None

=cut

use Moose;
use namespace::autoclean;
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
    my ($self) = @_;
    return [{
      col_id => 'description',
        type => 'href',
     p_width => '10',
        name => $self->Text('Description'),
   href_base => 'am.pl?__action=edit_business&id=',
    },
    {
      col_id => 'discount',
        type => 'text',
     p_width => '1',
        name => $self->Text('Discount (%)'),
    }];
};

=item name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('List of Business Types');
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
        $ref->{row_id} = $ref->{id};
        $ref->{discount} *= 100;
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
