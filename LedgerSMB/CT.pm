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
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# backend code for customers and vendors
#
#======================================================================

package CT;


sub create_links {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect($myconfig);
	my $query;
	my $sth;
	my $ref;
	my $arap = ($form->{db} eq 'customer') ? "ar" : "ap";
	my $ARAP = uc $arap;

	if ($form->{id}) {
		$query = qq|SELECT ct.*, b.description AS business, s.*,
						   e.name AS employee, g.pricegroup AS pricegroup,
						   l.description AS language, ct.curr
					  FROM $form->{db} ct
				 LEFT JOIN business b ON (ct.business_id = b.id)
				 LEFT JOIN shipto s ON (ct.id = s.trans_id)
				 LEFT JOIN employee e ON (ct.employee_id = e.id)
				 LEFT JOIN pricegroup g ON (g.id = ct.pricegroup_id)
				 LEFT JOIN language l ON (l.code = ct.language_code)
					 WHERE ct.id = $form->{id}|;

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		$ref = $sth->fetchrow_hashref(NAME_lc);
		for (keys %$ref) { $form->{$_} = $ref->{$_} }
		$sth->finish;

		# check if it is orphaned
		$query = qq|SELECT a.id
					  FROM $arap a
					  JOIN $form->{db} ct ON (a.$form->{db}_id = ct.id)
					 WHERE ct.id = $form->{id}

					 UNION

					SELECT a.id
					  FROM oe a
					  JOIN $form->{db} ct ON (a.$form->{db}_id = ct.id)
					 WHERE ct.id = $form->{id}|;

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		unless ($sth->fetchrow_array) {
			$form->{status} = "orphaned";
		}

		$sth->finish;

		# get taxes for customer/vendor
		$query = qq|SELECT c.accno
					  FROM chart c
					  JOIN $form->{db}tax t ON (t.chart_id = c.id)
					 WHERE t.$form->{db}_id = $form->{id}|;

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			$form->{tax}{$ref->{accno}}{taxable} = 1;
		}

		$sth->finish;

	} else {

		($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);

		$query = qq|SELECT current_date FROM defaults|;
		($form->{startdate}) = $dbh->selectrow_array($query);

	}

	# get tax labels
	$query = qq|SELECT DISTINCT c.accno, c.description
				  FROM chart c
				  JOIN tax t ON (t.chart_id = c.id)
				 WHERE c.link LIKE '%${ARAP}_tax%'
			  ORDER BY c.accno|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{taxaccounts} .= "$ref->{accno} ";
		$form->{tax}{$ref->{accno}}{description} = $ref->{description};
	}

	$sth->finish;
	chop $form->{taxaccounts};


	# get business types ## needs fixing, this is bad (SELECT * ...) with order by 2. Yuck 
	$query = qq|SELECT *
				  FROM business
			  ORDER BY 2|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_business} }, $ref;
	}

	$sth->finish;

	# employees/salespersons
	$form->all_employees($myconfig, $dbh, undef, ($form->{vc} eq 'customer') ? 1 : 0);

	# get language ## needs fixing, this is bad (SELECT * ...) with order by 2. Yuck  
	$query = qq|SELECT *
				  FROM language
			  ORDER BY 2|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_language} }, $ref;
	}

	$sth->finish;

	# get pricegroups ## needs fixing, this is bad (SELECT * ...) with order by 2. Yuck  
	$query = qq|SELECT *
				  FROM pricegroup
			  ORDER BY 2|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_pricegroup} }, $ref;
	}

	$sth->finish;

	# get currencies
	$query = qq|SELECT curr AS currencies
				  FROM defaults|;

	($form->{currencies}) = $dbh->selectrow_array($query);

	$dbh->disconnect;

}


