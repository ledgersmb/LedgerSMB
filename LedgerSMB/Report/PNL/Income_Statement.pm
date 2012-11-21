=head1 NAME

LedgerSMB::Report::PNL::Income_Statement - Basic Income Statement for LedgerSMB

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(%$request);
 $rpt->render($request);

=head1 DESCRIPTION

This provides the income statement report for LedgerSMB on 1.4 and later.

=cut

package LedgerSMB::Report::PNL::Income_Statement;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

Standard dates plus

=over

=item basis

This is either 'cash' or 'accrual' 

=cut

has basis => (is => 'ro', isa =>'Str', required => 1);


has '_cols' => (is => 'rw', isa => 'ArrayRef[Any]', required => 0);

has 'account_data' =>  (is => 'rw', isa => 'HashRef[Any]');

has 'comparisons'  =>  (is => 'rw', isa => 'ArrayRef[Any]');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

=cut

sub template { return 'Reports/PNL' }

=item name

=cut

sub name { return LedgerSMB::Report::text('Income Statement') }

=item header_lines

=cut

sub header_lines {
    return [{name => 'basis',
            text => LedgerSMB::Report::text('Reporting Basis') }];
}

=item columns

=cut

sub columns { return []  }

=back

=head1 METHODS

=cut

# private method
# report_base($from, $to)
# returns an array of hashrefs of report results.  Used in adding comparison
# as well as the main report

sub report_base {
    my ($self, $from_date, $to_date) = @_;
    die LedgerSMB::Report::text('Invalid Reporting Basis') 
           if ($self->basis ne 'accrual') and ($self->basis ne 'cash');
    my $procname = 'pnl__income_statement_' . $self->basis;
    return $self->exec_method({funcname => $procname});
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
        $data->{$r->{account_category}}->{$r->{account_number}} = {'main' => $r};
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
    my @rows = $self->report_base($self->from_date, $self->to_date);
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
