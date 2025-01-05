=head1 NAME

LedgerSMB:GL - General Ledger backend code

=cut

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
# Copyright (C) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# General ledger backend code
#
#======================================================================

package GL;

use LedgerSMB::File;

=over

=item get_files

Returns a list of files associated with the existing transaction.  This is
provisional, and wil change for 1.4 as the GL transaction functionality is
                  {ref_key => $self->{id}, file_class => 1}
rewritten

=back

=cut

sub get_files {
     my ($self, $form, $locale) = @_;
     my $file = LedgerSMB::File->new();
     @{$form->{files}} = $file->list({ref_key => $form->{id}, file_class => 1});
     @{$form->{file_links}} = $file->list_links(
                  {ref_key => $form->{id}, file_class => 1}
     );

}

sub post_transaction {

    my ( $self, $myconfig, $form, $locale) = @_;
    $form->all_business_units;
    $form->{reference} = $form->update_defaults( $myconfig, 'glnumber', $dbh )
      if $form->should_update_defaults('reference');
    my $null;
    my $project_id;
    my $department_id;
    my $i;

    my $dbh = $form->{dbh};

    my $query;
    my $sth;

    my $id = $dbh->quote( $form->{id} );
    $form->{approved} = '0';
    if ( $form->{id} ) {

        $query = qq|SELECT id FROM gl WHERE id = $id|;
        ( $form->{id} ) = $dbh->selectrow_array($query);
        die $dbh->errstr if $dbh->err;

        if ( $form->{id} ) {

            # delete individual transactions
            $query = qq|
            DELETE FROM acc_trans WHERE trans_id = $id|;

            $dbh->do($query) || $form->dberror($query);
            $query = qq|
            DELETE FROM voucher WHERE trans_id = $id
                                            and batch_class = 5|;

            $dbh->do($query) || $form->dberror($query);
        }
    }

    if ( !$form->{id} ) {

        $query = qq|
      INSERT INTO gl (reference, description, notes, transdate)
           VALUES (?, ?, ?, ?)
      RETURNING id|;

        $sth = $dbh->prepare($query) || $form->dberror($query);
        $sth->execute($form->{reference}, $form->{description},
                      $form->{notes}, $form->{transdate})
            || $form->dberror($query);

        ( $form->{id} ) = $sth->fetchrow_array();
        $query = q|UPDATE transactions SET workflow_id = ?, reversing = ? WHERE id = ? AND workflow_id IS NULL|;
        $sth   = $dbh->prepare($query);
        $form->{reversing} ||= undef; # convert empty string to NULL
        $sth->execute( $form->{workflow_id}, $form->{reversing}, $form->{id} )
            || $form->dberror($query);
    }

    ( $null, $department_id ) =
        split( /--/, $form->{department}) if $form->{department};
    ($department_id //= 0) *= 1;

    if (! $form->{reference} ) {
        $form->{reference} = $form->{id};
        $dbh->do(qq|
UPDATE gl
   SET reference = ?
 WHERE id = ?|, {}, $form->{reference}, $form->{id})
            or $form->dberror($dbh->errstr);
    }

    if (defined $form->{approved}) {
        my $query = qq| UPDATE gl SET approved = ? WHERE id = ?|;
        $dbh->prepare($query)->execute($form->{approved}, $form->{id})
             || $form->dberror($query);
        if (!$form->{approved} and $form->{batch_id}){
           if (not defined $form->{batch_id}){
               $form->error($locale->text('Batch ID Missing'));
           }
           my $vqh =
               $dbh->prepare('SELECT * FROM batch__lock_for_update(?)')
               or die $dbh->errstr;
           $vqh->execute($form->{batch_id})
               or die $vqh->errstr;
           my $bref = $vqh->fetchrow_hashref('NAME_lc');
           # Change the below to die with localization in 1.4
           $form->error('Approved Batch') if $bref->{approved_by};
           $form->error('Locked Batch') if $bref->{locked_by};
           my $query = qq|
         INSERT INTO voucher (batch_id, trans_id, batch_class)
         VALUES (?, ?, (select id FROM batch_class
                                 WHERE class = ?))|;
           my $sth2 = $dbh->prepare($query)
               or $form->dberror($query);
           $sth2->execute($form->{batch_id}, $form->{id}, 'gl') ||
                $form->dberror($query);
       }
    }

    my $amount = 0;
    my $posted = 0;
    my $debit;
    my $credit;

    $b_sth = $dbh->prepare(qq|
            INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
            VALUES (currval('acc_trans_entry_id_seq'), ?, ?)|
        ) or $form->dberror($dbh->errstr);
    my $s_sth = $dbh->prepare( qq|
            SELECT count(*) from account where accno = ?|
        ) or $form->dberror($dbh->errstr);
    my $l_sth = $dbh->prepare( qq|
            INSERT INTO acc_trans
                        (trans_id, chart_id, amount_bc, curr, amount_tc,
                         transdate, source,
                         memo, cleared)
                VALUES  (?, (SELECT id
                               FROM account
                              WHERE accno = ? ),
                       ?, ?, ?, ?, ?, ?, ?)|
        ) or $form->dberror($dbh->errstr);

    # insert acc_trans transactions
    foreach my $i ( 0 .. $form->{rowcount} ) {

        $debit  = $form->parse_amount( $myconfig, $form->{"debit_$i"} );
        $credit = $form->parse_amount( $myconfig, $form->{"credit_$i"} );
        $debit_fx  =
            (not $form->{fx_transaction}) ? $debit :
            $form->parse_amount( $myconfig, $form->{"debit_fx_$i"} );
        $credit_fx =
            (not $form->{fx_transaction}) ? $credit :
            $form->parse_amount( $myconfig, $form->{"credit_fx_$i"} );


        # extract accno
        ($accno) = split( /--/, $form->{"accno_$i"} );

        $form->error($locale->text("Can't post credits and debits on one line."))
            if ($debit && $credit);

        if ($credit) {
            $amount = $credit;
            $amount_fx = $credit_fx;
            $posted = 0;
        }

        if ($debit) {
            $amount = $debit * -1;
            $amount_fx = $debit_fx * -1;
            $posted = 0;
        }

        # add the record
        if ( !$posted ) {

            ( $null, $project_id ) =
                split( /--/, $form->{"projectnumber_$i"})
                if $form->{"projectnumber_$i"};
            $project_id ||= undef;
            $s_sth->execute($accno)
                or $form->dberror($s_sth->errstr);
            my ($count) = $s_sth->fetchrow_array()
                or $form->dberror($s_sth->errstr);
            if ($count == 0){
                 $form->error($locale->text('Account [_1] not found',
                                            $accno));
            }

            $l_sth->execute(
                $form->{id},                  $accno,
                $amount,                      $form->{"curr_$i"},
                $amount_fx,                   $form->{transdate},
                $form->{"source_$i"},
                $form->{"memo_$i"},
                ($form->{"cleared_$i"} || 0)
                ) or $form->dberror($l_sth->errstr);
            for my $cls(@{$form->{bu_class}}){
                if ($form->{"b_unit_$cls->{id}_$i"}){
                    $b_sth->execute($cls->{id},
                                    $form->{"b_unit_$cls->{id}_$i"})
                        or $form->dberror($b_sth->errstr);
                }
            }
            $posted = 1;
        }
    }

    $form->save_recurring( $dbh, $myconfig );

    return 1;
}

sub save_notes {
    my ( $self, $myconfig, $form ) = @_;

    my $query = 'UPDATE gl SET notes = ? where id = ?';
    $form->{dbh}->do( $query, {}, $form->{notes}, $form->{id} );
    $form->dberror( $query ) if $form->{dbh}->err;
}

sub transaction {

    my ( $self, $myconfig, $form ) = @_;

    my ( $query, $sth, $ref );

    my $dbh = $form->{dbh};

    if ( $form->{id} ) {

        @{$form->{currencies}} =
            $form->currencies;

        $query = qq|SELECT g.*, t.workflow_id, t.reversing, t.reversing_reference, t.reversed_by, t.reversed_by_reference
                 FROM gl g JOIN transactions_reversal t on g.id = t.id
                WHERE g.id = ?|;

        $sth = $dbh->prepare($query) || $form->dberror($dbh->errstr);
        $sth->execute( $form->{id} ) || $form->dberror($sth->errstr);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        # retrieve individual rows
        $query = qq|SELECT ac.*, c.accno, c.description
                      FROM acc_trans ac
                      JOIN account c ON (ac.chart_id = c.id)
                     WHERE ac.trans_id = ?
                  ORDER BY ac.entry_id|;

        $sth = $dbh->prepare($query) || $form->dberror($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        my $bu_sth = $dbh->prepare(
            qq|SELECT * FROM business_unit_ac
                WHERE entry_id = ?  |
        ) || die $dbh->errstr;

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $bu_sth->execute($ref->{entry_id})
                or die $bu_sth->errstr;
            while ($buref = $bu_sth->fetchrow_hashref(NAME_lc) ) {
                 $ref->{"b_unit_$buref->{class_id}"} = $buref->{bu_id};
            }
            $form->{fx_transaction} ||=
                ($ref->{curr} ne $form->{currencies}->[0]);
            push @{ $form->{GL} }, $ref;
        }
        # get recurring transaction
        $form->get_recurring($dbh);

    }
    else {
        @{$form->{currencies}} = $form->currencies;
    }

    # get chart of accounts
    $query = qq|SELECT id,accno,description
              FROM account
           ORDER BY accno|;

    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
   $ref->{accstyle}=$ref->{accno}."--".$ref->{description};
        push @{ $form->{all_accno} }, $ref;
    }

    $sth->finish;

    # get projects
    $form->all_business_units( $form->{transdate} );

}


sub get_all_acc_dep_pro
{

   my ( $self, $myconfig, $form ) = @_;

   my ( $query, $sth, $ref );

   my $dbh = $form->{dbh};

    $query = qq|SELECT id,accno,description
              FROM account
           ORDER BY accno|;

    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
   $ref->{accstyle}=$ref->{accno}."--".$ref->{description};
        push @{ $form->{all_accno} }, $ref;
    }

    $sth->finish;


   # get projects
   my $transdate = $form->{transdate};
   $transdate = undef if !$transdate;
    $form->all_business_units( $form->{transdate} );

}



1;
