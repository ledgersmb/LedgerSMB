
package LedgerSMB::Scripts::trial_balance;

=head1 NAME

LedgerSMB::Scripts::trial_balance - Trial Balance logic for LedgerSMB

=head1 SYNOPSIS

  LedgerSMB::Scripts::trial_balance::run($request);

=cut

use strict;
use warnings;

use LedgerSMB::Report::Trial_Balance;


=head1 DESCRIPTION

This module provides workflow scripts for trial balance functionality.  The
filter screen is displayed by LedgerSMB::Scripts::reports.

Please see LedgerSMB::Report::Trial_Balance for a list of criteria
that the methods expect.

=head1 METHODS

=over

=item run

Runs the trial balance. All criteria are applicable except id and desc.

=cut

sub run {
    my ($request) = @_;
    my @sl_columns = qw(account_number account_desc starting_balance debits
                        credits ending_balance);
    my @balance_columns = qw(account_number account_desc ending_balance_debit
                            ending_balance_credit);
    my $cols = \@sl_columns;
    $cols = \@balance_columns if $request->{tb_type} eq 'balance';
    $request->{"col_$_"} = 1 for @$cols;
    $request->{business_units} = [map {$request->{$_}}
                                 sort
                                 grep {$_ =~ /business_/}
                                 keys %$request];
    delete $request->{business_units}
    unless scalar @{$request->{business_units}};
    return $request->render_report(
        LedgerSMB::Report::Trial_Balance->new(
            %$request,
            formatter_options => $request->formatter_options,
            from_date => $request->parse_date( $request->{from_date} ),
            to_date => $request->parse_date( $request->{to_date} ),
        ));
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Scripts::reports

=item LedgerSMB::Report

=item LedgerSMB::Report::Trial_Balance

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
