
=head1 NAME

OP

=head1 SYNOPSIS

This module provides an overpayment function used by CP.pm

=head1 COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
 # This work contains copyrighted information from a number of sources
 # all used with permission.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders,
 # see the CONTRIBUTORS file.
 #
 # Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
 # Copyright (C) 2001
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 #  Contributors:
 #
 #====================================================================
 #
 # This file has undergone whitespace cleanup.
 #
 #====================================================================
 #
 # Overpayment function
 # used in AR, AP, IS, IR, OE, CP
 #
 #====================================================================

=head1 METHODS

=over

=cut

package OP;

=item OP::overpayment('', $myconfig, $form, $dbh, $amount, $ml);

Adds entries to acc_trans and ar or ap relating to overpayments found while
processing payments with CP->post_payment and CP->post_payments.  Also adds an
audit trail entry with a formname of 'deposit' if it is on an AR transaction
or 'pre-payment' if the transaction is an AP transaction.  $amount is the
overpayment amount without the exchange rate applied.

$form attributes used by this function:

=over

=item $form->{arap}

Possible values are 'ar' and 'ap'.  Indicates part of the transaction type.

=item $form->{ARAP}

Possible values are 'AR' and 'AP'.  Should be the upper case variant of the
value in $form->{arap}.

=item $form->{vc}

Possible values are 'vendor' and 'customer'.  Should be 'customer' if
$form->{arap} is 'ar' and 'vendor' if $form->{arap} is 'ap'.

=item $form->{invnumber}

Invoice number for the transaction being processed.

=item $form->{exchangerate}

Exchange rate used in the transaction.

=item $form->{currency}

Currency used by the transaction.

=item $form->{account}

Of the form 'accno--description'.  Used to obtain the account number of the
payment account.

=item $form->{$form->{ARAP}}

Of the form 'accno--description'.  Used to obtain the account number of the
non-payment account.

=item $form->{department}

Of the form 'description--department_id'.  Used to obtain the id of the
department involved in the transaction.

=item $form->{$form->{vc}_id}

The id of the customer or vendor involved in the overpayment.

=item $form->{datepaid}

The date to enter in as all the date fields related to the overpayment entries.

=item $form->{source}

Payment source

=item $form->{memo}

Payment memo

=item $form->{approved}

If this is false but defined, add a voucher entry.  Otherwise, is set to true.

=item $form->{batch_id}

Batch id for a voucher, only used if $form->{approved} is false but defined.

=back

=cut

sub overpayment {
    my ( $self, $myconfig, $form, $dbh, $amount, $ml ) = @_;

    my $invnumber = $form->{invnumber};
    $invnumber =
      $form->update_defaults( $myconfig, ( $form->{arap} eq 'ar' )
        ? "sinumber"
        : "vinumber", $dbh )
      unless $invnumber;
    my $fxamount = $form->round_amount( $amount * $form->{exchangerate}, 2 );
    my ($paymentaccno) = split /--/, $form->{account};

    my ( $null, $department_id ) = split /--/, $form->{department};
    $department_id *= 1;

    my $uid = localtime;
    $uid .= "$$";

    # add AR/AP header transaction with a payment
    my $login = $dbh->quote( $form->{login} );
    $query = qq|
		INSERT INTO $form->{arap} (invnumber, employee_id)
		     VALUES ('$uid', (SELECT id FROM employee
		      WHERE login = $login))|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|SELECT id FROM $form->{arap} WHERE invnumber = '$uid'|;
    ($uid) = $dbh->selectrow_array($query);


    $query = qq|
		UPDATE $form->{arap} 
		   set invnumber = ?,
		       $form->{vc}_id = ?,
		       transdate = ?,
		       datepaid = ?,
		       duedate = ?,
		       netamount = 0,
		       amount = 0,
		       paid = ?,
		       curr = ?,
		       department_id = ?
		 WHERE id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute(
        $invnumber,        $form->{"$form->{vc}_id"},
        $form->{datepaid}, $form->{datepaid},
        $form->{datepaid}, $fxamount,
        $form->{currency}, $department_id,
        $uid
    ) || $form->dberror($query);

    # add AR/AP
    ($accno) = split /--/, $form->{ $form->{ARAP} };

    $query = qq|
		INSERT INTO acc_trans (trans_id, chart_id, transdate, amount,
			approved)
		     VALUES (?, (SELECT id FROM chart 
		                  WHERE accno = ?), ?, ?, ?)|;
    if (not defined $form->{approved}){
        $form->{approved} = 1;
    }
    if (!$form->{approved}){
       if (not defined $form->{batch_id}){
           $form->error($locale->text('Batch ID Missing'));
       }
       $query = qq| 
			INSERT INTO voucher (batch_id, trans_id) VALUES (?, ?)|;
       $sth = $dbh->prepare($query);
       $sth->execute($form->{batch_id}, $uid) ||
            $form->dberror($query);
    }
    $sth = $dbh->prepare($query);
    $sth->execute( $uid, $accno, $form->{datepaid}, $fxamount * $ml, 
         $form->{approved} )
      || $form->dberror($query);

    # add payment
    $query = qq|
		INSERT INTO acc_trans (trans_id, chart_id, transdate, 
		                      amount, source, memo)
		     VALUES (?, (SELECT id FROM chart WHERE accno = ?),
		            ?, ?, ?, ?)|;
    $sth = $dbh->prepare($query);
    $sth->execute( $uid, $paymentaccno, $form->{datepaid}, $amount * $ml * -1,
        $form->{source}, $form->{memo} )
      || $form->dberror($query);

    # add exchangerate difference
    if ( $fxamount != $amount ) {
        $query = qq|
			INSERT INTO acc_trans (trans_id, chart_id, transdate,
			            amount, cleared, fx_transaction, source)
			     VALUES (?, (SELECT id FROM chart WHERE accno = ?),
			            ?, ?, '1', '1', ?)|;
        $sth = $dbh->prepare($query);
        $sth->execute( $uid, $paymentaccno, $form->{datepaid},
            ( $fxamount - $amount ) * $ml * -1,
            $form->{source} )
          || $form->dberror($query);
    }

    my %audittrail = (
        tablename => $form->{arap},
        reference => $invnumber,
        formname  => ( $form->{arap} eq 'ar' )
        ? 'deposit'
        : 'pre-payment',
        action => 'posted',
        id     => $uid
    );

    $form->audittrail( $dbh, "", \%audittrail );

}

1;

=back