sub save_customer {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);
	my $query;
	my $sth;
	my $null;

	# remove double spaces
	$form->{name} =~ s/  / /g;
	# remove double minus and minus at the end
	$form->{name} =~ s/--+/-/g;
	$form->{name} =~ s/-+$//;

	# assign value discount, terms, creditlimit
	$form->{discount} = $form->parse_amount($myconfig, $form->{discount});
	$form->{discount} /= 100;
	$form->{terms} *= 1;
	$form->{taxincluded} *= 1;
	$form->{creditlimit} = $form->parse_amount($myconfig, $form->{creditlimit});
	if (!$form->{creditlimit}){
		$form->{creditlimit} = 0;
	}


	if ($form->{id}) {
		$query = qq|DELETE FROM customertax
						  WHERE customer_id = $form->{id}|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|DELETE FROM shipto
						  WHERE trans_id = $form->{id}|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|SELECT id 
					  FROM customer
					 WHERE id = $form->{id}|;

		if (! $dbh->selectrow_array($query)) {
			$query = qq|INSERT INTO customer (id)
						VALUES ($form->{id})|;

			$dbh->do($query) || $form->dberror($query);
		}

		# retrieve enddate
		if ($form->{type} && $form->{enddate}) {
			my $now;
			$query = qq|SELECT enddate, current_date AS now FROM customer|;
			($form->{enddate}, $now) = $dbh->selectrow_array($query);
			$form->{enddate} = $now if $form->{enddate} lt $now;
		}

	} else {
		my $uid = localtime;
		$uid .= "$$";

		$query = qq|INSERT INTO customer (name)
					VALUES ('$uid')|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|SELECT id 
					  FROM customer
					 WHERE name = '$uid'|;

		($form->{id}) = $dbh->selectrow_array($query);

	}

	my $employee_id;
	($null, $employee_id) = split /--/, $form->{employee};
	$employee_id *= 1;

	my $pricegroup_id;
	($null, $pricegroup_id) = split /--/, $form->{pricegroup};
	$pricegroup_id *= 1;

	my $business_id;
	($null, $business_id) = split /--/, $form->{business};
	$business_id *= 1;

	my $language_code;
	($null, $language_code) = split /--/, $form->{language};

	$form->{customernumber} = $form->update_defaults($myconfig, "customernumber", $dbh) if ! $form->{customernumber};

	$query = qq|UPDATE customer 
				   SET customernumber = |.$dbh->quote($form->{customernumber}).qq|,
					   name = |.$dbh->quote($form->{name}).qq|,
					   address1 = |.$dbh->quote($form->{address1}).qq|,
					   address2 = |.$dbh->quote($form->{address2}).qq|,
					   city = |.$dbh->quote($form->{city}).qq|,
					   state = |.$dbh->quote($form->{state}).qq|,
					   zipcode = |.$dbh->quote($form->{zipcode}).qq|,
					   country = |.$dbh->quote($form->{country}).qq|,
					   contact = |.$dbh->quote($form->{contact}).qq|,
					   phone = '$form->{phone}',
					   fax = '$form->{fax}',
					   email = '$form->{email}',
					   cc = '$form->{cc}',
					   bcc = '$form->{bcc}',
					   notes = |.$dbh->quote($form->{notes}).qq|,
					   discount = $form->{discount},
					   creditlimit = $form->{creditlimit},
					   terms = $form->{terms},
					   taxincluded = '$form->{taxincluded}',
					   business_id = $business_id,
					   taxnumber = |.$dbh->quote($form->{taxnumber}).qq|,
					   sic_code = '$form->{sic_code}',
					   iban = '$form->{iban}',
					   bic = '$form->{bic}',
					   employee_id = $employee_id,
					   pricegroup_id = $pricegroup_id,
					   language_code = '$language_code',
					   curr = '$form->{curr}',
					   startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
					   enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|
				 WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	# save taxes
	foreach $item (split / /, $form->{taxaccounts}) {

		if ($form->{"tax_$item"}) {
			$query = qq|INSERT INTO customertax (customer_id, chart_id)
						VALUES ($form->{id}, (SELECT id
						  						FROM chart
											   WHERE accno = '$item'))|;

			$dbh->do($query) || $form->dberror($query);
		}
	}

	# add shipto
	$form->add_shipto($dbh, $form->{id});

	$dbh->commit;
	$dbh->disconnect;
}


