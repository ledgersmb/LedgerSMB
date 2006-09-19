#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://sourceforge.net/projects/ledger-smb/
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
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# Administration module
#    Chart of Accounts
#    template routines
#    preferences
#
#======================================================================

package AM;


sub get_account {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT accno, description, charttype, gifi_accno,
						  category, link, contra
					 FROM chart
					WHERE id = $form->{id}|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	# get default accounts
	$query = qq|SELECT inventory_accno_id, income_accno_id, expense_accno_id,
					   fxgain_accno_id, fxloss_accno_id
				  FROM defaults|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	# check if we have any transactions
	$query = qq|SELECT trans_id FROM acc_trans
				 WHERE chart_id = $form->{id}|;

	($form->{orphaned}) = $dbh->selectrow_array($query);
	$form->{orphaned} = !$form->{orphaned};

	$dbh->disconnect;

}


sub save_account {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn off AutoCommit
	my $dbh = $form->dbconnect_noauto($myconfig);

	$form->{link} = "";
	foreach my $item ($form->{AR},
					  $form->{AR_amount},
					  $form->{AR_tax},
					  $form->{AR_paid},
					  $form->{AP},
					  $form->{AP_amount},
					  $form->{AP_tax},
					  $form->{AP_paid},
					  $form->{IC},
					  $form->{IC_income},
					  $form->{IC_sale},
					  $form->{IC_expense},
					  $form->{IC_cogs},
					  $form->{IC_taxpart},
					  $form->{IC_taxservice}) {
		$form->{link} .= "${item}:" if ($item);
	}

	chop $form->{link};

	# strip blanks from accno
	for (qw(accno gifi_accno)) { $form->{$_} =~ s/( |')//g }

	foreach my $item (qw(accno gifi_accno description)) {
		$form->{$item} =~ s/-(-+)/-/g;
		$form->{$item} =~ s/ ( )+/ /g;
	}

	my $query;
	my $sth;

	$form->{contra} *= 1;

	# if we have an id then replace the old record
	if ($form->{id}) {
		$query = qq|UPDATE chart SET accno = '$form->{accno}',
									 description = |.$dbh->quote($form->{description}).qq|,
									 charttype = '$form->{charttype}',
									 gifi_accno = '$form->{gifi_accno}',
									 category = '$form->{category}',
									 link = '$form->{link}',
									 contra = '$form->{contra}'
							   WHERE id = $form->{id}|;
	} else {
		$query = qq|INSERT INTO chart (accno, description, charttype, 
									   gifi_accno, category, link, contra)
						 VALUES ('$form->{accno}',|
								 .$dbh->quote($form->{description}).qq|,
								 '$form->{charttype}', '$form->{gifi_accno}',
								 '$form->{category}', '$form->{link}', '$form->{contra}')|;
	}

	$dbh->do($query) || $form->dberror($query);


	$chart_id = $form->{id};

	if (! $form->{id}) {
		# get id from chart
		$query = qq|SELECT id
					  FROM chart
					 WHERE accno = '$form->{accno}'|;

		($chart_id) = $dbh->selectrow_array($query);
	}

	if ($form->{IC_taxpart} || $form->{IC_taxservice} || $form->{AR_tax} || $form->{AP_tax}) {

		# add account if it doesn't exist in tax
		$query = qq|SELECT chart_id
					  FROM tax
					 WHERE chart_id = $chart_id|;

		my ($tax_id) = $dbh->selectrow_array($query);

		# add tax if it doesn't exist
		unless ($tax_id) {
			$query = qq|INSERT INTO tax (chart_id, rate)
							 VALUES ($chart_id, 0)|;

			$dbh->do($query) || $form->dberror($query);
		}

	} else {

		# remove tax
		if ($form->{id}) {
			$query = qq|DELETE FROM tax
							  WHERE chart_id = $form->{id}|;

			$dbh->do($query) || $form->dberror($query);
		}
	}

	# commit
	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;
}



sub delete_account {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn off AutoCommit
	my $dbh = $form->dbconnect_noauto($myconfig);

	## needs fixing (SELECT *...)
	my $query = qq|SELECT * 
					 FROM acc_trans
					WHERE chart_id = $form->{id}|;

	if ($dbh->selectrow_array($query)) {
		$dbh->disconnect;
		return;
	}


	# delete chart of account record
	$query = qq|DELETE FROM chart
					  WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	# set inventory_accno_id, income_accno_id, expense_accno_id to defaults
	$query = qq|UPDATE parts
				   SET inventory_accno_id = (SELECT inventory_accno_id 
											   FROM defaults)
				 WHERE inventory_accno_id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	$query = qq|UPDATE parts
				   SET income_accno_id = (SELECT income_accno_id 
											FROM defaults)
				 WHERE income_accno_id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	$query = qq|UPDATE parts
				   SET expense_accno_id = (SELECT expense_accno_id 
											 FROM defaults)
				 WHERE expense_accno_id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	foreach my $table (qw(partstax customertax vendortax tax)) {
		$query = qq|DELETE FROM $table
						  WHERE chart_id = $form->{id}|;

		$dbh->do($query) || $form->dberror($query);
	}

	# commit and redirect
	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;
}


sub gifi_accounts {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT accno, description
					 FROM gifi
				 ORDER BY accno|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;

	$dbh->disconnect;
}



sub get_gifi {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT accno, description
					 FROM gifi
					WHERE accno = '$form->{accno}'|;

	($form->{accno}, $form->{description}) = $dbh->selectrow_array($query);

	# check for transactions ## needs fixing (SELECT *...)
	$query = qq|SELECT * 
				  FROM acc_trans a
				  JOIN chart c ON (a.chart_id = c.id)
				  JOIN gifi g ON (c.gifi_accno = g.accno)
				 WHERE g.accno = '$form->{accno}'|;

	($form->{orphaned}) = $dbh->selectrow_array($query);
	$form->{orphaned} = !$form->{orphaned};

	$dbh->disconnect;

}


sub save_gifi {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{accno} =~ s/( |')//g;

	foreach my $item (qw(accno description)) {
		$form->{$item} =~ s/-(-+)/-/g;
		$form->{$item} =~ s/ ( )+/ /g;
	}

	# id is the old account number!
	if ($form->{id}) {
		$query = qq|UPDATE gifi 
					   SET accno = '$form->{accno}',
						   description = |.$dbh->quote($form->{description}).qq|
					 WHERE accno = '$form->{id}'|;

	} else {
		$query = qq|INSERT INTO gifi (accno, description)
						 VALUES ('$form->{accno}',|
								.$dbh->quote($form->{description}).qq|)|;
	}

	$dbh->do($query) || $form->dberror; 
	$dbh->disconnect;

}


sub delete_gifi {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	# id is the old account number!
	$query = qq|DELETE FROM gifi
					  WHERE accno = '$form->{id}'|;

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub warehouses {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->sort_order();
	my $query = qq|SELECT id, description
					 FROM warehouse
				 ORDER BY description $form->{direction}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub get_warehouse {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT description
					 FROM warehouse
					WHERE id = $form->{id}|;

	($form->{description}) = $dbh->selectrow_array($query);

	# see if it is in use
	$query = qq|SELECT * FROM inventory
				 WHERE warehouse_id = $form->{id}|;

	($form->{orphaned}) = $dbh->selectrow_array($query);
	$form->{orphaned} = !$form->{orphaned};

	$dbh->disconnect;
}


sub save_warehouse {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{description} =~ s/-(-)+/-/g;
	$form->{description} =~ s/ ( )+/ /g;

	if ($form->{id}) {
		$query = qq|UPDATE warehouse 
					   SET description = |.$dbh->quote($form->{description}).qq|
					 WHERE id = $form->{id}|;
	} else {
		$query = qq|INSERT INTO warehouse (description)
						 VALUES (|.$dbh->quote($form->{description}).qq|)|;
	}

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub delete_warehouse {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM warehouse
					  WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}



sub departments {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->sort_order();
	my $query = qq|SELECT id, description, role
					 FROM department
				 ORDER BY description $form->{direction}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}



sub get_department {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT description, role
					 FROM department
					WHERE id = $form->{id}|;

	($form->{description}, $form->{role}) = $dbh->selectrow_array($query);

	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	# see if it is in use ## needs fixing (SELECT * ...)
	$query = qq|SELECT * 
				  FROM dpt_trans
				 WHERE department_id = $form->{id}|;

	($form->{orphaned}) = $dbh->selectrow_array($query);
	$form->{orphaned} = !$form->{orphaned};

	$dbh->disconnect;
}


sub save_department {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{description} =~ s/-(-)+/-/g;
	$form->{description} =~ s/ ( )+/ /g;

	if ($form->{id}) {
		$query = qq|UPDATE department 
					   SET description = |.$dbh->quote($form->{description}).qq|,
						   role = '$form->{role}'
					 WHERE id = $form->{id}|;

	} else {
		$query = qq|INSERT INTO department (description, role)
						 VALUES (| .$dbh->quote($form->{description}).qq|, '$form->{role}')|;
	}

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub delete_department {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM department
					  WHERE id = $form->{id}|;

	$dbh->do($query);
	$dbh->disconnect;

}


sub business {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->sort_order();
	my $query = qq|SELECT id, description, discount
					 FROM business
				 ORDER BY description $form->{direction}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub get_business {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT description, discount
					 FROM business
					WHERE id = $form->{id}|;

	($form->{description}, $form->{discount}) = $dbh->selectrow_array($query);
	$dbh->disconnect;

}


sub save_business {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{description} =~ s/-(-)+/-/g;
	$form->{description} =~ s/ ( )+/ /g;
	$form->{discount} /= 100;

	if ($form->{id}) {
		$query = qq|UPDATE business 
					   SET description = |.$dbh->quote($form->{description}).qq|,
						   discount = $form->{discount}
					 WHERE id = $form->{id}|;

	} else {
		$query = qq|INSERT INTO business (description, discount)
						 VALUES (| .$dbh->quote($form->{description}).qq|, $form->{discount})|;
	}

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub delete_business {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM business
					  WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{sort} = "code" unless $form->{sort};
	my @a = qw(code description);

	my %ordinal = ( code		=> 1,
					description	=> 3 );

	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query = qq|SELECT code, sictype, description
					 FROM sic
				 ORDER BY $sortorder|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub get_sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT code, sictype, description
					 FROM sic
					WHERE code = |.$dbh->quote($form->{code});

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;
	$dbh->disconnect;

}


sub save_sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	foreach my $item (qw(code description)) {
		$form->{$item} =~ s/-(-)+/-/g;
	}

	# if there is an id
	if ($form->{id}) {
		$query = qq|UPDATE sic 
					   SET code = |.$dbh->quote($form->{code}).qq|,
						   sictype = '$form->{sictype}',
						   description = |.$dbh->quote($form->{description}).qq|
					 WHERE code = |.$dbh->quote($form->{id});

	} else {
		$query = qq|INSERT INTO sic (code, sictype, description)
						 VALUES (|.$dbh->quote($form->{code}).qq|,
								 '$form->{sictype}',|
								 .$dbh->quote($form->{description}).qq|)|;

	}

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub delete_sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM sic
					  WHERE code = |.$dbh->quote($form->{code});

	$dbh->do($query);
	$dbh->disconnect;

}


sub language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{sort} = "code" unless $form->{sort};
	my @a = qw(code description);

	my %ordinal = ( code		=> 1,
					description	=> 2 );

	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query = qq|SELECT code, description
					 FROM language
				 ORDER BY $sortorder|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub get_language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	## needs fixing (SELECT *...)
	my $query = qq|SELECT *
					 FROM language
					WHERE code = |.$dbh->quote($form->{code});

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);

	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;
	$dbh->disconnect;

}


sub save_language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$form->{code} =~ s/ //g;

	foreach my $item (qw(code description)) {
		$form->{$item} =~ s/-(-)+/-/g;
		$form->{$item} =~ s/ ( )+/-/g;
	}

	# if there is an id
	if ($form->{id}) {
		$query = qq|UPDATE language 
					   SET code = |.$dbh->quote($form->{code}).qq|,
						   description = |.$dbh->quote($form->{description}).qq|
					 WHERE code = |.$dbh->quote($form->{id});

	} else {
		$query = qq|INSERT INTO language (code, description)
						 VALUES (|.$dbh->quote($form->{code}).qq|,|
								  .$dbh->quote($form->{description}).qq|)|;
	}

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub delete_language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	$query = qq|DELETE FROM language
					  WHERE code = |.$dbh->quote($form->{code});

	$dbh->do($query) || $form->dberror($query);
	$dbh->disconnect;

}


sub recurring_transactions {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT curr FROM defaults|;

	my ($defaultcurrency) = $dbh->selectrow_array($query);
	$defaultcurrency =~ s/:.*//g;

	$form->{sort} ||= "nextdate";
	my @a = ($form->{sort});
	my $sortorder = $form->sort_order(\@a);

	$query = qq|SELECT 'ar' AS module, 'ar' AS transaction, a.invoice,
						n.name AS description, a.amount,
						s.*, se.formname AS recurringemail,
						sp.formname AS recurringprint,
						s.nextdate - current_date AS overdue, 'customer' AS vc,
						ex.buy AS exchangerate, a.curr,
						(s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
				   FROM recurring s
				   JOIN ar a ON (a.id = s.id)
				   JOIN customer n ON (n.id = a.customer_id)
			  LEFT JOIN recurringemail se ON (se.id = s.id)
			  LEFT JOIN recurringprint sp ON (sp.id = s.id)
			  LEFT JOIN exchangerate ex ON (ex.curr = a.curr AND a.transdate = ex.transdate)

				  UNION

				 SELECT 'ap' AS module, 'ap' AS transaction, a.invoice,
						 n.name AS description, a.amount,
						 s.*, se.formname AS recurringemail,
						 sp.formname AS recurringprint,
						 s.nextdate - current_date AS overdue, 'vendor' AS vc,
						 ex.sell AS exchangerate, a.curr,
						 (s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
				   FROM recurring s
				   JOIN ap a ON (a.id = s.id)
				   JOIN vendor n ON (n.id = a.vendor_id)
			  LEFT JOIN recurringemail se ON (se.id = s.id)
			  LEFT JOIN recurringprint sp ON (sp.id = s.id)
			  LEFT JOIN exchangerate ex ON (ex.curr = a.curr AND a.transdate = ex.transdate)

				  UNION

				 SELECT 'gl' AS module, 'gl' AS transaction, FALSE AS invoice,
						a.description, (SELECT SUM(ac.amount) 
										  FROM acc_trans ac 
										 WHERE ac.trans_id = a.id 
										   AND ac.amount > 0) AS amount,
						s.*, se.formname AS recurringemail,
						sp.formname AS recurringprint,
						s.nextdate - current_date AS overdue, '' AS vc,
						'1' AS exchangerate, '$defaultcurrency' AS curr,
						(s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
				   FROM recurring s
				   JOIN gl a ON (a.id = s.id)
			  LEFT JOIN recurringemail se ON (se.id = s.id)
			  LEFT JOIN recurringprint sp ON (sp.id = s.id)

				  UNION

				 SELECT 'oe' AS module, 'so' AS transaction, FALSE AS invoice,
						n.name AS description, a.amount,
						s.*, se.formname AS recurringemail,
						sp.formname AS recurringprint,
						s.nextdate - current_date AS overdue, 'customer' AS vc,
						ex.buy AS exchangerate, a.curr,
						(s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
				   FROM recurring s
				   JOIN oe a ON (a.id = s.id)
				   JOIN customer n ON (n.id = a.customer_id)
			  LEFT JOIN recurringemail se ON (se.id = s.id)
			  LEFT JOIN recurringprint sp ON (sp.id = s.id)
			  LEFT JOIN exchangerate ex ON (ex.curr = a.curr AND a.transdate = ex.transdate)
				  WHERE a.quotation = '0'

				  UNION

				 SELECT 'oe' AS module, 'po' AS transaction, FALSE AS invoice,
						n.name AS description, a.amount,
						s.*, se.formname AS recurringemail,
						sp.formname AS recurringprint,
						s.nextdate - current_date AS overdue, 'vendor' AS vc,
						ex.sell AS exchangerate, a.curr,
						(s.nextdate IS NULL OR s.nextdate > s.enddate) AS expired
				   FROM recurring s
				   JOIN oe a ON (a.id = s.id)
				   JOIN vendor n ON (n.id = a.vendor_id)
			  LEFT JOIN recurringemail se ON (se.id = s.id)
			  LEFT JOIN recurringprint sp ON (sp.id = s.id)
			  LEFT JOIN exchangerate ex ON (ex.curr = a.curr AND a.transdate = ex.transdate)
				  WHERE a.quotation = '0'

			   ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $id;
	my $transaction;
	my %e = ();
	my %p = ();

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

		$ref->{exchangerate} ||= 1;

		if ($ref->{id} != $id) {

			if (%e) {
				$form->{transactions}{$transaction}->[$i]->{recurringemail} = "";
				for (keys %e) { $form->{transactions}{$transaction}->[$i]->{recurringemail} .= "${_}:" }
				chop $form->{transactions}{$transaction}->[$i]->{recurringemail};
			}

			if (%p) {
				$form->{transactions}{$transaction}->[$i]->{recurringprint} = "";
				for (keys %p) { $form->{transactions}{$transaction}->[$i]->{recurringprint} .= "${_}:" }
				chop $form->{transactions}{$transaction}->[$i]->{recurringprint};
			}

			%e = ();
			%p = ();

			push @{ $form->{transactions}{$ref->{transaction}} }, $ref;

			$id = $ref->{id};
			$i = $#{ $form->{transactions}{$ref->{transaction}} };

		}

		$transaction = $ref->{transaction};

		$e{$ref->{recurringemail}} = 1 if $ref->{recurringemail};
		$p{$ref->{recurringprint}} = 1 if $ref->{recurringprint};

	}

	$sth->finish;

	# this is for the last row
	if (%e) {
		$form->{transactions}{$transaction}->[$i]->{recurringemail} = "";
		for (keys %e) { $form->{transactions}{$transaction}->[$i]->{recurringemail} .= "${_}:" }
		chop $form->{transactions}{$transaction}->[$i]->{recurringemail};
	}

	if (%p) {
		$form->{transactions}{$transaction}->[$i]->{recurringprint} = "";
		for (keys %p) { $form->{transactions}{$transaction}->[$i]->{recurringprint} .= "${_}:" }
		chop $form->{transactions}{$transaction}->[$i]->{recurringprint};
	}


	$dbh->disconnect;

}

sub recurring_details {

	my ($self, $myconfig, $form, $id) = @_;

	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT s.*, ar.id AS arid, ar.invoice AS arinvoice,
						  ap.id AS apid, ap.invoice AS apinvoice,
						  ar.duedate - ar.transdate AS overdue,
						  ar.datepaid - ar.transdate AS paid,
						  oe.reqdate - oe.transdate AS req,
						  oe.id AS oeid, oe.customer_id, oe.vendor_id
					 FROM recurring s
				LEFT JOIN ar ON (ar.id = s.id)
				LEFT JOIN ap ON (ap.id = s.id)
				LEFT JOIN oe ON (oe.id = s.id)
					WHERE s.id = $id|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	$form->{vc} = "customer" if $ref->{customer_id};
	$form->{vc} = "vendor" if $ref->{vendor_id};
	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	$form->{invoice} = ($form->{arid} && $form->{arinvoice});
	$form->{invoice} = ($form->{apid} && $form->{apinvoice}) unless $form->{invoice};

	$query = qq|SELECT * 
				  FROM recurringemail
				 WHERE id = $id|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$form->{recurringemail} = "";

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{recurringemail} .= "$ref->{formname}:$ref->{format}:";
		$form->{message} = $ref->{message};
	}

	$sth->finish;

	$query = qq|SELECT * 
				  FROM recurringprint
				 WHERE id = $id|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$form->{recurringprint} = "";
		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{recurringprint} .= "$ref->{formname}:$ref->{format}:$ref->{printer}:";
	}

	$sth->finish;

	chop $form->{recurringemail};
	chop $form->{recurringprint};

	for (qw(arinvoice apinvoice)) { delete $form->{$_} }

	$dbh->disconnect;

}


sub update_recurring {

	my ($self, $myconfig, $form, $id) = @_;

	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT nextdate, repeat, unit
					 FROM recurring
					WHERE id = $id|;

	my ($nextdate, $repeat, $unit) = $dbh->selectrow_array($query);

	my %advance = ( 'Pg'  => "(date '$nextdate' + interval '$repeat $unit')",
					'DB2' => qq|(date ('$nextdate') + "$repeat $unit")|,);

	$interval{Oracle} = $interval{PgPP} = $interval{Pg};

	# check if it is the last date
	$query = qq|SELECT $advance{$myconfig->{dbdriver}} > enddate
				  FROM recurring
				 WHERE id = $id|;

	my ($last_repeat) = $dbh->selectrow_array($query);
	if ($last_repeat) {
		$advance{$myconfig->{dbdriver}} = "NULL";
	}

	$query = qq|UPDATE recurring 
				   SET nextdate = $advance{$myconfig->{dbdriver}}
				 WHERE id = $id|;

	$dbh->do($query) || $form->dberror($query);

	$dbh->disconnect;

}


sub load_template {

	my ($self, $form) = @_;

	open(TEMPLATE, "$form->{file}") or $form->error("$form->{file} : $!");

	while (<TEMPLATE>) {
		$form->{body} .= $_;
	}

	close(TEMPLATE);

}


sub save_template {

	my ($self, $form) = @_;

	open(TEMPLATE, ">$form->{file}") or $form->error("$form->{file} : $!");

	# strip 
	$form->{body} =~ s/\r//g;
	print TEMPLATE $form->{body};

	close(TEMPLATE);

}


sub save_preferences {

	my ($self, $myconfig, $form, $memberfile, $userspath) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	# update name
	my $query = qq|UPDATE employee
					  SET name = |.$dbh->quote($form->{name}).qq|,
						  role = '$form->{role}'
					WHERE login = '$form->{login}'|;

	$dbh->do($query) || $form->dberror($query);

	# get default currency
	$query = qq|SELECT curr, businessnumber
				  FROM defaults|;

	($form->{currency}, $form->{businessnumber}) = $dbh->selectrow_array($query);
	$form->{currency} =~ s/:.*//;

	$dbh->disconnect;

	my $myconfig = new User "$memberfile", "$form->{login}";

	foreach my $item (keys %$form) {
		$myconfig->{$item} = $form->{$item};
	}

	$myconfig->{password} = $form->{new_password} if ($form->{old_password} ne $form->{new_password});

	$myconfig->save_member($memberfile, $userspath);

	1;

}


sub save_defaults {

	my ($self, $myconfig, $form) = @_;

	for (qw(IC IC_income IC_expense FX_gain FX_loss)) { ($form->{$_}) = split /--/, $form->{$_} }

	my @a;
	$form->{curr} =~ s/ //g;
	for (split /:/, $form->{curr}) { push(@a, uc pack "A3", $_) if $_ }
	$form->{curr} = join ':', @a;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);

	# save defaults
	my $query = qq|UPDATE defaults 
					  SET inventory_accno_id = (SELECT id 
												  FROM chart
												 WHERE accno = '$form->{IC}'),
						  income_accno_id = (SELECT id 
											   FROM chart
											  WHERE accno = '$form->{IC_income}'),
						  expense_accno_id = (SELECT id 
												FROM chart
											   WHERE accno = '$form->{IC_expense}'),
						  fxgain_accno_id = (SELECT id 
											   FROM chart
											  WHERE accno = '$form->{FX_gain}'),
						  fxloss_accno_id = (SELECT id 
											   FROM chart
											  WHERE accno = '$form->{FX_loss}'),
						  glnumber = '$form->{glnumber}',
						  sinumber = '$form->{sinumber}',
						  vinumber = '$form->{vinumber}',
						  sonumber = '$form->{sonumber}',
						  ponumber = '$form->{ponumber}',
						  sqnumber = '$form->{sqnumber}',
						  rfqnumber = '$form->{rfqnumber}',
						  partnumber = '$form->{partnumber}',
						  employeenumber = '$form->{employeenumber}',
						  customernumber = '$form->{customernumber}',
						  vendornumber = '$form->{vendornumber}',
						  projectnumber = '$form->{projectnumber}',
						  yearend = '$form->{yearend}',
						  curr = '$form->{curr}',
						  weightunit = |.$dbh->quote($form->{weightunit}).qq|,
						  businessnumber = |.$dbh->quote($form->{businessnumber});

	$dbh->do($query) || $form->dberror($query);

	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;

}


sub defaultaccounts {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	# get defaults from defaults table
	my $query = qq|SELECT * FROM defaults|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$form->{defaults}{IC} = $form->{inventory_accno_id};
	$form->{defaults}{IC_income} = $form->{income_accno_id};
	$form->{defaults}{IC_sale} = $form->{income_accno_id};
	$form->{defaults}{IC_expense} = $form->{expense_accno_id};
	$form->{defaults}{IC_cogs} = $form->{expense_accno_id};
	$form->{defaults}{FX_gain} = $form->{fxgain_accno_id};
	$form->{defaults}{FX_loss} = $form->{fxloss_accno_id};

	$sth->finish;

	$query = qq|SELECT id, accno, description, link
				  FROM chart
				 WHERE link LIKE '%IC%'
			  ORDER BY accno|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $nkey;
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		foreach my $key (split(/:/, $ref->{link})) {
			if ($key =~ /IC/) {
				$nkey = $key;

					if ($key =~ /cogs/) {
						$nkey = "IC_expense";
					}

					if ($key =~ /sale/) {
						$nkey = "IC_income";
					}

				%{ $form->{accno}{$nkey}{$ref->{accno}} } = ( id => $ref->{id},
															description => $ref->{description} );
			}
		}
	}

	$sth->finish;


	$query = qq|SELECT id, accno, description
				  FROM chart
				 WHERE (category = 'I' OR category = 'E')
				   AND charttype = 'A'
			  ORDER BY accno|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		%{ $form->{accno}{FX_gain}{$ref->{accno}} } = ( id => $ref->{id},
														description => $ref->{description} );

		%{ $form->{accno}{FX_loss}{$ref->{accno}} } = ( id => $ref->{id},
														description => $ref->{description} );
	}

	$sth->finish;

	$dbh->disconnect;

}


sub taxes {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT c.id, c.accno, c.description,
						  t.rate * 100 AS rate, t.taxnumber, t.validto
					 FROM chart c
					 JOIN tax t ON (c.id = t.chart_id)
				 ORDER BY 3, 6|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{taxrates} }, $ref;
	}

	$sth->finish;

	$dbh->disconnect;

}


sub save_taxes {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $query = qq|DELETE FROM tax|;
	$dbh->do($query) || $form->dberror($query);

	foreach my $item (split / /, $form->{taxaccounts}) {
		my ($chart_id, $i) = split /_/, $item;
		my $rate = $form->parse_amount($myconfig, $form->{"taxrate_$i"}) / 100;
		
		$query = qq|INSERT INTO tax (chart_id, rate, taxnumber, validto)
						 VALUES ($chart_id, $rate, |
								.$dbh->quote($form->{"taxnumber_$i"}).qq|, |
								.$form->dbquote($form->{"validto_$i"}, SQL_DATE)
								.qq|)|;

		$dbh->do($query) || $form->dberror($query);
	}

	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;

}


sub backup {

	my ($self, $myconfig, $form, $userspath, $gzip) = @_;

	my $mail;
	my $err;

	my @t = localtime(time);
	$t[4]++;
	$t[5] += 1900;
	$t[3] = substr("0$t[3]", -2);
	$t[4] = substr("0$t[4]", -2);

	my $boundary = time;
	my $tmpfile = "$userspath/$boundary.$myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql";
	my $out = $form->{OUT};
	$form->{OUT} = ">$tmpfile";

	open(OUT, "$form->{OUT}") or $form->error("$form->{OUT} : $!");

	# get sequences, functions and triggers

	my $today = scalar localtime;

	$myconfig->{dbhost} = 'localhost' unless $myconfig->{dbhost};

	$ENV{PGPASSWD} = $myconfig->{dbpasswd};
	# drop tables and sequences

	# compress backup if gzip defined
	my $suffix = "";

	if ($form->{media} eq 'email') {
		if ($gzip){
			print OUT `pg_dump -U $myconfig->{dbuser} -h $myconfig->{dbhost} $myconfig->{dbname} | $gzip`;
		} else {
			print OUT `pg_dump -U $myconfig->{dbuser} -h $myconfig->{dbhost} $myconfig->{dbname}`;
		}
		close OUT;
		use LedgerSMB::Mailer;
		$mail = new Mailer;

		$mail->{to} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
		$mail->{from} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
		$mail->{subject} = "LedgerSMB Backup / $myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql$suffix";
		@{ $mail->{attachments} } = ($tmpfile);
		$mail->{version} = $form->{version};
		$mail->{fileid} = "$boundary.";

		$myconfig->{signature} =~ s/\\n/\n/g;
		$mail->{message} = "-- \n$myconfig->{signature}";

		$err = $mail->send($out);
	}

	if ($form->{media} eq 'file') {

		open(IN, "$tmpfile") or $form->error("$tmpfile : $!");
		open(OUT, ">-") or $form->error("STDOUT : $!");

		print OUT qq|Content-Type: application/file;\n| .
		qq|Content-Disposition: attachment; filename="$myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql$suffix"\n\n|;
		if ($gzip){
			print OUT `pg_dump -U $myconfig->{dbuser} -h $myconfig->{dbhost} $myconfig->{dbname} | $gzip`;
		} else {
			print OUT `pg_dump -U $myconfig->{dbuser} -h $myconfig->{dbhost} $myconfig->{dbname}`;
		}

	}

	unlink "$tmpfile";

}


sub closedto {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT closedto, revtrans, audittrail
					 FROM defaults|;

	($form->{closedto}, $form->{revtrans}, $form->{audittrail}) = $dbh->selectrow_array($query);

	$dbh->disconnect;

}


sub closebooks {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect_noauto($myconfig);
	my $query = qq|UPDATE defaults SET|;

	if ($form->{revtrans}) {
		$query .= qq| revtrans = '1'|;
	} else {
		$query .= qq| revtrans = '0'|;
	}

	$query .= qq|, closedto = |.$form->dbquote($form->{closedto}, SQL_DATE);

	if ($form->{audittrail}) {
		$query .= qq|, audittrail = '1'|;
	} else {
		$query .= qq|, audittrail = '0'|;
	}

	# set close in defaults
	$dbh->do($query) || $form->dberror($query);

	if ($form->{removeaudittrail}) {
		$query = qq|DELETE FROM audittrail
						  WHERE transdate < '$form->{removeaudittrail}'|;

		$dbh->do($query) || $form->dberror($query);
	}

	$dbh->commit;
	$dbh->disconnect;

}


sub earningsaccounts {

	my ($self, $myconfig, $form) = @_;

	my ($query, $sth, $ref);

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	# get chart of accounts
	$query = qq|SELECT accno,description
				  FROM chart
				 WHERE charttype = 'A'
				   AND category = 'Q'
			  ORDER BY accno|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);
	$form->{chart} = "";

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{chart} }, $ref;
	}
	
	$sth->finish;
	$dbh->disconnect;
}


