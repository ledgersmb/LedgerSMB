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
# Copyright (C) 2005
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
# Job Costing
#
#======================================================================


package JC;

use LedgerSMB::IS;
use LedgerSMB::PriceMatrix;
use LedgerSMB::Sysconfig;


sub get_jcitems {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT current_date|;
  ($form->{transdate}) = $dbh->selectrow_array($query);

  ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  
  my $dateformat = $myconfig->{dateformat};
  $dateformat =~ s/yy/yyyy/;
  $dateformat =~ s/yyyyyy/yyyy/;
 
  if ($form->{id}) {
    # retrieve timecard/storescard
    $query = qq|SELECT j.*, to_char(j.checkedin, 'HH24:MI:SS') AS checkedina,
                to_char(j.checkedout, 'HH24:MI:SS') AS checkedouta,
		to_char(j.checkedin, '$dateformat') AS transdate,
		e.name AS employee, p.partnumber,
		pr.projectnumber, pr.description AS projectdescription,
		pr.production, pr.completed, pr.parts_id AS project
                FROM jcitems j
		JOIN employee e ON (e.id = j.employee_id)
		JOIN parts p ON (p.id = j.parts_id)
		JOIN project pr ON (pr.id = j.project_id)
                WHERE j.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $sth->finish;
    $form->{project} = ($form->{project}) ? "job" : "project";
    for (qw(checkedin checkedout)) {
      $form->{$_} = $form->{"${_}a"};
      delete $form->{"${_}a"};
    }

    $query = qq|SELECT s.printed, s.spoolfile, s.formname
                FROM status s
		WHERE s.formname = '$form->{type}'
		AND s.trans_id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $form->{printed} .= "$ref->{formname} " if $ref->{printed};
      $form->{queued} .= "$ref->{formname} $ref->{spoolfile} " if $ref->{spoolfile};
    }
    $sth->finish;
    for (qw(printed queued)) { $form->{$_} =~ s/ +$//g }
  }
  
  JC->jcitems_links($myconfig, $form, $dbh);
 
  # get language codes
  $query = qq|SELECT *
              FROM language
	      ORDER BY 2|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  $form->{all_language} = ();
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_language} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect;

}


sub jcitems_links {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $disconnect = 0;

  if (! $dbh) {
    $dbh = $form->dbconnect($myconfig);
    $disconnect = 1;
  }
  
  my $query;

  if ($form->{project_id}) {
    $form->{orphaned} = 1;
    $query = qq|SELECT parts_id
                FROM project
	        WHERE id = $form->{project_id}|;
    if ($dbh->selectrow_array($query)) {
      $form->{project} = 'job';
      $query = qq|SELECT id
                  FROM project
	          WHERE parts_id > 0
	          AND production > completed
	          AND id = $form->{project_id}|;
      ($form->{orphaned}) = $dbh->selectrow_array($q);
    } else {
      $form->{project} = 'project';
    }
  }

  JC->jcparts($myconfig, $form, $dbh);
   
  $form->all_employees($myconfig, $dbh, $form->{transdate});
  
  my $where;
  
  if ($form->{transdate}) {
    $where .= qq| AND (enddate IS NULL
                       OR enddate >= '$form->{transdate}')
                  AND (startdate <= '$form->{transdate}'
		       OR startdate IS NULL)|;
  }
  
  if ($form->{project} eq 'job') {
    $query = qq|
		 SELECT pr.*
		 FROM project pr
		 WHERE pr.parts_id > 0
		 AND pr.production > pr.completed
		 $where|;
  } elsif ($form->{project} eq 'project') {
    $query = qq|
		 SELECT pr.*
		 FROM project pr
		 WHERE pr.parts_id IS NULL
		 $where|;
  } else {
    $query = qq|
    		 SELECT pr.*
		 FROM project pr
		 WHERE 1=1
		 $where
		 EXCEPT
		 SELECT pr.*
		 FROM project pr
		 WHERE pr.parts_id > 0
		 AND pr.production = pr.completed|;
  }

  if ($form->{project_id}) {
    $query .= qq|
                 UNION
		 SELECT *
		 FROM project
		 WHERE id = $form->{project_id}|;
  }
  
  $query .= qq|
                 ORDER BY projectnumber|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{all_project} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect if $disconnect;
  
}


