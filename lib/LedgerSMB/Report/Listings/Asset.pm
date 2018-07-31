
package LedgerSMB::Report::Listings::Asset;

=head1 NAME

LedgerSMB::Report::Listings::Asset - Search Fixed Assets in LedgerSMB

=head1 DESCRIPTION

Implements a listing of individual assets from the fixed asset accounting
subledger.

=head1 SYNPOSIS

  LedgerSMB::Report::Listings::Asset->new(%$request)->render($request);

=cut

use Moose;
use namespace::autoclean;
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
    my ($self) = @_;
    return [
     { col_id => 'tag',
         name => $self->Text('Tag'),
         type => 'href',
    href_base => 'asset.pl?action=asset_edit&id=', },
    {  col_id => 'description',
         name => $self->Text('Description'),
         type => 'text', },
    {  col_id => 'purchase_date',
         name => $self->Text('Purchase Date'),
         type => 'text', },
    {  col_id => 'purchase_value',
         name => $self->Text('Purchase Value'),
         type => 'text', },
    {  col_id => 'usable_life',
         name => $self->Text('Usable Life'),
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
    my ($self) = @_;
    return  [
     { name => 'tag',         text => $self->Text('Tag') },
     { name => 'description', text => $self->Text('Description') },
     {name => 'purchase_date',text => $self->Text('Purchase Date')},
     {name => 'purchase_value',
        text => $self->Text('Purchase Value') },
   ];
}

=head2 name

Asset Listing

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Asset Listing');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self, $request) = @_;
    my @rows = $self->call_dbmethod(funcname => 'asset__search');
    for my $r(@rows){
       $r->{row_id} = $r->{id};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file may be re-used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.txt for details

=cut

__PACKAGE__->meta->make_immutable;

1;
