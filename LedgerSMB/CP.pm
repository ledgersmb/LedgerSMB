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
#
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
use LedgerSMB::Sysconfig;


sub new {

    my ( $type, $countrycode ) = @_;

    $self = {};

    use LedgerSMB::Num2text;
    use LedgerSMB::Locale;
    $self->{'locale'} = LedgerSMB::Locale->get_handle($countrycode);

    bless $self, $type;

}

sub paymentaccounts {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|SELECT accno, description, link
					 FROM chart
					WHERE link LIKE ?
				 ORDER BY accno|;

    my $sth = $dbh->prepare($query);
    $sth->execute("%$form->{ARAP}%") || $form->dberror($query);

    $form->{PR}{ $form->{ARAP} } = ();
    $form->{PR}{"$form->{ARAP}_paid"} = ();

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {

        foreach my $item ( split /:/, $ref->{link} ) {

            if ( $item eq $form->{ARAP} ) {
                push @{ $form->{PR}{ $form->{ARAP} } }, $ref;
            }

            if ( $item eq "$form->{ARAP}_paid" ) {
                push @{ $form->{PR}{"$form->{ARAP}_paid"} }, $ref;
            }
        }
    }

    $sth->finish;

    # get currencies and closedto
    $query = qq|
		SELECT value, (SELECT value FROM defaults
		                WHERE setting_key = 'closedto'), 
		       current_date
		  FROM defaults
		 WHERE setting_key = 'curr'|;

    ( $form->{currencies}, $form->{closedto}, $form->{datepaid} ) =
      $dbh->selectrow_array($query);

    if ( $form->{payment} eq 'payments' ) {

        # get language codes
        $query = qq|SELECT *
					  FROM language
				  ORDER BY 2|;

        $sth = $dbh->prepare($query);
        $sth->execute || $self->dberror($query);

        $form->{all_language} = ();

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            push @{ $form->{all_language} }, $ref;
        }

        $sth->finish;

        $form->all_departments( $myconfig, $dbh, $form->{vc} );
    }

    $dbh->commit;

}

sub get_openvc {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $arap = ( $form->{vc} eq 'customer' ) ? 'ar' : 'ap';
    my $query = qq|
		SELECT count(*)
		  FROM entity_credit_account ct 
		  JOIN $arap a USING (entity_id)
		 WHERE a.amount != a.paid|;

    my ($count) = $dbh->selectrow_array($query);

    my $sth;
    my $ref;
    my $i = 0;

    my $where = qq|WHERE a.amount != a.paid|;

    if ( $form->{ $form->{vc} } ) {
        my $var = $dbh->quote( $form->like( lc $form->{ $form->{vc} } ) );
        $where .= " AND lower(name) LIKE $var";
    }

    # build selection list
    $query = qq|
	SELECT DISTINCT ct.*, e.name, c.*, l.*
	  FROM entity_credit_account ct 
	  JOIN $arap a USING (entity_id)
	  JOIN company c USING (entity_id)
	  JOIN entity e ON (e.id = a.entity_id)
	  LEFT JOIN company_to_location c2l ON (c.id = c2l.company_id)
	  LEFT JOIN location l ON (l.id = c2l.location_id)
	$where
	 ORDER BY name|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $i++;
        push @{ $form->{name_list} }, $ref;
    }

    $sth->finish;

    $form->all_departments( $myconfig, $dbh, $form->{vc} );

    # get language codes
    $query = qq|SELECT *
				  FROM language
			  ORDER BY 2|;

    $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);

    $form->{all_language} = ();

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_language} }, $ref;
    }

    $sth->finish;

    # get currency for first name
    if ( @{ $form->{name_list} } ) {

        # Chris T:  I don't like this but it seems safe injection-wise
        # Leaving it so we can change it when we go to a new system
        $query = qq|SELECT curr 
					  FROM $form->{vc}
					 WHERE entity_id = $form->{name_list}->[0]->{entity_id}|;

        ( $form->{currency} ) = $dbh->selectrow_array($query);
        $form->{currency} ||= $form->{defaultcurrency};
    }

    $dbh->commit;

    $i;
}

