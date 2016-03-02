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

    # connect to database, turn off AutoCommit
    my $dbh = $form->{dbh};

    my $query;
    my $sth;

    my $id = $dbh->quote( $form->{id} );
    if ($form->{separate_duties}){
        $form->{approved} = '0';
    }
    if ( $form->{id} ) {

        $query = qq|SELECT id FROM gl WHERE id = $id|;
        ( $form->{id} ) = $dbh->selectrow_array($query);

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

        my $uid = localtime;
        $uid .= "$$";

        $query = qq|
        INSERT INTO gl (reference)
             VALUES ('$uid')|;

        $sth = $dbh->prepare($query);
        $sth->execute() || $form->dberror($query);

        $query = qq|
            SELECT id
              FROM gl
             WHERE reference = '$uid'|;

        ( $form->{id} ) = $dbh->selectrow_array($query);
    }

    ( $null, $department_id ) = split /--/, $form->{department};
    $department_id *= 1;

    $form->{reference} ||= $form->{id};

    $query = qq|
        UPDATE gl
           SET reference = | . $dbh->quote( $form->{reference} ) . qq|,
              description = | . $dbh->quote( $form->{description} ) . qq|,
              notes = | . $dbh->quote( $form->{notes} ) . qq|,
              transdate = ?
        WHERE id = ?|;

    if (defined $form->{approved}) {
        my $query = qq| UPDATE gl SET approved = ? WHERE id = ?|;
        $dbh->prepare($query)->execute($form->{approved}, $form->{id})
             || $form->dberror($query);
        if (!$form->{approved} and $form->{batch_id}){
           if (not defined $form->{batch_id}){
               $form->error($locale->text('Batch ID Missing'));
           }
           my $vqh = $dbh->prepare('SELECT * FROM batch__lock_for_update(?)');
           $vqh->execute($form->{batch_id});
           my $bref = $vqh->fetchrow_hashref('NAME_lc');
           # Change the below to die with localization in 1.4
           $form->error('Approved Batch') if $bref->{approved_by};
           $form->error('Locked Batch') if $bref->{locked_by};
           my $query = qq|
            INSERT INTO voucher (batch_id, trans_id, batch_class)
            VALUES (?, ?, (select id FROM batch_class
                                    WHERE class = ?))|;
           my $sth2 = $dbh->prepare($query);
           $sth2->execute($form->{batch_id}, $form->{id}, 'gl') ||
                $form->dberror($query);
       }
    }
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{transdate}, $form->{id} )
      || $form->dberror($query);

    my $amount = 0;
    my $posted = 0;
    my $debit;
    my $credit;

    $b_sth = $dbh->prepare(
            qq|INSERT INTO business_unit_ac (entry_id, class_id, bu_id) | .
            qq|VALUES (currval('acc_trans_entry_id_seq'), ?, ?)|
    );
    # insert acc_trans transactions
    for $i ( 0 .. $form->{rowcount} ) {

        $debit  = $form->parse_amount( $myconfig, $form->{"debit_$i"} );
        $credit = $form->parse_amount( $myconfig, $form->{"credit_$i"} );

        # extract accno
        ($accno) = split( /--/, $form->{"accno_$i"} );
        if ($credit) {
            $amount = $credit;
            $posted = 0;
        }

        if ($debit) {
            $amount = $debit * -1;
            $posted = 0;
        }

        # add the record
        if ( !$posted ) {

            ( $null, $project_id ) = split /--/, $form->{"projectnumber_$i"};
            $project_id ||= undef;
            $query = qq|SELECT count(*) from account where accno = ?|;
            $sth = $dbh->prepare($query);
            $sth->execute($accno);
            my ($count) = $sth->fetchrow_array();
            if ($count == 0){
                 $form->error($locale->text('Account [_1] not found', $accno));
            }

            $query = qq|
                INSERT INTO acc_trans
                            (trans_id, chart_id, amount,
                            transdate, source,
                            fx_transaction, memo, cleared)
                    VALUES  (?, (SELECT id
                                   FROM account
                                  WHERE accno = ? ),
                           ?, ?, ?, ?, ?, ?)|;
            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{id},                  $accno,
                $amount,                      $form->{transdate},
                $form->{"source_$i"},
                ($form->{"fx_transaction_$i"} || 0), $form->{"memo_$i"},
                ($form->{"cleared_$i"} || 0)
            ) || $form->dberror($query);
            for my $cls(@{$form->{bu_class}}){
                if ($form->{"b_unit_$cls->{id}_$i"}){
                    $b_sth->execute($cls->{id},
                                     $form->{"b_unit_$cls->{id}_$i"});
                }
            }
            $posted = 1;
        }
    }

    $form->save_recurring( $dbh, $myconfig );
}

sub transaction {

    my ( $self, $myconfig, $form ) = @_;

    my ( $query, $sth, $ref );

    # connect to database
    my $dbh = $form->{dbh};

    if ( $form->{id} ) {

        $query = "SELECT setting_key, value
                    FROM defaults
                    WHERE setting_key IN
                        ('closedto',
                        'revtrans',
                        'separate_duties')";

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        my $results = $sth->fetchall_hashref('setting_key');
        $form->{closedto} = $results->{'closedto'}->{'value'};
        $form->{revtrans} = $results->{'revtrans'}->{'value'};
        #$form->{separate_duties} = $results->{'separate_duties'}->{'value'};
        $sth->finish;

        $query = qq|SELECT g.*
                      FROM gl g
                     WHERE g.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        # retrieve individual rows
        $query = qq|SELECT ac.*, c.accno, c.description
                      FROM acc_trans ac
                      JOIN chart c ON (ac.chart_id = c.id and c.charttype = 'A')
                     WHERE ac.trans_id = ?
                  ORDER BY ac.entry_id|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        my $bu_sth = $dbh->prepare(
            qq|SELECT * FROM business_unit_ac
                WHERE entry_id = ?  |
        );

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $bu_sth->execute($ref->{entry_id});
            while ($buref = $bu_sth->fetchrow_hashref(NAME_lc) ) {
                 $ref->{"b_unit_$buref->{class_id}"} = $buref->{bu_id};
            }

            if ( $ref->{fx_transaction} ) {
                $form->{transfer} = 1;
            }
            push @{ $form->{GL} }, $ref;
        }
        # get recurring transaction
        $form->get_recurring($dbh);

    }
    else {

        $query = "SELECT current_date AS transdate, setting_key, value
                    FROM defaults
                    WHERE setting_key IN
                        ('closedto',
                        'separate_duties',
                        'revtrans')";

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        my $results = $sth->fetchall_hashref('setting_key');
        $form->{separate_duties} = $results->{'separate_duties'}->{'value'};
        $form->{closedto}  = $results->{'closedto'}->{'value'};
        $form->{revtrans}  = $results->{'revtrans'}->{'value'};
        if (!$form->{transdate}){
            $form->{transdate} = $results->{'revtrans'}->{'transdate'};
        }
    }

    $sth->finish;

    # get chart of accounts
    $query = qq|SELECT id,accno,description
                  FROM account
              ORDER BY accno|;

    $sth = $dbh->prepare($query);
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

   # connect to database
   my $dbh = $form->{dbh};

    $query = qq|SELECT id,accno,description
                  FROM account
              ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
    $ref->{accstyle}=$ref->{accno}."--".$ref->{description};
        push @{ $form->{all_accno} }, $ref;
    }

    $sth->finish;


    # get projects
    $form->all_business_units( $form->{transdate} );

}



1;
