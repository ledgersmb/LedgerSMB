
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::FileFormats::ISO20022::CAMT053;

use XML::LibXML;
use XML::LibXML::XPathContext;

=head1 NAME

LedgerSMB::FileFormats::ISO20022::CAMT053 - Parse SEPA CAMT053 files

=head1 SYNOPSIS

    my $camt = LedgerSMB::FileFormats::ISO20022::CAMT053->new($filecontents);
    my @transactions = $camt->lineitems_simple;

=head1 DESCRIPTION

This module provides basic parsing and data extraction of CAMT053 bank statement
files for LedgerSMB.

=head1 AUTODETECTION

The constructor returns C<undef> if the file is not a CAMT053 docuent.

=head1 METHODS

=head2 new($xml_string)

Pass in a string of XML data. Returns undef if the string is not valid XML or
not identified as a CAMT053 document.

=cut

sub new {
    my ($class, $fh) = @_;
    return unless defined $fh;

    my ($dom, $ns);
    try {
        binmode $fh; # remove all IO layers as per the docs
        $dom = XML::LibXML->load_xml(IO => $fh);
        $ns = $dom->documentElement->namespaceURI;
    }
    catch ($e) { }

    return unless $dom
        and $ns
        and $ns eq 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';

    return bless ({dom => $dom}, $class);
}

=head1 PROPERTIES

=head2 dom

Returns the XML::LibXML DOM tree representing the input xml.

=cut

sub dom {
    my ($self) = @_;
    return $self->{dom};
}


=head2 lineitems_simple

Returns a flattened list with the following elements:

=over

=item entry_id

=item acc_id

=item amount

=item currency

=item booked_date

=item credit_debit (valued either "credit" or "debit")

=back

=cut

sub _decode_crdt {
    my ($code) = @_;
    die "bad debit/credit code: $code"
          unless lc($code) =~ /^(crdt|dbit)$/;
    my $ret;
    $ret = 'credit' if lc($code) eq 'crdt';
    return $ret // 'debit';
}

sub lineitems_simple {
    my ($self) = @_;

    my $xpc = XML::LibXML::XPathContext->new;
    $xpc->registerNs(
        'camt' => 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02'
    );
    $xpc->setContextNode($self->dom);

    my $transactions = $xpc->find(
        '//camt:Document/camt:BkToCstmrStmt/camt:Stmt/camt:Ntry'
    );

    return map {
        $xpc->setContextNode($_);
        {
            entry_id     => $xpc->findvalue('camt:NtryRef'),
            acc_id       => $xpc->findvalue('camt:AcctSvcrRef'),
            amount       => $xpc->findvalue('camt:Amt'),
            currency     => $xpc->findvalue('camt:Amt/@Ccy'),
            booked_date  => $xpc->findvalue('camt:BookgDt/camt:Dt'),
            credit_debit => _decode_crdt(
                $xpc->findvalue('camt:CdtDbtInd')
            ),
        }
    } @{$transactions};
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
