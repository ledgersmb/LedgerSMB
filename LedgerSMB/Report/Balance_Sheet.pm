=head1 NAME

LedgerSMB::Report::Balance_Sheet - The LedgerSMB Balance Sheet Report

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Balance_Sheet->new(%$request);
 $report->render($request);

=head1 DESCRIPTION

This report class defines the balance sheet functionality for LedgerSMB.   The
primary work is done in the database procedures, while this module largely
translates data structures for the report.

=cut

package LedgerSMB::Report::Balance_Sheet;
use Moose;
extends 'LedgerSMB::Report::Hierarchical';
with 'LedgerSMB::Report::Dates';

=head1 SEMI-PUBLIC METHODS

=head2 run_report()

This sets rows to an empty arrayref, and sets balance_sheet to the structure of 
the balance sheet. 

=cut

sub run_report {
    my ($self) = @_;
   
    my @lines = $self->call_dbmethod(funcname => 'report__balance_sheet');

    for my $line (@lines) {
        my $row_id = $self->rheads->map_path([ ( @{$line->{heading_path}},
                                               $line->{account_number})
                                             ]);
        my $col_id = $self->cheads->map_path([ 1 ]);
        $self->cell_value($row_id, $col_id, $line->{balance});
        $self->rheads->id_props($row_id, $line);
        $self->cheads->id_props($col_id, { description => 
                                               $self->to_date });
    }
    $self->rows([]);
}

=head2 template

Implements LedgerSMB::Report's abstract template method.

=cut

sub template {
    return "Reports/balance_sheet";
}

=head2 name

Implements LedgerSMB::Report's abstract 'name' method.

=cut

sub name {
    return 'Balance sheet';
}

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
