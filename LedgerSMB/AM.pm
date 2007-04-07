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
use LedgerSMB::Tax;
use LedgerSMB::Sysconfig;

sub get_account {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};

	my $query = qq|
		SELECT accno, description, charttype, gifi_accno,
		       category, link, contra
		  FROM chart
		 WHERE id = ?|;

	my $sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	# get default accounts
	$query = qq|
		SELECT (SELECT value FROM defaults
		         WHERE setting_key = 'inventory_accno_id')
		       AS inventory_accno_id,
		       (SELECT value FROM defaults
		         WHERE setting_key = 'income_accno_id')
		       AS income_accno_id, 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'expense_accno_id')
		       AS expense_accno_id,
		       (SELECT value FROM defaults
		         WHERE setting_key = 'fxgain_accno_id')
		       AS fxgain_accno_id, 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'fxloss_accno_id')
		       AS fxloss_accno_id|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	# check if we have any transactions
	$query = qq|
		SELECT trans_id 
		  FROM acc_trans
		 WHERE chart_id = ? 
		 LIMIT 1|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id});
	($form->{orphaned}) = $sth->fetchrow_array();
	$form->{orphaned} = !$form->{orphaned};

	$dbh->commit;
}


sub save_account {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn off AutoCommit
	my $dbh = $form->{dbh};

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

	my @queryargs;
	@queryargs = ($form->{accno}, $form->{description}, 
			$form->{charttype}, $form->{gifi_accno}, 
			$form->{category}, $form->{"link"},
			$form->{contra});
	# if we have an id then replace the old record
	if ($form->{id}) {
		$query = qq|
			UPDATE chart SET accno = ?,
			       description = ?,
			       charttype = ?,
			       gifi_accno = ?,
			       category = ?,
			       link = ?,
			       contra = ?
			 WHERE id = ?|;
		push @queryargs, $form->{id};
	} else {
		$query = qq|
			INSERT INTO chart 
                                    (accno, description, charttype, 
			            gifi_accno, category, link, contra)
			     VALUES (?, ?, ?, ?, ?, ?, ?)|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute(@queryargs) || $form->dberror($query);
	$sth->finish;

	$chart_id = $dbh->quote($form->{id});

	if (! $form->{id}) {
		# get id from chart
		$query = qq|
			SELECT id
			FROM   chart
			WHERE  accno = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute($form->{accno});
		($chart_id) = $sth->fetchrow_array();
		$sth->finish;
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

	$rc;
}



sub delete_account {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn off AutoCommit
	my $dbh = $form->{dbh};
	my $sth;
	my $query = qq|
		SELECT count(*)
		  FROM acc_trans
		 WHERE chart_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id});
	my ($rowcount) = $sth->fetchrow_array(); 
	
	if ($rowcount) {
		$form->error(
			"Cannot delete accounts with associated transactions!"
			);
	}


	# delete chart of account record
	$query = qq|
		DELETE FROM chart
		      WHERE id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	# set inventory_accno_id, income_accno_id, expense_accno_id to defaults
	$query = qq|
		UPDATE parts
		   SET inventory_accno_id = (SELECT value::int
		                               FROM defaults
					      WHERE setting_key = 
							'inventory_accno_id')::
		 WHERE inventory_accno_id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	for (qw(income_accno_id expense_accno_id)){
		$query = qq|
			UPDATE parts
			   SET $_ = (SELECT value::int
			               FROM defaults
			              WHERE setting_key = '$_')
			 WHERE $_ = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute($form->{id}) || $form->dberror($query);
		$sth->finish;
	}

	foreach my $table (qw(partstax customertax vendortax tax)) {
		$query = qq|
			DELETE FROM $table
			      WHERE chart_id = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute($form->{id}) || $form->dberror($query);
		$sth->finish;
	}

	# commit and redirect
	my $rc = $dbh->commit;

	$rc;
}


sub gifi_accounts {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $query = qq|
		  SELECT accno, description
		    FROM gifi
		ORDER BY accno|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->commit;

}



