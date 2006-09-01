#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# Check and receipt printing payment module backend routines
# Number to text conversion routines are in
# locale/{countrycode}/Num2text
#
#======================================================================

package CP;


sub new {

	my ($type, $countrycode) = @_;

	$self = {};

	if ($countrycode) {

		if (-f "locale/$countrycode/Num2text") {
			require "locale/$countrycode/Num2text";
		} else {
			use LedgerSMB::Num2text;
		}

	} else {
		use LedgerSMB::Num2text;
	}

	bless $self, $type;

}


sub paymentaccounts {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query = qq|SELECT accno, description, link
					 FROM chart
					WHERE link LIKE '%$form->{ARAP}%'
				 ORDER BY accno|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$form->{PR}{$form->{ARAP}} = ();
	$form->{PR}{"$form->{ARAP}_paid"} = ();

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

		foreach my $item (split /:/, $ref->{link}) {

			if ($item eq $form->{ARAP}) {
				push @{ $form->{PR}{$form->{ARAP}} }, $ref;
			}

			if ($item eq "$form->{ARAP}_paid") {
				push @{ $form->{PR}{"$form->{ARAP}_paid"} }, $ref;
			}
		}
	}

	$sth->finish;

	# get currencies and closedto
	$query = qq|SELECT curr, closedto, current_date
				  FROM defaults|;

	($form->{currencies}, $form->{closedto}, $form->{datepaid}) = $dbh->selectrow_array($query);

	if ($form->{payment} eq 'payments') {
		# get language codes
		$query = qq|SELECT *
					  FROM language
				  ORDER BY 2|;

		$sth = $dbh->prepare($query);
		$sth->execute || $self->dberror($query);

		$form->{all_language} = ();

		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			push @{ $form->{all_language} }, $ref;
		}

		$sth->finish;

		$form->all_departments($myconfig, $dbh, $form->{vc});
	}

	$dbh->disconnect;

}


sub get_openvc {

	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect($myconfig);

	my $arap = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
	my $query = qq|SELECT count(*)
					 FROM $form->{vc} ct, $arap a
					WHERE a.$form->{vc}_id = ct.id
					  AND a.amount != a.paid|;

	my ($count) = $dbh->selectrow_array($query);

	my $sth;
	my $ref;
	my $i = 0;

	my $where = qq|WHERE a.$form->{vc}_id = ct.id
					 AND a.amount != a.paid|;

	if ($form->{$form->{vc}}) {
		my $var = $form->like(lc $form->{$form->{vc}});
		$where .= " AND lower(name) LIKE '$var'";
	}

	# build selection list
	$query = qq|SELECT DISTINCT ct.*
				  FROM $form->{vc} ct, $arap a
				$where
			  ORDER BY name|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$i++;
		push @{ $form->{name_list} }, $ref;
	}

	$sth->finish;

	$form->all_departments($myconfig, $dbh, $form->{vc});

	# get language codes
	$query = qq|SELECT *
				  FROM language
			  ORDER BY 2|;

	$sth = $dbh->prepare($query);
	$sth->execute || $self->dberror($query);

	$form->{all_language} = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_language} }, $ref;
	}

	$sth->finish;

	# get currency for first name
	if (@{ $form->{name_list} }) {
		$query = qq|SELECT curr 
					  FROM $form->{vc}
					 WHERE id = $form->{name_list}->[0]->{id}|;

		($form->{currency}) = $dbh->selectrow_array($query);
		$form->{currency} ||= $form->{defaultcurrency};
	}

	$dbh->disconnect;

	$i;
}


