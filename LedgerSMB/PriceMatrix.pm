#=====================================================================
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
# Copyright (C) 2001
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has undergone  whitespace cleanup
#
#======================================================================
#
# Price Matrix module
#
#
#======================================================================

package PriceMatrix;

use strict;
use warnings;

sub price_matrix_query {
    my ( $dbh, $form ) = @_;

    my $query;
    my $sth;

    my @queryargs;
    my $transdate = $form->{dbh}->quote( $form->{transdate} );
    my $credit_id     = $form->{dbh}->quote( $form->{customer_id} );

    if ( $form->{customer_id} ) {
        my $defaultcurrency = $form->{dbh}->quote( $form->{defaultcurrency} );
        $query = qq|
                SELECT p.parts_id, p.credit_id AS entity_id,
                NULL AS pricegroup_id,
                p.pricebreak, p.sellprice, p.validfrom,
                p.validto, p.curr, NULL AS pricegroup,
                1 as priority
            FROM partscustomer p
            WHERE p.parts_id = ?
                AND coalesce(p.validfrom, $transdate) <=
                    $transdate
                AND coalesce(p.validto, $transdate) >=
                    $transdate
                AND p.credit_id = $credit_id

            UNION

                SELECT p.parts_id, p.credit_id AS entity_id,
                p.pricegroup_id,
                p.pricebreak, p.sellprice, p.validfrom,
                p.validto, p.curr, g.pricegroup, 2 AS priority
            FROM partscustomer p
            JOIN pricegroup g ON (g.id = p.pricegroup_id)
            JOIN entity_credit_account c ON (c.pricegroup_id = g.id)
            WHERE p.parts_id = ?
                AND coalesce(p.validfrom, $transdate) <=
                    $transdate
                AND coalesce(p.validto, $transdate) >=
                    $transdate
                AND c.id = $credit_id

            UNION

                SELECT p.parts_id, p.credit_id AS entity_id,
                p.pricegroup_id,
                p.pricebreak, p.sellprice, p.validfrom,
                p.validto, p.curr, g.pricegroup, 3 AS priority
            FROM partscustomer p
            LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
            WHERE p.credit_id = 0
                AND p.pricegroup_id = 0
                AND coalesce(p.validfrom, $transdate) <=
                    $transdate
                AND coalesce(p.validto, $transdate) >=
                    $transdate
                AND p.parts_id = ?

            ORDER BY priority LIMIT 1;
            |;
        $sth = $dbh->prepare($query) || $form->dberror($query);
    }
    elsif ( $form->{vendor_id} ) {

        # price matrix and vendor's partnumber
        $query = qq|
            SELECT partnumber, lastcost
            FROM partsvendor
            WHERE parts_id = ?
            AND credit_id = $credit_id|;
        $sth = $dbh->prepare($query) || $form->dberror($query);
    }

    $sth;
}

sub price_matrix {
    my ( $pmh, $ref, $transdate, $decimalplaces, $form, $myconfig ) = @_;
    my $customerprice;
    my $pricegroupprice;
    my $sellprice;
    my $mref;
    my %p = ();
    # depends if this is a customer or vendor
    if ( $form->{customer_id} ) {
        $pmh->execute( $ref->{id}, $ref->{id}, $ref->{id} );
    } elsif ( $form->{vendor_id} ) {
        $pmh->execute( $ref->{id} );
    } else {
        $form->error('Missing counter-party (customer or vendor)');
        return;
    }

    if ( $mref = $pmh->fetchrow_hashref('NAME_lc') ) {
       if ($form->{customer_id}){
            $form->db_parse_numeric(sth=>$pmh, hashref=>$mref);
            $sellprice = $mref->{sellprice} || $ref->{sellprice};
            if ($mref->{pricebreak}){
        $sellprice = $sellprice
                           - ($sellprice * ($mref->{pricebreak} / 100));
            }
            $ref->{sellprice} = $sellprice;
       } elsif ($form->{vendor_id}){
            $sellprice = $mref->{lastcost} || $ref->{sellprice};
            die $sellprice;
            $ref->{sellprice} = $sellprice;
       }
    }

}
1;
