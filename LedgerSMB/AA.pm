#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
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
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# AR/AP backend routines
# common routines
#
#======================================================================



package AA;
use LedgerSMB::Sysconfig;

=pod

=head1 post_transaction()
Post transaction uses the following variables in the $form variable:
 * dbh - the database connection handle
 * currency - The current users' currency
 * defaultcurrency - The "normal" currency
 * department - Unknown
 * department_id - ID for the department
 * exchangerate - Conversion between currency and defaultcurrency
 * invnumber - invoice number
 * reverse - ?
 * rowcount - Number of rows in the invoice
 * taxaccounts - Apply taxes?
 * taxincluded - ?
 * transdate - Date of the transaction
 * vc - Vendor or customer - determines transaction type

=cut

sub post_transaction {
	use strict;

    my ( $self, $myconfig, $form ) = @_;

    my $exchangerate;
    my $batch_class;
    my %paid;
    my $paidamount;
    my @queries;
    if ($form->{separate_duties}){
        $form->{approved} = '0';
    }
    for (1 .. $form->{rowcount}){
        $form->{"amount_$_"} = $form->parse_amount(
               $myconfig, $form->{"amount_$_"} 
         );
        $form->{"amount_$_"} *= -1 if $form->{reverse};
    }

    # connect to database
    my $dbh = $form->{dbh};

    my $query;
    my $sth;

    my $null;
    ( $null, $form->{department_id} ) = split( /--/, $form->{department} );
    $form->{department_id} *= 1;

    my $ml        = 1;
    my $table     = 'ar';
    my $buysell   = 'buy';
    my $ARAP      = 'AR';
    my $invnumber = "sinumber";
    my $keepcleared;

    if ( $form->{vc} eq 'vendor' ) {
        $table     = 'ap';
        $buysell   = 'sell';
        $ARAP      = 'AP';
        $ml        = -1;
        $invnumber = "vinumber";
    }
    $form->{invnumber} = $form->update_defaults( $myconfig, $invnumber )
      unless $form->{invnumber};

    if ( $form->{currency} eq $form->{defaultcurrency} ) {
        $form->{exchangerate} = 1;
    }
    else {
        $exchangerate =
          $form->check_exchangerate( $myconfig, $form->{currency},
            $form->{transdate}, $buysell );

        $form->{exchangerate} =
          ($exchangerate)
          ? $exchangerate
          : $form->parse_amount( $myconfig, $form->{exchangerate} );
    }

    my @taxaccounts = split / /, $form->{taxaccounts};
    my $tax         = 0;
    my $fxtax       = 0;
    my $amount;
    my $diff;

    my %tax = ();
    my $accno;
    # add taxes
    foreach $accno (@taxaccounts) {
        $form->{"tax_$accno"} *= -1 if $form->{reverse};
        $fxtax += $tax{fxamount}{$accno} = $form->{"tax_$accno"};
        $tax += $tax{fxamount}{$accno};

        push @{ $form->{acc_trans}{taxes} },
          {
            accno          => $accno,
            amount         => $tax{fxamount}{$accno},
            project_id     => undef,
            fx_transaction => 0
          };

        $amount = $tax{fxamount}{$accno} * $form->{exchangerate};
        $tax{amount}{$accno} = $form->round_amount( $amount - $diff, 2 );
        $diff = $tax{amount}{$accno} - ( $amount - $diff );
        $amount = $tax{amount}{$accno} - $tax{fxamount}{$accno};
        $tax += $amount;

        if ( $form->{currency} ne $form->{defaultcurrency} ) {
            push @{ $form->{acc_trans}{taxes} },
              {
                accno          => $accno,
                amount         => $amount,
                project_id     => undef,
                fx_transaction => 1
              };
        }

    }

    my %amount      = ();
    my $fxinvamount = 0;
    for ( 1 .. $form->{rowcount} ) {
        $fxinvamount += $amount{fxamount}{$_} = $form->{"amount_$_"};
    }

    $form->{taxincluded} *= 1;

    my $i;
    my $project_id;
    my $cleared = 0;

    $diff = 0;

    # deduct tax from amounts if tax included
    for $i ( 1 .. $form->{rowcount} ) {

        if ( $amount{fxamount}{$i} ) {

            if ( $form->{taxincluded} ) {
                $amount =
                  ($fxinvamount)
                  ? $fxtax * $amount{fxamount}{$i} / $fxinvamount
                  : 0;
                $amount{fxamount}{$i} -= $amount;
            }

            # multiply by exchangerate
            $amount = $amount{fxamount}{$i} * $form->{exchangerate};
            $amount{amount}{$i} = $form->round_amount( $amount - $diff, 2 );
            $diff = $amount{amount}{$i} - ( $amount - $diff );

            ( $null, $project_id ) = split /--/, $form->{"projectnumber_$i"};
            $project_id ||= undef;
            ($accno) = split /--/, $form->{"${ARAP}_amount_$i"};

            if ($keepcleared) {
                $cleared = ( $form->{"cleared_$i"} ) ? 1 : 0;
            }

            push @{ $form->{acc_trans}{lineitems} },
              {
                accno          => $accno,
                amount         => $amount{fxamount}{$i},
                project_id     => $project_id,
                description    => $form->{"description_$i"},
                cleared        => $cleared,
                fx_transaction => 0
              };

            if ( $form->{currency} ne $form->{defaultcurrency} ) {
                $amount = $amount{amount}{$i} - $amount{fxamount}{$i};
                push @{ $form->{acc_trans}{lineitems} },
                  {
                    accno          => $accno,
                    amount         => $amount,
                    project_id     => $project_id,
                    description    => $form->{"description_$i"},
                    cleared        => $cleared,
                    fx_transaction => 1
                  };
            }
        }
    }

    my $invnetamount = 0;
    for ( @{ $form->{acc_trans}{lineitems} } ) { $invnetamount += $_->{amount} }
    my $invamount = $invnetamount + $tax;

    # adjust paidaccounts if there is no date in the last row
    $form->{paidaccounts}--
      unless ( $form->{"datepaid_$form->{paidaccounts}"} );

    if ( $form->{vc} ne "customer" ) {
        $form->{vc} = "vendor";
    }

    my $paid = 0;
    my $fxamount;

    $diff = 0;

    # add payments
    for $i ( 1 .. $form->{paidaccounts} ) {
        $form->{"paid_$i"} = $form->parse_amount( 
              $myconfig, $form->{"paid_$i"} 
        );
        $form->{"paid_$i"} *= -1 if $form->{reverse};
        $fxamount = $form->{"paid_$i"};

        if ($fxamount) {
            $paid += $fxamount;

            $paidamount = $fxamount * $form->{exchangerate};

            $amount = $form->round_amount( $paidamount - $diff, 2 );
            $diff = $amount - ( $paidamount - $diff );

            $form->{datepaid} = $form->{"datepaid_$i"};

            $paid{fxamount}{$i} = $fxamount;
            $paid{amount}{$i}   = $amount;
        }
    }

    $fxinvamount += $fxtax unless $form->{taxincluded};
    $fxinvamount = $form->round_amount( $fxinvamount, 2 );
    $invamount   = $form->round_amount( $invamount,   2 );
    $paid        = $form->round_amount( $paid,        2 );

    $paid =
      ( $fxinvamount == $paid )
      ? $invamount
      : $form->round_amount( $paid * $form->{exchangerate}, 2 );

    $query = q|
		SELECT (SELECT value FROM defaults 
		         WHERE setting_key = 'fxgain_accno_id'), 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'fxloss_accno_id')|;

    my ( $fxgain_accno_id, $fxloss_accno_id ) = $dbh->selectrow_array($query);

    ( $null, $form->{employee_id} ) = split /--/, $form->{employee};
    unless ( $form->{employee_id} ) {
        ( $form->{employee}, $form->{employee_id} ) = $form->get_employee($dbh);
    }

    # check if id really exists
    if ( $form->{id} ) {
        my $id = $dbh->quote( $form->{id} );
        $keepcleared = 1;
        $query       = qq|
			SELECT id
			  FROM $table
			 WHERE id = $id|;

        if ( $dbh->selectrow_array($query) ) {

            # delete detail records
            $query = qq|
				DELETE FROM acc_trans
				 WHERE trans_id = $id|;

            $dbh->do($query) || $form->dberror($query);
        }
    }
    else {

        my $uid = localtime;
        $uid .= "$$";
        
        # The query is done like this as the login name maps to the users table
        # which maps to the user conf table, which links to an entity, to which 
        # a person is also attached. This is done in this fashion because we 
        # are using the current username as the "person" inserting the new 
        # AR/AP Transaction.
        # ~A
        $query = qq|
			INSERT INTO $table (invnumber, person_id, 
				entity_credit_account)
			     VALUES (?, (select e.id from person p, entity e, users u
			                 where u.username = ?
			                 AND e.id = u.entity_id
			                 AND p.entity_id = e.id ), ?)|;

        # the second param is undef, as the DBI api expects a hashref of
        # attributes to pass to $dbh->prepare. This is not used here.
        # ~A
        
        $dbh->do($query,undef,$uid,$form->{login}, $form->{"$form->{vc}_id"}) || $form->dberror($query);

        $query = qq|
			SELECT id FROM $table
			 WHERE invnumber = ?|;

        ( $form->{id} ) = $dbh->selectrow_array($query,undef,$uid);
    }

    # record last payment date in ar/ap table
    $form->{datepaid} = $form->{transdate} unless $form->{datepaid};
    my $datepaid = ($paid) ? qq|'$form->{datepaid}'| : undef;


    $query = qq|
		UPDATE $table 
		SET invnumber = ?,
			ordnumber = ?,
			transdate = ?,
			taxincluded = ?,
			amount = ?,
			duedate = ?,
			paid = ?,
			datepaid = ?,
			netamount = ?,
			curr = ?,
			notes = ?,
			department_id = ?,
			ponumber = ?
		WHERE id = ?
	|;
    
    my @queryargs = (
        $form->{invnumber},     $form->{ordnumber},
        $form->{transdate},     
        $form->{taxincluded},   $invamount,
        $form->{duedate},       $paid,
        $datepaid,              $invnetamount,
        $form->{currency},      $form->{notes},
        $form->{department_id},
        $form->{ponumber},      $form->{id}
    );

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
    if (defined $form->{approved}) {

        $query = qq| UPDATE $table SET approved = ? WHERE id = ?|;
        $dbh->prepare($query)->execute($form->{approved}, $form->{id}) ||
            $form->dberror($query);
        if (!$form->{approved} && $form->{batch_id}){
           if ($form->{arap} eq 'ar'){
               $batch_class = 'ar';
           } else {
               $batch_class = 'ap';
           }
           $query = qq| 
		INSERT INTO voucher (batch_id, trans_id, batch_class)
		VALUES (?, ?, (select id from batch_class where class = ?))|;
           $dbh->prepare($query)->execute($form->{batch_id}, $form->{id}, 
                $batch_class) || $form->dberror($query);
        }
        
    }
    @queries = $form->run_custom_queries( $table, 'INSERT' );

    # update exchangerate
    my $buy  = $form->{exchangerate};
    my $sell = 0;
    if ( $form->{vc} eq 'vendor' ) {
        $buy  = 0;
        $sell = $form->{exchangerate};
    }

    if ( ( $form->{currency} ne $form->{defaultcurrency} ) && !$exchangerate ) {
        $form->update_exchangerate( $dbh, $form->{currency}, $form->{transdate},
            $buy, $sell );
    }

    my $ref;

    # add individual transactions
    foreach $ref ( @{ $form->{acc_trans}{lineitems} } ) {
        # insert detail records in acc_trans
        if ( $ref->{amount} ) {
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, amount, 
				            transdate, project_id, memo, 
				            fx_transaction, cleared)
				    VALUES  (?, (SELECT id FROM chart
				                  WHERE accno = ?), 
				            ?, ?, ?, ?, ?, ?)|;

            @queryargs = (
                $form->{id},            $ref->{accno},
                $ref->{amount} * $ml,   $form->{transdate},
                $ref->{project_id},     $ref->{description},
                $ref->{fx_transaction}, $ref->{cleared}
            );
            $dbh->prepare($query)->execute(@queryargs)
              || $form->dberror($query);
        }
    }

    # save taxes
    foreach $ref ( @{ $form->{acc_trans}{taxes} } ) {
        if ( $ref->{amount} ) {
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, amount,
				            transdate, fx_transaction)
				     VALUES (?, (SELECT id FROM chart
					          WHERE accno = ?),
				            ?, ?, ?)|;

            @queryargs = (
                $form->{id}, $ref->{accno}, $ref->{amount} * $ml,
                $form->{transdate}, $ref->{fx_transaction}
            );
            $dbh->prepare($query)->execute(@queryargs)
              || $form->dberror($query);
        }
    }

    my $arap;

    # record ar/ap
    if ( ( $arap = $invamount ) ) {
        ($accno) = split /--/, $form->{$ARAP};

        $query = qq|
			INSERT INTO acc_trans 
			            (trans_id, chart_id, amount, transdate)
			     VALUES (?, (SELECT id FROM chart
			                  WHERE accno = ?), 
			                  ?, ?)|;
        @queryargs =
          ( $form->{id}, $accno, $invamount * -1 * $ml, $form->{transdate} );

        $dbh->prepare($query)->execute(@queryargs)
          || $form->dberror($query);
    }

    # if there is no amount force ar/ap
    if ( $fxinvamount == 0 ) {
        $arap = 1;
    }

    my $exchangerate;

    # add paid transactions
    for $i ( 1 .. $form->{paidaccounts} ) {

        if ( $paid{fxamount}{$i} ) {

            ($accno) = split( /--/, $form->{"${ARAP}_paid_$i"} );
            $form->{"datepaid_$i"} = $form->{transdate}
              unless ( $form->{"datepaid_$i"} );

            $exchangerate = 0;

            if ( $form->{currency} eq $form->{defaultcurrency} ) {
                $form->{"exchangerate_$i"} = 1;
            }
            else {
                $exchangerate =
                  $form->check_exchangerate( $myconfig, $form->{currency},
                    $form->{"datepaid_$i"}, $buysell );

                $form->{"exchangerate_$i"} =
                  ($exchangerate)
                  ? $exchangerate
                  : $form->parse_amount( $myconfig,
                    $form->{"exchangerate_$i"} );
            }

            # if there is no amount
            if ( $fxinvamount == 0 ) {
                $form->{exchangerate} = $form->{"exchangerate_$i"};
            }

            # ar/ap amount
            if ($arap) {
                ($accno) = split /--/, $form->{$ARAP};

                # add ar/ap
                $query = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, 
					            amount,transdate)
					     VALUES (?, (SELECT id FROM chart
					                  WHERE accno = ?),
					            ?, ?)|;

                @queryargs = (
                    $form->{id}, $accno,
                    $paid{amount}{$i} * $ml,
                    $form->{"datepaid_$i"}
                );
                $dbh->prepare($query)->execute(@queryargs)
                  || $form->dberror($query);
            }

            $arap = $paid{amount}{$i};

            # add payment
            if ( $paid{fxamount}{$i} ) {

                ($accno) = split /--/, $form->{"${ARAP}_paid_$i"};

                my $cleared = ( $form->{"cleared_$i"} ) ? 1 : 0;

                $amount = $paid{fxamount}{$i};
                $query  = qq|
					INSERT INTO acc_trans 
					            (trans_id, chart_id, amount,
					            transdate, source, memo, 
					            cleared)
					     VALUES (?, (SELECT id FROM chart
						          WHERE accno = ?),
					            ?, ?, ?, ?, ?)|;

                @queryargs = (
                    $form->{id},          $accno,
                    $amount * -1 * $ml,   $form->{"datepaid_$i"},
                    $form->{"source_$i"}, $form->{"memo_$i"},
                    $cleared
                );
                $dbh->prepare($query)->execute(@queryargs)
                  || $form->dberror($query);

                if ( $form->{currency} ne $form->{defaultcurrency} ) {

                    # exchangerate gain/loss
                    $amount = (
                        $form->round_amount(
                            $paid{fxamount}{$i} * $form->{exchangerate}, 2 ) -
                          $form->round_amount(
                            $paid{fxamount}{$i} * $form->{"exchangerate_$i"}, 2
                          )
                    ) * -1;

                    if ($amount) {

                        my $accno_id =
                          ( ( $amount * $ml ) > 0 )
                          ? $fxgain_accno_id
                          : $fxloss_accno_id;

                        $query = qq|
							INSERT INTO acc_trans 
							            (trans_id, 
							            chart_id, 
							            amount,
							            transdate, 
							            fx_transaction, 
							            cleared)
							     VALUES (?, ?, 
							            ?, 
							            ?, '1', ?)|;

                        @queryargs = (
                            $form->{id}, $accno_id,
                            $amount * $ml,
                            $form->{"datepaid_$i"}, $cleared
                        );
                        $sth = $dbh->prepare($query);
                        $sth->execute(@queryargs)
                          || $form->dberror($query);
                    }

                    # exchangerate difference
                    $amount = $paid{amount}{$i} - $paid{fxamount}{$i} + $amount;

                    $query = qq|
						INSERT INTO acc_trans 
						            (trans_id, chart_id,
						            amount,
						            transdate, 
						            fx_transaction, 
						            cleared, source)
						     VALUES (?, (SELECT id 
						                   FROM chart
						                  WHERE accno 
						                        = ?),
						            ?, ?, 
						            '1', ?, ?)|;

                    @queryargs = (
                        $form->{id}, $accno,
                        $amount * -1 * $ml,
                        $form->{"datepaid_$i"},
                        $cleared, $form->{"source_$i"}
                    );
                    $sth = $dbh->prepare($query);
                    $sth->execute(@queryargs)
                      || $form->dberror($query);

                }

                # update exchangerate record
                $buy  = $form->{"exchangerate_$i"};
                $sell = 0;

                if ( $form->{vc} eq 'vendor' ) {
                    $buy  = 0;
                    $sell = $form->{"exchangerate_$i"};
                }

                if ( ( $form->{currency} ne $form->{defaultcurrency} )
                    && !$exchangerate )
                {

                    $form->update_exchangerate( $dbh, $form->{currency},
                        $form->{"datepaid_$i"},
                        $buy, $sell );
                }
            }
        }
    }

    # save printed and queued
    $form->save_status($dbh);

    my %audittrail = (
        tablename => $table,
        reference => $form->{invnumber},
        formname  => 'transaction',
        action    => 'posted',
        id        => $form->{id}
    );

    $form->audittrail( $dbh, "", \%audittrail );

    $form->save_recurring( $dbh, $myconfig );

    my $rc = $dbh->commit;

    $rc;

}

