=pod

=head1 NAME

LedgerSMB::AA - Contains the routines for managing AR and AP transactions.

=head1 SYNOPSIS

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
use LedgerSMB::App_State;
use Log::Log4perl;
use LedgerSMB::File;
use LedgerSMB::PGNumber;
use LedgerSMB::Setting;

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

    $form->{crdate} ||= 'now';

    # connect to database
    my $dbh = $LedgerSMB::App_State::DBH;

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
      if $form->should_update_defaults('invnumber');

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
    my $diff        = 0;

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

    #tshvr4 trunk svn-revison 6589,$form->login seems to contain id instead of name or '',so person_id not found,thus reports with join on person_id not working,quick fix,use employee_name
    #( $null, $form->{employee_id} ) = split /--/, $form->{employee};
    ( $form->{employee_name}, $form->{employee_id} ) = split /--/, $form->{employee};
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

    #tshvr4 trunk svn-revison 6589,$form->login seems to contain id instead of name or '',so person_id not found,thus reports with join on person_id not working,quick fix,use employee_name
    $query = qq|
            INSERT INTO $table (invnumber, person_id,
                entity_credit_account)
                 VALUES (?,    (select  u.entity_id from users u
                 join entity e on(e.id = u.entity_id)
                 where u.username=? and u.entity_id in(select p.entity_id from person p) ), ?)|;

        # the second param is undef, as the DBI api expects a hashref of
        # attributes to pass to $dbh->prepare. This is not used here.
        # ~A

    #$dbh->do($query,undef,$uid,$form->{login}, $form->{"$form->{vc}_id"}) || $form->dberror($query);
    $dbh->do($query,undef,$uid,$form->{employee_name}, $form->{"$form->{vc}_id"}) || $form->dberror($query);

    $query = qq|
            SELECT id FROM $table
             WHERE invnumber = ?|;

    ( $form->{id} ) = $dbh->selectrow_array($query,undef,$uid);

    # record last payment date in ar/ap table
    $form->{datepaid} = $form->{transdate} unless $form->{datepaid};
    my $datepaid = ($paid) ? qq|'$form->{datepaid}'| : undef;

    if (defined $form->{approved}) {

        $query = qq| UPDATE $table SET approved = ? WHERE id = ?|;
        $dbh->prepare($query)->execute($form->{approved}, $form->{id}) ||
            $form->dberror($query);
        if (!$form->{approved} && $form->{batch_id}){
           if ($form->{ARAP} eq 'AR'){
               $batch_class = 'ar';
           } else {
               $batch_class = 'ap';
           }
           my $vqh = $dbh->prepare('SELECT * FROM batch__lock_for_update(?)');
           $vqh->execute($form->{batch_id});
           my $bref = $vqh->fetchrow_hashref('NAME_lc');
           # Change the below to die with localization in 1.4
           $form->error('Approved Batch') if $bref->{approved_by};
           $form->error('Locked Batch') if $bref->{locked_by};
           $query = qq|
        INSERT INTO voucher (batch_id, trans_id, batch_class)
        VALUES (?, ?, (select id from batch_class where class = ?))|;
           $dbh->prepare($query)->execute($form->{batch_id}, $form->{id},
                $batch_class) || $form->dberror($query);
        }

    }
    if ($table eq 'ar' and $form->{setting_sequence}){
       my $seqsth = $dbh->prepare(
            'UPDATE ar SET setting_sequence = ? WHERE id = ?'
       );
       $seqsth->execute($form->{setting_sequence}, $form->{id});
       $seqsth->finish;
    }

    $query = qq|
        UPDATE $table
        SET invnumber = ?,
                    description = ?,
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
            crdate = ?,
                        reverse = ?
        WHERE id = ?
    |;

    $form->{invnumber} = undef if $form->{invnumber} eq '';

    my @queryargs = (
        $form->{invnumber},     $form->{description},
        $form->{ordnumber},     $form->{transdate},
        $form->{taxincluded},   $invamount,
        $form->{duedate},       $paid,
        $datepaid,              $invnetamount,
        $form->{currency},      $form->{notes},
        $form->{intnotes},
        $form->{ponumber},      $form->{crdate},
    $form->{reverse},        $form->{id}
    );
    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
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
                    VALUES  (?, (SELECT id FROM account
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
                     VALUES (?, (SELECT id FROM account
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
                 VALUES (?, (SELECT id FROM account
                              WHERE accno = ?),
                              ?, ?)|;
        @queryargs =
          ( $form->{id}, $accno, $invamount * -1 * $ml / $form->{exchangerate},
            $form->{transdate} );

        $dbh->prepare($query)->execute(@queryargs)
          || $form->dberror($query);
        if ($form->{exchangerate} != 1){
           $dbh->prepare($query)->execute($form->{id}, $accno,
                  ($invamount * -1 * $ml) -
                  ($invamount * -1 * $ml / $form->{exchangerate}),
                  $form->{transdate} );
        }
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
                         VALUES (?, (SELECT id FROM account
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
                         VALUES (?, (SELECT id FROM account
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
                                           FROM account
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
     my $file = LedgerSMB::File->new(%$form);
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 1});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 1}
     );

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

    if ( $form->{transdate} =~ m/\d\d\d\d-\d\d-\d\d/ ) {
        $dateformat = 'yyyy-mm-dd';
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
    my $query = qq/
           SELECT entity.name AS $form->{vc}, c.discount,
                  c.creditlimit,
                  c.terms, c.taxincluded,
                  c.curr AS currency,
                  c.language_code, $duedate AS duedate,
              b.discount AS tradediscount,
                  b.description AS business,
              entity.control_code AS entity_control_code,
                          co.tax_id AS tax_id,
              c.meta_number, ctf.default_reportable,
                          c.cash_account_id, ca.accno as cash_accno,
                          c.id as eca_id,
                          coalesce(ecl.address, el.address) as address,
                          coalesce(ecl.city, el.city) as city
             FROM entity_credit_account c
             JOIN entity ON (entity.id = c.entity_id)
                LEFT JOIN account ca ON c.cash_account_id = ca.id
        LEFT JOIN business b ON (b.id = c.business_id)
                LEFT JOIN country_tax_form ctf ON ctf.id = c.taxform_id
                LEFT JOIN company co ON co.entity_id = c.entity_id
                LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.credit_id
                          FROM eca_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) ecl
                        ON (c.id = ecl.credit_id)
                LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.entity_id
                          FROM entity_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) el
                        ON (c.entity_id = el.entity_id)
            WHERE c.id = ?/;

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
    delete $ref->{duedate} if $form->{duedate};

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # get customer e-mail accounts
    $query = qq|SELECT * FROM eca__list_contacts(?)
                      WHERE class_id BETWEEN 12 AND ?
                      ORDER BY class_id DESC;|;
    my %id_map = ( 12 => 'email',
               13 => 'cc',
               14 => 'bcc',
               15 => 'email',
               16 => 'cc',
               17 => 'bcc' );
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{eca_id}, 17) || $form->dberror( $query );

    my $ctype;
    my $billing_email = 0;

    # Set these variables to empty, otherwise in some cases it keeps earlier values and cause doubled
    # values, ie. when emailing invoice
    $form->{email} = '';
    $form->{cc} = '';
    $form->{bcc} = '';

    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $ctype = $ref->{class_id};
        $ctype = $id_map{$ctype};
        $billing_email = 1
        if $ref->{class_id} == 15;

        # If there's an explicit billing email, don't use
        # the standard email addresses; otherwise fall back to standard
        $form->{$ctype} .= ($form->{$ctype} ? ", " : "") . $ref->{contact}
        if (($ref->{class_id} < 15 && ! $billing_email)
            || $ref->{class_id} >= 15);
    }
    $sth->finish;

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

    if (LedgerSMB::Setting->get('show_creditlimit')){
        $form->{creditremaining} = $form->{creditlimit};
        # acc_trans.approved is only false in the case of batch payments which
        # have not yet been approved.  Unapproved transactions set approved on
        # the ar or ap record level.  --CT
        $query = qq|
                SELECT sum(used) FROM (
        SELECT SUM(ac.amount)
                       * CASE WHEN '$arap' = 'ar' THEN -1 ELSE 1 END as used
          FROM $arap a
                  JOIN acc_trans ac ON a.id = ac.trans_id and ac.approved
                  JOIN account_link al ON al.account_id = ac.chart_id
                                       AND al.description IN ('AR', 'AP')
         WHERE entity_credit_account = ?
                 UNION
                SELECT sum(o.amount * coalesce(e.$buysell, 1)) as used
                  FROM oe o
             LEFT JOIN exchangerate e ON o.transdate = e.transdate
                                      AND o.curr = e.curr
                 WHERE not closed and oe_class_id in (1, 2)
                       and entity_credit_account = ?) s|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{"$form->{vc}_id"}, $form->{"$form->{vc}_id"})
           || $form->dberror($query);
        my ($credit_rem) = $sth->fetchrow_array;
        ( $form->{creditremaining} ) -= LedgerSMB::PGNumber->new($credit_rem);

        $sth->finish;
    }

    # get taxes
    $query = qq|
        SELECT c.accno
          FROM account c
          JOIN eca_tax ct ON (ct.chart_id = c.id)
         WHERE ct.eca_id = ? AND NOT obsolete |;

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
             FROM account c
             JOIN tax t ON (c.id = t.chart_id)
            WHERE true
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