sub get_openinvoices {

	my ($self, $myconfig, $form) = @_;

	my $null;
	my $department_id;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $where = qq|WHERE a.$form->{vc}_id = $form->{"$form->{vc}_id"}
					 AND a.amount != a.paid|;

	$where .= qq| AND a.curr = '$form->{currency}'| if $form->{currency};

	my $sortorder = "transdate, invnumber";

	my ($buysell);

	if ($form->{vc} eq 'customer') {
		$buysell = "buy";
	} else {
		$buysell = "sell";
	}

	if ($form->{payment} eq 'payments') {

		$where = qq|WHERE a.amount != a.paid|;
		$where .= qq| AND a.curr = '$form->{currency}'| if $form->{currency};

		if ($form->{duedatefrom}) {
			$where .= qq| AND a.duedate >= '$form->{duedatefrom}'|;
		}

		if ($form->{duedateto}) {
			$where .= qq| AND a.duedate <= '$form->{duedateto}'|;
		}

		$sortorder = "name, transdate";
	}


	($null, $department_id) = split /--/, $form->{department};

	if ($department_id) {
		$where .= qq| AND a.department_id = $department_id|;
	}

	my $query = qq|SELECT a.id, a.invnumber, a.transdate, a.amount, a.paid,
						  a.curr, c.name, a.$form->{vc}_id, c.language_code
					 FROM $form->{arap} a
					 JOIN $form->{vc} c ON (c.id = a.$form->{vc}_id)
				   $where
				 ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$query = qq|SELECT s.spoolfile
				  FROM status s
				 WHERE s.formname = '$form->{formname}'
				   AND s.trans_id = ?|;

	my $vth = $dbh->prepare($query);

	my $spoolfile;

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

		# if this is a foreign currency transaction get exchangerate
		$ref->{exchangerate} = $form->get_exchangerate($dbh, $ref->{curr}, $ref->{transdate}, $buysell) if ($form->{currency} ne $form->{defaultcurrency});

		$vth->execute($ref->{id});
		$ref->{queue} = "";
	
		while (($spoolfile) = $vth->fetchrow_array) {
			$ref->{queued} .= "$form->{formname} $spoolfile ";
		}

		$vth->finish;
		$ref->{queued} =~ s/ +$//g;

		push @{ $form->{PR} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}



sub post_payment {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn AutoCommit off
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $sth;

	my ($paymentaccno) = split /--/, $form->{account};

	# if currency ne defaultcurrency update exchangerate
	if ($form->{currency} ne $form->{defaultcurrency}) {

		$form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate});

		if ($form->{vc} eq 'customer') {
			$form->update_exchangerate($dbh, $form->{currency}, $form->{datepaid}, $form->{exchangerate}, 0);
		} else {
			$form->update_exchangerate($dbh, $form->{currency}, $form->{datepaid}, 0, $form->{exchangerate});
		}

	} else {
		$form->{exchangerate} = 1;
	}

	my $query = qq|SELECT fxgain_accno_id, fxloss_accno_id
					 FROM defaults|;

	my ($fxgain_accno_id, $fxloss_accno_id) = $dbh->selectrow_array($query);

	my ($buysell);

	if ($form->{vc} eq 'customer') {
		$buysell = "buy";
	} else {
		$buysell = "sell";
	}

	my $ml;
	my $where;

	if ($form->{ARAP} eq 'AR') {

		$ml = 1;
		$where = qq| (c.link = 'AR' OR c.link LIKE 'AR:%') |;

	} else {

		$ml = -1;
		$where = qq| (c.link = 'AP' OR c.link LIKE '%:AP' OR c.link LIKE '%:AP:%') |;

	}

	my $paymentamount = $form->parse_amount($myconfig, $form->{amount});

	# query to retrieve paid amount
	$query = qq|SELECT paid 
				  FROM $form->{arap}
				 WHERE id = ?
			FOR UPDATE|;

	my $pth = $dbh->prepare($query) || $form->dberror($query);

	my %audittrail;

	# go through line by line
	for my $i (1 .. $form->{rowcount}) {

		$form->{"paid_$i"} = $form->parse_amount($myconfig, $form->{"paid_$i"});
		$form->{"due_$i"} = $form->parse_amount($myconfig, $form->{"due_$i"});

		if ($form->{"checked_$i"} && $form->{"paid_$i"}) {

			$paymentamount -= $form->{"paid_$i"};

			# get exchangerate for original 
			$query = qq|SELECT $buysell
						  FROM exchangerate e
						  JOIN $form->{arap} a ON (a.transdate = e.transdate)
						 WHERE e.curr = '$form->{currency}'
						   AND a.id = $form->{"id_$i"}|;

			my ($exchangerate) = $dbh->selectrow_array($query);

			$exchangerate = 1 unless $exchangerate;

			$query = qq|SELECT c.id
						  FROM chart c
						  JOIN acc_trans a ON (a.chart_id = c.id)
						 WHERE $where
						   AND a.trans_id = $form->{"id_$i"}|;

			my ($id) = $dbh->selectrow_array($query);

			$amount = $form->round_amount($form->{"paid_$i"} * $exchangerate, 2);

			# add AR/AP
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate, amount)
						VALUES ($form->{"id_$i"}, $id, '$form->{datepaid}', $amount * $ml)|;

			$dbh->do($query) || $form->dberror($query);

			# add payment
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
												amount, source, memo)
						VALUES ($form->{"id_$i"}, (SELECT id 
													 FROM chart
													WHERE accno = '$paymentaccno'),
								'$form->{datepaid}', $form->{"paid_$i"} * $ml * -1, |
								.$dbh->quote($form->{source}).qq|, |
								.$dbh->quote($form->{memo}).qq|)|;

			$dbh->do($query) || $form->dberror($query);

			# add exchangerate difference if currency ne defaultcurrency
			$amount = $form->round_amount($form->{"paid_$i"} * ($form->{exchangerate} - 1), 2);

			if ($amount) {
				# exchangerate difference
				$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
													amount, cleared, fx_transaction, source)
							VALUES ($form->{"id_$i"}, (SELECT id 
														 FROM chart
														WHERE accno = '$paymentaccno'),
									'$form->{datepaid}', $amount * $ml * -1, '0', '1', |
									.$dbh->quote($form->{source}).qq|)|;

				$dbh->do($query) || $form->dberror($query);

				# gain/loss
				$amount = ($form->round_amount($form->{"paid_$i"} * $exchangerate,2) - $form->round_amount($form->{"paid_$i"} * $form->{exchangerate},2)) * $ml * -1;

				if ($amount) {

					my $accno_id = ($amount > 0) ? $fxgain_accno_id : $fxloss_accno_id;

					$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
														amount, cleared, fx_transaction)
								VALUES ($form->{"id_$i"}, $accno_id,
										'$form->{datepaid}', $amount, '0', '1')|;

					$dbh->do($query) || $form->dberror($query);
				}
			}

			$form->{"paid_$i"} = $form->round_amount($form->{"paid_$i"} * $exchangerate, 2);

			$pth->execute($form->{"id_$i"}) || $form->dberror;
			($amount) = $pth->fetchrow_array;
			$pth->finish;

			$amount += $form->{"paid_$i"};

			# update AR/AP transaction
			$query = qq|UPDATE $form->{arap} 
						   SET paid = $amount,
							   datepaid = '$form->{datepaid}'
						 WHERE id = $form->{"id_$i"}|;

			$dbh->do($query) || $form->dberror($query);

			%audittrail = ( tablename  => $form->{arap},
							reference  => $form->{source},
							formname   => $form->{formname},
							action     => 'posted',
							id         => $form->{"id_$i"} );

			$form->audittrail($dbh, "", \%audittrail);

		}
	}


	# record a AR/AP with a payment
	if ($form->round_amount($paymentamount, 2)) {
		$form->{invnumber} = "";
		OP::overpayment("", $myconfig, $form, $dbh, $paymentamount, $ml, 1);
	}

	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;

}


