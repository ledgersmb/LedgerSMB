
package LedgerSMB::Reconciliation::ISO20022;

=head1 NAME

LedgerSMB::Reconciliation::ISO20022 - SEPA payment file processing

=head1 DESCRIPTION

Implements the mapping from the ISO-20022 CAMT.053 XML message format
(account statement) to the input data for reconciliation.

=head1 METHODS


=cut

use LedgerSMB::FileFormats::ISO20022::CAMT053;
use strict;
use warnings;


=head2 process_xml($content)

Processes the supplied ISO 20022 file content for reconciliation.

Returns an array of transaction lines.

=cut

sub process_xml {
    my ($contents) = @_;
    my $camt053 = LedgerSMB::FileFormats::ISO20022::CAMT053->new($contents);
    return unless $camt053;

    my @elements =
           map { my $sign = (lc($_->{credit_debit}) eq 'credit') ? -1 : 1;
              { amount => $_->{amount} * $sign, # note signs reverse
                cleared_date => $_->{booking_date},
                scn => $_->{acc_id} // $_->{entry_id},
                type => "camt053 xml, $_->{currency}" }
           } $camt053->lineitems_simple;
    return @elements;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;