sub delete_transaction {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database, turn AutoCommit off
    my $dbh = $form->{dbh};

    my $table = ( $form->{vc} eq 'customer' ) ? 'ar' : 'ap';

    my %audittrail = (
        tablename => $table,
        reference => $form->{invnumber},
        formname  => 'transaction',
        action    => 'deleted',
        id        => $form->{id}
    );

    $form->audittrail( $dbh, "", \%audittrail );

    my $query = qq|DELETE FROM $table WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|DELETE FROM acc_trans WHERE trans_id = ?|;
    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);

    # get spool files
    $query = qq|SELECT spoolfile 
				  FROM status
				 WHERE trans_id = ?
				   AND spoolfile IS NOT NULL|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $spoolfile;
    my @spoolfiles = ();

    while ( ($spoolfile) = $sth->fetchrow_array ) {
        push @spoolfiles, $spoolfile;
    }

    $sth->finish;

    $query = qq|DELETE FROM status WHERE trans_id = ?|;
    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);

    # commit
    my $rc = $dbh->commit;

    if ($rc) {
        foreach $spoolfile (@spoolfiles) {
            unlink "${LedgerSMB::Sysconfig::spool}/$spoolfile" if $spoolfile;
        }
    }

    $rc;
}

# This is going to get a little awkward because it involves delving into the 
# acc_trans table in order to avoid catching unapproved payment vouchers.
sub transactions {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $null;
    my $var;
    my $paid    = "a.paid";
    my $ml      = 1;
    my $ARAP    = 'AR';
    my $table   = 'ar';
    my $buysell = 'buy';
    my $acc_trans_join;
    my $acc_trans_flds;
    my $approved = ($form->{approved}) ? 'TRUE' : 'FALSE';

    if ( $form->{vc} eq 'vendor' ) {
        $ml      = -1;
        $ARAP    = 'AP';
        $table   = 'ap';
        $buysell = 'sell';
    }
    $form->{db_dateformat} = $myconfig->{dateformat};

    ( $form->{transdatefrom}, $form->{transdateto} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if (($form->{year} && $form->{month}) && 
          (!$form->{transdatefrom} && !$form->{transdateto}));

    my @paidargs = ();
    if ( $form->{outstanding} ) {
        $paid = qq|
			SELECT SUM(ac.amount) * -1 * $ml
			  FROM acc_trans ac
			  JOIN chart c ON (c.id = ac.chart_id)
			 WHERE ac.trans_id = a.id
			       AND ($approved OR ac.approved)
			       AND (c.link LIKE '%${ARAP}_paid%' 
			       OR c.link = '')|;
        if ( $form->{transdateto} ) {
            $paid .= qq|
			       AND ac.transdate <= ?|;
       #     push @paidargs, $form->{transdateto};
        }
    }

    if ( !$form->{summary} and !$form->{outstanding} ) {
        $acc_trans_flds = qq|
			, c.accno, ac.source,
			pr.projectnumber, ac.memo AS description,
			ac.amount AS linetotal,
			i.description AS linedescription|;

        $acc_trans_join = qq| 
			     JOIN acc_trans ac ON (a.id = ac.trans_id)
			     JOIN chart c ON (c.id = ac.chart_id)
			LEFT JOIN project pr ON (pr.id = ac.project_id)
			LEFT JOIN invoice i ON (i.id = ac.invoice_id)|;
    }
    my $query;
    if ($form->{outstanding}){
        # $form->{ARAP} is safe since it is set in calling scripts and not passed from the UA
        if ($form->{transdateto} eq ''){
            delete $form->{transdateto};
        }
        if ($form->{summary}){
            $query = qq|
		   SELECT count(a.id) as invnumber, min(a.transdate) as transdate,
		          min(a.duedate) as duedate, 
		          sum(a.netamount) as netamount, 
		          sum(a.amount) as amount, 
		          sum(a.amount) - sum(acs.amount) AS paid,
		          vce.name, vc.meta_number,
		          a.entity_id, 
		          d.description AS department, 
		          a.ponumber
		     FROM $table a
		     JOIN entity_credit_account vc ON (a.entity_credit_account = vc.id)
		     JOIN acc_trans acs ON (acs.trans_id = a.id)
		     JOIN entity vce ON (vc.entity_id = vce.id)
		     JOIN chart c ON (acs.chart_id = c.id)
		LEFT JOIN exchangerate ex ON (ex.curr = a.curr
		          AND ex.transdate = a.transdate)
		LEFT JOIN department d ON (a.department_id = d.id)
		$acc_trans_join
		    WHERE c.link = '$form->{ARAP}' AND 
		          (|.$dbh->quote($form->{transdateto}) . qq| IS NULL OR 
		           |.$dbh->quote($form->{transdateto}) . qq| >= acs.transdate)
			AND a.approved IS TRUE AND acs.approved IS TRUE
			AND a.force_closed IS NOT TRUE
		 GROUP BY 
		          vc.meta_number, a.entity_id, vce.name, d.description,
		          a.ponumber, a.invoice, a.datepaid 
		   HAVING abs(sum(a.amount) - (sum(a.amount) - sum(acs.amount))) > 0.005 |;
        } else {
            $query = qq|
		   SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
		          a.duedate, a.netamount, a.amount, a.amount - sum(acs.amount) AS paid,
		          a.invoice, a.datepaid, a.terms, a.notes,
		          a.shipvia, a.shippingpoint, 
		          vce.name, vc.meta_number,
		          a.entity_id, a.till, 
		          ex.$buysell AS exchangerate, 
		          d.description AS department, 
		          a.ponumber $acc_trans_fields
		     FROM $table a
		     JOIN entity_credit_account vc ON (a.entity_credit_account = vc.id)
		     JOIN acc_trans acs ON (acs.trans_id = a.id)
		     JOIN entity vce ON (vc.entity_id = vce.id)
		     JOIN chart c ON (acs.chart_id = c.id)
		LEFT JOIN exchangerate ex ON (ex.curr = a.curr
		          AND ex.transdate = a.transdate)
		LEFT JOIN department d ON (a.department_id = d.id)
		$acc_trans_join
		    WHERE c.link = '$form->{ARAP}' AND 
		          (|.$dbh->quote($form->{transdateto}) . qq| IS NULL OR 
		           |.$dbh->quote($form->{transdateto}) . qq| >= acs.transdate)
			AND a.approved IS TRUE AND acs.approved IS TRUE
			AND a.force_closed IS NOT TRUE
		 GROUP BY a.id, a.invnumber, a.ordnumber, a.transdate, a.duedate, a.netamount,
		          a.amount, a.terms, a.notes, a.shipvia, a.shippingpoint, vce.name,
		          vc.meta_number, a.entity_id, a.till, ex.$buysell, d.description, vce.name,
		          a.ponumber, a.invoice, a.datepaid $acc_trans_fields
		   HAVING abs(a.amount - (a.amount - sum(acs.amount))) > 0.005 |;
       } 
    } else {
        $query = qq|
		   SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
		          a.duedate, a.netamount, a.amount, ($paid) AS paid,
		          a.invoice, a.datepaid, a.terms, a.notes,
		          a.shipvia, a.shippingpoint, ee.name AS employee, 
		          vce.name, vc.meta_number,
		          vc.entity_id, a.till, me.name AS manager, a.curr,
		          ex.$buysell AS exchangerate, 
		          d.description AS department, 
		          a.ponumber $acc_trans_flds
		     FROM $table a
		     JOIN entity_credit_account vc ON (a.entity_credit_account = vc.id)
		LEFT JOIN employee e ON (a.person_id = e.entity_id)
		LEFT JOIN employee m ON (e.manager_id = m.entity_id)
		LEFT JOIN entity ee ON (e.entity_id = ee.id)
                LEFT JOIN entity me ON (m.entity_id = me.id)
		     JOIN entity vce ON (vc.entity_id = vce.id)
		LEFT JOIN exchangerate ex ON (ex.curr = a.curr
		          AND ex.transdate = a.transdate)
		LEFT JOIN department d ON (a.department_id = d.id) 
		$acc_trans_join|;
    }

    my %ordinal = (
        id            => 1,
        invnumber     => 2,
        ordnumber     => 3,
        transdate     => 4,
        duedate       => 5,
        datepaid      => 10,
        shipvia       => 13,
        shippingpoint => 14,
        employee      => 15,
        name          => 16,
        manager       => 20,
        curr          => 21,
        department    => 23,
        ponumber      => 24,
        accno         => 25,
        source        => 26,
        project       => 27,
        description   => 28
    );

    my @a = ( transdate, invnumber, name );
    push @a, "employee" if $form->{l_employee};
    push @a, "manager"  if $form->{l_manager};
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $where = "";
    if (!$form->{outstanding}){
        $where = "1 = 1";
    }
    if ($form->{"meta_number"}){
        $where .= " AND vc.meta_number = " . $dbh->quote($form->{meta_number});
    }
    if ( $form->{"$form->{vc}_id"} ) {
        $form->{entity_id} = $form->{$form->{vc}."_id"};
        $where .= qq| AND a.entity_id = $form->{entity_id}|;
    }
    else {
        if ( $form->{ $form->{vc} } ) {
            $var = $dbh->quote( $form->like( lc $form->{ $form->{vc} } ) );
            $where .= " AND lower(vce.name) LIKE $var";
        }
    }

    for (qw(department employee)) {
        if ( $form->{$_} ) {
            ( $null, $var ) = split /--/, $form->{$_};
            $var = $dbh->quote($var);
            $where .= " AND a.${_}_id = $var";
        }
    }

    for (qw(invnumber ordnumber)) {
        if ( $form->{$_} ) {
            $var = $dbh->quote( $form->like( lc $form->{$_} ) );
            $where .= " AND lower(a.$_) LIKE $var";
            $form->{open} = $form->{closed} = 0;
        }
    }
    if ( $form->{partsid} ) {
        my $partsid = $dbh->quote( $form->{partsid} );
        $where .= " AND a.id IN (select trans_id FROM invoice
			WHERE parts_id = $partsid)";
    }

    for (qw(ponumber shipvia notes)) {
        if ( $form->{$_} ) {
            $var = $dbh->quote( $form->like( lc $form->{$_} ) );
            $where .= " AND lower(a.$_) LIKE $var";
        }
    }

    if ( $form->{description} ) {
        if ($acc_trans_flds) {
            $var = $dbh->quote( $form->like( lc $form->{description} ) );
            $where .= " AND lower(ac.memo) LIKE $var
			OR lower(i.description) LIKE $var";
        }
        else {
            $where .= " AND a.id = 0";
        }
    }

    if ( $form->{source} ) {
        if ($acc_trans_flds) {
            $var = $dbh->quote( $form->like( lc $form->{source} ) );
            $where .= " AND lower(ac.source) LIKE $var";
        }
        else {
            $where .= " AND a.id = 0";
        }
    }

    my $transdatefrom = $dbh->quote( $form->{transdatefrom} );
    $where .= " AND a.transdate >= $transdatefrom"
      if $form->{transdatefrom};

    my $transdateto = $dbh->quote( $form->{transdateto} );
    $where .= " AND a.transdate <= $transdateto" if $form->{transdateto};

    if ( $form->{open} || $form->{closed} ) {
        unless ( $form->{open} && $form->{closed} ) {
            $where .= " AND a.amount != a.paid" if ( $form->{open} );
            $where .= " AND a.amount = a.paid"  if ( $form->{closed} );
        }
    }

    if ( $form->{till} ne "" ) {
	$form->{till} = $dbh->quote($form->{till});
        $where .= " AND a.invoice = '1'
					AND a.till = $form->{till}";

        if ( $myconfig->{role} eq 'user' ) {
            my $login = $dbh->quote( $form->{login} );
            $where .= " AND e.entity_id = (select entity_id from users where username = $login";
        }
    }

    if ( $form->{$ARAP} ) {
        my ($accno) = split /--/, $form->{$ARAP};
        $accno = $dbh->quote($accno);
        $where .= qq|
			AND a.id IN (SELECT ac.trans_id
			               FROM acc_trans ac
			               JOIN chart c ON (c.id = ac.chart_id)
			              WHERE a.id = ac.trans_id
			                    AND c.accno = $accno)|;
    }

    if ( $form->{description} ) {
        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $where .= qq|
			AND (a.id IN (SELECT DISTINCT trans_id
			                FROM acc_trans
			               WHERE lower(memo) LIKE $var)
			                     OR a.id IN 
			                     (SELECT DISTINCT trans_id
			                                 FROM invoice
			                                WHERE lower(description)
			                                      LIKE $var))|;
    }
    
    if ($form->{invoice_type}) {
        
        if ( $form->{invoice_type} == 2 ) {
        
            $where .= qq|
                AND a.on_hold = 'f'        
            |;
        }
    
        if ($form->{invoice_type} == 3) {
        
            $where .= qq|
                AND a.on_hold = 't'
            |;
        }
    }
    
    # the third state, all invoices, sets no explicit toggles. It just selects them all, as normal. 
    # $approved is safe as it is set to either "TRUE" or "FALSE"
    if ($form->{outstanding}){
        if ($where ne ""){
            $query =~ s/GROUP BY / $where \n GROUP BY /;
        }
	if ($form->{summary}){
		$sortorder = "vc.meta_number";
	}
        $query .= "\n ORDER BY $sortorder";
    } else {
        $query .= "WHERE ($approved OR a.approved) AND $where
			ORDER BY $sortorder";
    }

    my $sth = $dbh->prepare($query);
    $sth->execute(@paidargs) || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
	$form->db_parse_numeric(sth => $sth, hashref => $ref);
        $ref->{exchangerate} = 1 unless $ref->{exchangerate};

        if ( $ref->{linetotal} <= 0 ) {
            $ref->{debit}  = $ref->{linetotal} * -1;
            $ref->{credit} = 0;
        }
        else {
            $ref->{debit}  = 0;
            $ref->{credit} = $ref->{linetotal};
        }

        if ( $ref->{invoice} ) {
            $ref->{description} ||= $ref->{linedescription};
        }

        push @{ $form->{transactions} }, $ref;
    }

    $sth->finish;
    $dbh->commit;
}

