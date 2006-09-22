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
    $query = qq|SELECT e.*
                FROM employee e
                WHERE e.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
  
    # check if employee can be deleted, orphaned
    $form->{status} = "orphaned" unless $ref->{login};

$form->{status} = 'orphaned';   # leave orphaned for now until payroll is done

    $ref->{employeelogin} = $ref->{login};
    delete $ref->{login};
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;

    # get manager
    $form->{managerid} *= 1;
    $query = qq|SELECT name
                FROM employee
		WHERE id = $form->{managerid}|;
    ($form->{manager}) = $dbh->selectrow_array($query);
    
		
######### disabled for now
if ($form->{deductions}) {
    # get allowances
    $query = qq|SELECT d.id, d.description, da.before, da.after, da.rate
		FROM employeededuction da
		JOIN deduction d ON (da.deduction_id = d.id)
		WHERE da.employee_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{rate} *= 100;
      push @{ $form->{all_employeededuction} }, $ref;
    }
    $sth->finish;
}    

    $notid = qq|AND id != $form->{id}|;
    
  } else {

    $query = qq|SELECT current_date FROM defaults|;
    ($form->{startdate}) = $dbh->selectrow_array($query);
  
  }
  
  # get managers
  $query = qq|SELECT id, name
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


  # get deductions
if ($form->{deductions}) {  
  $query = qq|SELECT id, description
              FROM deduction
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deduction} }, $ref;
  }
  $sth->finish;
}

  $dbh->disconnect;

}



sub save_employee {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  my $query;
  my $sth;

  if (! $form->{id}) {
    my $uid = localtime;
    $uid .= "$$";

    $query = qq|INSERT INTO employee (name)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM employee
                WHERE name = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }

  my ($null, $managerid) = split /--/, $form->{manager};
  $managerid *= 1;
  $form->{sales} *= 1;

  $form->{employeenumber} = $form->update_defaults($myconfig, "employeenumber", $dbh) if ! $form->{employeenumber};

  $query = qq|UPDATE employee SET
              employeenumber = |.$dbh->quote($form->{employeenumber}).qq|,
	      name = |.$dbh->quote($form->{name}).qq|,
	      address1 = |.$dbh->quote($form->{address1}).qq|,
	      address2 = |.$dbh->quote($form->{address2}).qq|,
	      city = |.$dbh->quote($form->{city}).qq|,
	      state = |.$dbh->quote($form->{state}).qq|,
	      zipcode = |.$dbh->quote($form->{zipcode}).qq|,
	      country = |.$dbh->quote($form->{country}).qq|,
	      workphone = '$form->{workphone}',
	      homephone = '$form->{homephone}',
	      startdate = |.$form->dbquote($form->{startdate}, SQL_DATE).qq|,
	      enddate = |.$form->dbquote($form->{enddate}, SQL_DATE).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      role = '$form->{role}',
	      sales = '$form->{sales}',
	      email = |.$dbh->quote($form->{email}).qq|,
	      ssn = '$form->{ssn}',
	      dob = |.$form->dbquote($form->{dob}, SQL_DATE).qq|,
	      iban = '$form->{iban}',
	      bic = '$form->{bic}',
              managerid = $managerid
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

# for now
if ($form->{selectdeduction}) {	      
  # insert deduction and allowances for payroll
  $query = qq|DELETE FROM employeededuction
              WHERE employee_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|INSERT INTO employeededuction (employee_id, deduction_id,
              before, after, rate) VALUES ($form->{id},?,?,?,?)|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);

  for ($i = 1; $i <= $form->{deduction_rows}; $i++) {
    for (qw(before after)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    ($null, $deduction_id) = split /--/, $form->{"deduction_$i"};
    if ($deduction_id) {
      $sth->execute($deduction_id, $form->{"before_$i"}, $form->{"after_$i"}, $form->{"rate_$i"} / 100) || $form->dberror($query);
    }
  }
  $sth->finish;
}

  $dbh->commit;
  $dbh->disconnect;

}


