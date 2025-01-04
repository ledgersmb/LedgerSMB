
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::FileFormats::OFX::BankStatement;

use XML::LibXML;

=head1 NAME

LedgerSMB::FileFormats::OFX::BankStatement - Parse OFX Bank Statement files

=head1 SYNOPSIS

    my $ofx = LedgerSMB::FileFormats::OFX::BankStatement->new($filecontents);
    my @transactions = $ofx->transactions;

=head1 DESCRIPTION

This module provides basic parsing and data extraction of OFX bank statement
files for LedgerSMB.

=head1 OFX SPECIFICATION

This parser has been created with reference to the Open Financial
Exchange Specification, available from
L<https://www.ofx.net/downloads/OFX%202.2.pdf>.

This document, as retrieved on 2020-03-29 carries the following licence:

A royalty-free, worldwide, and perpetual license is hereby granted to any
party to use the Open Financial Exchange Specification to make, use, and
sell products and services that conform to this Specification.

=head2 Statement Transactions

A C<STMTTRN> aggregate describes a single transaction. It identifies the type
of the transaction and the date it was posted. It can also
provide additional information to help recognize the
transaction: check number, payee name, and memo.

Each C<STMTTRN> contains an C<FITID> (Financial Institution Trasaction ID)
that the client can use to detect whether the transaction  has previously
been downloaded.

=head2 Transaction Types

The following C<TRNTYPE>s are specified:

CREDIT, DEBIT, INT, DIV, FEE, SRVCHG, DEP, ATM, POS, XFER, CHECK,
PAYMENT, CASH, DIRECTDEP, DIRECTDEBIT, REPEATPMT, OTHER.

=head2 Amounts

Amounts that do not represent whole numbers (for example, 540.32), must
include a decimal point or comma to indicate the start of the fractional
amount.

Amounts should not include any punctuation separating thousands, millions,
and so forth. The maximum value accepted depends on the client.

=head2 Transaction Sign

Transaction amounts are signed from the perspective of the customer.
For example, a credit card payment is positive while a credit card purchase
is negative.

=head2 Payee Name

Either C<NAME> or C<PAYEE> elements may be provided within a STMTTRN element,
but not both.

C<PAYEE> provides a complete billing address for a payee. C<NAME> will be
provided as one of its child elements.

=head1 AUTODETECTION

The constructor returns C<undef> if the file is not a OFX docuent.

=head1 METHODS

=head2 new($xml_string)

Pass in a string of XML data. Returns undef if the string is not valid XML or
not identified as a OFX document.

=cut

sub new {
    my ($class, $fh) = @_;
    return unless defined $fh;

    my ($dom, $is_ofx);
    try {
        binmode $fh; # remove all IO layers, as per the docs
        $dom = XML::LibXML->load_xml(IO => $fh);
        $is_ofx = $dom->find('/processing-instruction("OFX")')
    }
    catch ($e) { }

    return unless $dom and $is_ofx;

    return bless ({dom => $dom}, $class);
}


=head2 dom

Returns the XML::LibXML DOM tree representing the input xml.

=cut

sub dom {
    my ($self) = @_;
    return $self->{dom};
}


=head2 transactions

Returns a transaction list reference, each transaction being a hash with the
following elements:

  * amount
  * cleared_date
  * scn
  * type

=cut

sub transactions {
    my ($self) = @_;

    my $transactions = $self->dom->find('//STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN');

    my @transactions = map {{
        amount => $_->findvalue('TRNAMT') * -1,
        cleared_date => $_->findvalue('DTPOSTED'),
        scn => $_->findvalue('NAME'),
        type => 'OFX FITID:' . $_->findvalue('FITID'),
    }} @{$transactions};

    return \@transactions;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
