=head1 NAME

LedgerSMB::DBObject::EOY: End of Year handling module

=head1 SYNOPSYS

This class contains methods for end of year entry.

=head1 BASIC PROPERTIES

=over

=item end_date specifies the end date for a closed period.

=item reference specifies the gl reference field associated with the account 
closure

=item description specifies the gl description field associated with the account
closure

=item retention_acc_id specifies the account id used as a retaining account.

=back

=head1 METHODS

=over

=cut

use strict;
package LedgerSMB::DBObject::EOY;
use base qw(LedgerSMB::DBObject);

=item $eoy->checkpoint_only();

This creates account checkpoints at $eoy->{end_date}.  This has two uses:
1)  Can be used to "close" books without zeroing income/expense accounts.  This
prevents data from being inserted for earlier dates.

2)  This can be used to improve performance by creating a "lookback" point.

=cut

sub checkpoint_only {
    my ($self) = @_;
   $self->exec_method(funcname => 'eoy_create_checkpoint');
   $self->{dbh}->commit;
}

=item $eoy->reopen_books()

This reverses any end of year transaction on $eoy->{end_date}, and deletes 
checkpoints for that day.

=cut

sub reopen_books {
    my ($self) = @_;
   $self->exec_method(funcname => 'eoy_reopen_books');
   $self->{dbh}->commit;
}

=item $eoy->close_books()

Requires all properies in BASIC PROPERTIES to be set.  This creates a gl 
yearend transaction, and moves income/expenses to the selected equity account
for retained earnings.

=cut

sub close_books {
    my ($self) = @_;
   $self->exec_method(funcname => 'eoy_close_books');
   $self->{dbh}->commit;
}

=item $eoy->list_earnings_accounts

Returns a list of equity accounts, and sets $eoy->{earnings_accounts} to a 
list of hashrefs.  These are used to select retained earnings accounts in 
closing books.

=cut

sub list_earnings_accounts{
    my ($self) = @_;
    my @results = $self->exec_method(funcname => 'eoy_earnings_accounts');
    $self->{earnings_accounts} = \@results;
    return @results;
}

1;

=back

=head1 COPYRYIGHT

Copyright (C) 2009 The LedgerSMB Core Team.  This may be re-used as permitted by
the GNU General Public License v 2 or at your option any later version.  Please
see included License.txt for details.
