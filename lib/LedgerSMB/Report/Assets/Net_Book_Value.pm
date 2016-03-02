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

package LedgerSMB::Report::Assets::Net_Book_Value;
use Moose;
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
    return
    [
          {type => 'text',
         col_id => 'id',
           name =>  LedgerSMB::Report::text('ID'), },

          {type => 'href',
         col_id => 'tag',
      href_base => 'asset.pl?action=ed&id=',
           name =>  LedgerSMB::Report::text('Tag'),},

          {type => 'text',
         col_id => 'description',
           name =>  LedgerSMB::Report::text('Description'), },

          {type => 'text',
         col_id => 'begin_depreciation',
           name =>  LedgerSMB::Report::text('In Svc'), },

          {type => 'text',
         col_id => 'method',
           name =>  LedgerSMB::Report::text('Method'),},

          {type => 'text',
         col_id => 'remaining_life',
           name =>  LedgerSMB::Report::text('Rem. Life'),},

          {type => 'text',
         col_id => 'basis',
           name =>  LedgerSMB::Report::text('Basis'),},

          {type => 'text',
         col_id => 'salvage_value',
           name =>  LedgerSMB::Report::text('(+) Salvage Value'),},

          {type => 'text',
         col_id => 'through_date',
           name =>  LedgerSMB::Report::text('Dep. Through'),},

          {type => 'text',
         col_id => 'accum_depreciation',
           name =>  LedgerSMB::Report::text('(-) Accum. Dep.'),},

          {type => 'text',
         col_id => 'net_book_value',
           name =>  LedgerSMB::Report::text('(=) NBV'),},

          {type => 'text',
         col_id => 'percent_depreciated',
           name =>  LedgerSMB::Report::text('% Dep.'),},
  ];
};


=head2 header_lines

None added

=cut

sub header_lines {
    return [];
}

=head2 name

Net Book Value

=cut

sub name {
    return LedgerSMB::Report->text('Net Book Value');
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
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