sub get_openinvoices {

    my ( $self, $myconfig, $form ) = @_;

    my $null;
    my $department_id;

    # connect to database
    my $dbh = $form->{dbh};

    $vc_id = $dbh->quote( $form->{"entity_id"} );
    my $where = qq|WHERE a.entity_id = $vc_id
					 AND a.amount != a.paid|;

    $curr = $dbh->quote( $form->{currency} );
    $where .= qq| AND a.curr = $curr| if $form->{currency};

    my $sortorder = "transdate, invnumber";

    my ($buysell);

    if ( $form->{vc} eq 'customer' ) {
        $buysell = "buy";
    }
    else {
        $buysell = "sell";
    }

    if ( $form->{payment} eq 'payments' ) {

        $where = qq|WHERE a.amount != a.paid|;
        $where .= qq| AND a.curr = $curr| if $form->{currency};

        if ( $form->{duedatefrom} ) {
            $where .= qq| AND a.duedate >= 
				| . $dbh->quote( $form->{duedatefrom} );
        }

        if ( $form->{duedateto} ) {
            $where .=
              qq| AND a.duedate <= | . $dbh->quote( $form->{duedateto} );
        }

        $sortorder = "name, transdate";
    }

    ( $null, $department_id ) = split /--/, $form->{department};

    if ($department_id) {
        $where .= qq| AND a.department_id = $department_id|;
    }

    my $query = qq|SELECT a.id, a.invnumber, a.transdate, a.amount, a.paid,
						  a.curr, e.name, a.entity_id, c.language_code
					 FROM $form->{arap} a
					 JOIN $form->{vc} c ON (c.entity_id = a.entity_id)
					 JOIN entity e ON (a.entity_id = e.id)
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

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {

        # if this is a foreign currency transaction get exchangerate
        $ref->{exchangerate} =
          $form->get_exchangerate( $dbh, $ref->{curr}, $ref->{transdate},
            $buysell )
          if ( $form->{currency} ne $form->{defaultcurrency} );

        $vth->execute( $ref->{id} );
        $ref->{queue} = "";

        while ( ($spoolfile) = $vth->fetchrow_array ) {
            $ref->{queued} .= "$form->{formname} $spoolfile ";
        }

        $vth->finish;
        $ref->{queued} =~ s/ +$//g;

        push @{ $form->{PR} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

sub post_payment {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database, turn AutoCommit off
    my $dbh = $form->{dbh};

    my $sth;

    my ($paymentaccno) = split /--/, $form->{account};

    # if currency ne defaultcurrency update exchangerate
    if ( $form->{currency} ne $form->{defaultcurrency} ) {

        $form->{exchangerate} =
          $form->parse_amount( $myconfig, $form->{exchangerate} );

        if ( $form->{vc} eq 'customer' ) {
            $form->update_exchangerate( $dbh, $form->{currency},
                $form->{datepaid}, $form->{exchangerate}, 0 );
        }
        else {
            $form->update_exchangerate( $dbh, $form->{currency},
                $form->{datepaid}, 0, $form->{exchangerate} );
        }

    }
    else {
        $form->{exchangerate} = 1;
    }

    my $query = qq|
		SELECT (SELECT value FROM defaults 
		         WHERE setting_key='fxgain_accno_id'), 
		       (SELECT value FROM defaults
		         WHERE setting_key='fxloss_accno_id')|;

    my ( $fxgain_accno_id, $fxloss_accno_id ) = $dbh->selectrow_array($query);

    my ($buysell);

    if ( $form->{vc} eq 'customer' ) {
        $buysell = "buy";
    }
    else {
        $buysell = "sell";
    }

    my $ml;
    my $where;

    if ( $form->{ARAP} eq 'AR' ) {

        $ml    = 1;
        $where = qq| (c.link = 'AR' OR c.link LIKE 'AR:%') |;

    }
    else {

        $ml = -1;
        $where =
          qq| (c.link = 'AP' OR c.link LIKE '%:AP' OR c.link LIKE '%:AP:%') |;

    }

    my $paymentamount = $form->parse_amount( $myconfig, $form->{amount} );

    # query to retrieve paid amount
    $query = qq|SELECT paid 
				  FROM $form->{arap}
				 WHERE id = ?
			FOR UPDATE|;

    my $pth = $dbh->prepare($query) || $form->dberror($query);

    my %audittrail;

    # go through line by line
    for my $i ( 1 .. $form->{rowcount} ) {

        $form->{"paid_$i"} =
          $form->parse_amount( $myconfig, $form->{"paid_$i"} );
        $form->{"due_$i"} = $form->parse_amount( $myconfig, $form->{"due_$i"} );

        if ( $form->{"checked_$i"} && $form->{"paid_$i"} ) {

            $paymentamount -= $form->{"paid_$i"};

            # get exchangerate for original
            $query = qq|
				SELECT $buysell
				  FROM exchangerate e
				  JOIN $form->{arap} a 
				       ON (a.transdate = e.transdate)
				 WHERE e.curr = ?
				       AND a.id = ?|;

            my $sth = $dbh->prepare($query);
            $sth->execute( $form->{currency}, $form->{"id_$i"} );
            my ($exchangerate) = $sth->fetchrow_array();

            $exchangerate = 1 unless $exchangerate;

            $query = qq|
				SELECT c.id
				  FROM chart c
				  JOIN acc_trans a ON (a.chart_id = c.id)
				 WHERE $where
				       AND a.trans_id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{"id_$i"} );
            my ($id) = $sth->fetchrow_array;

            $amount =
              $form->round_amount( $form->{"paid_$i"} * $exchangerate, 2 );

            # add AR/AP
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, transdate, 
				            amount)
				     VALUES (?, ?, 
				            ?, 
				            ?)|;
            $sth = $dbh->prepare($query);
            $sth->execute( $form->{"id_$i"}, $id, $form->{date_paid},
                $amount * $ml )
              || $form->dberror( $query, __FILE__, __LINE__ );

            # add payment
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, transdate,
				             amount, source, memo)
				     VALUES (?, (SELECT id 
				                   FROM chart
				                  WHERE accno = ?),
				 	    ?, ?, ?, ?)|;
            $sth = $dbh->prepare($query);
            $sth->execute( $form->{"id_$i"}, $paymentaccno, $form->{datepaid},
                $form->{"paid_$i"} * $ml * -1,
                $form->{source}, $form->{memo} )
              || $form->dberror( $query, 'CP.pm', 444 );

            # add exchangerate difference if currency ne defaultcurrency
            $amount =
              $form->round_amount(
                $form->{"paid_$i"} * ( $form->{exchangerate} - 1 ), 2 );

            if ($amount) {

                # exchangerate difference
                $query = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, 
					            transdate, amount, cleared,
					            fx_transaction, source)
					     VALUES (?, (SELECT id 
					                   FROM chart
					                  WHERE accno = ?),
					             ?, ?, '0', '1', 
					             ?)|;
                $sth = $dbh->prepare($query);
                $sth->execute(
                    $form->{"id_$i"},   $paymentaccno, $form->{datepaid},
                    $amount * $ml * -1, $form->{source}
                ) || $form->dberror( $query, 'CP.pm', 470 );

                # gain/loss
                $amount = (
                    $form->round_amount(
                        $form->{"paid_$i"} * $exchangerate, 2
                      ) - $form->round_amount(
                        $form->{"paid_$i"} * $form->{exchangerate}, 2
                      )
                ) * $ml * -1;

                if ($amount) {

                    my $accno_id =
                      ( $amount > 0 )
                      ? $fxgain_accno_id
                      : $fxloss_accno_id;

                    $query = qq|
						INSERT INTO acc_trans 
						            (trans_id, 
						            chart_id, 
						            transdate,
						            amount, cleared, 
						            fx_transaction)
						VALUES (?, ?, ?, ?, '0', '1')|;
                    $sth = $dbh->prepare($query);
                    $sth->execute(
                        $form->{"id_$i"},  $accno_id,
                        $form->{datepaid}, $amount
                    ) || $form->dberror( $query, 'CP.pm', 506 );
                }
            }

            $form->{"paid_$i"} =
              $form->round_amount( $form->{"paid_$i"} * $exchangerate, 2 );

            $pth->execute( $form->{"id_$i"} ) || $form->dberror($pth->statement);
            ($amount) = $pth->fetchrow_array;
            $pth->finish;

            $amount += $form->{"paid_$i"};

            # update AR/AP transaction
            $query = qq|
				UPDATE $form->{arap} 
				   SET paid = ?,
				       datepaid = ?
				 WHERE id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $amount, $form->{datepaid}, $form->{"id_$i"} )
              || $form->dberror( $query, 'CP.pm', 530 );

            %audittrail = (
                tablename => $form->{arap},
                reference => $form->{source},
                formname  => $form->{formname},
                action    => 'posted',
                id        => $form->{"id_$i"}
            );

            $form->audittrail( $dbh, "", \%audittrail );

        }
    }

    # record a AR/AP with a payment
    if ( $form->round_amount( $paymentamount, 2 ) ) {
        $form->{invnumber} = "";
        OP::overpayment( "", $myconfig, $form, $dbh, $paymentamount, $ml, 1 );
    }

    my $rc = $dbh->commit;

    $rc;

}

