
package LedgerSMB::Reconciliation::Parser::OFX;

=head1 NAME

LedgerSMB::Reconciliation::Parser::OFX - Open Finance eXchange format bank statement

=head1 DESCRIPTION


=head1 METHODS


=cut

use strict;
use warnings;
use Moo;
with 'LedgerSMB::Reconciliation::Format';

use LedgerSMB::FileFormats::OFX::BankStatement;

=head2 process($fh)

=cut

sub process {
    my ($self, $fh) = @_;

    my $ofx = LedgerSMB::FileFormats::OFX::BankStatement->new($fh);
    return $ofx->transactions;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