sub get_gifi {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};
	my $sth;

	my $query = qq|
		SELECT accno, description
		  FROM gifi
		 WHERE accno = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{accno}) || $form->dberror($query);
	($form->{accno}, $form->{description}) = $sth->fetchrow_array();

	$sth->finish;

	# check for transactions 
	$query = qq|
		SELECT count(*) 
		  FROM acc_trans a
		  JOIN chart c ON (a.chart_id = c.id)
		  JOIN gifi g ON (c.gifi_accno = g.accno)
		 WHERE g.accno = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{accno}) || $form->dberror($query);
	($numrows) = $sth->fetchrow_array;
	if (($numrows * 1) == 0){
		$form->{orphaned} = 1;
	} else {
		$form->{orphaned} = 0;
	}

	$dbh->commit;

}


sub save_gifi {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};

	$form->{accno} =~ s/( |')//g;

	foreach my $item (qw(accno description)) {
		$form->{$item} =~ s/-(-+)/-/g;
		$form->{$item} =~ s/ ( )+/ /g;
	}

	my @queryargs = ($form->{accno}, $form->{description});
	# id is the old account number!
	if ($form->{id}) {
		$query = qq|
			UPDATE gifi 
			   SET accno = ?,
			       description = ?
			 WHERE accno = ?|;
		push @queryargs, $form->{id};

	} else {
		$query = qq|
			INSERT INTO gifi (accno, description)
			     VALUES (?, ?)|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute(@queryargs) || $form->dberror; 
	$sth->finish;
	$dbh->commit;

}


sub delete_gifi {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	# id is the old account number!
	$query = qq|
		DELETE FROM gifi
		      WHERE accno = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
	$sth->finish;
	$dbh->commit;

}


sub warehouses {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$form->sort_order();
	my $query = qq|
		  SELECT id, description
		    FROM warehouse
		ORDER BY description $form->{direction}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->commit;

}


sub get_warehouse {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};
	my $sth;

	my $query = qq|
		SELECT description
		  FROM warehouse
		 WHERE id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
	($form->{description}) = $sth->fetchrow_array;
	$sth->finish;

	# see if it is in use
	$query = qq|
		SELECT count(*) 
		  FROM inventory
		 WHERE warehouse_id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id});

	($form->{orphaned}) = $sth->fetchrow_array;
	if (($form->{orphaned} * 1) == 0){
		$form->{orphaned} = 1;
	} else {
		$form->{orphaned} = 0;
	}

	$dbh->commit;
}


sub save_warehouse {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $sth;
	my @queryargs = ($form->{description});

	$form->{description} =~ s/-(-)+/-/g;
	$form->{description} =~ s/ ( )+/ /g;


	if ($form->{id}) {
		$query = qq|
			UPDATE warehouse 
			   SET description = ?
			 WHERE id = ?|;
		push @queryargs, $form->{id};
	} else {
		$query = qq|
			INSERT INTO warehouse (description)
			     VALUES (?)|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute(@queryargs) || $form->dberror($query);
	$sth->finish;
	$dbh->commit;

}


sub delete_warehouse {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$query = qq|
		DELETE FROM warehouse
		      WHERE id = ?|;

	$dbh->prepare($query)->execute($form->{id}) || $form->dberror($query);
	$dbh->commit;

}



sub departments {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

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
	$dbh->commit;

}



sub get_department {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};
	my $sth;

	my $query = qq|
		SELECT description, role
		  FROM department
		 WHERE id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id});
	($form->{description}, $form->{role}) = $sth->fetchrow_array;
	$sth->finish;

	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	# see if it is in use 
	$query = qq|
		SELECT count(*) 
		  FROM dpt_trans
		 WHERE department_id = ? |;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id});
	($form->{orphaned}) = $sth->fetchrow_array;
	if (($form->{orphaned} * 1) == 0){
		$form->{orphaned} = 1;
	} else {
		$form->{orphaned} = 0;
	}

	$dbh->commit;
}


