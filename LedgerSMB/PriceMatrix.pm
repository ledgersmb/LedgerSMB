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

sub price_matrix_query {
	my ($dbh, $form) = @_;

	my $query;
	my $sth;

	my @queryargs;

	if ($form->{customer_id}) {
		my $defaultcurrency = $form->{dbh}->quote(
				$form->{defaultcurrency});
		my $customer_id = $form->{dbh}->quote($form->{customer_id});
		$query = qq|
			SELECT p.id AS parts_id, 0 AS customer_id, 
				0 AS pricegroup_id, 0 AS pricebreak, 
				p.sellprice, NULL AS validfrom, NULL AS validto,
				(SELECT substr(curr,1,3) FROM defaults) AS curr,
			        '' AS pricegroup
	     		FROM parts p
			WHERE p.id = ?

			UNION

    			SELECT p.parts_id, p.customer_id, p.pricegroup_id, 
				p.pricebreak, p.sellprice, p.validfrom,
				p.valid_to, p.curr, g.pricegroup
			FROM partscustomer p
			LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
			WHERE p.parts_id = ?
			AND p.customer_id = $customer_id

			UNION

    			SELECT p.parts_id, p.customer_id, p.pricegroup_id, 
				p.pricebreak, p.sellprice, p.validfrom,
				p.valid_to, p.curr, g.pricegroup
			FROM partscustomer p
			LEFT JOIN pricegroup g ON (g.id = p.pricegroup_id)
			JOIN customer c ON (c.pricegroup_id = g.id)
			WHERE p.parts_id = ?
			AND c.id = $customer_id

			UNION

    			SELECT p.parts_id, p.customer_id, p.pricegroup_id, 
				p.pricebreak, p.sellprice, p.validfrom,
				p.valid_to, p.curr, g.pricegroup
			FROM partscustomer p
			WHERE p.customer_id = 0
			AND p.pricegroup_id = 0
			AND p.parts_id = ?

			ORDER BY customer_id DESC, pricegroup_id DESC, 
				pricebreak
			|;
		$sth = $dbh->prepare($query) || $form->dberror($query);
	} elsif ($form->{vendor_id}) {
		my $vendor_id = $form->{dbh}->quote($form->{vendor_id});
		# price matrix and vendor's partnumber
		$query = qq|
			SELECT partnumber
			FROM partsvendor
			WHERE parts_id = ?
			AND vendor_id = $vendor_id|;
		$sth = $dbh->prepare($query) || $form->dberror($query);
	}
  
	$sth;
}


sub price_matrix {
	my ($pmh, $ref, $transdate, $decimalplaces, $form, $myconfig) = @_;
	$ref->{pricematrix} = "";
	my $customerprice;
	my $pricegroupprice;
	my $sellprice;
	my $mref;
	my %p = ();
  
	# depends if this is a customer or vendor
	if ($form->{customer_id}) {
		$pmh->execute($ref->{id}, $ref->{id}, $ref->{id}, $ref->{id});

		while ($mref = $pmh->fetchrow_hashref(NAME_lc)) {

			# check date
			if ($mref->{validfrom}) {
				next if $transdate < $form->datetonum(
					$myconfig, $mref->{validfrom});
			}
			if ($mref->{validto}) {
				next if $transdate > $form->datetonum(
					$myconfig, $mref->{validto});
			}

			# convert price
			$sellprice = $form->round_amount($mref->{sellprice} 
				* $form->{$mref->{curr}}, $decimalplaces);
      
			if ($mref->{customer_id}) {
				$ref->{sellprice} = $sellprice 
					if !$mref->{pricebreak};
				$p{$mref->{pricebreak}} = $sellprice;
				$customerprice = 1;
			}

			if ($mref->{pricegroup_id}) {
				if (! $customerprice) {
					$ref->{sellprice} = $sellprice 
						if !$mref->{pricebreak};
					$p{$mref->{pricebreak}} = $sellprice;
				}
				$pricegroupprice = 1;
			}

			if (!$customerprice && !$pricegroupprice) {
				$p{$mref->{pricebreak}} = $sellprice;
			}

		}
		$pmh->finish;

		if (%p) {
			if ($ref->{sellprice}) {
				$p{0} = $ref->{sellprice};
		}
			for (sort { $a <=> $b } keys %p) { 
				$ref->{pricematrix} .= "${_}:$p{$_} "; 
			}
		} else {
			if ($init) {
				$ref->{sellprice} = $form->round_amount(
					$ref->{sellprice}, $decimalplaces);
			} else {
				$ref->{sellprice} = $form->round_amount(
					$ref->{sellprice} * 
						(1 - $form->{tradediscount}), 
						$decimalplaces);
			}
			$ref->{pricematrix} = "0:$ref->{sellprice} " 
				if $ref->{sellprice};
		}
		chop $ref->{pricematrix};

	}


	if ($form->{vendor_id}) {
		$pmh->execute($ref->{id});
    
		$mref = $pmh->fetchrow_hashref(NAME_lc);

		if ($mref->{partnumber} ne "") {
			$ref->{partnumber} = $mref->{partnumber};
		}

		if ($mref->{lastcost}) {
			# do a conversion
			$ref->{sellprice} = $form->round_amount(
				$mref->{lastcost} * $form->{$mref->{curr}}, 
				$decimalplaces);
		}
		$pmh->finish;

		$ref->{sellprice} *= 1;

		# add 0:price to matrix
		$ref->{pricematrix} = "0:$ref->{sellprice}";

	}

}
1;
