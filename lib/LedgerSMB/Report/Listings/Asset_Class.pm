
package LedgerSMB::Report::Listings::Asset_Class;

=head1 NAME

LedgerSMB::Report::Listings::Asset_Class - Asset Class listings

=head1 DESCRIPTION

Implements a listing of fixed asset classes

=head1 SYNPOSIS

 LedgerSMB::Report::Listings::Asset_Class->new(%$request)->render($request);

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 CRITERIA PROPERTIES

=head2 label

Partial match for asset class label

=head2 method

Exact match for method, by id, int

=head2 asset_account_id

id for asset account id, exact match

=head2 dep_account_id

id for depreciation account id, exact match

=cut

has label             => (is => 'ro', isa => 'Str', required => 0);
has method            => (is => 'ro', isa => 'Int', required => 0);
has asset_account_id  => (is => 'ro', isa => 'Int', required => 0);
has dep_account_id    => (is => 'ro', isa => 'Int', required => 0);

=head1 CONSTANT METHODS

=head2 columns

=over

=item id

=item label

=item method

=item asset_description

=item dep_description

=back

=cut

sub columns {
    my ($self) = @_;
    return [
   {  col_id => 'id',
        name => $self->Text('ID'),
        type => 'text' },
   {  col_id => 'label',
        name =>  $self->Text('Label'),
        type => 'href',
   href_base => 'asset.pl?action=edit_asset_class&id=', },
  {   col_id => 'method',
        name => $self->Text('Depreciation Method'),
        type => 'text' },
   {  col_id => 'asset_description',
        name => $self->Text('Asset Account'),
        type => 'text' },
   {  col_id => 'dep_description',
        name => $self->Text('Depreciation Account'),
        type => 'text' },
   ];
}

=head2 header_lines

Label and method

=cut

sub header_lines {
    my ($self) = @_;
    return [
       {name => 'label',
        text => $self->Text('Label') },
       {name => 'method',
        text => $self->Text('Depreciation Method') },
    ];
}


=head2 name

Asset Class List

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Asset Class List');
};

=head1 METHODS

=head2 run_report

Populates rows.

=cut

sub run_report {
    my ($self, $request) = @_;
    my @rows = $self->call_dbmethod(funcname => 'asset_class__search');
    for my $r (@rows){
        $r->{row_id} = $r->{id};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2014 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the included LICENSE.txt for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
