
package LedgerSMB::Reconciliation::Parser::CAMT053;

=head1 NAME

LedgerSMB::Reconciliation::Parser::CAMT053 - SEPA Customer bank statement parser

=head1 DESCRIPTION

Implements the mapping from the ISO-20022 CAMT.053 XML message format
(account statement) to the input data for reconciliation.

=head1 METHODS

=cut

use strict;
use warnings;
use Moo;
with 'LedgerSMB::Reconciliation::Format';

use LedgerSMB::FileFormats::ISO20022::CAMT053;

=head2 process($fh)

Returns a reference to an array of entries extracted from the
transactions inn the ISO-20022/CAMT.053 XML file.

=cut

sub process {
    my ($self, $fh) = @_;

    my $camt053 = LedgerSMB::FileFormats::ISO20022::CAMT053->new($fh);
    return [
        map { my $sign = (lc($_->{credit_debit}) eq 'credit') ? -1 : 1;
              {
                  amount => $_->{amount} * $sign, # note signs reverse
                  date   => $_->{booking_date},
                  source => $_->{acc_id} // $_->{entry_id},
                  type   => "camt053 xml, $_->{currency}"
              }
        } $camt053->lineitems_simple ];
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
