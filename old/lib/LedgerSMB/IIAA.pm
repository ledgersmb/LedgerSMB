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
    if ($form->{paidaccounts} and $form->{paidaccounts} > 0) {
        for my $i ( 1 .. $form->{paidaccounts} ) {

            if ( $form->{"paid_$i"} ) {
                # variables in same order as arguments of payment_post sproc
                my $datepaid = $form->{"datepaid_$i"};
                my $eca_class = ($form->{vc} eq 'vendor') ? 1 : 2;
                my $eca_id = $form->{"$form->{vc}_id"};
                my $curr = $form->{currency};
                my $exchangerate;
                # no 'notes'
                # no 'gl description'
                my ($cashaccno) = split( /--/, $form->{"$form->{ARAP}_paid_$i"} );
                my $amount =
                    LedgerSMB::PGNumber->from_input($form->{"paid_$i"})->to_db;
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

                $sth->execute($datepaid, $eca_class, $eca_id, $curr,
                              $exchangerate, undef, undef, $cashaccno,
                              [$amount], [0],
                              [$source], [$memo], [$trans_id], undef, undef,
                              undef, undef, undef, undef,

                              # Post payment lines as 'approved':
                              # the total transaction will be approved at some
                              # point; at that point, all lines will be
                              # considered to be approved too (unless they are
                              # explicitly *not* approved).
                              1)
                    or $form->dberror($sth->errstr);
            }
        }
    }
}


sub post_form_manual_tax {
    my ($self, $myconfig, $form, $sign, $pay_rec) = @_;
    my $dbh = $form->{dbh};
    my $invamount = 0;

    my $ac_sth = $dbh->prepare(
        "INSERT INTO acc_trans (chart_id, trans_id,
                                amount_bc, curr, amount_tc, source, memo)
                    VALUES ((select id from account where accno = ?),
                            ?, ?, ?, ?, ?, ?)"
        ) or $form->dberror($dbh->errstr);
    my $tax_sth = $dbh->prepare(
        "INSERT INTO tax_extended (entry_id, tax_basis, rate)
                    VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
        ) or $form->dberror($dbh->errstr);
    for my $taccno (split / /, $form->{taxaccounts}){
        my $taxamount;
        my $taxbasis;
        my $taxrate;
        my $fx = $form->{exchangerate} || 1;
        $taxamount = $form->parse_amount($myconfig,
                                         $form->{"mt_amount_$taccno"});
        $taxbasis = $form->parse_amount($myconfig,
                                        $form->{"mt_basis_$taccno"});
        $taxrate=$form->parse_amount($myconfig,$form->{"mt_rate_$taccno"});
        my $fx_taxamount = $taxamount * $fx;
        my $fx_taxbasis = $taxbasis * $fx;
        $form->{$pay_rec} += $fx_taxamount * $sign * -1;
        $invamount += $fx_taxamount;
        $ac_sth->execute($taccno, $form->{id}, $fx_taxamount * $sign,
                         $form->{defaultcurrency},
                         $fx_taxamount * $sign,
                         $form->{"mt_ref_$taccno"},
                         $form->{"mt_desc_$taccno"})
            or $form->dberror($ac_sth->errstr);
        $tax_sth->execute($fx_taxbasis * $sign, $taxrate)
            or $form->dberror($tax_sth->errstr);
    }
    $ac_sth->finish;
    $tax_sth->finish;

    return $invamount;
}


1;
