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
# Copyright (C) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# Project module
# also used for partsgroups
#
#======================================================================

package PE;


sub projects {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};

	$form->{sort} = "projectnumber" unless $form->{sort};
	my @a = ($form->{sort});
	my %ordinal = ( projectnumber	=> 2,
                  description	=> 3,
		  startdate => 4,
		  enddate => 5,
		);
	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query;
	my $where = "WHERE 1=1";
  
	$query = qq|
		   SELECT pr.*, c.name 
		     FROM project pr
		LEFT JOIN customer c ON (c.id = pr.customer_id)|;

	if ($form->{type} eq 'job') {
	  $where .= qq| AND pr.id NOT IN (SELECT DISTINCT id
			            FROM parts
			            WHERE project_id > 0)|;
	}
  
	my $var;
	if ($form->{projectnumber} ne "") {
		$var = $dbh->quote($form->like(lc $form->{projectnumber}));
		$where .= " AND lower(pr.projectnumber) LIKE $var";
	}
	if ($form->{description} ne "") {
		$var = $dbh->quote($form->like(lc $form->{description}));
		$where .= " AND lower(pr.description) LIKE $var";
	}

	($form->{startdatefrom}, $form->{startdateto}) 
		= $form->from_to(
			$form->{year}, $form->{month}, $form->{interval}) 
				if $form->{year} && $form->{month};
  
	if ($form->{startdatefrom}) {
		$where .= " AND (pr.startdate IS NULL OR pr.startdate >= ".
			$dbh->quote($form->{startdatefrom}).")";
	}
	if ($form->{startdateto}) {
		$where .= " AND (pr.startdate IS NULL OR pr.startdate <= ".
			$dbh->quote($form->{startdateto}).")";
	}
  
	if ($form->{status} eq 'orphaned') {
		$where .= qq| AND pr.id NOT IN (SELECT DISTINCT project_id
                                    FROM acc_trans
				    WHERE project_id > 0
                                 UNION
                                    SELECT DISTINCT project_id
		                    FROM invoice
				    WHERE project_id > 0
				 UNION
		                    SELECT DISTINCT project_id
		                    FROM orderitems
				    WHERE project_id > 0
				 UNION
		                    SELECT DISTINCT project_id
		                    FROM jcitems
				    WHERE project_id > 0)
		|;

	}
	if ($form->{status} eq 'active') {
		$where .= qq| 
			AND (pr.enddate IS NULL 
			OR pr.enddate >= current_date)|;
	}
	if ($form->{status} eq 'inactive') {
		$where .= qq| AND pr.enddate <= current_date|;
	}

	$query .= qq|
		 $where
		 ORDER BY $sortorder|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $i = 0;
	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_project} }, $ref;
		$i++;
	}

  $sth->finish;
  $dbh->commit;
  
  $i;

}


sub get_project {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};

	my $query;
	my $sth;
	my $ref;
	my $where;
  
	if ($form->{id}) {

    
		$query = qq|
			   SELECT pr.*, c.name AS customer
			     FROM project pr
			LEFT JOIN customer c ON (c.id = pr.customer_id)
			    WHERE pr.id = ?|;
		$sth = $dbh->prepare($query);
		$sth->execute($form->{id}) || $form->dberror($query);

		$ref = $sth->fetchrow_hashref(NAME_lc);
    
		for (keys %$ref) { $form->{$_} = $ref->{$_} }

		$sth->finish;

		# check if it is orphaned
		$query = qq|
			SELECT count(*)
			  FROM acc_trans
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM invoice
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM orderitems
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM jcitems
			 WHERE project_id = ?|;
		$sth = $dbh->prepare($query);
		$sth->execute(
			$form->{id}, $form->{id}, $form->{id}, $form->{id}
			)|| $form->dberror($query);

		my $count;
		while (($count) = $sth->fetchrow_array) {
			$form->{orphaned} += $count;
		}
		$sth->finish;
		$form->{orphaned} = !$form->{orphaned};
	}

	PE->get_customer($myconfig, $form, $dbh);

	$form->run_custom_queries('project', 'SELECT');

	$dbh->commit;

}


sub save_project {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	$form->{customer_id} ||= undef;

	$form->{projectnumber} 
		= $form->update_defaults($myconfig, "projectnumber", $dbh) 
			unless $form->{projectnumber};
	my $enddate;
	my $startdate;
	$enddate = $form->{enddate} if $form->{enddate};
	$startdate = $form->{startdate} if $form->{startdate};

	if ($form->{id}) {

		$query = qq|
			UPDATE project
			   SET projectnumber = ?,
			       description = ?,
			       startdate = ?,
			       enddate = ?,
			       customer_id = ?
			 WHERE id = |.$dbh->quote($form->{id});
	} else {
   
		$query = qq|
			INSERT INTO project (projectnumber, description, 
			            startdate, enddate, customer_id)
			     VALUES (?, ?, ?, ?, ?)|;
	}
	$sth = $dbh->prepare($query);
	$sth->execute(
		$form->{projectnumber}, $form->{description}, 
		$startdate, $enddate, $form->{customer_id}
		) || $form->dberror($query);
	$form->run_custom_queries('project', 'UPDATE');
  
	$dbh->commit;

}