sub jcparts {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my ($null, $project_id) = split /--/, $form->{projectnumber};
  $project_id *= 1;

  my $query = qq|SELECT customer_id
                 FROM project
		 WHERE id = $project_id|;
  my ($customer_id) = $dbh->selectrow_array($query);
  $customer_id *= 1;
  
  my $where;

  if ($form->{project} eq 'job') {
    $where = " AND p.income_accno_id IS NULL";
    if ($form->{type} eq 'storescard') {
      $where = " AND p.inventory_accno_id > 0
                 AND p.income_accno_id > 0";
    }
    
    $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
		 p.unit, t.description AS translation
                 FROM parts p
		 LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
	         WHERE p.obsolete = '0'
		 $where|;
  } elsif ($form->{project} eq 'project') {
    $where = " AND p.inventory_accno_id IS NULL";
    if ($form->{type} eq 'storescard') {
      $where = " AND p.inventory_accno_id > 0";
    }
    
    $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
		 p.unit, t.description AS translation 
		 FROM parts p 
		 LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
		 WHERE p.obsolete = '0'
		 AND p.assembly = '0'
		 $where|;
  } else {
    
    $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
		 p.unit, t.description AS translation
                 FROM parts p
		 LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
	         WHERE p.obsolete = '0'
		 AND p.income_accno_id IS NULL
		 UNION
                 SELECT p.id, p.partnumber, p.description, p.sellprice,
		 p.unit, t.description AS translation 
		 FROM parts p 
		 LEFT JOIN translation t ON (t.trans_id = p.id AND t.language_code = '$form->{language_code}')
		 WHERE p.obsolete = '0'
		 AND p.assembly = '0'
		 AND p.inventory_accno_id IS NULL|;
  }

  $query .= qq|
		 ORDER BY 2|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $pmh = PriceMatrix::price_matrix_query($dbh, $form);
  IS::exchangerate_defaults($dbh, $form);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    PriceMatrix::price_matrix($pmh, $ref, $form->{transdate}, 4, $form, $myconfig);
    push @{ $form->{all_parts} }, $ref;
  }
  $sth->finish;

}