sub save_department {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$form->{description} =~ s/-(-)+/-/g;
	$form->{description} =~ s/ ( )+/ /g;
	my $sth;
	my @queryargs = ($form->{description}, $form->{role});
	if ($form->{id}) {
		$query = qq|
			UPDATE department 
			   SET description = ?,
			       role = ?
			 WHERE id = ?|;
		push @queryargs, $form->{id};

	} else {
		$query = qq|
			INSERT INTO department (description, role)
			     VALUES (?, ?)|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute(@queryargs) || $form->dberror($query);
	$dbh->commit;

}


sub delete_department {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$query = qq|
		DELETE FROM department
		      WHERE id = ?|;

	$dbh->prepare($query)->execute($form->{id});
	$dbh->commit;

}


sub business {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$form->sort_order();
	my $query = qq|
		  SELECT id, description, discount
		    FROM business
		ORDER BY description $form->{direction}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->commit;

}


sub get_business {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $query = qq|
		SELECT description, discount
		  FROM business
		 WHERE id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($form->{id});
	($form->{description}, $form->{discount}) = $sth->fetchrow_array();
	$dbh->commit;

}


sub save_business {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$form->{description} =~ s/-(-)+/-/g;
	$form->{description} =~ s/ ( )+/ /g;
	$form->{discount} /= 100;

	my $sth;
	my @queryargs = ($form->{description}, $form->{discount});

	if ($form->{id}) {
		$query = qq|
			UPDATE business 
			   SET description = ?,
			       discount = ?
			 WHERE id = ?|;
		push @queryargs, $form->{id};

	} else {
		$query = qq|INSERT INTO business (description, discount)
						 VALUES (?, ?)|;
	}

	$dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
	$dbh->commit;

}


sub delete_business {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$query = qq|
		DELETE FROM business
		      WHERE id = ?|;

	$dbh->prepare($query)->execute($form->{id}) || $form->dberror($query);
	$dbh->commit;

}


sub sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

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
	$dbh->commit;

}


sub get_sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $query = qq|
		SELECT code, sictype, description
		  FROM sic
		 WHERE code = |.$dbh->quote($form->{code});

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;
	$dbh->commit;

}


sub save_sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	foreach my $item (qw(code description)) {
		$form->{$item} =~ s/-(-)+/-/g;
	}
	my $sth;
	@queryargs = ($form->{code}, $form->{sictype}, $form->{description});
	# if there is an id
	if ($form->{id}) {
		$query = qq|
			UPDATE sic 
			   SET code = ?,
			       sictype = ?,
			       description = ?
			 WHERE code = ?)|;
		push @queryargs, $form->{id};

	} else {
		$query = qq|
		INSERT INTO sic (code, sictype, description)
		     VALUES (?, ?, ?)|;

	}

	$dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
	$dbh->commit;

}


sub delete_sic {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$query = qq|
		DELETE FROM sic
		      WHERE code = ?|;

	$dbh->prepare($query)->execute($form->{code});
	$dbh->commit;

}


sub language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$form->{sort} = "code" unless $form->{sort};
	my @a = qw(code description);

	my %ordinal = ( code		=> 1,
					description	=> 2 );

	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query = qq|
		  SELECT code, description
		    FROM language
		ORDER BY $sortorder|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{ALL} }, $ref;
	}

	$sth->finish;
	$dbh->commit;

}


sub get_language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	## needs fixing (SELECT *...)
	my $query = qq|
		SELECT *
		  FROM language
		 WHERE code = ?|;

	my $sth = $dbh->prepare($query);
	$sth->execute($form->{code}) || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);

	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;
	$dbh->commit;

}


sub save_language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$form->{code} =~ s/ //g;

	foreach my $item (qw(code description)) {
		$form->{$item} =~ s/-(-)+/-/g;
		$form->{$item} =~ s/ ( )+/-/g;
	}
	my $sth;
	my @queryargs = ($form->{code}, $form->{description});
	# if there is an id
	if ($form->{id}) {
		$query = qq|
			UPDATE language 
			   SET code = ?,
			       description = ?
			 WHERE code = ?|;
		push @queryargs, $form->{id};

	} else {
		$query = qq|
			INSERT INTO language (code, description)
			     VALUES (?, ?)|;
	}

	$dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
	$dbh->commit;

}


