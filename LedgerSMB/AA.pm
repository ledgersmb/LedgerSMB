=pod

=head1 NAME

LedgerSMB::AA - Contains the routines for managing AR and AP transactions.

=head1 SYNPOSIS

This module contains the routines for managing AR and AP transactions and 
many of the reorts (a few others are found in LedgerSMB::RP.pm).

All routines require $form->{dbh} to be set so that database actions can
be performed.

This module is due to be deprecated for active development as soon as a 
replacement is available.

=cut

#=====================================================================
#
# AR/AP backend routines
# common routines
#
#======================================================================



package AA;
use LedgerSMB::Sysconfig;
use Log::Log4perl;
use LedgerSMB::File;
use Math::BigFloat;

my $logger = Log::Log4perl->get_logger("AA");

=pod

=over

=item post_transaction()
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
    $form->all_business_units;

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
        #tshvr HV parse first or problem at aa.pl create_links $form->{"${akey}_$form->{acc_trans}{$key}->[$i-1]->{accno}"}=$form->{acc_trans}{$key}->[ $i - 1 ]->{amount} * $ml; 123,45 * -1  gives 123 !!
        $form->{"tax_$accno"}=$form->parse_amount($myconfig,$form->{"tax_$accno"});
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

	    # The following line used to be
	    # $amount{amount}{$i} =  $form->round_amount( $amount - $diff, 2 );
	    # but that causes problems when processing the payments
	    # due to the fact that the payments are un-rounded
            $amount{amount}{$i} = $amount;
            $diff = $amount{amount}{$i} - ( $amount - $diff );

            ( $null, $project_id ) = split /--/, $form->{"projectnumber_$i"};
            $project_id ||= undef;
            ($accno) = split /--/, $form->{"${ARAP}_amount_$i"};

            if ($keepcleared) {
                $cleared = ( $form->{"cleared_$i"} ) ? 1 : 0;
            }

            push @{ $form->{acc_trans}{lineitems} },
              {
                row_num        => $i,
                accno          => $accno,
                amount         => $amount{fxamount}{$i},
                project_id     => $project_id,
                description    => $form->{"description_$i"},
                taxformcheck   => $form->{"taxformcheck_$i"},
                cleared        => $cleared,
                fx_transaction => 0
              };

            if ( $form->{currency} ne $form->{defaultcurrency} ) {
                $amount = $amount{amount}{$i} - $amount{fxamount}{$i};
                push @{ $form->{acc_trans}{lineitems} },
                  {
                    row_num        => $i,
                    accno          => $accno,
                    amount         => $amount,
                    project_id     => $project_id,
                    description    => $form->{"description_$i"},
                    taxformcheck   => $form->{"taxformcheck_$i"},
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
#   These lines are commented out because payments get posted without
#   rounding. Having rounded amounts on the AR/AP creation side leads
#   to unmatched payments
#    $fxinvamount = $form->round_amount( $fxinvamount, 2 );
#    $invamount   = $form->round_amount( $invamount,   2 );
#    $paid        = $form->round_amount( $paid,        2 );

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
        my ($exists) = $dbh->selectrow_array($query);
        if ($exists and $form->{batch_id}) {
           $query = "SELECT voucher__delete(id) 
                       FROM voucher 
                      where trans_id = ? and batch_class in (1, 2)";
           $dbh->prepare($query)->execute($form->{id}) || $form->dberror($query);           
        } elsif ($exists) {

           # delete detail records

	    $dbh->do($query) || $form->dberror($query);
            $query = qq|
				DELETE FROM ac_tax_form
                                       WHERE entry_id IN 
                                             (SELECT entry_id FROM acc_trans
				              WHERE trans_id = $id)|;

            $dbh->do($query) || $form->dberror($query);

            $query = qq|
				DELETE FROM acc_trans
				 WHERE trans_id = $id|;

            $dbh->do($query) || $form->dberror($query);
            $dbh->do("DELETE FROM $table where id = $id");
        }

    }

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
			     VALUES (?,    (select  u.entity_id from users u
                 join entity e on(e.id = u.entity_id)
                 where u.username=? and u.entity_id in(select p.entity_id from person p) ), ?)|;

        # the second param is undef, as the DBI api expects a hashref of
        # attributes to pass to $dbh->prepare. This is not used here.
        # ~A
        
    $dbh->do($query,undef,$uid,$form->{login}, $form->{"$form->{vc}_id"}) || $form->dberror($query);

    $query = qq|
			SELECT id FROM $table
			 WHERE invnumber = ?|;

    ( $form->{id} ) = $dbh->selectrow_array($query,undef,$uid);

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
			intnotes = ?,
			ponumber = ?,
                        reverse = ?
		WHERE id = ?
	|;
    
    my @queryargs = (
        $form->{invnumber},     $form->{ordnumber},
        $form->{transdate},     
        $form->{taxincluded},   $invamount,
        $form->{duedate},       $paid,
        $datepaid,              $invnetamount,
        $form->{currency},      $form->{notes},
        $form->{intnotes},
        $form->{ponumber},      $form->{reverse},
        $form->{id}
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

    my $taxformfound=AA->taxform_exist($form,$form->{"$form->{vc}_id"});


    my $b_unit_sth = $dbh->prepare(
         "INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
          VALUES (currval('acc_trans_entry_id_seq'), ?, ?)"
    );

    foreach $ref ( @{ $form->{acc_trans}{lineitems} } ) {
        # insert detail records in acc_trans
        if ( $ref->{amount} ) {
            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, amount, 
				            transdate, memo, 
				            fx_transaction, cleared)
				    VALUES  (?, (SELECT id FROM chart
				                  WHERE accno = ?), 
				            ?, ?, ?, ?, ?)|;

            @queryargs = (
                $form->{id},            $ref->{accno},
                $ref->{amount} * $ml,   $form->{transdate},
                $ref->{description},
                $ref->{fx_transaction}, $ref->{cleared}
            );
           $dbh->prepare($query)->execute(@queryargs)
              || $form->dberror($query);
           if ($ref->{row_num} and !$ref->{fx_transaction}){
              my $i = $ref->{row_num};
              for my $cls(@{$form->{bu_class}}){
                  if ($form->{"b_unit_$cls->{id}_$i"}){
                     $b_unit_sth->execute($cls->{id}, $form->{"b_unit_$cls->{id}_$i"});
                  }
              }
           }

           if($taxformfound)
           {
            $query="select max(entry_id) from acc_trans;";
            my $sth1=$dbh->prepare($query);
            $sth1->execute();
            my $entry_id=$sth1->fetchrow()  || $form->dberror($query);
            my $report=($taxformfound and $ref->{taxformcheck})?"true":"false";
            AA->update_ac_tax_form($form,$dbh,$entry_id,$report);
           }
           else
           {
            $logger->debug("skipping ac_tax_form because no tax_form");
           }
        }
    }#foreach

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

    #$form->audittrail( $dbh, "", \%audittrail );

    $form->save_recurring( $dbh, $myconfig );

    my $rc = $dbh->commit;

    $rc;

}