sub list_stock {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};

	my $var;
	my $where = "1 = 1";

	if ($form->{status} eq 'active') {
		$where = qq|
			(pr.enddate IS NULL OR pr.enddate >= current_date)
			AND pr.completed < pr.production|;
	}
	if ($form->{status} eq 'inactive') {
		$where = qq|pr.completed = pr.production|;
	}
 
	if ($form->{projectnumber}) {
		$var = $dbh->quote($form->like(lc $form->{projectnumber}));
		$where .= " AND lower(pr.projectnumber) LIKE $var";
	}
  
	if ($form->{description}) {
		$var = $dbh->quote($form->like(lc $form->{description}));
		$where .= " AND lower(pr.description) LIKE $var";
	}
  
	$form->{sort} = "projectnumber" unless $form->{sort};
	my @a = ($form->{sort});
	my %ordinal = ( projectnumber => 2, description   => 3 );
	my $sortorder = $form->sort_order(\@a, \%ordinal);
 
	my $query = qq|
		   SELECT pr.*, p.partnumber
		     FROM project pr
		     JOIN parts p ON (p.id = pr.parts_id)
		    WHERE $where
		 ORDER BY $sortorder|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_project} }, $ref;
	}
	$sth->finish;

	$query = qq|SELECT current_date|;
	($form->{stockingdate}) = $dbh->selectrow_array($query) 
		if !$form->{stockingdate};
  
	$dbh->commit;
  
}


sub jobs {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
 
	$form->{sort} = "projectnumber" unless $form->{sort};
	my @a = ($form->{sort});
	my %ordinal = (projectnumber => 2, description  => 3, startdate => 4);
	my $sortorder = $form->sort_order(\@a, \%ordinal);
  
	my $query = qq|
		   SELECT pr.*, p.partnumber, p.onhand, c.name
		     FROM project pr
		     JOIN parts p ON (p.id = pr.parts_id)
		LEFT JOIN customer c ON (c.id = pr.customer_id)
		    WHERE 1=1|;

	if ($form->{projectnumber} ne "") {
		$var = $dbh->quote($form->like(lc $form->{projectnumber}));
		$query .= " AND lower(pr.projectnumber) LIKE $var";
	}
	if ($form->{description} ne "") {
		$var = $dbh->quote($form->like(lc $form->{description}));
		$query .= " AND lower(pr.description) LIKE $var";
	}

	($form->{startdatefrom}, $form->{startdateto}) 
		= $form->from_to($form->{year}, $form->{month}, 
		$form->{interval}) 
			if $form->{year} && $form->{month};
  
	if ($form->{startdatefrom}) {
		$query .= " AND pr.startdate >= ".
			$dbh->quote($form->{startdatefrom});
	}
	if ($form->{startdateto}) {
		$query .= " AND pr.startdate <= ".
			$dbh->quote($form->{startdateto});
	}

	if ($form->{status} eq 'active') { 
		$query .= qq| AND NOT pr.production = pr.completed|;
	} 
	if ($form->{status} eq 'inactive') { 
		$query .= qq| AND pr.production = pr.completed|;
	}
	if ($form->{status} eq 'orphaned') {
		$query .= qq| 
			AND pr.completed = 0
			AND (pr.id NOT IN 
			(SELECT DISTINCT project_id
			   FROM invoice
			  WHERE project_id > 0
			 UNION
			 SELECT DISTINCT project_id
			   FROM orderitems
			  WHERE project_id > 0
			 UNION
			 SELECT DISTINCT project_id
			   FROM jcitems
			  WHERE project_id > 0)
			 )|;
	}

	$query .= qq|
		ORDER BY $sortorder|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_project} }, $ref;
	}

	$sth->finish;
  
	$dbh->commit;
  
}


