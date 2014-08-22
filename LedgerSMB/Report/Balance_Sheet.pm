=head1 NAME

LedgerSMB::Report::Balance_Sheet - The LedgerSMB Balance Sheet Report

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Balance_Sheet->new(%$request);
 $report->render($request);

=head1 DESCRIPTION

This report class defines the balance sheet functionality for LedgerSMB.   The
primary work is done in the database procedures, while this module largely translates data structures for the report.

=cut

package LedgerSMB::Report::Balance_Sheet;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

=over

=item to_date LedgerSMB::PGDate

=back

=head1 INTERNAL PROPERTIES

=head2 headings

This stores the account headings for handling the hierarchy in a single hashref

=cut

has 'headings' => (is => 'rw', isa => 'HashRef[Any]', required => 0);

=head2 balance_sheet

This is the hashref that holds the main balance sheet data structure

=cut

has 'balance_sheet' => (is => 'rw', isa => 'HashRef[Any]', required => 0);

=head2 comparisons

An arrayref of hashrefs, each is:

=over 

=item through_date

=item index

A hashref of hashref in the form of account_number => balance

=back

=cut

has 'comparisons' => (is => 'rw', isa => 'ArrayRef[Any]', required => 0, default => sub { return [] });

=head1 STATIC METHODS

=over

=item columns

Returns no columns since this is hardwired into the template

=cut

sub columns {
    return [];
};

=item header_lines

Returns none since this is not applicable to this.

=cut 

sub header_lines {
    return [];
}



=item name

Returns the localized string 'Balance Sheet'

=cut

sub name {
    return LedgerSMB::Report::text('Balance Sheet');
}

=item template

Returns 'Reports/balance_sheet'

=cut

sub template {
    return 'Reports/balance_sheet';
}

=back

=head1 SEMI-PUBLIC METHODS

=head2 run_report()

This sets rows to an empty hashref, and sets balance_sheet to the structure of 
the balance sheet. 

=cut

sub run_report {
    my ($self) = @_;
    my @headings = $self->call_dbmethod(funcname => 'account__all_headings');
    my $head = {};
    $head->{$_->{accno}} = $_ for (@headings);
   
    my @lines = $self->call_dbmethod(funcname => 'report__balance_sheet');

    my $sheet = {A => { # Assets
                       lines => [], 
                       total => 0, },
                 L => { # Liabilities 
                       lines => [], 
                       total => 0, },
                 Q => { # Equity 
                       lines => [], 
                       total => 0, },
                 ratios => {},
    };
    for my $ref(@lines){
        my $cat = $ref->{account_category};
        push @{$sheet->{$cat}->{lines}},  $ref;
        $sheet->{$cat}->{total} += $ref->{balance}; 
    }
    $sheet->{ratios}->{AL} = $sheet->{A}->{total} / $sheet->{L}->{total} 
        if $sheet->{L}->{total};
    $sheet->{ratios}->{AQ} = $sheet->{A}->{total} / $sheet->{Q}->{total} 
        if $sheet->{Q}->{total};
    $sheet->{ratios}->{QL} = $sheet->{Q}->{total} / $sheet->{L}->{total} 
        if $sheet->{L}->{total};
    $sheet->{total_LQ} = $sheet->{L}->{total} + $sheet->{Q}->{total};
    $self->headings($head);
    $self->balance_sheet($sheet);
    $self->rows([]);
}

=head2 add_comparison($balance_sheet)

Adds a comparison to the current balance sheet.  Among other things it checks 
the sheet for new account keys and adds them.

=cut

sub add_comparison{
    my ($self, $comparison) = @_;
    my $old_sheet = $self->balance_sheet;
    my $new_sheet = $comparison->balance_sheet;
    my $comparisons = $self->comparisons;
    my $idx = {};
    for my $type (('A', 'L', 'Q')){
        for my $line (@{$new_sheet->{$type}->{lines}}){
            $idx->{$line->{account_number}} = $line->{balance};
            my $found = 0;
            for my $l2 (@{$old_sheet->{$type}->{lines}}){
               $found = 1 if $l2->{account_number} eq $line->{account_number};
            }
            push @{$old_sheet->{$type}->{lines}}, 
               {account_number => $line->{account_number},
                account_desc   =>  $line->{account_desc},
                    balance    => '---' } unless $found;
        }
    }
    my $comparison_hash = {     to_date => $comparison->to_date,
                                  index => $idx,
                                 totals => {A => $new_sheet->{A}->{total},
                                            L => $new_sheet->{L}->{total},
                                            Q => $new_sheet->{Q}->{total},
                                           LQ => $new_sheet->{total_LQ}, }};
    push @$comparisons, $comparison_hash;
    $self->comparisons($comparisons);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
