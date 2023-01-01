
package LedgerSMB::Reconciliation::Format;

=head1 NAME

LedgerSMB::Reconciliation::Format - Role for reconciliation input parsers

=head1 DESCRIPTION

This is a Moo role defining the API to adhere to for classes which serve
as reconciliation statement parsers. For examples on how to write custom
parsers, please check out e.g. L<LedgerSMB::Reconciliation::Parser::CSV>.

=cut

use strict;
use warnings;
use Moo::Role;


=head1 ATTRIBUTES

=head2 name

This attribute holds a string containing the name of the configuration the input
parser is known by. The same input parser may be used with different configurations,
leading to multiple instances of the same class.

=cut

my $unnamed = 0;

has name => (is => 'ro', default => sub { 'Unnamed ' . $unnamed++ });

=head1 REQUIRED METHODS

=head2 process($fh)

Takes as its argument a file handle from which it reads the input provided by the
user in the format.

Returns a reference to an array of hashes to be used for reconciliation, holding
the following keys per hash:

=over

=item amount

Either a L<LedgerSMB::PGNumber> or a string containing a number without thousands
separators and the C<.> (dot) as the decimal separator.

=item date

Eithe a L<LedgerSMB::PGDate> or a string in ISO-8601 date format (YYYY-MM-DD).

=item source

Reference or identifier by which the transaction is known on the bank statement,
used to find the same transaction in the ledger.

=item type

Information classifying the transaction; e.g. Cash, ACH, etc.

=back

=cut

requires 'process';


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
