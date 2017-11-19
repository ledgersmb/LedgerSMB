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

=head1 NAME

PriceMatrix - Customer/vendor specific price determination

=head1 SYNOPSIS

  my $sth = PriceMatrix::price_matrix_query( $dbh, $form );
  PriceMatrix::price_matrix( $sth, $ref, $transdate, $form, \%myconfig);

=head1 DESCRIPTION

Very much old_code we want to part with


=cut

use strict;
use warnings;


=head1 FUNCTIONS

=over

=item price_matrix_query( $dbh, $form )

Returns a DBI statement handle from $dbh, based on the values provided in $form

=cut

sub price_matrix_query {
    my ( $dbh, $form ) = @_;

    my $sth;

    if ( $form->{customer_id} ) {
        $sth = $dbh->prepare('
            SELECT * FROM pricematrix__for_customer(?, ?, ?, ?, ?) 
        ') || $form->dberror('pricematrix__for_customer');
    }
    elsif ( $form->{vendor_id} ) {

        $sth = $dbh->prepare(
           'select * from pricematrix__for_vendor(?, ?)
            ORDER BY lastcost DESC' # pessimistic
        ) || $form->dberror('pricematrix__for_vendor');
    }

    $sth;
}


=item price_matrix( $sth, $ref, $transdate, $decimalplaces, $form \%myconfig)

Updates $ref with the price matrix outcomes given $transdate and $form.

=cut

sub price_matrix {
    my ( $pmh, $ref, $transdate, $decimalplaces, $form, $myconfig) = @_;
    return if $form->{id};
    my $sellprice;
    my $mref;
    my %p = ();
    my $qty;
    # depends if this is a customer or vendor
    if ( $form->{customer_id} ) {
        if ($form->{rowcount} and not $form->{qtycache}){
           $form->{qtycache} = { map {$form->{"id_$_"} => 0 } (1 .. $form->{rowcount}) };
           $form->{qtycache}->{$form->{"id_$_"}} += $form->{"qty_$_"} for (1 .. $form->{rowcount} - 1);
        }
        $qty = $form->{qtycache}->{$ref->{id}} || 0;
        my $qty2 = $form->{"qty_$form->{rowcount}"} || 1; # default qty
        $pmh->execute( $form->{customer_id}, $ref->{id},
                       $form->{transdate}, $qty + $qty2, $form->{currency})
            or $form->dberror($pmh->errstr);
    } elsif ( $form->{vendor_id} ) {
        $pmh->execute( $form->{vendor_id}, $ref->{id} )
            or $form->dberror($pmh->errstr);
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
            if ($mref->{qty} > ($form->{qtycache}->{$ref->{id}} // 0)){
                for my $i (1 .. $form->{rowcount}){
                    $form->{"sellprice_$i"} = $sellprice if $ref->{id} == $form->{"id_$i"};
                    $form->{"sellprice_$form->{rowcount}"} = $sellprice if $form->{rowcount};
                }
            }
       } elsif ($form->{vendor_id}){
            $sellprice = $mref->{lastcost} || $ref->{sellprice};
            $ref->{sellprice} = $sellprice;
       }
    }
}

=back

=cut

1;