sub post_payments {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database, turn AutoCommit off
    my $dbh = $form->{dbh};

    my $sth;

    my ($paymentaccno) = split /--/, $form->{account};

    # if currency ne defaultcurrency update exchangerate
    if ( $form->{currency} ne $form->{defaultcurrency} ) {
        $form->{exchangerate} =
          $form->parse_amount( $myconfig, $form->{exchangerate} );

        if ( $form->{vc} eq 'customer' ) {
            $form->update_exchangerate( $dbh, $form->{currency},
                $form->{datepaid}, $form->{exchangerate}, 0 );
        }
        else {
            $form->update_exchangerate( $dbh, $form->{currency},
                $form->{datepaid}, 0, $form->{exchangerate} );
        }

    }
    else {
        $form->{exchangerate} = 1;
    }

    my $query = qq|
		SELECT (SELECT value FROM defaults 
		         WHERE setting_key='fxgain_accno_id'), 
		       (SELECT value FROM defaults
		         WHERE setting_key='fxloss_accno_id')|;

    my ( $fxgain_accno_id, $fxloss_accno_id ) = $dbh->selectrow_array($query);

    my ($buysell);

    if ( $form->{vc} eq 'customer' ) {
        $buysell = "buy";
    }
    else {
        $buysell = "sell";
    }

    my $ml;
    my $where;

    if ( $form->{ARAP} eq 'AR' ) {

        $ml    = 1;
        $where = qq| (c.link = 'AR' OR c.link LIKE 'AR:%') |;

    }
    else {

        $ml = -1;
        $where =
          qq| (c.link = 'AP' OR c.link LIKE '%:AP' OR c.link LIKE '%:AP:%') |;

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
    for my $i ( 1 .. $form->{rowcount} ) {

        $ath->execute( $form->{"id_$i"} );
        ( $form->{ $form->{ARAP} } ) = $ath->fetchrow_array;
        $ath->finish;

        $form->{"paid_$i"} =
          $form->parse_amount( $myconfig, $form->{"paid_$i"} );
        $form->{"due_$i"} = $form->parse_amount( $myconfig, $form->{"due_$i"} );

        if ( $form->{"$form->{vc}_id_$i"} ne $sameid ) {

            # record a AR/AP with a payment
            if ( $overpayment > 0 && $form->{ $form->{ARAP} } ) {
                $form->{invnumber} = "";
                OP::overpayment( "", $myconfig, $form, $dbh, $overpayment, $ml,
                    1 );
            }

            $overpayment = 0;
            $form->{"$form->{vc}_id"} = $form->{"$form->{vc}_id_$i"};
            for (qw(source memo)) { $form->{$_} = $form->{"${_}_$i"} }
        }

        if ( $form->{"checked_$i"} && $form->{"paid_$i"} ) {

            $overpayment += ( $form->{"paid_$i"} - $form->{"due_$i"} );

            # get exchangerate for original
            $query = qq|
				SELECT $buysell AS fx
				  FROM exchangerate e
				  JOIN $form->{arap} a 
				       ON (a.transdate = e.transdate)
				 WHERE e.curr = ?
				       AND a.id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{currency}, $form->{"id_$i"} )
              || $form->dberror( $query, 'CP.pm', 671 );
            my $ref = $sth->fetchrow_arrayref();
            $form->db_parse_numeric(sth => $sth, arrayref => $ref);
            my ($exchangerate) = @$ref;

            $exchangerate ||= 1;

            $query = qq|
				SELECT c.id
				  FROM chart c
				  JOIN acc_trans a ON (a.chart_id = c.id)
				 WHERE $where
				       AND a.trans_id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{"id_$i"} );
            ($id) = $sth->fetchrow_array();

            $paid =
              ( $form->{"paid_$i"} > $form->{"due_$i"} )
              ? $form->{"due_$i"}
              : $form->{"paid_$i"};
            $amount = $form->round_amount( $paid * $exchangerate, 2 );

            # add AR/AP
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, transdate, 
				            amount)
				     VALUES (?, ?, ?, ?)|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{"id_$i"}, $id, $form->{datepaid},
                $amount * $ml )
              || $form->dberror( $query, 'CP.pm', 701 );

            $query = qq|SELECT id
						  FROM chart
						 WHERE accno = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute($paymentaccno);
            ($accno_id) = $sth->fetchrow_array;

            # add payment
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, transdate,
				            amount, source, memo)
				    VALUES (?, ?, ?, ?, ?, ?)|;

            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{"id_$i"}, $accno_id,       $form->{datepaid},
                $paid * $ml * -1, $form->{source}, $form->{memo}
            ) || $form->dberror( $query, 'CP.pm', 723 );

            # add exchangerate difference if currency ne defaultcurrency
            $amount =
              $form->round_amount(
                $paid * ( $form->{exchangerate} - 1 ) * $ml * -1, 2 );

            if ($amount) {

                # exchangerate difference
                $query = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, 
					            transdate,
					            amount, source)
					      VALUES (?, ?, ?, ?, ?)|;

                $sth = $dbh->prepare($query);
                $sth->execute(
                    $form->{"id_$i"}, $accno_id, $form->{datepaid},
                    $amount,          $form->{source}
                ) || $form->dberror( $query, 'CP.pm', 748 );

                # gain/loss
                $amount =
                  ( $form->round_amount( $paid * $exchangerate, 2 ) -
                      $form->round_amount( $paid * $form->{exchangerate}, 2 ) )
                  * $ml * -1;

                if ($amount) {
                    $accno_id =
                      ( $amount > 0 )
                      ? $fxgain_accno_id
                      : $fxloss_accno_id;

                    $query = qq|
						INSERT INTO acc_trans 
						            (trans_id, 
						            chart_id, 
						            transdate,
						            amount, 
						            fx_transaction)
						    VALUES (?, ?, ?, ?, '1')|;

                    $sth = $dbh->prepare($query);
                    $sth->execute(
                        $form->{"id_$i"},  $accno_id,
                        $form->{datepaid}, $amount
                    ) || $form->dberror( $query, 'CP.pm', 775 );
                }
            }

            $paid = $form->round_amount( $paid * $exchangerate, 2 );

            $pth->execute( $form->{"id_$i"} ) || $form->dberror($pth->statement);
            ($amount) = $pth->fetchrow_array;
            $pth->finish;

            $amount += $paid;

            # update AR/AP transaction
            $query = qq|
				UPDATE $form->{arap} 
				   SET paid = ?,
				       datepaid = ?
				 WHERE id = ?|;

            $sth = $dbh->prepare($query);
            $sth->execute( $amount, $form->{datepaid}, $form->{"id_$i"} )
              || $form->dberror( $query, 'CP.pm', 796 );

            %audittrail = (
                tablename => $form->{arap},
                reference => $form->{source},
                formname  => $form->{formname},
                action    => 'posted',
                id        => $form->{"id_$i"}
            );

            $form->audittrail( $dbh, "", \%audittrail );

        }

        $sameid = $form->{"$form->{vc}_id_$i"};

    }

    # record a AR/AP with a payment
    if ( $overpayment > 0 && $form->{ $form->{ARAP} } ) {
        $form->{invnumber} = "";
        OP::overpayment( "", $myconfig, $form, $dbh, $overpayment, $ml, 1 );
    }

    my $rc = $dbh->commit;

    $rc;

}

1;