=item get_files

Returns a list of files associated with the existing transaction.  This is 
provisional, and will change for 1.4 as the GL transaction functionality is 
                  {ref_key => $self->{id}, file_class => 1}
rewritten

=cut

sub get_files {
     my ($self, $form, $locale) = @_;
     return if !$form->{id};
     my $file = LedgerSMB::File->new();
     $file->new_dbobject({base => $form, locale => $locale});
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 1});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 1}
     );

}

=item delete_transaction(\%myconfig, $form)

Deletes a transaction identified by $form->{id}, whether it is an ar or ap
transaction is identified by $form->{vc}.  $form->{invnumber} used for the 
audittrail routine.

=cut

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
    my $query = qq|DELETE FROM ac_tax_form WHERE entry_id IN
                   (SELECT entry_id FROM acc_trans WHERE trans_id = ?)|;
    $dbh->prepare($query)->execute($form->{id}) || $form->dberror($query);

    $query = qq|DELETE FROM $table WHERE id = ?|;
    $dbh->prepare($query)->execute($form->{id}) || $form->dberror($query);

    $query = qq|DELETE FROM acc_trans WHERE trans_id = ?|;
    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);

    # get spool files
    $query = qq|SELECT spoolfile 
				  FROM status
				 WHERE trans_id = ?
				   AND spoolfile IS NOT NULL|;

    $logger->debug("query: $query");
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