sub post_payments {

	my ($self, $myconfig, $form) = @_;

	# connect to database, turn AutoCommit off
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $sth;

	my ($paymentaccno) = split /--/, $form->{account};

	# if currency ne defaultcurrency update exchangerate
	if ($form->{currency} ne $form->{defaultcurrency}) {
		$form->{exchangerate} = $form->parse_amount($myconfig, $form->{exchangerate});

		if ($form->{vc} eq 'customer') {
			$form->update_exchangerate($dbh, $form->{currency}, $form->{datepaid}, $form->{exchangerate}, 0);
		} else {
			$form->update_exchangerate($dbh, $form->{currency}, $form->{datepaid}, 0, $form->{exchangerate});
		}

	} else {
		$form->{exchangerate} = 1;
	}

	my $query = qq|SELECT fxgain_accno_id, fxloss_accno_id
					 FROM defaults|;

	my ($fxgain_accno_id, $fxloss_accno_id) = $dbh->selectrow_array($query);

	my ($buysell);

	if ($form->{vc} eq 'customer') {
		$buysell = "buy";
	} else {
		$buysell = "sell";
	}

	my $ml;
	my $where;

	if ($form->{ARAP} eq 'AR') {

		$ml = 1;
		$where = qq| (c.link = 'AR' OR c.link LIKE 'AR:%') |;

	} else {

		$ml = -1;
		$where = qq| (c.link = 'AP' OR c.link LIKE '%:AP' OR c.link LIKE '%:AP:%') |;

	}

	# get AR/AP account
	$query = qq|SELECT c.accno 
				  FROM chart c
				  JOIN acc_trans ac ON (ac.chart_id = c.id)
				 WHERE trans_id = ?
				   AND $where|;

	my $ath = $dbh->prepare($query) || $form->dberror($query);

	# query to retrieve paid amount
	$query = qq|SELECT paid 
				  FROM $form->{arap}
				 WHERE id = ?
			FOR UPDATE|;

	my $pth = $dbh->prepare($query) || $form->dberror($query);

	my %audittrail;

	my $overpayment = 0;
	my $accno_id;

	# go through line by line
	for my $i (1 .. $form->{rowcount}) {

		$ath->execute($form->{"id_$i"});
		($form->{$form->{ARAP}}) = $ath->fetchrow_array;
		$ath->finish;

		$form->{"paid_$i"} = $form->parse_amount($myconfig, $form->{"paid_$i"});
		$form->{"due_$i"} = $form->parse_amount($myconfig, $form->{"due_$i"});

		if ($form->{"$form->{vc}_id_$i"} ne $sameid) {
			# record a AR/AP with a payment
			if ($overpayment > 0 && $form->{$form->{ARAP}}) {
				$form->{invnumber} = "";
				OP::overpayment("", $myconfig, $form, $dbh, $overpayment, $ml, 1);
			}

			$overpayment = 0;
			$form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
			for (qw(source memo)) { $form->{$_} = $form->{"${_}_$i"} }
		}

		if ($form->{"checked_$i"} && $form->{"paid_$i"}) {

			$overpayment += ($form->{"paid_$i"} - $form->{"due_$i"});

			# get exchangerate for original 
			$query = qq|SELECT $buysell
						  FROM exchangerate e
						  JOIN $form->{arap} a ON (a.transdate = e.transdate)
						 WHERE e.curr = '$form->{currency}'
						   AND a.id = $form->{"id_$i"}|;

			my ($exchangerate) = $dbh->selectrow_array($query);

			$exchangerate ||= 1;

			$query = qq|SELECT c.id
						  FROM chart c
						  JOIN acc_trans a ON (a.chart_id = c.id)
						 WHERE $where
						   AND a.trans_id = $form->{"id_$i"}|;

			my ($id) = $dbh->selectrow_array($query);

			$paid = ($form->{"paid_$i"} > $form->{"due_$i"}) ? $form->{"due_$i"} : $form->{"paid_$i"};
			$amount = $form->round_amount($paid * $exchangerate, 2);

			# add AR/AP
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate, amount)
						VALUES ($form->{"id_$i"}, $id, '$form->{datepaid}',
								$amount * $ml)|;

			$dbh->do($query) || $form->dberror($query);

			$query = qq|SELECT id
						  FROM chart
						 WHERE accno = '$paymentaccno'|;

			($accno_id) = $dbh->selectrow_array($query);

			# add payment
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
												amount, source, memo)
						VALUES ($form->{"id_$i"}, $accno_id, '$form->{datepaid}',
								$paid * $ml * -1, |
								.$dbh->quote($form->{source}).qq|, |
								.$dbh->quote($form->{memo}).qq|)|;

			$dbh->do($query) || $form->dberror($query);

			# add exchangerate difference if currency ne defaultcurrency
			$amount = $form->round_amount($paid * ($form->{exchangerate} - 1) * $ml * -1, 2);

			if ($amount) {
				# exchangerate difference
				$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
													amount, source)
							VALUES ($form->{"id_$i"}, $accno_id, '$form->{datepaid}',
									$amount, |
									.$dbh->quote($form->{source}).qq|)|;

				$dbh->do($query) || $form->dberror($query);

				# gain/loss
				$amount = ($form->round_amount($paid * $exchangerate,2) - $form->round_amount($paid * $form->{exchangerate},2)) * $ml * -1;

				if ($amount) {
					$accno_id = ($amount > 0) ? $fxgain_accno_id : $fxloss_accno_id;

					$query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
														amount, fx_transaction)
								VALUES ($form->{"id_$i"}, $accno_id,
										'$form->{datepaid}', $amount, '1')|;

					$dbh->do($query) || $form->dberror($query);
				}
			}

			$paid = $form->round_amount($paid * $exchangerate, 2);

			$pth->execute($form->{"id_$i"}) || $form->dberror;
			($amount) = $pth->fetchrow_array;
			$pth->finish;

			$amount += $paid;

			# update AR/AP transaction
			$query = qq|UPDATE $form->{arap} 
						   SET paid = $amount,
							   datepaid = '$form->{datepaid}'
						 WHERE id = $form->{"id_$i"}|;

			$dbh->do($query) || $form->dberror($query);

			%audittrail = ( tablename  => $form->{arap},
							reference  => $form->{source},
							formname   => $form->{formname},
							action     => 'posted',
							id         => $form->{"id_$i"} );

			$form->audittrail($dbh, "", \%audittrail);

		}

		$sameid = $form->{"$form->{vc}_id_$i"};

	}

	# record a AR/AP with a payment
	if ($overpayment > 0 && $form->{$form->{ARAP}}) {
		$form->{invnumber} = "";
		OP::overpayment("", $myconfig, $form, $dbh, $overpayment, $ml, 1);
	}

	my $rc = $dbh->commit;
	$dbh->disconnect;

	$rc;

}


1;