sub delete_timecard {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
 
  my %audittrail = ( tablename  => 'jcitems',
                     reference  => $form->{id},
		     formname   => $form->{type},
		     action     => 'deleted',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
 
  my $query = qq|DELETE FROM jcitems
                 WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # delete spool files
  $query = qq|SELECT spoolfile FROM status
              WHERE formname = '$form->{type}'
	      AND trans_id = $form->{id}
	      AND spoolfile IS NOT NULL|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $spoolfile;
  my @spoolfiles = ();

  while (($spoolfile) = $sth->fetchrow_array) {
    push @spoolfiles, $spoolfile;
  }
  $sth->finish;

  # delete status entries
  $query = qq|DELETE FROM status
              WHERE formname = '$form->{type}'
	      AND trans_id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  my $rc = $dbh->commit;

  if ($rc) {
    foreach $spoolfile (@spoolfiles) {
      unlink "${LedgerSMB::Sysconfig::spool}/$spoolfile" if $spoolfile;
    }
  }

  $dbh->disconnect;

  $rc;

}


sub jcitems {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  
  my $query;
  my $where = "1 = 1";
  my $null;
  my $var;
  
  if ($form->{projectnumber}) {
    ($null, $var) = split /--/, $form->{projectnumber};
    $where .= " AND j.project_id = $var";

    $query = qq|SELECT parts_id
                FROM project
		WHERE id = $var|;
    my ($job) = $dbh->selectrow_array($query);
    $form->{project} = ($job) ? "job" : "project";
    
  }
  if ($form->{partnumber}) {
    ($null, $var) = split /--/, $form->{partnumber};
    $where .= " AND j.parts_id = $var";

    $query = qq|SELECT inventory_accno_id
                FROM parts
		WHERE id = $var|;
    my ($job) = $dbh->selectrow_array($query);
    $form->{project} = ($job) ? "job" : "project";
    
  }
  if ($form->{employee}) {
    ($null, $var) = split /--/, $form->{employee};
    $where .= " AND j.employee_id = $var";
  }
  if ($form->{open} || $form->{closed}) {
    unless ($form->{open} && $form->{closed}) {
      $where .= " AND j.qty != j.allocated" if $form->{open};
      $where .= " AND j.qty = j.allocated" if $form->{closed};
    }
  }
  
  ($form->{startdatefrom}, $form->{startdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  
  $where .= " AND j.checkedin >= '$form->{startdatefrom}'" if $form->{startdatefrom};
  $where .= " AND j.checkedout < date '$form->{startdateto}' + 1" if $form->{startdateto};

  my %ordinal = ( id => 1,
                  description => 2,
		  transdate => 7,
		  partnumber => 9,
		  projectnumber => 10,
		  projectdescription => 11,
		);
  
  my @a = (transdate, projectnumber);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $dateformat = $myconfig->{dateformat};
  $dateformat =~ s/yy$/yyyy/;
  $dateformat =~ s/yyyyyy/yyyy/;
  
  if ($form->{project} eq 'job') {
    if ($form->{type} eq 'timecard') {
      $where .= " AND pr.parts_id > 0
                  AND p.income_accno_id IS NULL";
    }
      
    if ($form->{type} eq 'storescard') {
      $where .= " AND pr.parts_id > 0
                  AND p.income_accno_id > 0";
    }
  }
  if ($form->{project} eq 'project') {
    $where .= " AND pr.parts_id IS NULL";
  }
  
  $query = qq|SELECT j.id, j.description, j.qty, j.allocated,
	      to_char(j.checkedin, 'HH24:MI') AS checkedin,
	      to_char(j.checkedout, 'HH24:MI') AS checkedout,
	      to_char(j.checkedin, 'yyyymmdd') AS transdate,
	      to_char(j.checkedin, '$dateformat') AS transdatea,
	      to_char(j.checkedin, 'D') AS weekday,
	      p.partnumber,
	      pr.projectnumber, pr.description AS projectdescription,
	      e.employeenumber, e.name AS employee,
	      to_char(j.checkedin, 'WW') AS workweek, pr.parts_id,
	      j.sellprice
	      FROM jcitems j
	      JOIN parts p ON (p.id = j.parts_id)
	      JOIN project pr ON (pr.id = j.project_id)
	      JOIN employee e ON (e.id = j.employee_id)
	      WHERE $where
	      ORDER BY employee, employeenumber, $sortorder|;

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{project} = ($ref->{parts_id}) ? "job" : "project";
    $ref->{transdate} = $ref->{transdatea};
    delete $ref->{transdatea};
    push @{ $form->{transactions} }, $ref;
  }
  $sth->finish;
  
  $dbh->disconnect;

}


sub save {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;
  
  my ($null, $project_id) = split /--/, $form->{projectnumber};

  if ($form->{id}) {
    # check if it was a job
    $query = qq|SELECT pr.parts_id, pr.production - pr.completed
		FROM project pr
		JOIN jcitems j ON (j.project_id = pr.id)
		WHERE j.id = $form->{id}|;
    my ($job_id, $qty) = $dbh->selectrow_array($query);

    if ($job_id && $qty == 0) {
      $dbh->disconnect;
      return -1;
    }
    
    # check if new one belongs to a job
    if ($project_id) {
      $query = qq|SELECT pr.parts_id, pr.production - pr.completed
		  FROM project pr
		  WHERE pr.id = $project_id|;
      my ($job_id, $qty) = $dbh->selectrow_array($query);

      if ($job_id && $qty == 0) {
	$dbh->disconnect;
	return -2;
      }
    }
    
  } else {
    my $uid = localtime;
    $uid .= "$$";

    $query = qq|INSERT INTO jcitems (description)
                VALUES ('$uid')|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM jcitems
                WHERE description = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }

  for (qw(inhour inmin insec outhour outmin outsec)) { $form->{$_} = substr("00$form->{$_}", -2) }
  for (qw(qty sellprice allocated)) { $form->{$_} = $form->parse_amount($myconfig, $form->{$_}) }

  my $checkedin = "$form->{inhour}$form->{inmin}$form->{insec}";
  my $checkedout = "$form->{outhour}$form->{outmin}$form->{outsec}";
  
  my $outdate = $form->{transdate};
  if ($checkedout < $checkedin) {
    $outdate = $form->add_date($myconfig, $form->{transdate}, 1, 'days');
  }

  ($null, $form->{employee_id}) = split /--/, $form->{employee};
  unless ($form->{employee_id}) {
    ($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh);
  } 

  my $parts_id;
  ($null, $parts_id) = split /--/, $form->{partnumber};
  
  $query = qq|UPDATE jcitems SET
              project_id = $project_id,
	      parts_id = $parts_id,
	      description = |.$dbh->quote($form->{description}).qq|,
	      qty = $form->{qty},
	      allocated = $form->{allocated},
	      sellprice = $form->{sellprice},
	      fxsellprice = $form->{sellprice},
	      serialnumber = |.$dbh->quote($form->{serialnumber}).qq|,
	      checkedin = timestamp '$form->{transdate} $form->{inhour}:$form->{inmin}:$form->{insec}',
	      checkedout = timestamp '$outdate $form->{outhour}:$form->{outmin}:$form->{outsec}',
	      employee_id = $form->{employee_id},
	      notes = |.$dbh->quote($form->{notes}).qq|
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  # save printed, queued
  $form->save_status($dbh);

  my %audittrail = ( tablename  => 'jcitems',
                     reference  => $form->{id},
		     formname   => $form->{type},
		     action     => 'saved',
		     id         => $form->{id} );

  $form->audittrail($dbh, "", \%audittrail);
  
  my $rc = $dbh->commit;
  
  $rc;

}



1;