sub save_vendor {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $query;
	my $sth;
	my $null;

	# remove double spaces
	$form->{name} =~ s/  / /g;
	# remove double minus and minus at the end
	$form->{name} =~ s/--+/-/g;
	$form->{name} =~ s/-+$//;

	$form->{discount} = $form->parse_amount($myconfig, $form->{discount});
	$form->{discount} /= 100;
	$form->{terms} *= 1;
	$form->{taxincluded} *= 1;
	$form->{creditlimit} = $form->parse_amount($myconfig, $form->{creditlimit});


	if ($form->{id}) {
		$query = qq|DELETE FROM vendortax
					 WHERE vendor_id = $form->{id}|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|DELETE FROM shipto
					 WHERE trans_id = $form->{id}|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|SELECT id 
					  FROM vendor
					 WHERE id = $form->{id}|;

		if (! $dbh->selectrow_array($query)) {
			$query = qq|INSERT INTO vendor (id)
						VALUES ($form->{id})|;

			$dbh->do($query) || $form->dberror($query);
		}

		# retrieve enddate
		if ($form->{type} && $form->{enddate}) {
			my $now;
			$query = qq|SELECT enddate, current_date AS now FROM vendor|;
			($form->{enddate}, $now) = $dbh->selectrow_array($query);
			$form->{enddate} = $now if $form->{enddate} lt $now;
		}

	} else {
		my $uid = localtime;
		$uid .= "$$";

		$query = qq|INSERT INTO vendor (name)
					VALUES ('$uid')|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|SELECT id 
					  FROM vendor
					 WHERE name = '$uid'|;

		($form->{id}) = $dbh->selectrow_array($query);

	}

	my $employee_id;
	($null, $employee_id) = split /--/, $form->{employee};
	$employee_id *= 1;

	my $pricegroup_id;
	($null, $pricegroup_id) = split /--/, $form->{pricegroup};
	$pricegroup_id *= 1;

	my $business_id;
	($null, $business_id) = split /--/, $form->{business};
	$business_id *= 1;

	my $language_code;
	($null, $language_code) = split /--/, $form->{language};

	$form->{vendornumber} = $form->update_defaults($myconfig, "vendornumber", $dbh) if ! $form->{vendornumber};

	$query = qq|UPDATE vendor 
				   SET vendornumber = |.$dbh->quote($form->{vendornumber}).qq|,
					   name = |.$dbh->quote($form->{name}).qq|,
					   address1 = |.$dbh->quote($form->{address1}).qq|,
					   address2 = |.$dbh->quote($form->{address2}).qq|,
					   city = |.$dbh->quote($form->{city}).qq|,
					   state = |.$dbh->quote($form->{state}).qq|,
					   zipcode = |.$dbh->quote($form->{zipcode}).qq|,
					   country = |.$dbh->quote($form->{country}).qq|,
					   contact = |.$dbh->quote($form->{contact}).qq|,
					   phone = '$form->{phone}',
					   fax = '$form->{fax}',
					   email = '$form->{email}',
					   cc = '$form->{cc}',
					   bcc = '$form->{bcc}',
					   notes = |.$dbh->quote($form->{notes}).qq|,
					   terms = $form->{terms},
					   discount = $form->{discount},
					   creditlimit = $form->{creditlimit},
					   taxincluded = '$form->{taxincluded}',
					   gifi_accno = '$form->{gifi_accno}',
					   business_id = $business_id,
					   taxnumber = |.$dbh->quote($form->{taxnumber}).qq|,
					   sic_code = '$form->{sic_code}',
					   iban = '$form->{iban}',
					   bic = '$form->{bic}',
					   employee_id = $employee_id,
					   language_code = '$language_code',
					   pricegroup_id = $pricegroup_id,
					   curr = '$form->{curr}',
					   startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
					   enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|
				 WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	# save taxes
	foreach $item (split / /, $form->{taxaccounts}) {
		if ($form->{"tax_$item"}) {
			$query = qq|INSERT INTO vendortax (vendor_id, chart_id)
						VALUES ($form->{id}, (SELECT id
												FROM chart
											   WHERE accno = '$item'))|;
	
			$dbh->do($query) || $form->dberror($query);
		}
	}

	# add shipto
	$form->add_shipto($dbh, $form->{id});

	$dbh->commit;
	$dbh->disconnect;

}



sub delete {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	# delete customer/vendor
	my $query = qq|DELETE FROM $form->{db}
					WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;

}