sub get_job {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $query;
	my $sth;
	my $ref;

	if ($form->{id}) {
		$query = qq|
			SELECT value FROM defaults 
			 WHERE setting_key = 'weightunit'|;
		($form->{weightunit}) = $dbh->selectrow_array($query);

		$query = qq|
			   SELECT pr.*, p.partnumber, 
			          p.description AS partdescription, p.unit, 
			          p.listprice, p.sellprice, p.priceupdate, 
			          p.weight, p.notes, p.bin, p.partsgroup_id,
			          ch.accno AS income_accno, 
			          ch.description AS income_description, 
			          pr.customer_id, c.name AS customer, 
			          pg.partsgroup
			     FROM project pr
			LEFT JOIN parts p ON (p.id = pr.parts_id)
			LEFT JOIN chart ch ON (ch.id = p.income_accno_id)
			LEFT JOIN customer c ON (c.id = pr.customer_id)
			LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
			    WHERE pr.id = |.$dbh->quote($form->{id});
	} else {
		$query = qq|
			SELECT value, current_date AS startdate FROM defaults
			 WHERE setting_key = 'weightunit'|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$ref = $sth->fetchrow_hashref(NAME_lc);
  
	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;

	if ($form->{id}) {
		# check if it is orphaned
		$query = qq|
			SELECT count(*)
			  FROM invoice
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM orderitems
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM jcitems
			 WHERE project_id = ?|;
		$sth = $dbh->prepare($query);
		$sth->execute(
			$form->{id}, $form->{id}, $form->{id}
			)|| $form->dberror($query);

		my $count;

		my $count;
		while (($count) = $sth->fetchrow_array) {
			$form->{orphaned} += $count;
		}
		$sth->finish;

	}

	$form->{orphaned} = !$form->{orphaned};
  
	$query = qq|
		  SELECT accno, description, link
		    FROM chart
		   WHERE link LIKE ?
		ORDER BY accno|;
	$sth = $dbh->prepare($query);
	$sth->execute('%IC%') || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		for (split /:/, $ref->{link}) {
			if (/IC/) {
				push @{ $form->{IC_links}{$_} }, 
					{ accno => $ref->{accno},
					description => $ref->{description} };
			}
		}
	}
	$sth->finish;

	if ($form->{id}) {
		$query = qq|
			SELECT ch.accno
			  FROM parts p
			  JOIN partstax pt ON (pt.parts_id = p.id)
			  JOIN chart ch ON (pt.chart_id = ch.id)
			 WHERE p.id = ?|;
		
		$sth = $dbh->prepare($query);
		$sth->execute($form->{id}) || $form->dberror($query);
    
		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			$form->{amount}{$ref->{accno}} = $ref->{accno};
		}
		$sth->finish;
	}
  
	PE->get_customer($myconfig, $form, $dbh);

	$dbh->commit;

}


sub get_customer {
	my ($self, $myconfig, $form, $dbh) = @_;
  
	if (! $dbh) {
		$dbh = $form->{dbh};
	}

	my $query;
	my $sth;
	my $ref;

	if (! $form->{startdate}) {
		$query = qq|SELECT current_date|;
		($form->{startdate}) = $dbh->selectrow_array($query);
	}
  
	my $where = qq|(startdate >= |.$dbh->quote($form->{startdate}).
		qq| OR startdate IS NULL OR enddate IS NULL)|;
  
	if ($form->{enddate}) {
		$where .= qq| AND (enddate >= |.$dbh->quote($form->{enddate}).
			qq| OR enddate IS NULL)|;
	} else {
		$where .= 
			qq| AND (enddate >= current_date OR enddate IS NULL)|;
	}
  
	$query = qq|
		SELECT count(*)
		  FROM customer
		 WHERE $where|;
	my ($count) = $dbh->selectrow_array($query);

	if ($count < $myconfig->{vclimit}) {
		$query = qq|
			SELECT id, name
			  FROM customer
			 WHERE $where|;

		if ($form->{customer_id}) {
			$query .= qq|
				UNION 
				SELECT id,name
				  FROM customer
				 WHERE id = |.
					$dbh->quote($form->{customer_id});
		}

		$query .= qq|
			ORDER BY name|;
		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		@{ $form->{all_customer} } = ();
		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			push @{ $form->{all_customer} }, $ref;
		}
		$sth->finish;
	}

}


