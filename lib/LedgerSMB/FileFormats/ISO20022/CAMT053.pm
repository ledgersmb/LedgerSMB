package LedgerSMB::FileFormats::ISO20022::CAMT053;
use strict;
use warnings;

use XML::Simple;

=head1 NAME

LedgerSMB::FileFormats::ISO20022::CAMT053 - Parse SEPA CAMT053 files

=head1 SYNOPSIS

    LedgerSMB::FileFormats::ISO20022::CAMT053->new($filename);
    LedgerSMB::FileFormats::ISO20022::CAMT053->new($filecontents);

=head1 DESCRIPTION

This module provides basic management functions for CAMT053 files for LedgerSMB

=head1 AUTODETECTION

The constructor returns UNDEF if the file is not a CAMT053 docuent.

=head1 METHODS

=head2 new($spec)

You can pass in any input type specified by XML::Simple's XMLin method.

Specifically you can pass in a file name, an undef (always returns undef), or an
IO::Handle object.

=cut

sub new{
    my ($class, $spec) = @_;
    return unless defined $spec;
    my $raw = XMLin($spec);
    return unless $raw->{xmlns} and $raw->{xmlns} eq 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';
    return bless ({struct => $raw}, $class);
}

=head1 PROPERTIES

=head2 raw_struct

Returns the raw structure

=cut

sub raw_struct {
    my ($self) = @_;
    return $self->{struct}
}

=head2 lineitems_full

Returns a simple list of data structures representing the statement lines

=cut

sub lineitems_full {
    my ($self) = @_;
    return @{$self->raw_struct->{BkToCstmrStmt}->{Stmt}->{Ntry}};
}

=head2 lineitems_simple

Returns a flattened list with the following elements:

=over

=item entry_id

=item acc_id

=item counterparty_name

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
    return map {
        {
             entry_id          => $_->{NtryRef},
             acc_id            => $_->{AcctSvcrRef},
             amount            => $_->{Amt}->{content},
             currency          => $_->{Amt}->{Ccy},
             booked_date       => $_->{BookgDt}->{Dt},
             credit_debit      => _decode_crdt($_->{CdtDbtInd}),
        }
    } $self->lineitems_full;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