=item transactions(\%myconfig, $form)

Generates the transaction and outstanding reports.  Form variables used in this
function are:

approved: whether or not transactions must be approved to show up

transdatefrom: Earliest day of transactions

transdateto:  Latest day of transactions

month, year, interval:  Used in palce of transdatefrom and transdate to

vc:  'customer' for ar, 'vendor' for ap.

meta_number:  customer/vendor number

entity_id:  A specific entity id

parts_id:  Show transactions including a specific part

department_id:  Transactions for a department

entity_credit_account: As an alternate for meta_number to identify a customer
of vendor credit account

invoice_type:  3 for on-hold, 2 for active

The transaction list is stored at:
@{$form->{transactions}}

=cut

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

    #print STDERR localtime()." AA.pm transactions \$approved=$approved\n";

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
        if ( $form->{transdateto} ) {
            $paid .= qq|
			       AND ac.transdate <= ?|;
       #     push @paidargs, $form->{transdateto};
        }
    }

    if ( !$form->{summary} and !$form->{outstanding} ) {
        $acc_trans_flds = qq|
			, c.accno, ac.source,
			p.projectnumber, ac.memo AS description,
			ac.amount AS linetotal,
			i.description AS linedescription|;
        $group_by_fields = qq|, c.accno, ac.source, p.projectnumber, ac.memo,
                              ac.amount, i.description |;

        $acc_trans_join = qq| 
			     JOIN acc_trans ac ON (a.id = ac.trans_id)
			     JOIN chart c ON (c.id = ac.chart_id 
                                              AND charttype = 'A')
			LEFT JOIN invoice i ON (i.id = ac.invoice_id)|;
    }
    #print STDERR localtime()." AA.pm transactions summary=$form->{summary} outstanding=$form->{outstanding} group_by_fields=$group_by_fields\n";
    my $query;
    if ($form->{outstanding}){
        # $form->{ARAP} is safe since it is set in calling scripts and not passed from the UA
        my $p = $LedgerSMB::Sysconfig::decimal_places;
        if ($form->{transdateto} eq ''){
            delete $form->{transdateto};
        }
        if ($form->{summary}){
            $query = qq|
		   SELECT count(a.id) as invnumber, min(a.transdate) as transdate,
		          min(a.duedate) as duedate, 
		          sum(a.netamount) as netamount, 
		          sum(a.amount::numeric(20,$p)) as amount, 
		          sum(a.amount::numeric(20,$p)) 
                             - (sum(acs.amount::numeric(20,$p)) 
                                * CASE WHEN '$table' = 'ar' THEN -1 ELSE 1 END)
                          AS paid,
		          vce.name, vc.meta_number,
		          a.entity_credit_account, 
		          d.description AS department
		     FROM $table a
		     JOIN entity_credit_account vc ON (a.entity_credit_account = vc.id)
		     JOIN acc_trans acs ON (acs.trans_id = a.id)
		     JOIN entity vce ON (vc.entity_id = vce.id)
		     JOIN chart c ON (acs.chart_id = c.id 
                                     AND charttype = 'A')
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
		          vc.meta_number, a.entity_credit_account, vce.name, 
                          d.description --,
		          --a.ponumber, a.invoice 
		   HAVING abs(sum(acs.amount::numeric(20,2))) > 0.000 |;
        } else {
            #HV typo error a.ponumber $acc_trans_fields -> a.ponumber $acc_trans_flds
            $query = qq|
		   SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
		          a.duedate, a.netamount, a.amount::numeric(20,$p), 
		          a.amount::numeric(20,$p)
                             - (sum(acs.amount::numeric(20,$p)) 
                                * CASE WHEN '$table' = 'ar' THEN -1 ELSE 1 END)
                          AS paid,
		          a.invoice, a.datepaid, a.terms, a.notes,
		          a.shipvia, a.shippingpoint, 
		          vce.name, vc.meta_number,
		          a.entity_credit_account, a.till, 
		          ex.$buysell AS exchangerate, 
		          d.description AS department, 
		          as_array(p.projectnumber) as ac_projects,
		          a.ponumber $acc_trans_flds
		     FROM $table a
		     JOIN entity_credit_account vc ON (a.entity_credit_account = vc.id)
		     JOIN acc_trans acs ON (acs.trans_id = a.id)
		     JOIN entity vce ON (vc.entity_id = vce.id)
		     JOIN chart c ON (acs.chart_id = c.id
                                      AND charttype='A')
		LEFT JOIN exchangerate ex ON (ex.curr = a.curr
		          AND ex.transdate = a.transdate)
		LEFT JOIN department d ON (a.department_id = d.id)
                LEFT JOIN project p ON acs.project_id = p.id 
		$acc_trans_join
		    WHERE c.link = '$ARAP' AND 
		          (|.$dbh->quote($form->{transdateto}) . qq| IS NULL OR 
		           |.$dbh->quote($form->{transdateto}) . qq| >= acs.transdate)
			AND a.approved IS TRUE AND acs.approved IS TRUE
			AND a.force_closed IS NOT TRUE
		 GROUP BY a.id, a.invnumber, a.ordnumber, a.transdate, a.duedate, a.netamount,
		          a.amount, a.terms, a.notes, a.shipvia, a.shippingpoint, vce.name,
		          vc.meta_number, a.entity_credit_account, a.till, ex.$buysell, d.description, vce.name,
		          a.ponumber, a.invoice, a.datepaid $acc_trans_flds
		   HAVING abs(sum(acs.amount::numeric(20,$p))) > 0 |;
       } 
    } else {
        # XXX MUST BE PORTED TO NEW BUSINESS UNIT FRAMEWORK
        $query = qq|
		   SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
		          a.duedate, a.netamount, a.amount, 
                          (a.amount - pd.due) AS paid,
		          a.invoice, a.datepaid, a.terms, a.notes,
		          a.shipvia, a.shippingpoint, ee.name AS employee, 
		          vce.name, vc.meta_number,
		          vc.entity_id, a.till, me.name AS manager, a.curr,
		          ex.$buysell AS exchangerate, 
		          d.description AS department, 
		          a.ponumber, as_array(p.projectnumber) as ac_projects,
                          as_array(ip.projectnumber) as inv_projects
                          $acc_trans_flds
		     FROM $table a
		     JOIN entity_credit_account vc ON (a.entity_credit_account = vc.id)
                     JOIN acc_trans ac ON (a.id = ac.trans_id)
                     JOIN chart c ON (c.id = ac.chart_id)
                     JOIN (SELECT acc_trans.trans_id,
                                sum(CASE WHEN '$table' = 'ap' THEN amount
                                         WHEN '$table' = 'ar'
                                         THEN amount * -1
                                    END) AS due
                           FROM acc_trans
                           JOIN account coa ON (coa.id = acc_trans.chart_id)
                           JOIN account_link al ON (al.account_id = coa.id)
                          WHERE ((al.description = 'AP' AND '$table' = 'ap')
                                OR (al.description = 'AR' AND '$table' = 'ar'))
                          AND (approved IS TRUE)
                       GROUP BY acc_trans.trans_id) pd ON (a.id = pd.trans_id)
		LEFT JOIN entity_employee e ON (a.person_id = e.entity_id)
		LEFT JOIN entity_employee m ON (e.manager_id = m.entity_id)
		LEFT JOIN entity ee ON (e.entity_id = ee.id)
                LEFT JOIN entity me ON (m.entity_id = me.id)
		     JOIN entity vce ON (vc.entity_id = vce.id)
		LEFT JOIN exchangerate ex ON (ex.curr = a.curr
		          AND ex.transdate = a.transdate)
		LEFT JOIN department d ON (a.department_id = d.id) 
                LEFT JOIN invoice i ON (i.trans_id = a.id)
                LEFT JOIN project ip ON (i.project_id = ip.id)
                LEFT JOIN project p ON ac.project_id = p.id |;
        $group_by = qq| 
                GROUP BY  a.id, a.invnumber, a.ordnumber, a.transdate,
                          a.duedate, a.netamount, a.amount,
                          a.invoice, a.datepaid, a.terms, a.notes,
                          a.shipvia, a.shippingpoint, ee.name , 
                          vce.name, vc.meta_number, a.amount, pd.due,
                          vc.entity_id, a.till, me.name, a.curr,
                          ex.$buysell, a.ponumber,
                          d.description $group_by_fields|;
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

    my @a = qw( transdate invnumber name );
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

    for (qw(department_id entity_credit_account)) {
        if ( $form->{$_} ) {
            ( $null, $var ) = split /--/, $form->{$_};
            $var = $dbh->quote($var);
            $where .= " AND a.$_ = $var";
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
            $where .= " AND pd.due <> 0" if ( $form->{open} );
            $where .= " AND pd.due = 0"  if ( $form->{closed} );
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
			               JOIN chart c ON (c.id = ac.chart_id AND charttype = 'A')
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
                   $group_by
			ORDER BY $sortorder";
    }
    #print STDERR localtime()." AA.pm transactions query=$query\n";
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

        #print STDERR localtime()." AA.pm transactions row=".Data::Dumper::Dumper($ref)."\n";
        push @{ $form->{transactions} }, $ref;
    }

    $sth->finish;
    $dbh->commit;
}