sub save_job {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
  
	my ($income_accno) = split /--/, $form->{IC_income};
  
	my ($partsgroup, $partsgroup_id) = split /--/, $form->{partsgroup};
  
	if ($form->{id}) {
		$query = qq|
			SELECT id FROM project
			WHERE id = |.$dbh->quote($form->{id});
		($form->{id}) = $dbh->selectrow_array($query);
	}

	if (!$form->{id}) {
		my $uid = localtime;
		$uid .= "$$";
    
 		$query = qq|
			INSERT INTO project (projectnumber)
			     VALUES ('$uid')|;
		$dbh->do($query) || $form->dberror($query);

		$query = qq|
			SELECT id FROM project 
			 WHERE projectnumber = '$uid'|;
		($form->{id}) = $dbh->selectrow_array($query);
	}

	$form->{projectnumber} 
		= $form->update_defaults($myconfig, "projectnumber", $dbh) 
		unless $form->{projectnumber};

	$query = qq|
		UPDATE project 
		   SET projectnumber = ?,
		       description = ?,
		       startdate = ?,
		       enddate = ?,
		       parts_id = ?
		       production = ?,
		       customer_id = ?
		 WHERE id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute(
		$form->{projectnumber}, $form->{description}, 
		$form->{startdate}, $form->{enddate}, $form->{id},
		$form->{production}, $form->{customer_id}, $form->{id}
		) || $form->dberror($query);


	#### add/edit assembly
	$query = qq|SELECT id FROM parts WHERE id = |.$dbh->quote($form->{id});
	my ($id) = $dbh->selectrow_array($query);

	if (!$id) {
	  $query = qq|
		INSERT INTO parts (id) 
		     VALUES (|.$dbh->quote($form->{id}).qq|)|;
	  $dbh->do($query) || $form->dberror($query);
	}
  
	my $partnumber = 
		($form->{partnumber}) 
		? $form->{partnumber} 
		: $form->{projectnumber};
  
	$query = qq|
		UPDATE parts 
		   SET partnumber = ?,
		       description = ?,
		       priceupdate = ?,
		       listprice = ?,
		       sellprice = ?,
		       weight = ?,
		       bin = ?,
		       unit = ?,
		       notes = ?,
		       income_accno_id = (SELECT id FROM chart
		                           WHERE accno = ?),
		       partsgroup_id = ?,
		       assembly = '1',
		       obsolete = '1',
		       project_id = ?
		       WHERE id = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute(
			$partnumber, $form->{partdescription},
			$form->{priceupdate}, 
			$form->parse_amount($myconfig, $form->{listprice}),
			$form->parse_amount($myconfig, $form->{sellprice}),
			$form->parse_amount($myconfig, $form->{weight}),
			$form->{bin}, $form->{unit}, $form->{notes}, 
			$income_accno, 
			($partsgroup_id) ? $partsgroup_id : undef,
			$form->{id}, $form->{id}
			)  || $form->dberror($query);

	$query = qq|DELETE FROM partstax WHERE parts_id = |.
		$dbh->qupte($form->{id});
	$dbh->do($query) || $form->dberror($query);

	$query = qq|
		INSERT INTO partstax (parts_id, chart_id)
		    VALUES (?, (SELECT id FROM chart WHERE accno = ?))|;
	$sth = $dbh->prepare($query);
	for (split / /, $form->{taxaccounts}) {
		if ($form->{"IC_tax_$_"}) {
			$sth->execute($form->{id}, $_) 
				|| $form->dberror($query);
		}
	}
  
	$dbh->commit;

}