sub post_yearend {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn off AutoCommit
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $query;
	my $uid = localtime;
	$uid .= "$$";

	$query = qq|INSERT INTO gl (reference, employee_id)
					 VALUES ('$uid', (SELECT id FROM employee
					  WHERE login = '$form->{login}'))|;

	$dbh->do($query) || $form->dberror($query);

	$query = qq|SELECT id 
				  FROM gl
				 WHERE reference = '$uid'|;

	($form->{id}) = $dbh->selectrow_array($query);

	$query = qq|UPDATE gl 
				   SET reference = |.$dbh->quote($form->{reference}).qq|,
					   description = |.$dbh->quote($form->{description}).qq|,
					   notes = |.$dbh->quote($form->{notes}).qq|,
					   transdate = '$form->{transdate}',
					   department_id = 0
				 WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	my $amount;
	my $accno;

	# insert acc_trans transactions
	for my $i (1 .. $form->{rowcount}) {
		# extract accno
		($accno) = split(/--/, $form->{"accno_$i"});
		$amount = 0;

		if ($form->{"credit_$i"}) {
			$amount = $form->{"credit_$i"};
		}

		if ($form->{"debit_$i"}) {
			$amount = $form->{"debit_$i"} * -1;
		}


		# if there is an amount, add the record
		if ($amount) {
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate, source)
							 VALUES ($form->{id}, (SELECT id
													 FROM chart
													WHERE accno = '$accno'),
									 $amount, '$form->{transdate}', |
									.$dbh->quote($form->{reference}).qq|)|;

		$dbh->do($query) || $form->dberror($query);
		}
	}

	$query = qq|INSERT INTO yearend (trans_id, transdate)
					 VALUES ($form->{id}, '$form->{transdate}')|;

	$dbh->do($query) || $form->dberror($query);

	my %audittrail = ( tablename	=> 'gl',
					   reference	=> $form->{reference},
					    formname	=> 'yearend',
					      action	=> 'posted',
							  id	=> $form->{id} );

	$form->audittrail($dbh, "", \%audittrail);

	# commit and redirect
	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;

}


1;