sub delete_employee {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  # delete employee
  my $query = qq|DELETE FROM $form->{db}
	         WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  $dbh->commit;
  $dbh->disconnect;

}


sub employees {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $where = "1 = 1";
  $form->{sort} = ($form->{sort}) ? $form->{sort} : "name";
  my @a = qw(name);
  my $sortorder = $form->sort_order(\@a);
  
  my $var;
  
  if ($form->{startdatefrom}) {
    $where .= " AND e.startdate >= '$form->{startdatefrom}'";
  }
  if ($form->{startdateto}) {
    $where .= " AND e.startddate <= '$form->{startdateto}'";
  }
  if ($form->{name} ne "") {
    $var = $form->like(lc $form->{name});
    $where .= " AND lower(e.name) LIKE '$var'";
  }
  if ($form->{notes} ne "") {
    $var = $form->like(lc $form->{notes});
    $where .= " AND lower(e.notes) LIKE '$var'";
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

  my $query = qq|SELECT e.*, m.name AS manager
                 FROM employee e
                 LEFT JOIN employee m ON (m.id = e.managerid)
                 WHERE $where
		 ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{address} = "";
    for (qw(address1 address2 city state zipcode country)) { $ref->{address} .= "$ref->{$_} " }
    push @{ $form->{all_employee} }, $ref;
  }

  $sth->finish;
  $dbh->disconnect;

}


sub get_deduction {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
  my $ref;
  my $item;
  my $i;
  
  if ($form->{id}) {
    $query = qq|SELECT d.*,
                 c1.accno AS ap_accno,
                 c1.description AS ap_description,
		 c2.accno AS expense_accno,
		 c2.description AS expense_description
                 FROM deduction d
		 LEFT JOIN chart c1 ON (c1.id = d.ap_accno_id)
		 LEFT JOIN chart c2 ON (c2.id = d.expense_accno_id)
                 WHERE d.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
  
    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }

    $sth->finish;
  
    # check if orphaned
$form->{status} = 'orphaned';     # for now
  

    # get the rates
    $query = qq|SELECT rate, amount, above, below
                FROM deductionrate
                WHERE trans_id = $form->{id}
		ORDER BY rate, amount|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{deductionrate} }, $ref;
    }
    $sth->finish;
		
    # get all for deductionbase
    $query = qq|SELECT d.description, d.id, db.maximum
                FROM deductionbase db
		JOIN deduction d ON (d.id = db.deduction_id)
                WHERE db.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{deductionbase} }, $ref;
    }
    $sth->finish;
	   
    # get all for deductionafter
    $query = qq|SELECT d.description, d.id
                FROM deductionafter da
		JOIN deduction d ON (d.id = da.deduction_id)
                WHERE da.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{deductionafter} }, $ref;
    }
    $sth->finish;
    
    # build selection list for base and after
    $query = qq|SELECT id, description
                FROM deduction
	        WHERE id != $form->{id}
		ORDER BY 2|;
	   
  } else {
    # build selection list for base and after
    $query = qq|SELECT id, description
                FROM deduction
		ORDER BY 2|;
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deduction} }, $ref;
  }
  $sth->finish;

      
  my %category = ( ap		=> 'L',
                   expense	=> 'E' );
  
  foreach $item (keys %category) {
    $query = qq|SELECT accno, description
		FROM chart
		WHERE charttype = 'A'
		AND category = '$category{$item}'
		ORDER BY accno|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      push @{ $form->{"${item}_accounts"} }, $ref;
    }
    $sth->finish;
  }

   
  $dbh->disconnect;

}