sub delete_language {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	$query = qq|
		DELETE FROM language
		      WHERE code = |.$dbh->quote($form->{code});

	$dbh->do($query) || $form->dberror($query);
	$dbh->{dbh};

}


sub recurring_transactions {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};

	my $query = qq|SELECT value FROM defaults where setting_key = 'curr'|;

	my ($defaultcurrency) = $dbh->selectrow_array($query);
	$defaultcurrency = $dbh->quote($defaultcurrency =~ s/:.*//g);

	$form->{sort} ||= "nextdate";
	my @a = ($form->{sort});
	my $sortorder = $form->sort_order(\@a);

	$query = qq|
		   SELECT 'ar' AS module, 'ar' AS transaction, a.invoice,
		          n.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 
		          'customer' AS vc,
		          ex.buy AS exchangerate, a.curr,
	                  (s.nextdate IS NULL OR s.nextdate > s.enddate) 
                          AS expired
		     FROM recurring s
		     JOIN ar a ON (a.id = s.id)
		     JOIN customer n ON (n.id = a.customer_id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex 
		          ON (ex.curr = a.curr AND a.transdate = ex.transdate)

		    UNION

		  SELECT 'ap' AS module, 'ap' AS transaction, a.invoice,
		          n.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 'vendor' AS vc,
		          ex.sell AS exchangerate, a.curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN ap a ON (a.id = s.id)
		     JOIN vendor n ON (n.id = a.vendor_id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex ON 
		          (ex.curr = a.curr AND a.transdate = ex.transdate)

		    UNION

		   SELECT 'gl' AS module, 'gl' AS transaction, FALSE AS invoice,
		          a.description, (SELECT SUM(ac.amount) 
		     FROM acc_trans ac 
		    WHERE ac.trans_id = a.id 
		      AND ac.amount > 0) AS amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, '' AS vc,
		          '1' AS exchangerate, $defaultcurrency AS curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN gl a ON (a.id = s.id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)

		    UNION

		   SELECT 'oe' AS module, 'so' AS transaction, FALSE AS invoice,
		          n.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 
		          'customer' AS vc,
		          ex.buy AS exchangerate, a.curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN oe a ON (a.id = s.id)
		     JOIN customer n ON (n.id = a.customer_id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex ON 
		          (ex.curr = a.curr AND a.transdate = ex.transdate)
		    WHERE a.quotation = '0'

		    UNION

		   SELECT 'oe' AS module, 'po' AS transaction, FALSE AS invoice,
		          n.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 'vendor' AS vc,
		          ex.sell AS exchangerate, a.curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN oe a ON (a.id = s.id)
		     JOIN vendor n ON (n.id = a.vendor_id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex ON 
		          (ex.curr = a.curr AND a.transdate = ex.transdate)
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
				for (keys %e) { 
					$form->{transactions}{$transaction}->[$i]->{recurringemail} .= "${_}:"; 
				}
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


	$dbh->commit;

}

sub recurring_details {

	my ($self, $myconfig, $form, $id) = @_;

	my $dbh = $form->{dbh};
	my $query = qq|
		   SELECT s.*, ar.id AS arid, ar.invoice AS arinvoice,
		          ap.id AS apid, ap.invoice AS apinvoice,
		          ar.duedate - ar.transdate AS overdue,
		          ar.datepaid - ar.transdate AS paid,
		          oe.reqdate - oe.transdate AS req,
		          oe.id AS oeid, oe.customer_id, oe.vendor_id
		     FROM recurring s
		LEFT JOIN ar ON (ar.id = s.id)
		LEFT JOIN ap ON (ap.id = s.id)
		LEFT JOIN oe ON (oe.id = s.id)
		    WHERE s.id = ?|;

	my $sth = $dbh->prepare($query);
	$sth->execute($id) || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
	$form->{vc} = "customer" if $ref->{customer_id};
	$form->{vc} = "vendor" if $ref->{vendor_id};
	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	$form->{invoice} = ($form->{arid} && $form->{arinvoice});
	$form->{invoice} = ($form->{apid} && $form->{apinvoice}) unless $form->{invoice};

	$query = qq|
		SELECT * 
		  FROM recurringemail
		 WHERE id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($id) || $form->dberror($query);

	$form->{recurringemail} = "";

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{recurringemail} .= "$ref->{formname}:$ref->{format}:";
		$form->{message} = $ref->{message};
	}

	$sth->finish;

	$query = qq|
		SELECT * 
		  FROM recurringprint
		 WHERE id = ?|;

	$sth = $dbh->prepare($query);
	$sth->execute($id) || $form->dberror($query);

	$form->{recurringprint} = "";
		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{recurringprint} .= 
			"$ref->{formname}:$ref->{format}:$ref->{printer}:";
	}

	$sth->finish;

	chop $form->{recurringemail};
	chop $form->{recurringprint};

	for (qw(arinvoice apinvoice)) { delete $form->{$_} }

	$dbh->commit;

}


sub update_recurring {

	my ($self, $myconfig, $form, $id) = @_;

	my $dbh = $form->{dbh};

	$id = $dbh->quote($id);
	my $query = qq|
		SELECT nextdate, repeat, unit
		  FROM recurring
		 WHERE id = $id|;

	my ($nextdate, $repeat, $unit) = $dbh->selectrow_array($query);

	$nextdate = $dbh->quote($nextdate);
	my $interval = $dbh->quote("$repeat $unit");
	# check if it is the last date
	$query = qq|
		SELECT (date $nextdate + interval $interval) > enddate
		  FROM recurring
		 WHERE id = $id|;

	my ($last_repeat) = $dbh->selectrow_array($query);
	if ($last_repeat) {
		$advance{$myconfig->{dbdriver}} = "NULL";
	}

	$query = qq|
		UPDATE recurring 
		   SET nextdate = (date $nextdate + interval $interval)
		 WHERE id = $id|;

	$dbh->do($query) || $form->dberror($query);

	$dbh->commit;

}


sub check_template_name {

	my ($self, $myconfig, $form) = @_;

	my @allowedsuff = qw(css tex txt html xml);
	if ($form->{file} =~ /^(.:)*?\/|:|\.\.\/|^\//){
		$form->error("Directory transversal not allowed.");
	}
	if ($form->{file} =~ /^${LedgerSMB::Sysconfig::backuppath}\//){
		$form->error("Not allowed to access ${LedgerSMB::Sysconfig::backuppath}/ with this method");
	}
	my $whitelisted = 0;
	for (@allowedsuff){
		if ($form->{file} =~ /$_$/){
			$whitelisted = 1;
		}
	}
	if (!$whitelisted){
		$form->error("Error:  File is of type that is not allowed.");
	}

	if ($form->{file} !~ /^$myconfig->{templates}\//){
		$form->error("Not in a whitelisted directory: $form->{file}") unless $form->{file} =~ /^css\//;
	}
}


sub load_template {

	my ($self, $myconfig, $form) = @_;

	$self->check_template_name(\%$myconfig, \%$form);
	open(TEMPLATE, '<', "$form->{file}") or $form->error("$form->{file} : $!");

	while (<TEMPLATE>) {
		$form->{body} .= $_;
	}

	close(TEMPLATE);

}


sub save_template {

	my ($self, $myconfig, $form) = @_;

	$self->check_template_name(\%$myconfig, \%$form);
	open(TEMPLATE, '>', "$form->{file}") or $form->error("$form->{file} : $!");

	# strip 
	$form->{body} =~ s/\r//g;
	print TEMPLATE $form->{body};

	close(TEMPLATE);

}


sub save_preferences {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	# get username, is same as requested?
	my @queryargs;
	my $query = qq|
		SELECT login
		  FROM employee
		 WHERE login = ?|;
	@queryargs = ($form->{login});
	my $sth = $dbh->prepare($query);
	$sth->execute(@queryargs) || $form->dberror($query);
	my ($dbusername) = $sth->fetchrow_array;
	$sth->finish;

	return 0 if ($dbusername ne $form->{login});

	# update name
	$query = qq|
		UPDATE employee
		   SET name = ?
		 WHERE login = ?|;

	@queryargs = ($form->{name}, $form->{login});
	$dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);

	# get default currency
	$query = qq|
		SELECT value, (SELECT value FROM defaults
		                WHERE setting_key = 'businessnumber')
		  FROM defaults
		 WHERE setting_key = 'curr'|;

	($form->{currency}, $form->{businessnumber}) = 
			$dbh->selectrow_array($query);
	$form->{currency} =~ s/:.*//;

	$dbh->commit;

	my $myconfig = LedgerSMB::User->new($form->{login});

	map {$myconfig->{$_} = $form->{$_} if exists $form->{$_}}
		qw(name email dateformat signature numberformat vclimit tel fax
		company menuwidth countrycode address timeout stylesheet
		printer password);

	$myconfig->{password} = $form->{new_password} if ($form->{old_password} ne $form->{new_password});

	$myconfig->save_member();

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
	my $dbh = $form->{dbh};
	# save defaults
	$sth_plain = $dbh->prepare("
		UPDATE defaults SET value = ? WHERE setting_key = ?");
	$sth_accno = $dbh->prepare(qq|
		UPDATE defaults
                   SET value = (SELECT id
                                               FROM chart
                                              WHERE accno = ?)
		 WHERE setting_key = ?|);
	my %translation = (
		inventory_accno_id => 'IC',
		income_accno_id => 'IC_income',
		expense_accno_id => 'IC_expense',
		fxgain_accno_id => 'FX_gain',
		fxloss_accno_id => 'FX_loss'	
	);
	for (
		qw(inventory_accno_id income_accno_id expense_accno_id 
		fxgain_accno_id fxloss_accno_id glnumber sinumber vinumber
		sonumber ponumber sqnumber rfqnumber partnumber employeenumber
		customernumber vendornumber projectnumber yearend curr
		weightunit businessnumber)
	){
		my $val = $form->{$_};

		if ($translation{$_}){
			$val = $form->{$translation{$_}};
		} 
		if ($_ =~ /accno/){
			$sth_accno->execute($val, $_) 
				|| $form->dberror("Saving $_");
		} else {
			$sth_plain->execute($val, $_)
				|| $form->dberror("Saving $_");
		}

	}
	my $rc = $dbh->commit;

	$rc;

}


sub defaultaccounts {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	# get defaults from defaults table
	my $query = qq|
		SELECT setting_key, value FROM defaults
		 WHERE setting_key LIKE ?|;
	my $sth = $dbh->prepare($query);
	$sth->execute('%accno_id') || $form->dberror($query);

	my $ref;
	while ($ref = $sth->fetchrow_hashref(NAME_lc)){
		$form->{$ref->{setting_key}} = $ref->{value};
	}

	$form->{defaults}{IC} = $form->{inventory_accno_id};
	$form->{defaults}{IC_income} = $form->{income_accno_id};
	$form->{defaults}{IC_sale} = $form->{income_accno_id};
	$form->{defaults}{IC_expense} = $form->{expense_accno_id};
	$form->{defaults}{IC_cogs} = $form->{expense_accno_id};
	$form->{defaults}{FX_gain} = $form->{fxgain_accno_id};
	$form->{defaults}{FX_loss} = $form->{fxloss_accno_id};

	$sth->finish;

	$query = qq|
		SELECT id, accno, description, link
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


	$query = qq|
		    SELECT id, accno, description
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

	$dbh->commit;

}


sub taxes {

	my ($self, $myconfig, $form) = @_;
	my $taxaccounts = '';

	# connect to database
	my $dbh = $form->{dbh};

	my $query = qq|
		  SELECT c.id, c.accno, c.description, 
		         t.rate * 100 AS rate, t.taxnumber, t.validto,
			 t.pass, m.taxmodulename
		    FROM chart c
		    JOIN tax t ON (c.id = t.chart_id)
		    JOIN taxmodule m ON (t.taxmodule_id = m.taxmodule_id)
		ORDER BY 3, 6|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{taxrates} }, $ref;
		$taxaccounts .= " " . $ref{accno};
	}

	$sth->finish;
	
	$query = qq|
		SELECT taxmodule_id, taxmodulename FROM taxmodule
		ORDER BY 2|;
	
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{"taxmodule_".$ref->{taxmodule_id}} = 
			$ref->{taxmodulename};
	}

	$sth->finish;

	$dbh->commit;

}


