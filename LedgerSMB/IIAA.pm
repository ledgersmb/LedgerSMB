=head1 NAME

LedgerSMB::IIAA - Common code abstracted out of IS, IR and AA

=cut
#====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
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
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: Jim Rawlings <jim@your-dba.com>
#
#======================================================================
#
# Commonality between IR, IS and AA
#
#======================================================================


package IIAA;

use Math::BigFloat;
use warnings;
use diagnostics;
use strict;


sub process_form_payments {

    my ($self, $myconfig, $form) = @_;
    my $dbh = $form->{dbh};
    my $query = qq|
SELECT payment_post(?, ?, ?, ?, ?,
                    ?, ?, ARRAY[(select id from account where accno = ?)], ?, ?,
                    ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?)
|;

    my $sth = $dbh->prepare($query)
        or $form->dberror($dbh->errstr);
    
    # add paid transactions
    for $i ( 1 .. $form->{paidaccounts} ) {

        if ( $paid{fxamount}{$i} ) {
            # variables in same order as arguments of payment_post sproc
            my $datepaid = $form->{"datepaid_$i"};
            my $eca_class = ($form->{vc} eq 'vendor') ? 1 : 2;
            my $eca_id = $form->{"$form->{vc}_id"};
            my $curr = $form->{currency};
            my $exchangerate;
            # no 'notes'
            # no 'gl description'
            my ($cashaccno) = split( /--/, $form->{"${ARAP}_paid_$i"} );
            my $amount = $paid{amount}{$i}->to_db();
            # no 'cash approved'
            my $source = $form->{"source_$i"};
            my $memo = $form->{"memo_$i"};
            my $trans_id = $form->{id};
            # none of the in_op_*
            # ###Verify that there's no overpayment going on!!

            if ( $form->{currency} eq $form->{defaultcurrency} ) {
                $exchangerate = 1;
            }
            else {
                $exchangerate =
                    $form->parse_amount( $myconfig,
                                         $form->{"exchangerate_$i"} )->to_db();
            }
            @queryargs = ($datepaid, $eca_class, $eca_id, $curr, $exchangerate,
                          undef, undef, $cashaccno, [$amount], [0],
                          [$source], [$memo], [$trans_id], undef, undef,
                          undef, undef, undef, undef, 0);

            $sth->execute(@queryargs)
                or $form->dberror($sth->errstr);
        }
    }
}
