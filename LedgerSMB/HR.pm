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
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# backend code for human resources and payroll
#
#======================================================================

package HR;


sub get_employee {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->dbconnect($myconfig);

	my $query;
	my $sth;
	my $ref;
	my $notid = "";

	if ($form->{id}) {
		$query = qq|SELECT e.* FROM employee e WHERE e.id = ?|;
		$sth = $dbh->prepare($query);
		$sth->execute($form->{id}) || $form->dberror($query);
  
		$ref = $sth->fetchrow_hashref(NAME_lc);
  
		# check if employee can be deleted, orphaned
		$form->{status} = "orphaned" unless $ref->{login};


		$ref->{employeelogin} = $ref->{login};
		delete $ref->{login};
		for (keys %$ref) { $form->{$_} = $ref->{$_} }

		$sth->finish;

		# get manager
		$form->{managerid} *= 1;
		$query = qq|SELECT name FROM employee WHERE id = ?|;

		$sth = $dbh->prepare($query);
		$sth->execute($form->{managerid});
		($form->{manager}) = $sth->fetchrow_array($query);
    
		
		$notid = qq|AND id != |.$dbh->quote($form->{id});
    
	} else {

		$query = qq|SELECT current_date|;
		($form->{startdate}) = $dbh->selectrow_array($query);
  
	}
  
	# get managers
	  $query = qq|
		  SELECT id, name
		    FROM employee
		   WHERE sales = '1'
		         AND role = 'manager'
		         $notid
		ORDER BY 2|;
	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{all_manager} }, $ref;
	}
	$sth->finish;


	$dbh->commit;

}



sub save_employee {
	my ($self, $myconfig, $form) = @_;

	my $dbh = $form->{dbh};
	my $query;
	my $sth;

	if (! $form->{id}) {
		my $uid = localtime;
		$uid .= "$$";

		$query = qq|INSERT INTO employee (name) VALUES ('$uid')|;
		$dbh->do($query) || $form->dberror($query);
    
		$query = qq|SELECT id FROM employee WHERE name = '$uid'|;
		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		($form->{id}) = $sth->fetchrow_array;
		$sth->finish;
	}

	my ($null, $managerid) = split /--/, $form->{manager};
	$managerid *= 1;
	$form->{sales} *= 1;

	$form->{employeenumber} = $form->update_defaults(
		$myconfig, "employeenumber", $dbh) 
			if ! $form->{employeenumber};

	$query = qq|
		UPDATE employee 
		   SET employeenumber = ?,
		       name = ?,
		       address1 = ?,
		       address2 = ?,
		       city = ?,
		       state = ?,
		       zipcode = ?,
		       country = ?,
		       workphone = ?,
		       homephone = ?,
		       startdate = ?,
		       enddate = ?,
		       notes = ?,
		       role = ?,
		       sales = ?,
		       email = ?,
		       ssn = ?,
		       dob = ?,
		       iban = ?,
		       bic = ?,
		       managerid = ?
		 WHERE id = ?|;
	$sth = $dbh->prepare($query);
	$form->db_prepare_vars('startdate', 'enddate');
	$sth->execute(
		$form->{employeenumber}, $form->{name}, $form->{address1},
		$form->{address2}, $form->{city}, $form->{state},
		$form->{zipcode}, $form->{country}, $form->{workphone},
		$form->{homephone}, $form->{startdate}, $form->{enddate},
		$form->{notes}, $form->{role}, $form->{sales}, $form->{email},
		$form->{ssn}, $form->{dob}, $form->{iban}, $form->{bic},
		$managerid, $form->{id}
		) || $form->dberror($query);


	$dbh->commit;

}


sub delete_employee {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);

	# delete employee
	
	my $query = qq|
		DELETE FROM employee 
		      WHERE id = |.$dbh->quote($form->{id});
	$dbh->do($query) || $form->dberror($query);

	$dbh->commit;

}


sub employees {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->{dbh};

	my $where = "1 = 1";
	$form->{sort} = ($form->{sort}) ? $form->{sort} : "name";
	my @a = qw(name);
	my $sortorder = $form->sort_order(\@a);
  
	my $var;
  
	if ($form->{startdatefrom}) {
		$where .= " AND e.startdate >= ".
			$dbh->quote($form->{startdatefrom});
	}
	if ($form->{startdateto}) {
		$where .= " AND e.startddate <= ".
			$dbh->quote($form->{startdateto});
	}
	if ($form->{name} ne "") {
		$var = $dbh->quote($form->like(lc $form->{name}));
		$where .= " AND lower(e.name) LIKE $var";
	}
	if ($form->{notes} ne "") {
		$var = $dbh->quote($form->like(lc $form->{notes}));
		$where .= " AND lower(e.notes) LIKE $var";
	}
	if ($form->{sales} eq 'Y') {
		$where .= " AND e.sales = '1'";
	}
	if ($form->{status} eq 'orphaned') {
		$where .= qq| AND e.login IS NULL|;
	}
	if ($form->{status} eq 'active') {
		$where .= qq| AND e.enddate IS NULL|;
	}
	if ($form->{status} eq 'inactive') {
		$where .= qq| AND e.enddate <= current_date|;
	}

	my $query = qq|
		   SELECT e.*, m.name AS manager
		     FROM employee e
		LEFT JOIN employee m ON (m.id = e.managerid)
		    WHERE $where
		 ORDER BY $sortorder|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		$ref->{address} = "";
		for (qw(address1 address2 city state zipcode country)) { 
			$ref->{address} .= "$ref->{$_} "; 
		}
		push @{ $form->{all_employee} }, $ref;
	}

	$sth->finish;
	$dbh->commit;

}


1;

