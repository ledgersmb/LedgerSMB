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
# Copyright (C) 2002
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
# Account reconciliation routines
#
#======================================================================

package RC;


sub paymentaccounts {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT accno, description
                 FROM chart
		 WHERE link LIKE '%_paid%'
		 AND (category = 'A' OR category = 'L')
		 ORDER BY accno|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @{ $form->{PR} }, $ref;
  }
  $sth->finish;

  $form->all_years($myconfig, $dbh);

  $dbh->disconnect;

}


sub payment_transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database, turn AutoCommit off
  my $dbh = $form->dbconnect_noauto($myconfig);

  my $query;
  my $sth;

  $query = qq|SELECT category FROM chart
              WHERE accno = '$form->{accno}'|;
  ($form->{category}) = $dbh->selectrow_array($query);
  
  my $cleared;

  ($form->{fromdate}, $form->{todate}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};

  my $transdate = qq| AND ac.transdate < date '$form->{fromdate}'|;

  if (! $form->{fromdate}) {
    $cleared = qq| AND ac.cleared = '1'|;
    $transdate = "";
  }
    
  # get beginning balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      $transdate
	      $cleared
	      |;
  ($form->{beginningbalance}) = $dbh->selectrow_array($query);

  # fx balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      AND ac.fx_transaction = '1'
	      $transdate
	      $cleared
	      |;
  ($form->{fx_balance}) = $dbh->selectrow_array($query);
  

  $transdate = "";
  if ($form->{todate}) {
    $transdate = qq| AND ac.transdate <= date '$form->{todate}'|;
  }
 
  # get statement balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      $transdate
	      |;
  ($form->{endingbalance}) = $dbh->selectrow_array($query);

  # fx balance
  $query = qq|SELECT sum(ac.amount)
	      FROM acc_trans ac
	      JOIN chart ch ON (ch.id = ac.chart_id)
	      WHERE ch.accno = '$form->{accno}'
	      AND ac.fx_transaction = '1'
	      $transdate
	      |;
  ($form->{fx_endingbalance}) = $dbh->selectrow_array($query);


  $cleared = qq| AND ac.cleared = '0'| unless $form->{fromdate};
  
  if ($form->{report}) {
    $cleared = qq| AND NOT (ac.cleared = '0' OR ac.cleared = '1')|;
    if ($form->{cleared}) {
      $cleared = qq| AND ac.cleared = '1'|;
    }
    if ($form->{outstanding}) {
      $cleared = ($form->{cleared}) ? "" : qq| AND ac.cleared = '0'|;
    }
    if (! $form->{fromdate}) {
      $form->{beginningbalance} = 0;
      $form->{fx_balance} = 0;
    }
  }
  
  my $fx_transaction;
  if ($form->{fx_transaction}) {
    $fx_transaction = qq|
	      AND NOT
		 (ac.chart_id IN
		  (SELECT fxgain_accno_id FROM defaults
		   UNION
		   SELECT fxloss_accno_id FROM defaults))|;
  } else {
    $fx_transaction = qq|
	      AND ac.fx_transaction = '0'|;
  }
 
  
  if ($form->{summary}) {
    $query = qq|SELECT ac.transdate, ac.source,
		sum(ac.amount) AS amount, ac.cleared
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ch.accno = '$form->{accno}'
		AND ac.amount >= 0
		$fx_transaction
		$cleared|;
    $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
    $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
    $query .= " GROUP BY ac.source, ac.transdate, ac.cleared";
    $query .= qq|
                UNION ALL
		SELECT ac.transdate, ac.source,
		sum(ac.amount) AS amount, ac.cleared
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ch.accno = '$form->{accno}'
		AND ac.amount < 0
		$fx_transaction
		$cleared|;
    $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
    $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
    $query .= " GROUP BY ac.source, ac.transdate, ac.cleared";

    $query .= " ORDER BY 1,2";
    
  } else {
    
    $query = qq|SELECT ac.transdate, ac.source, ac.fx_transaction,
		ac.amount, ac.cleared, g.id, g.description
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		JOIN gl g ON (g.id = ac.trans_id)
		WHERE ch.accno = '$form->{accno}'
		$fx_transaction
		$cleared|;
    $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
    $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
    $query .= qq|
                UNION ALL
		SELECT ac.transdate, ac.source, ac.fx_transaction,
		ac.amount, ac.cleared, a.id, n.name
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		JOIN ar a ON (a.id = ac.trans_id)
		JOIN customer n ON (n.id = a.customer_id)
		WHERE ch.accno = '$form->{accno}'
		$fx_transaction
		$cleared|;
    $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
    $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
    $query .= qq|
                UNION ALL
		SELECT ac.transdate, ac.source, ac.fx_transaction,
		ac.amount, ac.cleared, a.id, n.name
		FROM acc_trans ac
		JOIN chart ch ON (ac.chart_id = ch.id)
		JOIN ap a ON (a.id = ac.trans_id)
		JOIN vendor n ON (n.id = a.vendor_id)
		WHERE ch.accno = '$form->{accno}'
		$fx_transaction
		$cleared|;
    $query .= " AND ac.transdate >= '$form->{fromdate}'" if $form->{fromdate};
    $query .= " AND ac.transdate <= '$form->{todate}'" if $form->{todate};
    
    $query .= " ORDER BY 1,2,3";
  }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  my $dr;
  my $cr;
  
  if ($form->{summary}) {
    $query = qq|SELECT c.name
		FROM customer c
		JOIN ar a ON (c.id = a.customer_id)
		JOIN acc_trans ac ON (a.id = ac.trans_id)
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ac.transdate = ?
		AND ch.accno = '$form->{accno}'
		AND (ac.source = ? OR ac.source IS NULL)
		AND ac.amount >= 0
		$cleared
	UNION
		SELECT v.name
		FROM vendor v
		JOIN ap a ON (v.id = a.vendor_id)
		JOIN acc_trans ac ON (a.id = ac.trans_id)
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ac.transdate = ?
		AND ch.accno = '$form->{accno}'
		AND (ac.source = ? OR ac.source IS NULL)
		AND ac.amount > 0
		$cleared
	UNION
		SELECT g.description
		FROM gl g
		JOIN acc_trans ac ON (g.id = ac.trans_id)
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ac.transdate = ?
		AND ch.accno = '$form->{accno}'
		AND (ac.source = ? OR ac.source IS NULL)
		AND ac.amount >= 0
		$cleared
		|;
    
    $query .= " ORDER BY 1";
    $dr = $dbh->prepare($query);

    $query = qq|SELECT c.name
		FROM customer c
		JOIN ar a ON (c.id = a.customer_id)
		JOIN acc_trans ac ON (a.id = ac.trans_id)
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ac.transdate = ?
		AND ch.accno = '$form->{accno}'
		AND (ac.source = ? OR ac.source IS NULL)
		AND ac.amount < 0
		$cleared
	UNION
		SELECT v.name
		FROM vendor v
		JOIN ap a ON (v.id = a.vendor_id)
		JOIN acc_trans ac ON (a.id = ac.trans_id)
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ac.transdate = ?
		AND ch.accno = '$form->{accno}'
		AND (ac.source = ? OR ac.source IS NULL)
		AND ac.amount < 0
		$cleared
	UNION
		SELECT g.description
		FROM gl g
		JOIN acc_trans ac ON (g.id = ac.trans_id)
		JOIN chart ch ON (ac.chart_id = ch.id)
		WHERE ac.transdate = ?
		AND ch.accno = '$form->{accno}'
		AND (ac.source = ? OR ac.source IS NULL)
		AND ac.amount < 0
		$cleared
		|;
		
    $query .= " ORDER BY 1";
    $cr = $dbh->prepare($query);
  }
 
  my $name;
  my $ref;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

    if ($form->{summary}) {

      if ($ref->{amount} > 0) {
	$dr->execute($ref->{transdate}, $ref->{source}, $ref->{transdate}, $ref->{source}, $ref->{transdate}, $ref->{source});
	$ref->{oldcleared} = $ref->{cleared};
	$ref->{name} = ();

	while (($name) = $dr->fetchrow_array) {
	  push @{ $ref->{name} }, $name;
	}
	$dr->finish;
      } else {
      
	$cr->execute($ref->{transdate}, $ref->{source}, $ref->{transdate}, $ref->{source}, $ref->{transdate}, $ref->{source});
	$ref->{oldcleared} = $ref->{cleared};
	$ref->{name} = ();
	while (($name) = $cr->fetchrow_array) {
	  push @{ $ref->{name} }, $name;
	}
	$cr->finish;
	
      }

    } else {
      push @{ $ref->{name} }, $ref->{description};
    }

    push @{ $form->{PR} }, $ref;

  }
  $sth->finish;

  $dbh->disconnect;
  
}