# this is used in IS, IR to retrieve the name
sub get_name {

    my ( $self, $myconfig, $form ) = @_;

    # sanitize $form->{vc}
    if ( $form->{vc} ne 'customer' ) {
        $form->{vc} = 'vendor';
    }
    else {
        $form->{vc} = 'customer';
    }

    # connect to database
    my $dbh = $form->{dbh};

    my $dateformat = $myconfig->{dateformat};

    if ( $myconfig->{dateformat} !~ /^y/ ) {
        my @a = split /\W/, $form->{transdate};
        $dateformat .= "yy" if ( length $a[2] > 2 );
    }

    if ( $form->{transdate} !~ /\W/ ) {
        $dateformat = 'yyyymmdd';
    }

    my $duedate;

    $dateformat = $dbh->quote($dateformat);
    my $tdate = $dbh->quote( $form->{transdate} );
    $duedate = ( $form->{transdate} )
      ? "to_date($tdate, $dateformat) 
			+ c.terms"
      : "current_date + c.terms";

    $form->{"$form->{vc}_id"} *= 1;

    # get customer/vendor
    my $query = qq|
		   SELECT entity.name AS $form->{vc}, c.discount, 
		          c.creditlimit, 
		          c.terms, c.taxincluded,
		          c.curr AS currency, 
		          c.language_code, $duedate AS duedate, 
			  b.discount AS tradediscount, 
		          b.description AS business
		     FROM entity_credit_account c
		     JOIN entity ON (entity.id = c.entity_id)
		LEFT JOIN business b ON (b.id = c.business_id)
		    WHERE c.id = ?|;
    # TODO:  Add location join

    @queryargs = ( $form->{"$form->{vc}_id"} );
    my $sth = $dbh->prepare($query);

    $sth->execute(@queryargs) || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    $form->db_parse_numeric(sth => $sth, hashref => $ref);
    if ( $form->{id} ) {
        for (qw(currency employee employee_id intnotes)) {
            delete $ref->{$_};
        }
    }

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # TODO:  Retrieve contact records

    my $buysell = ( $form->{vc} eq 'customer' ) ? "buy" : "sell";

    # if no currency use defaultcurrency
    $form->{currency} =
      ( $form->{currency} )
      ? $form->{currency}
      : $form->{defaultcurrency};
    $form->{exchangerate} = 0
      if $form->{currency} eq $form->{defaultcurrency};

    if ( $form->{transdate}
        && ( $form->{currency} ne $form->{defaultcurrency} ) )
    {
        $form->{exchangerate} =
          $form->get_exchangerate( $dbh, $form->{currency}, $form->{transdate},
            $buysell );
    }

    $form->{forex} = $form->{exchangerate};

    # if no employee, default to login
    ( $form->{employee}, $form->{employee_id} ) = $form->get_employee($dbh)
      unless $form->{employee_id};

    my $arap = ( $form->{vc} eq 'customer' ) ? 'ar' : 'ap';
    my $ARAP = uc $arap;

    $form->{creditremaining} = $form->{creditlimit};
    $query = qq|
		SELECT SUM(amount - paid)
		  FROM $arap
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{"$form->{vc}_id"} )
      || $form->dberror($query);

    ( $form->{creditremaining} ) -= $sth->fetchrow_array;

    $sth->finish;
    if ( $form->{vc} ne "customer" ) {
        $form->{vc} = 'vendor';
    }

    $query = qq|
		SELECT o.amount, (SELECT e.$buysell FROM exchangerate e
		                   WHERE e.curr = o.curr
		                         AND e.transdate = o.transdate)
		  FROM oe o
		 WHERE o.entity_id = 
		       (select entity_id from $form->{vc} WHERE id = ?)
		       AND o.quotation = '0' AND o.closed = '0'|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{"$form->{vc}_id"} ) || $form->dberror($query);

    while ( my @ref = $sth->fetchrow_array ) {
        $form->db_parse_numeric(sth => $sth, arrayref => \@ref);
        my ($amount, $exch) = @ref;
        $exch = 1 unless $exch;
        $form->{creditremaining} -= $amount * $exch;
    }

    $sth->finish;

    # get shipto if we did not converted an order or invoice
    if ( !$form->{shipto} ) {

        for (
            qw(shiptoname shiptoaddress1 shiptoaddress2
            shiptocity shiptostate shiptozipcode
            shiptocountry shiptocontact shiptophone
            shiptofax shiptoemail)
          )
        {
            delete $form->{$_};
        }

        ## needs fixing (SELECT *)
        $query = qq|
			SELECT * 
			  FROM shipto
			 WHERE trans_id = $form->{"$form->{vc}_id"}|;

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;
    }

    # get taxes
    $query = qq|
		SELECT c.accno
		  FROM chart c
		  JOIN $form->{vc}tax ct ON (ct.chart_id = c.id)
		 WHERE ct.$form->{vc}_id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{"$form->{vc}_id"} ) || $form->dberror($query);

    my %tax;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $tax{ $ref->{accno} } = 1;
    }

    $sth->finish;
    $transdate = $dbh->quote( $form->{transdate} );
    my $where = qq|AND (t.validto >= $transdate OR t.validto IS NULL)|
      if $form->{transdate};

    # get tax rates and description
    $query = qq|
		   SELECT c.accno, c.description, t.rate, t.taxnumber
		     FROM chart c
		     JOIN tax t ON (c.id = t.chart_id)
		    WHERE c.link LIKE '%${ARAP}_tax%'
		          $where
		 ORDER BY accno, validto|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $form->{taxaccounts} = "";
    my %a = ();

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth => $sth, hashref => $hashref);

        if ( $tax{ $ref->{accno} } ) {
            if ( not exists $a{ $ref->{accno} } ) {
                for (qw(rate description taxnumber)) {
                    $form->{"$ref->{accno}_$_"} = $ref->{$_};
                }
                $form->{taxaccounts} .= "$ref->{accno} ";
                $a{ $ref->{accno} } = 1;
            }
        }
    }

    $sth->finish;
    chop $form->{taxaccounts};

    # setup last accounts used for this customer/vendor
    if ( !$form->{id} && $form->{type} !~ /_(order|quotation)/ ) {

        $query = qq|
			   SELECT c.accno, c.description, c.link, 
                                  c.category,
			          ac.project_id,
			          a.department_id
			     FROM chart c
			     JOIN acc_trans ac ON (ac.chart_id = c.id)
			     JOIN $arap a ON (a.id = ac.trans_id)
			    WHERE a.entity_id = ?
			          AND a.id = (SELECT max(id) 
			                         FROM $arap
			                        WHERE entity_id = 
			                              ?)
			|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{"$form->{vc}_id"}, $form->{"$form->{vc}_id"} )
          || $form->dberror($query);

        my $i = 0;

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $form->{department_id} = $ref->{department_id};
            if ( $ref->{link} =~ /_amount/ ) {
                $i++;
                $form->{"$form->{ARAP}_amount_$i"} =
                  "$ref->{accno}--$ref->{description}"
                  if $ref->{accno};
                $form->{"projectnumber_$i"} =
                  "$ref->{projectnumber}--" . "$ref->{project_id}"
                  if $ref->{project_id};
            }

            if ( $ref->{link} eq $form->{ARAP} ) {
                $form->{ $form->{ARAP} } = $form->{"$form->{ARAP}_1"} =
                  "$ref->{accno}--" . "$ref->{description}"
                  if $ref->{accno};
            }
        }

        $sth->finish;
        $query = "select description from department where id = ?";
        $sth = $dbh->prepare($query);
        $sth->execute($form->{department_id});
        ($form->{department}) = $sth->fetchrow_array;
        $form->{rowcount} = $i if ( $i && !$form->{type} );
    }

    $dbh->commit;
}

1;