# this is used in IS, IR to retrieve the name

=item get_name(\%myconfig, $form)

Retrieves the last account used.  Also retrieves tax accounts,
departments, and a few other things.

Form variables used:
vc: customer or vendor
${vc}_id:  id of vendor/customemr
transdate:  Transaction date desired

Sets the following form variables
currency
exchangerate
forex
taxaccounts


=cut

sub get_name {

    my ( $self, $myconfig, $form ) = @_;

    # sanitize $form->{vc}
    if ( $form->{vc} ne 'customer' ) {
        $form->{vc} = 'vendor';
    }
    else {
        $form->{vc} = 'customer';
    }

    # grab the db connection
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
		          b.description AS business, 
			  entity.control_code as entity_control_code,
			  c.meta_number
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
    my ($credit_rem) = $sth->fetchrow_array;
    ( $form->{creditremaining} ) -= Math::BigFloat->new($credit_rem);

    $sth->finish;
    if ( $form->{vc} ne "customer" ) {
        $form->{vc} = 'vendor';
    }

    $query = qq|
		SELECT o.amount, (SELECT e.$buysell FROM exchangerate e
		                   WHERE e.curr = o.curr
		                         AND e.transdate = o.transdate)
		  FROM oe o
		 WHERE o.entity_id = ?
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
			  FROM new_shipto
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
		  FROM account c
		  JOIN eca_tax ct ON (ct.chart_id = c.id)
		 WHERE ct.eca_id = ?|;

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
    #$logger->trace("\$form->{taxaccounts}=$form->{taxaccounts}");

    $sth->finish;
    chop $form->{taxaccounts};

    # setup last accounts used for this customer/vendor

   if ( !$form->{id} && $form->{type} !~ /_(order|quotation)/ ) {

         $query = qq|
			   SELECT c.accno, c.description, c.link, 
                                  c.category,
			          pbu.bu_id AS project_id,
			          dbu.bu_id AS department_id
			     FROM chart c
			     JOIN acc_trans ac ON (ac.chart_id = c.id)
			     JOIN $arap a ON (a.id = ac.trans_id)
                        LEFT JOIN business_unit_ac pbu 
                                  ON (ac.entry_id = pbu.entry_id 
                                     AND pbu.class_id = 2)
                        LEFT JOIN business_unit_ac dbu
                                  ON (ac.entry_id = dbu.entry_id
                                      AND dbu.class_id = 1)
			    WHERE c.charttype = 'A' AND a.entity_credit_account = ?
			          AND a.id = (SELECT max(id) 
			                         FROM $arap
			                        WHERE entity_credit_account = 
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

=item taxform_exist($form, $cv_id)

Determines if a taxform attached to the entity_credit_account record (where
the id field is the same as $cv_id) exists. Returns true if it exists, false
if not.

=cut



sub taxform_exist
{

   my ( $self,$form,$cv_id) = @_;

   my $query = "select taxform_id from entity_credit_account where id=?";

   my $sth = $form->{dbh}->prepare($query);

   $sth->execute($cv_id) || $form->dberror($query);

   my $retval=0;

   while(my $val=$sth->fetchrow())
   {
        $retval=1;
   }
   
   return $retval;


}

=item update_ac_tax_form($form,$dbh,$entry_id,$report)

Updates the ac_tax_form checkbox for the acc_trans.entry_id (where it is the 
same as $entry_id).  If $report is true, sets it to true, if false, sets it to
false.  $report must be a valid *postgresql* bool value (0/1, t/f, 
'true'/'false').

=cut

sub update_ac_tax_form
{

   my ( $self,$form,$dbh,$entry_id,$report) = @_;

   my $query=qq|select count(*) from ac_tax_form where entry_id=?|;
   my $sth=$dbh->prepare($query);
   $sth->execute($entry_id) ||  $form->dberror($query);
   
   my $found=0;

   while(my $ret1=$sth->fetchrow())
   {
      $found=1;  

   }

   if($found)
   {
	  my $query = qq|update ac_tax_form set reportable=? where entry_id=?|;
          my $sth = $dbh->prepare($query);
          $sth->execute($report,$entry_id) || $form->dberror($query);
   }
  else
   {
          my $query = qq|insert into ac_tax_form(entry_id,reportable) values(?,?)|;
          my $sth = $dbh->prepare($query);
          $sth->execute($entry_id,$report) || $form->dberror("Sada $query");
   }

   $dbh->commit();


}

=item get_taxchech($entry_id,$dbh)

Returns true if the acc_trans record has been set to reportable in the past
false otherwise.

=cut

sub get_taxcheck
{

   my ( $self,$entry_id,$dbh) = @_;

   my $query=qq|select reportable from ac_tax_form where entry_id=?|;
   my $sth=$dbh->prepare($query);
   $sth->execute($entry_id) ||  $form->dberror($query);
   
   my $found=0;

   while(my $ret1=$sth->fetchrow())
   {

      if($ret1 eq "t" || $ret1)   # this if is not required because when reportable is false, control would not come inside while itself.
      { $found=1;  }

   }

   return($found);

}

=item save_intnotes($form)

Saves the $form->{intnotes} into the ar/ap.intnotes field.

=cut

sub save_intnotes {
    my ($self,$form) = @_;
    my $table;
    if ($form->{arap} eq 'ar') {
        $table = 'ar';
    } elsif ($form->{arap} eq 'ap') {
        $table = 'ap';
    } else {
        $form->error('Bad arap in save_intnotes');
    }
    my $sth = $form->{dbh}->prepare("UPDATE $table SET intnotes = ? " .
                                      "where id = ?");
    $sth->execute($form->{intnotes}, $form->{id});
    $form->{dbh}->commit;
}

=back

=head1 COPTYRIGHT

# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# Copyright (C) 2006-2010
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

=cut

1;
