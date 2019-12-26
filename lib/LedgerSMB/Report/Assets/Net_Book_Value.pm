
package LedgerSMB::Report::Assets::Net_Book_Value;

=head1 NAME

LedgerSMB::Report::Assets::Net_Book_Value - Fixed Asset Current Book Value
Report

=head1 SYNPOSIS

 my $report = LedgerSMB::Report::Assets::Net_Book_Value->new(%$request);
 $report->render($request);

=head1 DESCRIPTION

The Net Book Value report provides current information on the book value of
assets at the current date.  The net book value is the depreciable basis plus
the estimated salvage value, less accumulated depreciation.  This thus gives
a view of the current value left per asset, as they contribute to the specific
asset accounts.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

=head1 CRITERIA PROPERTIES

none

=head1 STATIC METHODS

=head2 columns

=over

=item id, id of asset

=item tag, text id of asset

=item description, text description of asset

=item begin_depreciation, date when asset begins to depreciate

=item method, short description of method.

=item remaining life, how much is left to depreciate

=item basis, amount that can be depreciated

=item salvage_value, amount expected to be recovered on salvage

=item accum_depreciation, amount depreciated so far

=item net_book_value, value still remaining as asset for accounting purposes

=item precent_depreciated, percent the asset has been depreciated.

=back

=cut

sub columns {
    my ($self) = @_;
    return
    [
          {type => 'text',
         col_id => 'id',
           name =>  $self->Text('ID'), },

          {type => 'href',
         col_id => 'tag',
      href_base => 'asset.pl?action=asset_edit&id=',
           name =>  $self->Text('Tag'),},

          {type => 'text',
         col_id => 'description',
           name =>  $self->Text('Description'), },

          {type => 'text',
         col_id => 'begin_depreciation',
           name =>  $self->Text('In Svc'), },

          {type => 'text',
         col_id => 'method',
           name =>  $self->Text('Method'),},

          {type => 'text',
         col_id => 'remaining_life',
           name =>  $self->Text('Rem. Life'),},

          {type => 'text',
         col_id => 'basis',
           name =>  $self->Text('Basis'),},

          {type => 'text',
         col_id => 'salvage_value',
           name =>  $self->Text('(+) Salvage Value'),},

          {type => 'text',
         col_id => 'through_date',
           name =>  $self->Text('Dep. Through'),},

          {type => 'text',
         col_id => 'accum_depreciation',
           name =>  $self->Text('(-) Accum. Dep.'),},

          {type => 'text',
         col_id => 'net_book_value',
           name =>  $self->Text('(=) NBV'),},

          {type => 'text',
         col_id => 'percent_depreciated',
           name =>  $self->Text('% Dep.'),},
  ];
};

=head2 name

Net Book Value

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Net Book Value');
}

=head1 METHODS

=head2 run_report

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'asset_nbv_report');
    for my $row(@rows){
        $row->{row_id} = $row->{id};
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