sub deductions {
  my ($self, $myconfig, $form) = @_;

  my $dbh = $form->dbconnect($myconfig);
  
  my $query = qq|SELECT d.id, d.description, d.employeepays, d.employerpays,
                 c1.accno AS ap_accno, c2.accno AS expense_accno,
                 dr.rate, dr.amount, dr.above, dr.below
                 FROM deduction d
		 JOIN deductionrate dr ON (dr.trans_id = d.id)
		 LEFT JOIN chart c1 ON (d.ap_accno_id = c1.id)
		 LEFT JOIN chart c2 ON (d.expense_accno_id = c2.id)
                 ORDER BY 2, 7, 8|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_deduction} }, $ref;
  }
  
  $sth->finish;
  $dbh->disconnect;

}


sub save_deduction {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  ($form->{ap_accno}) = split /--/, $form->{ap_accno};
  ($form->{expense_accno}) = split /--/, $form->{expense_accno};
  
  my $null;
  my $deduction_id;
  my $query;
  my $sth;

  if (! $form->{id}) {
    my $uid = localtime;
    $uid .= "$$";

    $query = qq|INSERT INTO deduction (description)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM deduction
                WHERE description = '$uid'|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    ($form->{id}) = $sth->fetchrow_array;
    $sth->finish;
  }

  
  for (qw(employeepays employerpays)) { $form->{$_} = $form->parse_amount($myconfig, $form->{$_}) }
  
  $query = qq|UPDATE deduction SET
	      description = |.$dbh->quote($form->{description}).qq|,
	      ap_accno_id =
	           (SELECT id FROM chart
	            WHERE accno = '$form->{ap_accno}'),
	      expense_accno_id =
	           (SELECT id FROM chart
	            WHERE accno = '$form->{expense_accno}'),
	      employerpays = '$form->{employerpays}',
	      employeepays = '$form->{employeepays}',
	      fromage = |.$form->dbquote($form->{fromage}, SQL_INT).qq|,
	      toage = |.$form->dbquote($form->{toage}, SQL_INT).qq|
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);


  $query = qq|DELETE FROM deductionrate
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
  
  $query = qq|INSERT INTO deductionrate
	      (trans_id, rate, amount, above, below) VALUES (?,?,?,?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
 
  for ($i = 1; $i <= $form->{rate_rows}; $i++) {
    for (qw(rate amount above below)) { $form->{"${_}_$i"} = $form->parse_amount($myconfig, $form->{"${_}_$i"}) }
    $form->{"rate_$i"} /= 100;

    if ($form->{"rate_$i"} || $form->{"amount_$i"}) {
      $sth->execute($form->{id}, $form->{"rate_$i"}, $form->{"amount_$i"}, $form->{"above_$i"}, $form->{"below_$i"}) || $form->dberror($query);
    }
  }
  $sth->finish;


  $query = qq|DELETE FROM deductionbase
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
 
  $query = qq|INSERT INTO deductionbase
	      (trans_id, deduction_id, maximum) VALUES (?,?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
 
  for ($i = 1; $i <= $form->{base_rows}; $i++) {
    ($null, $deduction_id) = split /--/, $form->{"base_$i"};
    $form->{"maximum_$i"} = $form->parse_amount($myconfig, $form->{"maximum_$i"});
    if ($deduction_id) {
      $sth->execute($form->{id}, $deduction_id, $form->{"maximum_$i"}) || $form->dberror($query);
    }
  }
  $sth->finish;


  $query = qq|DELETE FROM deductionafter
              WHERE trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);
 
  $query = qq|INSERT INTO deductionafter
	      (trans_id, deduction_id) VALUES (?,?)|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
 
  for ($i = 1; $i <= $form->{after_rows}; $i++) {
    ($null, $deduction_id) = split /--/, $form->{"after_$i"};
    if ($deduction_id) {
      $sth->execute($form->{id}, $deduction_id) || $form->dberror($query);
    }
  }
  $sth->finish;
 
  $dbh->commit;
  $dbh->disconnect;

}


sub delete_deduction {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  # delete deduction
  my $query = qq|DELETE FROM $form->{db}
	         WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  foreach $item (qw(rate base after)) {
    $query = qq|DELETE FROM deduction$item
                WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }

  $dbh->commit;
  $dbh->disconnect;

}

1;

