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

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

This may be overridden by child reports.

=cut

sub template { return 'Reports/PNL' }

=item columns

=cut

sub columns { return []  }

=back

=head1 METHODS

=cut

# private method
# report_base($from, $to)
# returns an array of hashrefs of report results.  Used in adding comparison
# as well as the main report.  To be overridden.

sub report_base {
}

# private method
# _merge_rows(arrayref $rows, string $label, report $report)

sub _merge_rows {
    my $self = shift @_;
    my $label = shift @_;
    my @rows = @_;

    my $data = $self->account_data;
    $data ||= $data = {'I' => {}, 'E' => {}};
    for my $r (@rows){
        $data->{$r->{account_category}}->{$r->{account_number}} = {$label => $r};
        $data->{$r->{account_category}}->{$r->{account_number}}->{info} = $r;
    }
    my $i_total = 0;
    my $e_total = 0;
    my $total;
    for my $k (keys %{$data->{I}}){
       $i_total += $data->{I}->{$k}->{$label}->{amount}; 
    }
    for my $k (keys %{$data->{E}}){
       $e_total += $data->{E}->{$k}->{$label}->{amount}; 
    }
    $data->{totals}->{$label}->{I} = $i_total;
    $data->{totals}->{$label}->{E} = $e_total;
    $data->{totals}->{$label}->{total} = $i_total - $e_total;
    $self->account_data($data);
}

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->report_base();
    $self->rows(\@rows);
    $self->_merge_rows('main', @rows);
    return @rows;
}

=item add_comparison($from, $to)

Adds a comparison.

=cut

sub add_comparison {
    my ($self, $label, $from, $to) = @_;
    my %attributes = %{ $self->meta->get_attribute_map };
    my %new_data;
    while (my ($name, $attribute) = each %attributes) { 
        my $reader = $attribute->get_read_method;
        $new_data{$name} = $self->$reader;
    }
    $new_data{from_date} = $from;
    $new_data{to_date} = $to;
    my $new_report = $self->new(%new_data);
    my @rows = $new_report->run_report;
    my $comparisons = $self->comparisons;
    $comparisons ||= [];
    push $comparisons, {label => $label, from_date => $from, to_date => $to}; 
    $self->_merge_rows($label, @rows);
}

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