sub stock_assembly {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};

	my $ref;
  
	my $query = qq|SELECT * FROM project WHERE id = ?|;
	my $sth = $dbh->prepare($query) || $form->dberror($query);

	$query = qq|SELECT COUNT(*) FROM parts WHERE project_id = ?|;
	my $rvh = $dbh->prepare($query) || $form->dberror($query);

	if (! $form->{stockingdate}) {
		$query = qq|SELECT current_date|;
		($form->{stockingdate}) = $dbh->selectrow_array($query);
	}
  
	$query = qq|SELECT * FROM parts WHERE id = ?|;
	my $pth = $dbh->prepare($query) || $form->dberror($query);
 
	$query = qq|
		  SELECT j.*, p.lastcost FROM jcitems j
		    JOIN parts p ON (p.id = j.parts_id)
		   WHERE j.project_id = ?
		         AND j.checkedin <= |.
				$dbh->quote($form->{stockingdate}).qq|
		ORDER BY parts_id|;
	my $jth = $dbh->prepare($query) || $form->dberror($query);

	$query = qq|
		INSERT INTO assembly (id, parts_id, qty, bom, adj)
		     VALUES (?, ?, ?, '0', '0')|;
	my $ath = $dbh->prepare($query) || $form->dberror($query);

	my $i = 0;
	my $sold;
	my $ship;
  
	while (1) {
		$i++;
		last unless $form->{"id_$i"};
    
		$stock = $form->parse_amount($myconfig, $form->{"stock_$i"});
    
		if ($stock) {
			$sth->execute($form->{"id_$i"});
			$ref = $sth->fetchrow_hashref(NAME_lc);

			if ($stock >($ref->{production} - $ref->{completed})) {
				$stock = $ref->{production} 
					- $ref->{completed};
			}
			if (($stock * -1) > $ref->{completed}) {
				$stock = $ref->{completed} * -1;
			}
      
			$pth->execute($form->{"id_$i"});
			$pref = $pth->fetchrow_hashref(NAME_lc);

			my %assembly = ();
			my $lastcost = 0;
			my $sellprice = 0;
			my $listprice = 0;
      
			$jth->execute($form->{"id_$i"});
			while ($jref = $jth->fetchrow_hashref(NAME_lc)) {
				$assembly{qty}{$jref->{parts_id}} 
					+= ($jref->{qty} - $jref->{allocated});
				$assembly{parts_id}{$jref->{parts_id}} 
					= $jref->{parts_id};
				$assembly{jcitems}{$jref->{id}} = $jref->{id};
				$lastcost += $form->round_amount(
					$jref->{lastcost} * ($jref->{qty} 
						- $jref->{allocated}), 
					2);
				$sellprice += $form->round_amount(
					$jref->{sellprice} * ($jref->{qty} 
						- $jref->{allocated}), 
					2);
				$listprice += $form->round_amount(
					$jref->{listprice} * ($jref->{qty} 
						- $jref->{allocated}), 
					2);
			}
			$jth->finish;

			$uid = localtime;
			$uid .= "$$";
      
			$query = qq|
				INSERT INTO parts (partnumber)
				     VALUES ('$uid')|;
			$dbh->do($query) || $form->dberror($query);

			$query = qq|
				SELECT id
				  FROM parts
				 WHERE partnumber = '$uid'|;
			($uid) = $dbh->selectrow_array($query);

			$lastcost = $form->round_amount($lastcost / $stock, 2);
			$sellprice = 
				($pref->{sellprice}) 
				? $pref->{sellprice} 
				: $form->round_amount($sellprice / $stock, 2);
			$listprice = 
				($pref->{listprice}) 
				? $pref->{listprice} 
				: $form->round_amount($listprice / $stock, 2);

			$rvh->execute($form->{"id_$i"});
			my ($rev) = $rvh->fetchrow_array;
			$rvh->finish;
      
			$query = qq|
				UPDATE parts 
				   SET partnumber = ?,
				       description = ?,
				       priceupdate = ?,
				       unit = ?,
				       listprice = ?,
				       sellprice = ?,
				       lastcost = ?,
				       weight = ?,
				       onhand = ?,
				       notes = ?,
				       assembly = '1',
				       income_accno_id = ?,
				       bin = ?,
				       project_id = ?
				 WHERE id = ?|;
			$sth = $dbh->prepare($query);
			$sth->execute(
				"$pref->{partnumber}-$rev", 
				$pref->{partdescription}, 
				$form->{stockingdate}, $pref->{unit},
				$listprice, $sellprice, $lastcost,
				$pref->{weight}, $stock, $pref->{notes},
				$pref->{income_accno_id}, $pref->{bin},
				$form->{"id_$i"}, $uid
				)|| $form->dberror($query);

			$query = qq|
				INSERT INTO partstax (parts_id, chart_id)
				     SELECT ?, chart_id FROM partstax
				      WHERE parts_id = ?|;
			$sth = $dbh->prepare($query);
			$sth->execute($uid, $pref->{id}) 
				|| $form->dberror($query);
		  

			$pth->finish;
      
			for (keys %{$assembly{parts_id}}) {
				if ($assembly{qty}{$_}) {
					$ath->execute(
						$uid, $assembly{parts_id}{$_}, 
						$form->round_amount(
							$assembly{qty}{$_} 
								/ $stock, 
							4));
					$ath->finish;
				}
			}
      
			$form->update_balance(
				$dbh, "project", "completed", 
				qq|id = $form->{"id_$i"}|, $stock);
      
			$query = qq|
				UPDATE jcitems 
				   SET allocated = qty
				 WHERE allocated != qty
				       AND checkedin <= ?
				       AND project_id = ?|;
			$sth = $dbh->prepare($query);
			$sth->execute($form->{stockingdate}, $form->{"id_$i"}) 
				|| $form->dberror($query);

			$sth->finish;
      
		}

	}

	my $rc = $dbh->commit;
  
	$rc;

}


sub delete_project {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	$query = qq|DELETE FROM project WHERE id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
  
	$query = qq|DELETE FROM translation
	      WHERE trans_id = $form->{id}|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	my $rc = $dbh->commit;

	$rc;
  
}


sub delete_partsgroup {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	$query = qq|DELETE FROM partsgroup WHERE id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
  
	$query = qq|DELETE FROM translation WHERE trans_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	my $rc = $dbh->commit;

	$rc;
  
}


sub delete_pricegroup {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	$query = qq|DELETE FROM pricegroup WHERE id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
  
	my $rc = $dbh->commit;

	$rc;

}


sub delete_job {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
 
	my %audittrail = ( 
		tablename  => 'project',
		reference  => $form->{id},
		formname   => $form->{type},
		action     => 'deleted',
		id         => $form->{id} );

	$form->audittrail($dbh, "", \%audittrail);
 
	my $query = qq|DELETE FROM project WHERE id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
  
	$query = qq|DELETE FROM translation WHERE trans_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	# delete all the assemblies
	$query = qq|
		DELETE FROM assembly a 
		       JOIN parts p ON (a.id = p.id)
		      WHERE p.project_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);
	
	$query = qq|DELETE FROM parts WHERE project_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	my $rc = $dbh->commit;

	$rc;

}