sub save_taxes {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $query = qq|DELETE FROM tax|;
	$dbh->do($query) || $form->dberror($query);


	$query = qq|
		INSERT INTO tax (chart_id, rate, taxnumber, validto, 
			pass, taxmodule_id)
			VALUES (?, ?, ?, ?, ?, ?)|;

	my $sth = $dbh->prepare($query);
	foreach my $item (split / /, $form->{taxaccounts}) {
		my ($chart_id, $i) = split /_/, $item;
		my $rate = $form->parse_amount(
			$myconfig, $form->{"taxrate_$i"}) / 100;
		my $validto = $form->{"validto_$i"};
		$validto = undef if not $validto;
		my @queryargs = ($chart_id, $rate, $form->{"taxnumber_$i"},
			$validto, $form->{"pass_$i"},
			$form->{"taxmodule_id_$i"});

		$sth->execute(@queryargs) || $form->dberror($query);
	}

	my $rc = $dbh->commit;

	$rc;

}


sub backup {

	my ($self, $myconfig, $form) = @_;

	my $mail;
	my $err;

	my @t = localtime(time);
	$t[4]++;
	$t[5] += 1900;
	$t[3] = substr("0$t[3]", -2);
	$t[4] = substr("0$t[4]", -2);

	my $boundary = time;
	my $tmpfile = "${LedgerSMB::Sysconfig::backuppath}/$boundary.$globalDBname-$form->{dbversion}-$t[5]$t[4]$t[3].sql";
	$form->{OUT} = "$tmpfile";

	open(OUT, '>', "$form->{OUT}") or $form->error("$form->{OUT} : $!");

	# get sequences, functions and triggers

	my $today = scalar localtime;

	# compress backup if gzip defined
	my $suffix = "";

	if ($form->{media} eq 'email') {
		print OUT qx(PGPASSWORD="$globalDBPassword" pg_dump -U $globalDBUserName -h $globalDBhost -Fc -p $globalDBport $globalDBname);
		close OUT;
		use LedgerSMB::Mailer;
		$mail = new Mailer;

		$mail->{to} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
		$mail->{from} = qq|"$myconfig->{name}" <$myconfig->{email}>|;
		$mail->{subject} = "LedgerSMB Backup / $globalDBname-$form->{dbversion}-$t[5]$t[4]$t[3].sql$suffix";
		@{ $mail->{attachments} } = ($tmpfile);
		$mail->{version} = $form->{version};
		$mail->{fileid} = "$boundary.";
		$mail->{format} = "plain";
		$mail->{format} = "octet-stream";

		$myconfig->{signature} =~ s/\\n/\n/g;
		$mail->{message} = "-- \n$myconfig->{signature}";

		$err = $mail->send;
	}

	if ($form->{media} eq 'file') {

		open(IN, '<', "$tmpfile") or $form->error("$tmpfile : $!");
		open(OUT, ">-") or $form->error("STDOUT : $!");

		print OUT qq|Content-Type: application/file;\n| .
		qq|Content-Disposition: attachment; filename="$myconfig->{dbname}-$form->{dbversion}-$t[5]$t[4]$t[3].sql$suffix"\n\n|;
		print OUT qx(PGPASSWORD="$globalDBPassword" pg_dump -U $globalDBUserName -h $globalDBhost -Fc -p $globalDBport $globalDBname);
	}

	unlink "$tmpfile";

}