sub search {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $where = "1 = 1";
	$form->{sort} = ($form->{sort}) ? $form->{sort} : "name";
	my @a = qw(name);
	my $sortorder = $form->sort_order(\@a);

	my $var;
	my $item;

	@a = ("$form->{db}number");
	push @a, qw(name contact city state zipcode country notes phone email);

	if ($form->{employee}) {
		$var = $form->like(lc $form->{employee});
		$where .= " AND lower(e.name) LIKE '$var'";
	}

	foreach $item (@a) {

		if ($form->{$item} ne "") {
			$var = $form->like(lc $form->{$item});
			$where .= " AND lower(ct.$item) LIKE '$var'";
		}
	}

	if ($form->{address} ne "") {
		$var = $form->like(lc $form->{address});
		$where .= " AND (lower(ct.address1) LIKE '$var' OR lower(ct.address2) LIKE '$var')";
	}

	if ($form->{startdatefrom}) {
		$where .= " AND ct.startdate >= '$form->{startdatefrom}'";
	}

	if ($form->{startdateto}) {
		$where .= " AND ct.startdate <= '$form->{startdateto}'";
	}

	if ($form->{status} eq 'active') {
		$where .= " AND ct.enddate IS NULL";
	}

	if ($form->{status} eq 'inactive') {
		$where .= " AND ct.enddate <= current_date";
	}

	if ($form->{status} eq 'orphaned') {
		$where .= qq| AND ct.id NOT IN (SELECT o.$form->{db}_id
										  FROM oe o, $form->{db} vc
										 WHERE vc.id = o.$form->{db}_id)|;

		if ($form->{db} eq 'customer') {
			$where .= qq| AND ct.id NOT IN (SELECT a.customer_id
											  FROM ar a, customer vc
											 WHERE vc.id = a.customer_id)|;
		}
	
		if ($form->{db} eq 'vendor') {
			$where .= qq| AND ct.id NOT IN (SELECT a.vendor_id
											  FROM ap a, vendor vc
											 WHERE vc.id = a.vendor_id)|;
		}

		$form->{l_invnumber} = $form->{l_ordnumber} = $form->{l_quonumber} = "";
	}


	my $query = qq|SELECT ct.*, b.description AS business,
						  e.name AS employee, g.pricegroup, l.description AS language,
						  m.name AS manager
					 FROM $form->{db} ct
				LEFT JOIN business b ON (ct.business_id = b.id)
				LEFT JOIN employee e ON (ct.employee_id = e.id)
				LEFT JOIN employee m ON (m.id = e.managerid)
				LEFT JOIN pricegroup g ON (ct.pricegroup_id = g.id)
				LEFT JOIN language l ON (l.code = ct.language_code)
				    WHERE $where|;

	# redo for invoices, orders and quotations
	if ($form->{l_transnumber} || $form->{l_invnumber} || $form->{l_ordnumber} || $form->{l_quonumber}) {

		my ($ar, $union, $module);
		$query = "";
		my $transwhere;
		my $openarap = "";
		my $openoe = "";

		if ($form->{open} || $form->{closed}) {
			unless ($form->{open} && $form->{closed}) {
				$openarap = " AND a.amount != a.paid" if $form->{open};
				$openarap = " AND a.amount = a.paid" if $form->{closed};
				$openoe = " AND o.closed = '0'" if $form->{open};
				$openoe = " AND o.closed = '1'" if $form->{closed};
			}
		}

		if ($form->{l_transnumber}) {

			$ar = ($form->{db} eq 'customer') ? 'ar' : 'ap';
			$module = $ar;

			$transwhere = "";
			$transwhere .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
			$transwhere .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};


			$query = qq|SELECT ct.*, b.description AS business,
							   a.invnumber, a.ordnumber, a.quonumber, a.id AS invid,
							   '$ar' AS module, 'invoice' AS formtype,
							   (a.amount = a.paid) AS closed, a.amount, a.netamount,
							   e.name AS employee, m.name AS manager
						  FROM $form->{db} ct
						  JOIN $ar a ON (a.$form->{db}_id = ct.id)
					 LEFT JOIN business b ON (ct.business_id = b.id)
					 LEFT JOIN employee e ON (a.employee_id = e.id)
					 LEFT JOIN employee m ON (m.id = e.managerid)
						 WHERE $where
						   AND a.invoice = '0'
							   $transwhere
							   $openarap |;

			$union = qq| UNION |;

		}

		if ($form->{l_invnumber}) {
			$ar = ($form->{db} eq 'customer') ? 'ar' : 'ap';
			$module = ($ar eq 'ar') ? 'is' : 'ir';

			$transwhere = "";
			$transwhere .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
			$transwhere .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

			$query .= qq|$union
						 SELECT ct.*, b.description AS business,
								a.invnumber, a.ordnumber, a.quonumber, a.id AS invid,
								'$module' AS module, 'invoice' AS formtype,
								(a.amount = a.paid) AS closed, a.amount, a.netamount,
								e.name AS employee, m.name AS manager
						   FROM $form->{db} ct
						   JOIN $ar a ON (a.$form->{db}_id = ct.id)
					  LEFT JOIN business b ON (ct.business_id = b.id)
					  LEFT JOIN employee e ON (a.employee_id = e.id)
					  LEFT JOIN employee m ON (m.id = e.managerid)
						  WHERE $where
							AND a.invoice = '1'
								$transwhere
								$openarap |;

			$union = qq| UNION|;

		}

		if ($form->{l_ordnumber}) {

			$transwhere = "";
			$transwhere .= " AND o.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
			$transwhere .= " AND o.transdate <= '$form->{transdateto}'" if $form->{transdateto};

			$query .= qq|$union
						 SELECT ct.*, b.description AS business,
								' ' AS invnumber, o.ordnumber, o.quonumber, o.id AS invid,
								'oe' AS module, 'order' AS formtype,
								o.closed, o.amount, o.netamount,
								e.name AS employee, m.name AS manager
						   FROM $form->{db} ct
						   JOIN oe o ON (o.$form->{db}_id = ct.id)
					  LEFT JOIN business b ON (ct.business_id = b.id)
					  LEFT JOIN employee e ON (o.employee_id = e.id)
					  LEFT JOIN employee m ON (m.id = e.managerid)
						  WHERE $where
							AND o.quotation = '0'
								$transwhere
								$openoe |;

			$union = qq| UNION|;

		}

		if ($form->{l_quonumber}) {

			$transwhere = "";
			$transwhere .= " AND o.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
			$transwhere .= " AND o.transdate <= '$form->{transdateto}'" if $form->{transdateto};

			$query .= qq|$union
						 SELECT ct.*, b.description AS business,
								' ' AS invnumber, o.ordnumber, o.quonumber, o.id AS invid,
								'oe' AS module, 'quotation' AS formtype,
								o.closed, o.amount, o.netamount,
								e.name AS employee, m.name AS manager
						   FROM $form->{db} ct
						   JOIN oe o ON (o.$form->{db}_id = ct.id)
					  LEFT JOIN business b ON (ct.business_id = b.id)
					  LEFT JOIN employee e ON (o.employee_id = e.id)
					  LEFT JOIN employee m ON (m.id = e.managerid)
						  WHERE $where
							AND o.quotation = '1'
								$transwhere
								$openoe |;

		}

		$sortorder .= ", invid";
	}

	$query .= qq| ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	# accounts
	$query = qq|SELECT c.accno
				  FROM chart c
				  JOIN $form->{db}tax t ON (t.chart_id = c.id)
				 WHERE t.$form->{db}_id = ?|;

	my $tth = $dbh->prepare($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		$tth->execute($ref->{id});

		while (($item) = $tth->fetchrow_array) {
			$ref->{taxaccount} .= "$item ";
		}

		$tth->finish;
		chop $ref->{taxaccount};

		$ref->{address} = "";

		for (qw(address1 address2 city state zipcode country)) { $ref->{address} .= "$ref->{$_} " }
		push @{ $form->{CT} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub get_history {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query;
	my $where = "1 = 1";
	$form->{sort} = "partnumber" unless $form->{sort};
	my $sortorder = $form->{sort};
	my %ordinal = ();
	my $var;
	my $table;

	# setup ASC or DESC
	$form->sort_order();

	if ($form->{"$form->{db}number"} ne "") {
		$var = $form->like(lc $form->{"$form->{db}number"});
		$where .= " AND lower(ct.$form->{db}number) LIKE '$var'";
	}

	if ($form->{address} ne "") {
		$var = $form->like(lc $form->{address});
		$where .= " AND lower(ct.address1) LIKE '$var'";
	}

	for (qw(name contact email phone notes city state zipcode country)) {

		if ($form->{$_} ne "") {
			$var = $form->like(lc $form->{$_});
			$where .= " AND lower(ct.$_) LIKE '$var'";
		}
	}

	if ($form->{employee} ne "") {
		$var = $form->like(lc $form->{employee});
		$where .= " AND lower(e.name) LIKE '$var'";
	}

	$where .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
	$where .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

	if ($form->{open} || $form->{closed}) {

		unless ($form->{open} && $form->{closed}) {

			if ($form->{type} eq 'invoice') {
				$where .= " AND a.amount != a.paid" if $form->{open};
				$where .= " AND a.amount = a.paid" if $form->{closed};
			} else {
				$where .= " AND a.closed = '0'" if $form->{open};
				$where .= " AND a.closed = '1'" if $form->{closed};
			}
		}
	}

	my $invnumber = 'invnumber';
	my $deldate = 'deliverydate';
	my $buysell;
	my $sellprice = "sellprice";

	if ($form->{db} eq 'customer') {
		$buysell = "buy";

		if ($form->{type} eq 'invoice') {
			$where .= qq| AND a.invoice = '1' AND i.assemblyitem = '0'|;
			$table = 'ar';
			$sellprice = "fxsellprice";
		} else {
			$table = 'oe';

			if ($form->{type} eq 'order') {
				$invnumber = 'ordnumber';
				$where .= qq| AND a.quotation = '0'|;
			} else {
				$invnumber = 'quonumber';
				$where .= qq| AND a.quotation = '1'|;
			}

			$deldate = 'reqdate';
		}
	}

	if ($form->{db} eq 'vendor') {

		$buysell = "sell";

		if ($form->{type} eq 'invoice') {

			$where .= qq| AND a.invoice = '1' AND i.assemblyitem = '0'|;
			$table = 'ap';
			$sellprice = "fxsellprice";

		} else {

			$table = 'oe';

			if ($form->{type} eq 'order') {
				$invnumber = 'ordnumber';
				$where .= qq| AND a.quotation = '0'|;
			} else {
				$invnumber = 'quonumber';
				$where .= qq| AND a.quotation = '1'|;
			} 

			$deldate = 'reqdate';
		}
	}

	my $invjoin = qq| JOIN invoice i ON (i.trans_id = a.id)|;

	if ($form->{type} eq 'order') {
		$invjoin = qq| JOIN orderitems i ON (i.trans_id = a.id)|;
	}

	if ($form->{type} eq 'quotation') {
		$invjoin = qq| JOIN orderitems i ON (i.trans_id = a.id)|;
		$where .= qq| AND a.quotation = '1'|;
	}


	%ordinal = ( partnumber		=> 9,
				 description	=> 12,
				 "$deldate"		=> 16,
				 serialnumber	=> 17,
				 projectnumber	=> 18 );

	$sortorder = "2 $form->{direction}, 1, 11, $ordinal{$sortorder} $form->{direction}";

	$query = qq|SELECT ct.id AS ctid, ct.name, ct.address1,
					   ct.address2, ct.city, ct.state,
					   p.id AS pid, p.partnumber, a.id AS invid,
					   a.$invnumber, a.curr, i.description,
					   i.qty, i.$sellprice AS sellprice, i.discount,
					   i.$deldate, i.serialnumber, pr.projectnumber,
					   e.name AS employee, ct.zipcode, ct.country, i.unit,
					   (SELECT $buysell 
						  FROM exchangerate ex
						 WHERE a.curr = ex.curr
						   AND a.transdate = ex.transdate) AS exchangerate
				  FROM $form->{db} ct
				  JOIN $table a ON (a.$form->{db}_id = ct.id)
					   $invjoin
				  JOIN parts p ON (p.id = i.parts_id)
			 LEFT JOIN project pr ON (pr.id = i.project_id)
			 LEFT JOIN employee e ON (e.id = a.employee_id)
				 WHERE $where
			  ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		$ref->{address} = "";
		$ref->{exchangerate} ||= 1;
		for (qw(address1 address2 city state zipcode country)) { $ref->{address} .= "$ref->{$_} " }
		$ref->{id} = $ref->{ctid};
		push @{ $form->{CT} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub pricelist {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query;

	if ($form->{db} eq 'customer') {
		$query = qq|SELECT p.id, p.partnumber, p.description,
						   p.sellprice, pg.partsgroup, p.partsgroup_id,
						   m.pricebreak, m.sellprice,
						   m.validfrom, m.validto, m.curr
					  FROM partscustomer m
					  JOIN parts p ON (p.id = m.parts_id)
				 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
					 WHERE m.customer_id = $form->{id}
				  ORDER BY partnumber|;
	}

	if ($form->{db} eq 'vendor') {
		$query = qq|SELECT p.id, p.partnumber AS sku, p.description,
						   pg.partsgroup, p.partsgroup_id,
						   m.partnumber, m.leadtime, m.lastcost, m.curr
					  FROM partsvendor m
					  JOIN parts p ON (p.id = m.parts_id)
				 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
					 WHERE m.vendor_id = $form->{id}
				  ORDER BY p.partnumber|;
	}

	my $sth;
	my $ref;

	if ($form->{id}) {

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			push @{ $form->{all_partspricelist} }, $ref;
		}
	
		$sth->finish;
	}

	$query = qq|SELECT curr FROM defaults|;
	($form->{currencies}) = $dbh->selectrow_array($query);

	$query = qq|SELECT id, partsgroup 
				  FROM partsgroup
			  ORDER BY partsgroup|;

	$sth = $dbh->prepare($query);
	$sth->execute || $self->dberror($query);

	$form->{all_partsgroup} = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_partsgroup} }, $ref;
	}

	$sth->finish;

	$dbh->disconnect;

}


