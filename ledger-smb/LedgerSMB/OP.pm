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
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# Overpayment function
# used in AR, AP, IS, IR, OE, CP
#
#======================================================================

package OP;

sub overpayment {
  my ($self, $myconfig, $form, $dbh, $amount, $ml) = @_;
 
  my $fxamount = $form->round_amount($amount * $form->{exchangerate}, 2);
  my ($paymentaccno) = split /--/, $form->{account};

  my ($null, $department_id) = split /--/, $form->{department};
  $department_id *= 1;

  my $uid = localtime;
  $uid .= "$$";

  # add AR/AP header transaction with a payment
  $query = qq|INSERT INTO $form->{arap} (invnumber, employee_id)
	      VALUES ('$uid', (SELECT id FROM employee
			     WHERE login = '$form->{login}'))|;
  $dbh->do($query) || $form->dberror($query);

  $query = qq|SELECT id FROM $form->{arap}
	    WHERE invnumber = '$uid'|;
  ($uid) = $dbh->selectrow_array($query);

  my $invnumber = $form->{invnumber};
  $invnumber = $form->update_defaults($myconfig, ($form->{arap} eq 'ar') ? "sinumber" : "vinumber", $dbh) unless $invnumber;

  $query = qq|UPDATE $form->{arap} set
	      invnumber = |.$dbh->quote($invnumber).qq|,
	      $form->{vc}_id = $form->{"$form->{vc}_id"},
	      transdate = '$form->{datepaid}',
	      datepaid = '$form->{datepaid}',
	      duedate = '$form->{datepaid}',
	      netamount = 0,
	      amount = 0,
	      paid = $fxamount,
	      curr = '$form->{currency}',
	      department_id = $department_id
	      WHERE id = $uid|;
  $dbh->do($query) || $form->dberror($query);

  # add AR/AP
  ($accno) = split /--/, $form->{$form->{ARAP}};
  
  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate, amount)
	      VALUES ($uid, (SELECT id FROM chart
			     WHERE accno = '$accno'),
	      '$form->{datepaid}', $fxamount * $ml)|;
  $dbh->do($query) || $form->dberror($query);

  # add payment
  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
	      amount, source, memo)
	      VALUES ($uid, (SELECT id FROM chart
			     WHERE accno = '$paymentaccno'),
		'$form->{datepaid}', $amount * $ml * -1, |
		.$dbh->quote($form->{source}).qq|, |
		.$dbh->quote($form->{memo}).qq|)|;
  $dbh->do($query) || $form->dberror($query);

  # add exchangerate difference
  if ($fxamount != $amount) {
    $query = qq|INSERT INTO acc_trans (trans_id, chart_id, transdate,
		amount, cleared, fx_transaction, source)
		VALUES ($uid, (SELECT id FROM chart
			       WHERE accno = '$paymentaccno'),
	        '$form->{datepaid}', ($fxamount - $amount) * $ml * -1,
	        '1', '1', |
		.$dbh->quote($form->{source}).qq|)|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  my %audittrail = ( tablename  => $form->{arap},
                     reference  => $invnumber,
		     formname   => ($form->{arap} eq 'ar') ? 'deposit' : 'pre-payment',
		     action     => 'posted',
		     id         => $uid );
 
  $form->audittrail($dbh, "", \%audittrail);
  
}


1;