sub partsgroups {
	my ($self, $myconfig, $form) = @_;
  
	my $var;
  
	my $dbh = $form->{dbh};

	$form->{sort} = "partsgroup" unless $form->{partsgroup};
	my @a = (partsgroup);
	my $sortorder = $form->sort_order(\@a);

	my $query = qq|SELECT g.* FROM partsgroup g|;

	my $where = "1 = 1";
  
	if ($form->{partsgroup} ne "") {
		$var = $dbh->quote($form->like(lc $form->{partsgroup}));
		$where .= " AND lower(partsgroup) LIKE '$var'";
	}
	$query .= qq| WHERE $where ORDER BY $sortorder|;
  
	if ($form->{status} eq 'orphaned') {
		$query = qq|
			   SELECT g.*
			     FROM partsgroup g
			LEFT JOIN parts p ON (p.partsgroup_id = g.id)
			    WHERE $where
			EXCEPT
			   SELECT g.*
			     FROM partsgroup g
			     JOIN parts p ON (p.partsgroup_id = g.id)
			    WHERE $where
			 ORDER BY $sortorder|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $i = 0;
	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{item_list} }, $ref;
		$i++;
	}

	$sth->finish;
  
	$i;

}


sub save_partsgroup {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	if ($form->{id}) {
		$query = qq|
			UPDATE partsgroup 
			   SET partsgroup = |.
				$dbh->quote($form->{partsgroup}).qq|
			 WHERE id = $form->{id}|;
	} else {
		$query = qq|
			INSERT INTO partsgroup (partsgroup)
			     VALUES (|.$dbh->quote($form->{partsgroup}).qq|)|;
	}
	$dbh->do($query) || $form->dberror($query);

	$dbh->commit; 

}


sub get_partsgroup {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
  
	my $query = qq|SELECT * FROM partsgroup WHERE id = ?|;
	my $sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
 
	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;

	# check if it is orphaned
	$query = qq|SELECT count(*) FROM parts WHERE partsgroup_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	($form->{orphaned}) = $sth->fetchrow_array;
	$form->{orphaned} = !$form->{orphaned};
       
	$sth->finish;
  
	$dbh->commit;

}


sub pricegroups {
	my ($self, $myconfig, $form) = @_;
  
	my $var;
  
	my $dbh = $form->{dbh};

	$form->{sort} = "pricegroup" unless $form->{sort};
	my @a = (pricegroup);
	my $sortorder = $form->sort_order(\@a);

	my $query = qq|SELECT g.* FROM pricegroup g|;

	my $where = "1 = 1";
  
	if ($form->{pricegroup} ne "") {
		$var = $dbh->quote($form->like(lc $form->{pricegroup}));
		$where .= " AND lower(pricegroup) LIKE $var";
	}
	$query .= qq|
		WHERE $where ORDER BY $sortorder|;
  
	if ($form->{status} eq 'orphaned') {
		$query = qq|
			SELECT g.*
			  FROM pricegroup g
			 WHERE $where
			       AND g.id NOT IN (SELECT DISTINCT pricegroup_id
			                          FROM partscustomer
			                         WHERE pricegroup_id > 0)
		ORDER BY $sortorder|;
	}

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $i = 0;
	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{item_list} }, $ref;
		$i++;
	}

	$sth->finish;
	$dbh->commit;
  
	$i;

}


sub save_pricegroup {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	if ($form->{id}) {
		$query = qq|
			UPDATE pricegroup SET
			       pricegroup = ?
			 WHERE id = |.$dbh->quote($form->{id});
	} else {
		$query = qq|
			INSERT INTO pricegroup (pricegroup)
			VALUES (?)|;
	}
	$sth = $dbh->prepare($query);
	$sth->execute($form->{pricegroup}) || $form->dberror($query);
  
	$dbh->commit;

}


sub get_pricegroup {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
  
	my $query = qq|SELECT * FROM pricegroup WHERE id = ?|;
	my $sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	my $ref = $sth->fetchrow_hashref(NAME_lc);
 
	for (keys %$ref) { $form->{$_} = $ref->{$_} }

	$sth->finish;

	# check if it is orphaned
	$query = "SELECT count(*) FROM partscustomer WHERE pricegroup_id = ?";
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id}) || $form->dberror($query);

	($form->{orphaned}) = $sth->fetchrow_array;
	$form->{orphaned} = !$form->{orphaned};

	$sth->finish;
  
	$dbh->commit;

}