sub save_pricelist {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect_noauto($myconfig);

	my $query = qq|DELETE FROM parts$form->{db}
					WHERE $form->{db}_id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	foreach $i (1 .. $form->{rowcount}) {

		if ($form->{"id_$i"}) {

			if ($form->{db} eq 'customer') {

				for (qw(pricebreak sellprice)) { 
					$form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) 
				}

				$query = qq|INSERT INTO parts$form->{db} (parts_id, customer_id,
														  pricebreak, sellprice, 
														  validfrom, validto, curr)
							VALUES ($form->{"id_$i"}, $form->{id},
									$form->{"pricebreak_$i"}, $form->{"sellprice_$i"},|
									.$form->dbquote($form->{"validfrom_$i"}, SQL_DATE) .qq|,|
									.$form->dbquote($form->{"validto_$i"}, SQL_DATE) .qq|,
									'$form->{"curr_$i"}')|;
			} else {

				for (qw(leadtime lastcost)) { 
					$form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) 
				}

				$query = qq|INSERT INTO parts$form->{db} (parts_id, vendor_id,
														  partnumber, lastcost, 
														  leadtime, curr)
							VALUES ($form->{"id_$i"}, $form->{id},
									'$form->{"partnumber_$i"}', $form->{"lastcost_$i"},
									$form->{"leadtime_$i"}, '$form->{"curr_$i"}')|;

			}
			$dbh->do($query) || $form->dberror($query);
		}

	}

	$_ = $dbh->commit;
	$dbh->disconnect;

}



sub retrieve_item {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $i = $form->{rowcount};
	my $var;
	my $null;

	my $where = "WHERE p.obsolete = '0'";

	if ($form->{db} eq 'vendor') {
		# parts, services, labor
		$where .= " AND p.assembly = '0'";
	}

	if ($form->{db} eq 'customer') {
		# parts, assemblies, services
		$where .= " AND p.income_accno_id > 0";
	}

	if ($form->{"partnumber_$i"} ne "") {
		$var = $form->like(lc $form->{"partnumber_$i"});
		$where .= " AND lower(p.partnumber) LIKE '$var'";
	}

	if ($form->{"description_$i"} ne "") {
		$var = $form->like(lc $form->{"description_$i"});
		$where .= " AND lower(p.description) LIKE '$var'";
	}

	if ($form->{"partsgroup_$i"} ne "") {
		($null, $var) = split /--/, $form->{"partsgroup_$i"};
		$var *= 1;
		$where .= qq| AND p.partsgroup_id = $var|;
	}


	my $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
						  p.lastcost, p.unit, pg.partsgroup, p.partsgroup_id
					 FROM parts p
				LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
				   $where
				 ORDER BY partnumber|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);
	my $ref;
	$form->{item_list} = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{item_list} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;
}


1;

