=head1 NAME

LedgerSMB::Report::PNL - Profit and Loss Reporting Base Class for LedgerSMB

=head1 SYNPOSIS

 use Moose;
 extends LedgerSMB::Report::PNL;

=head1 DESCRIPTION

This provides the common profit and loss reporting functions for LedgerSMB 1.4 
and later.

=cut

package LedgerSMB::Report::PNL;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

Standard dates.  Additional fields can be added by child reports.

=cut

=head1 Datastore Properties

=over

=item account_data

This is a hash with three keys:  I, E, and totals.

I and E contain hashes where each property is formed from the pnl_line type from
the database for each interval.  Totals contains three totals for each 
interval:  I, E, and total.

By default the only interval listed is "main".  The others are stored in
comparisons and comparisons are added using the "add_comparison" method.

=cut

has 'account_data' =>  (is => 'rw', isa => 'HashRef[Any]');

=item gifi

Boolean, true if it is a gifi report.

=cut

has gifi => (is => 'rw', isa => 'Bool');

=item comparisons

This stores a list of comparison itnervals, each is a hashref with the following
keys:

=over

=item label

This is the label for the comparison, used for coordinating with account_data 
above

=item from_date

=item to_date

=back

=cut

has 'comparisons'  =>  (is => 'rw', isa => 'ArrayRef[Any]');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

This may be overridden by child reports.

=cut

sub template { return 'Reports/PNL' }

=item columns

=cut

sub columns { [{col_id => 'amount',
                money => 1  }]
}


=back

=head1 METHODS

=cut

# private method
# _merge_rows(arrayref $rows, string $label, report $report)

sub _merge_rows {
    my $self = shift @_;
    my $label = shift @_;
    my @rows = @_;

    my $data = $self->account_data;
    $data ||= {};
    my $max_depth = 0;
    for my $r (@rows){
	my $headings = $r->{heading_path};
	$max_depth = ($max_depth >= scalar(@{$headings})) ? $max_depth : scalar(@{$headings});
    }
    for my $r (@rows){
        $data->{$r->{accno}} = { $label => $r,
				 info => $r,
				 max_depth => $max_depth,
				 depth => $#{$r->{heading_path}},
	};
    }
    $self->account_data($data);
}

sub _transform_gifi {
    my @rows = @_;
    my %hashamount;
    my @xformed_rows =  map { {%$_, 
                               account_number => $_->{gifi}, 
                               account_description => $_->{gifi_description}} } @rows;
    $hashamount{I} = { map { 
                       ($_->{gifi},  {%$_})
                     } grep {$_->{account_category} eq 'I' and $_->{gifi}} @xformed_rows};
    $hashamount{E} = { map { 
                       ($_->{gifi}, {%$_})
                     } grep {$_->{account_category} eq 'E' and $_->{gifi}} @xformed_rows};
    for my $cat (keys %hashamount){
        for (keys %{$hashamount{$cat}}){
            $hashamount{$cat}->{$_}->{amount} = 0;
        }
    }
    $hashamount{$_->{account_category}}->{$_->{gifi}}->{amount} 
               += $_->{amount} for @xformed_rows;
    return (sort(values %{$hashamount{I}})), (sort (values %{$hashamount{E}}));
}


=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->report_base();
    @rows = _transform_gifi(@rows) if $self->gifi;
    $self->rows(\@rows);
    $self->_merge_rows('main', @rows);
    return @rows;
}

=item add_comparison($from, $to)

Adds a comparison.

=cut

sub add_comparison {
    my ($self, $new_pnl) = @_;
    my $comparisons = $self->comparisons;
    $comparisons ||= [];
    my $old_ad = $self->account_data;
    my $new_ad = $new_pnl->account_data;
    for my $cat (qw(I E)){
       for my $k (keys %{$new_ad->{$cat}}){
           $old_ad->{$cat}->{$k}->{main}->{account_description} 
             ||=  $new_ad->{$cat}->{$k}->{main}->{account_description};
       }
    }
    push @$comparisons, {from_date => $new_pnl->from_date, 
                           to_date => $new_pnl->to_date,
                      account_data => $new_pnl->account_data,
                         }; 
    $self->comparisons($comparisons);
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