sub description_translations {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
	my $where = "1 = 1";
	my $var;
	my $ref;
  
	for (qw(partnumber description)) {
		if ($form->{$_}) {
			$var = $dbh->quote($form->like(lc $form->{$_}));
			$where .= " AND lower(p.$_) LIKE $var";
		}
	}
  
	$where .= " AND p.obsolete = '0'";
	$where .= " AND p.id = ".$dbh->quote($form->{id}) if $form->{id};


	my %ordinal = ( 'partnumber' => 2, 'description' => 3 );
  
	my @a = qw(partnumber description);
	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query = qq|
		  SELECT l.description AS language, 
		         t.description AS translation, l.code
		    FROM translation t
		    JOIN language l ON (l.code = t.language_code)
		   WHERE trans_id = ?
		ORDER BY 1|;
	my $tth = $dbh->prepare($query);
  
	$query = qq|
		  SELECT p.id, p.partnumber, p.description
		    FROM parts p
		   WHERE $where
		ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $tra;
  
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{translations} }, $ref;

		# get translations for description
		$tth->execute($ref->{id}) || $form->dberror;

		while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
			$form->{trans_id} = $ref->{id};
			$tra->{id} = $ref->{id};
			push @{ $form->{translations} }, $tra;
		}
		$tth->finish;

	}
	$sth->finish;

	&get_language("", $dbh, $form) if $form->{id};

	$dbh->commit;

}


sub partsgroup_translations {
	my ($self, $myconfig, $form) = @_;
	my $dbh = $form->{dbh};

	my $where = "1 = 1";
	my $ref;
	my $var;

	if ($form->{description}) {
		$var = $dbh->quote($form->like(lc $form->{description}));
		$where .= " AND lower(p.partsgroup) LIKE $var";
	}
	$where .= " AND p.id = ".$dbh->quote($form->{id}) if $form->{id};
  

	my $query = qq|
		  SELECT l.description AS language, 
		         t.description AS translation, l.code
		    FROM translation t
		    JOIN language l ON (l.code = t.language_code)
		   WHERE trans_id = ?
		ORDER BY 1|;
	my $tth = $dbh->prepare($query);
  
	$form->sort_order();
  
	$query = qq|
		  SELECT p.id, p.partsgroup AS description
		    FROM partsgroup p
		   WHERE $where
		ORDER BY 2 $form->{direction}|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $tra;
  
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{translations} }, $ref;

		# get translations for partsgroup
		$tth->execute($ref->{id}) || $form->dberror;

		while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
			$form->{trans_id} = $ref->{id};
			push @{ $form->{translations} }, $tra;
		}
		$tth->finish;

	}
	$sth->finish;

	&get_language("", $dbh, $form) if $form->{id};

	$dbh->commit;

}


sub project_translations {
	my ($self, $myconfig, $form) = @_;
	my $dbh = $form->{dbh};

	my $where = "1 = 1";
	my $var;
	my $ref;
  
	for (qw(projectnumber description)) {
		if ($form->{$_}) {
			$var = $dbh->quote($form->like(lc $form->{$_}));
			$where .= " AND lower(p.$_) LIKE $var";
		}
	}
  
	$where .= " AND p.id = ".$dbh->quote($form->{id}) if $form->{id};


	my %ordinal = ( 'projectnumber' => 2, 'description' => 3 );
  
	my @a = qw(projectnumber description);
	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $query = qq|
		  SELECT l.description AS language, 
		         t.description AS translation, l.code
		    FROM translation t
		    JOIN language l ON (l.code = t.language_code)
		   WHERE trans_id = ?
		ORDER BY 1|;
	my $tth = $dbh->prepare($query);
  
	$query = qq|
		  SELECT p.id, p.projectnumber, p.description
		    FROM project p
		   WHERE $where
		ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $tra;
  
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{translations} }, $ref;

		# get translations for description
		$tth->execute($ref->{id}) || $form->dberror;

		while ($tra = $tth->fetchrow_hashref(NAME_lc)) {
			$form->{trans_id} = $ref->{id};
			$tra->{id} = $ref->{id};
			push @{ $form->{translations} }, $tra;
		}
		$tth->finish;

	}
	$sth->finish;

	&get_language("", $dbh, $form) if $form->{id};

	$dbh->commit;

}


sub get_language {
	my ($self, $dbh, $form) = @_;
  
	my $query = qq|SELECT * FROM language ORDER BY 2|;
	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_language} }, $ref;
	}
	$sth->finish;

}


sub save_translation {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};

	my $query = qq|DELETE FROM translation WHERE trans_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id})|| $form->dberror($query);

	$query = qq|
		INSERT INTO translation (trans_id, language_code, description)
		     VALUES (?, ?, ?)|;
	my $sth = $dbh->prepare($query) || $form->dberror($query);

	foreach my $i (1 .. $form->{translation_rows}) {
		if ($form->{"language_code_$i"} ne "") {
			$sth->execute($form->{id}, $form->{"language_code_$i"},
				$form->{"translation_$i"});
			$sth->finish;
		}
	}
  $dbh->commit;

}


