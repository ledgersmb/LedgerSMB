
#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Simple TrustCommerce API using Net::TCLink

package LedgerSMB::CreditCard::TrustCommerce;
use LedgerSMB::CreditCard::Config;
use LedgerSMB::CreditCard::TrustCommerce::Config;
use Net::TCLink;

$debug = $1;

sub sale {
    $form           = shift @_;
    $params{action} = 'sale';
    $params{amount} = $form->{amount} * 100;
    $params{track1} = $form->{track1};
    $params{track2} = $form->{track2};
    &process;
}

sub process {
    for ( keys %params ) {
        print "$_=  " . $params{$_} . "\n";
    }
    my %result = Net::TCLink::send( \%params );
    $form->{status} = $result{status};
    if ( $result{status} eq 'decline' ) {
        $form->{declinetype} = $result{declinetype};
        $form->{declinemsg}  = $declinemsg{ $result{declinetype} };
    }
    $form->{ccauth} = $result{transID};

    # log transID and status
    print STDERR "Info: TCLink CC AUTH transID $result{transid} returned "
      . "status $result{status}:$result{declinetype}:$result{baddata}:"
      . "$result{errortype}\n";
    if ($debug) {
        print STDERR "Full Result:\n";

        for ( keys %result ) {
            print STDERR "$_=  " . $result{$_} . "\n";
        }
    }

    %result;
}

sub credit {
    $form = shift @_;
    my %params = %baseparams;
    $params{transid} = $form->{transid};
    $params{amount}  = $form->{amount};
    &process;
}

%declinemsg = (
    decline      => 'Transaction declined by bank',
    avs          => 'AVS failed:  Address and/or Zip mismatch',
    cvv          => 'CVV2 Failure:  Check the CVV2 number and try again',
    call         => 'Call customer service number on card to get authcode',
    expiredcard  => 'This card has expired',
    carderror    => 'This card number is invalid.',
    authexpired  => 'The authorization expired.  Can not postauth.',
    fraud        => 'CrediGuard Fraud Score exceeded desired threshold',
    blacklist    => 'CrediGuard Declined: blacklisted this transaction.',
    velocity     => 'Crediguard declined:  Too many transactions',
    dailylimit   => 'Too many transactions in a day.',
    weeklylimit  => 'Too many transactions in a week',
    monthlylimit => 'Too many transactions in a month'
);

1;