sub closedto {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};

	my $query = qq|
		SELECT (SELECT value FROM defaults 
		         WHERE setting_key = 'closedto'), 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'revtrans'), 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'audittrail')|;

	($form->{closedto}, $form->{revtrans}, $form->{audittrail}) 
		= $dbh->selectrow_array($query);

	$dbh->commit;

}


sub closebooks {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
	my $query = qq|
		UPDATE defaults SET value = ? 
		 WHERE setting_key = ?|;
	my $sth = $dbh->prepare($query);
	for (qw(revtrans closedto audittrail)){
		
		if ($form->{$_}){
			$val = 1;
		} else {
			$val = 0;
		}
		$sth->execute($val, $_);
	}


	if ($form->{removeaudittrail}) {
		$query = qq|
			DELETE FROM audittrail
			 WHERE transdate < | . 
				$dbh->quote($form->{removeaudittrail});

		$dbh->do($query) || $form->dberror($query);
	}

	$dbh->commit;

}


sub earningsaccounts {

	my ($self, $myconfig, $form) = @_;

	my ($query, $sth, $ref);

	# connect to database
	my $dbh = $form->{dbh};

	# get chart of accounts
	$query = qq|
		    SELECT accno,description
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
	$dbh->commit;
}


sub post_yearend {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn off AutoCommit
	my $dbh = $form->{dbh};

	my $query;
	my @queryargs;
	my $uid = localtime;
	$uid .= "$$";

	$query = qq|
		INSERT INTO gl (reference, employee_id)
		     VALUES (?, (SELECT id FROM employee
		                  WHERE login = ?))|;

	$dbh->prepare($query)->execute($uid, $form->{login}) 
			|| $form->dberror($query);

	$query = qq|
		SELECT id 
		  FROM gl
		 WHERE reference = ?|;

	my $sth = $dbh->prepare($query);
	$sth->execute($uid);
	($form->{id}) = $sth->fetchrow_array;

	$query = qq|
		UPDATE gl 
		   SET reference = ?,
		       description = ?,
		       notes = ?,
		       transdate = ?,
		       department_id = 0
		 WHERE id = ?|;

	@queryargs = ($form->{reference}, $form->{description}, $form->{notes},
		$form->{transdate}, $form->{id});
	$dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);

	my $amount;
	my $accno;
	$query = qq|
		INSERT INTO acc_trans (trans_id, chart_id, amount, transdate, 
		            source)
		     VALUES (?, (SELECT id
		                   FROM chart
		                  WHERE accno = ?),
		            ?, ?, ?)|;


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
			my @args = ($form->{id}, $accno, $amount,
				$form->{transdate}, $form->{reference});

			$dbh->prepare($query)->execute(@args) 
				|| $form->dberror($query);
		}
	}

	$query = qq|
		INSERT INTO yearend (trans_id, transdate)
		     VALUES (?, ?)|;

	$dbh->prepare($query)->execute($form->{id}, $form->{transdate}) 
		|| $form->dberror($query);

	my %audittrail = ( 
		tablename	=> 'gl',
		reference	=> $form->{reference},
		formname	=> 'yearend',
		action	=> 'posted',
		id	=> $form->{id} );

	$form->audittrail($dbh, "", \%audittrail);

	# commit and redirect
	my $rc = $dbh->commit;

	$rc;

}

sub get_all_defaults{
	my ($self, $form) = @_;
	my $dbh = $form->{dbh};
	my $query = "select setting_key, value FROM defaults";
	$sth = $dbh->prepare($query);
	$sth->execute;
	while (($skey, $value) = $sth->fetchrow_array()){
		$form->{$skey} = $value;
	}

	$self->defaultaccounts(undef, $form);
	$dbh->commit;
}

1;
