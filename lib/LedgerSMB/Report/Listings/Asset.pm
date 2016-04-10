=head1 NAME

LedgerSMB::Report::Listings::Asset - Search Fixed Assets in LedgerSMB

=head1 SYNPOSIS

  LedgerSMB::Report::Listings::Asset->new(%$request)->render($request);

=cut

package LedgerSMB::Report::Listings::Asset;
use Moose;
extends 'LedgerSMB::Report';
use LedgerSMB::MooseTypes;

=head1 CRITERIA PROPERTIES

=head2 asset_class int

id of asset class

=head2 description text

Partial string search for description

=head2 tag

Partial string search for tag

=head2 purchase_date

Exact search on purchase date

=head2 purchase_value

Exact search on purchase value

=head2 usable_life

Exact search on usable life

=head2 salvage_value

Exact search on salvage value

=cut

has asset_class     => (is => 'ro', isa => 'Int', required => 0);
has description     => (is => 'ro', isa => 'Str', required => 0);
has tag             => (is => 'ro', isa => 'Str', required => 0);
has purchase_date   => (is => 'ro', isa => 'LedgerSMB::Moose::Date',coerce=> 1);
has purchase_value  => (is => 'ro', isa => 'LedgerSMB::Moose::Number',
                       coerce => 1);
has usable_life     => (is => 'ro', isa => 'Int', required => 0);
has salvage_value   => (is => 'ro', isa => 'LedgerSMB::Moose::Number',
                       coerce => 1);

=head1 CONSTANT METHODS

=head2 columns

=over

=item tag

=item description

=item purchase_date

=item purchase_value

=item usable_life

=back

=cut

sub columns {
    return [
     { col_id => 'tag',
         name => LedgerSMB::Report::text('Tag'),
         type => 'href',
    href_base => 'asset.pl?action=asset_edit&id=', },
    {  col_id => 'description',
         name => LedgerSMB::Report::text('Description'),
         type => 'text', },
    {  col_id => 'purchase_date',
         name => LedgerSMB::Report::text('Purchase Date'),
         type => 'text', },
    {  col_id => 'purchase_value',
         name => LedgerSMB::Report::text('Purchase Value'),
         type => 'text', },
    {  col_id => 'usable_life',
         name => LedgerSMB::Report::text('Usable Life'),
         type => 'text', },
   ];
}


=head2 header_lines

=over

=item tag

=item description

=item purchase_date

=item purchase_value

=back

=cut

sub header_lines {
    return  [
     { name => 'tag',         text => LedgerSMB::Report::text('Tag') },
     { name => 'description', text => LedgerSMB::Report::text('Description') },
     {name => 'purchase_date',text => LedgerSMB::Report::text('Purchase Date')},
     {name => 'purchase_value',
        text => LedgerSMB::Report::text('Purchase Value') },
   ];
}

=head2 name

Asset Listing

=cut

sub name { return LedgerSMB::Report::text('Asset Listing') }

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self, $request) = @_;
    my @rows = $self->call_dbmethod(funcname => 'asset__search');
    for my $r(@rows){
       $r->{row_id} = $r->{id};
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file may be re-used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.txt for details

=cut

__PACKAGE__->meta->make_immutable;

1;