sub reconcile {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  my $query = qq|SELECT id FROM chart
                 WHERE accno = '$form->{accno}'|;
  my ($chart_id) = $dbh->selectrow_array($query);
  $chart_id *= 1;
  
  $query = qq|SELECT trans_id FROM acc_trans
              WHERE (source = ? OR source IS NULL)
	      AND transdate = ?
	      AND cleared = '0'
	      AND chart_id = $chart_id|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
    
  my $i;
  my $trans_id;

  $query = qq|UPDATE acc_trans SET cleared = '1'
              WHERE cleared = '0'
	      AND trans_id = ? 
	      AND transdate = ?
	      AND chart_id = $chart_id|;
  my $tth = $dbh->prepare($query) || $form->dberror($query);
  
  # clear flags
  for $i (1 .. $form->{rowcount}) {
    if ($form->{"cleared_$i"} && ! $form->{"oldcleared_$i"}) {
      if ($form->{summary}) {
	$sth->execute($form->{"source_$i"}, $form->{"transdate_$i"}) || $form->dberror;
      
	while (($trans_id) = $sth->fetchrow_array) {
	  $tth->execute($trans_id, $form->{"transdate_$i"}) || $form->dberror;
	  $tth->finish;
	}
	$sth->finish;
	
      } else {

	$tth->execute($form->{"id_$i"}, $form->{"transdate_$i"}) || $form->dberror;
	$tth->finish;
      }
    }
  }

  $dbh->disconnect;

}

1;