sub delete_translation {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};
  
	my $query = qq|DELETE FROM translation WHERE trans_id = ?|;
	$sth = $dbh->prepare($query);
	$sth->execute($form->{id})|| $form->dberror($query);

	$dbh->commit;

}

sub timecard_get_currency {
	my $self = shift @_;
	my $form = shift @_;
	my $dbh = $form->{dbh};
	my $query = qq|SELECT curr FROM customer WHERE id = ?|;
        my $sth = $dbh->prepare($query);
	$sth->execute($form->{customer_id});
	my ($curr) = $sth->fetchrow_array;
	$form->{currency} = $curr;
}


sub project_sales_order {
   my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->{dbh};

  my $query = qq|SELECT current_date|;
  my ($transdate) = $dbh->selectrow_array($query);
  
  $form->all_years($myconfig, $dbh);
  
  $form->all_projects($myconfig, $dbh, $transdate);
  
  $form->all_employees($myconfig, $dbh, $transdate);

  $dbh->commit;

}


sub get_jcitems {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};

	my $null;
	my $var;
	my $where;
  
	if ($form->{projectnumber}) {
		($null, $var) = split /--/, $form->{projectnumber};
		$var = $dbh->quote($var);
		$where .= " AND j.project_id = $var";
	}
  
	if ($form->{employee}) {
		($null, $var) = split /--/, $form->{employee};
		$var = $dbh->quote($var);
		$where .= " AND j.employee_id = $var";
	}

	($form->{transdatefrom}, $form->{transdateto}) 
		= $form->from_to(
			$form->{year}, $form->{month}, $form->{interval}) 
				if $form->{year} && $form->{month};
  
	if ($form->{transdatefrom}) {
		$where .= " AND j.checkedin >= ".
			$dbh->quote($form->{transdatefrom});
	}
	if ($form->{transdateto}) {
		$where .= " AND j.checkedout <= (date ".
			$dbh->quote($form->{transdateto}) . 
			" + interval '1 days')";
	}

	my $query;
	my $ref;

	$query = qq|
		   SELECT j.id, j.description, j.qty - j.allocated AS qty,
		          j.sellprice, j.parts_id, pr.$form->{vc}_id, 
		          j.project_id, j.checkedin::date AS transdate, 
		          j.notes, c.name AS $form->{vc}, pr.projectnumber, 
		          p.partnumber
		     FROM jcitems j
		     JOIN project pr ON (pr.id = j.project_id)
		     JOIN employees e ON (e.id = j.employee_id)
		     JOIN parts p ON (p.id = j.parts_id)
		LEFT JOIN $form->{vc} c ON (c.id = pr.$form->{vc}_id)
		    WHERE pr.parts_id IS NULL
		          AND j.allocated != j.qty $where
		 ORDER BY pr.projectnumber, c.name, j.checkedin::date|;

	if ($form->{summary}) {
		$query =~ s/j\.description/p\.description/;
		$query =~ s/c\.name,/c\.name, j\.parts_id, /;
	}
    
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	# tax accounts
	$query = qq|
		SELECT c.accno
		  FROM chart c
		  JOIN partstax pt ON (pt.chart_id = c.id)
		 WHERE pt.parts_id = ?|;
	my $tth = $dbh->prepare($query) || $form->dberror($query);
	my $ptref;

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    
		$tth->execute($ref->{parts_id});
		$ref->{taxaccounts} = "";
		while ($ptref = $tth->fetchrow_hashref(NAME_lc)) {
			$ref->{taxaccounts} .= "$ptref->{accno} ";
		}
		$tth->finish;
		chop $ref->{taxaccounts};
    
		$ref->{amount} = $ref->{sellprice} * $ref->{qty};

		push @{ $form->{jcitems} }, $ref;
	}

	$sth->finish;

	$query = qq|SELECT value FROM defaults WHERE setting_key = 'curr'|;
	($form->{currency}) = $dbh->selectrow_array($query);
	$form->{currency} =~ s/:.*//;
	$form->{defaultcurrency} = $form->{currency};

	$query = qq|
		SELECT c.accno, t.rate
		  FROM tax t
		  JOIN chart c ON (c.id = t.chart_id)|;
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);
	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$form->{taxaccounts} .= "$ref->{accno} ";
		$form->{"$ref->{accno}_rate"} = $ref->{rate};
	}
	chop $form->{taxaccounts};
	$sth->finish;
 
	$dbh->commit;
 
}


sub allocate_projectitems {
	my ($self, $myconfig, $form) = @_;
  
	my $dbh = $form->{dbh};

	for my $i (1 .. $form->{rowcount}) {
		for (split / /, $form->{"jcitems_$i"}) {
			my ($id, $qty) = split /:/, $_;
			$form->update_balance(
				$dbh, 'jcitems', 'allocated', "id = $id", 
				$qty);
		}
	}
    
	$rc = $dbh->commit;

	$rc;
 
}


1;

