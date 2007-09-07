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

sub delete_transaction {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my %audittrail = (
        tablename => 'gl',
        reference => $form->{reference},
        formname  => 'transaction',
        action    => 'deleted',
        id        => $form->{id}
    );

    $form->audittrail( $dbh, "", \%audittrail );
    my $id    = $dbh->quote( $form->{id} );
    my $query = qq|DELETE FROM gl WHERE id = $id|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|DELETE FROM acc_trans WHERE trans_id = $id|;
    $dbh->do($query) || $form->dberror($query);

    # commit and redirect
    my $rc = $dbh->commit;

    $rc;
}

sub post_transaction {

    my ( $self, $myconfig, $form ) = @_;
    $form->{reference} = $form->update_defaults( $myconfig, 'glnumber', $dbh )
      unless $form->{reference};

    my $null;
    my $project_id;
    my $department_id;
    my $i;

    # connect to database, turn off AutoCommit
    my $dbh = $form->{dbh};

    my $query;
    my $sth;

    my $id = $dbh->quote( $form->{id} );
    if ( $form->{id} ) {

        $query = qq|SELECT id FROM gl WHERE id = $id|;
        ( $form->{id} ) = $dbh->selectrow_array($query);

        if ( $form->{id} ) {

            # delete individual transactions
            $query = qq|
				DELETE FROM acc_trans WHERE trans_id = $id|;

            $dbh->do($query) || $form->dberror($query);
        }
    }

    if ( !$form->{id} ) {

        my $uid = localtime;
        $uid .= "$$";

        $query = qq|
		INSERT INTO gl (reference, employee_id)
		     VALUES ('$uid', (SELECT id FROM employee
		                       WHERE login = ?))|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{login} ) || $form->dberror($query);

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
		      transdate = ?,
		      department_id = ?
		WHERE id = ?|;

    if (defined $form->{approved}) {

        $query = qq| UPDATE gl SET approved = ? WHERE id = ?|;
        $dbh->prepare($query)->execute($form->{approved}, $form->{id}) 
             || $form->dberror($query);
        if (!$form->{approved}){
           if (not defined $form->{batch_id}){
               $form->error($locale->text('Batch ID Missing'));
           }
           $query = qq| 
			INSERT INTO voucher (batch_id, trans_id) VALUES (?, ?)|;
           $sth = $dbh->prepare($query);
           $sth->execute($form->{batch_id}, $form->{id}) ||
                $form->dberror($query);
       }
    }
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{transdate}, $department_id, $form->{id} )
      || $form->dberror($query);

    my $amount = 0;
    my $posted = 0;
    my $debit;
    my $credit;

    # insert acc_trans transactions
    for $i ( 1 .. $form->{rowcount} ) {

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

            $query = qq|
				INSERT INTO acc_trans 
				            (trans_id, chart_id, amount, 
				            transdate, source, project_id, 
				            fx_transaction, memo, cleared)
				    VALUES  (?, (SELECT id
				                   FROM chart
				                  WHERE accno = ?),
				           ?, ?, ?, ?, ?, ?, ?)|;

            $sth = $dbh->prepare($query);
            $sth->execute(
                $form->{id},                  $accno,
                $amount,                      $form->{transdate},
                $form->{"source_$i"},         $project_id,
                ($form->{"fx_transaction_$i"} || 0), $form->{"memo_$i"},
                ($form->{"cleared_$i"} || 0)
            ) || $form->dberror($query);

            $posted = 1;
        }
    }

    my %audittrail = (
        tablename => 'gl',
        reference => $form->{reference},
        formname  => 'transaction',
        action    => 'posted',
        id        => $form->{id}
    );

    $form->audittrail( $dbh, "", \%audittrail );

    $form->save_recurring( $dbh, $myconfig );

    # commit and redirect
    my $rc = $dbh->commit;

    $rc;
}

sub all_transactions {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $query;
    my $sth;
    my $var;
    my $null;

    my ( $glwhere, $arwhere, $apwhere ) = ( "1 = 1", "1 = 1", "1 = 1" );

    if ( $form->{reference} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{reference} ) );
        $glwhere .= " AND lower(g.reference) LIKE $var";
        $arwhere .= " AND lower(a.invnumber) LIKE $var";
        $apwhere .= " AND lower(a.invnumber) LIKE $var";
    }

    if ( $form->{department} ne "" ) {
        ( $null, $var ) = split /--/, $form->{department};
        $var = $dbh->quote($var);
        $glwhere .= " AND g.department_id = $var";
        $arwhere .= " AND a.department_id = $var";
        $apwhere .= " AND a.department_id = $var";
    }

    if ( $form->{source} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{source} ) );
        $glwhere .= " AND lower(ac.source) LIKE $var";
        $arwhere .= " AND lower(ac.source) LIKE $var";
        $apwhere .= " AND lower(ac.source) LIKE $var";
    }

    if ( $form->{memo} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{memo} ) );
        $glwhere .= " AND lower(ac.memo) LIKE $var";
        $arwhere .= " AND lower(ac.memo) LIKE $var";
        $apwhere .= " AND lower(ac.memo) LIKE $var";
    }

    ( $form->{datefrom}, $form->{dateto} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if $form->{year} && $form->{month};

    if ( $form->{datefrom} ) {
        $glwhere .= " AND ac.transdate >= " . $dbh->quote( $form->{datefrom} );
        $arwhere .= " AND ac.transdate >= " . $dbh->quote( $form->{datefrom} );
        $apwhere .= " AND ac.transdate >= " . $dbh->quote( $form->{datefrom} );
    }

    if ( $form->{dateto} ) {
        $glwhere .= " AND ac.transdate <= " . $dbh->quote( $form->{dateto} );
        $arwhere .= " AND ac.transdate <= " . $dbh->quote( $form->{dateto} );
        $apwhere .= " AND ac.transdate <= " . $dbh->quote( $form->{dateto} );
    }

    if ( $form->{amountfrom} ) {
        $glwhere .=
          " AND abs(ac.amount) >= " . $dbh->quote( $form->{amountfrom} );
        $arwhere .=
          " AND abs(ac.amount) >= " . $dbh->quote( $form->{amountfrom} );
        $apwhere .=
          " AND abs(ac.amount) >= " . $dbh->quote( $form->{amountfrom} );
    }

    if ( $form->{amountto} ) {
        $glwhere .=
          " AND abs(ac.amount) <= " . $dbh->quote( $form->{amountto} );
        $arwhere .=
          " AND abs(ac.amount) <= " . $dbh->quote( $form->{amountto} );
        $apwhere .=
          " AND abs(ac.amount) <= " . $dbh->quote( $form->{amountto} );
    }

    if ( $form->{description} ) {

        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $glwhere .= " AND lower(g.description) LIKE $var";
        $arwhere .= " AND (lower(ct.name) LIKE $var
					   OR lower(ac.memo) LIKE $var
					   OR a.id IN (SELECT DISTINCT trans_id
					 FROM invoice
					WHERE lower(description) LIKE $var))";

        $apwhere .= " AND (lower(ct.name) LIKE $var
					   OR lower(ac.memo) LIKE $var
					   OR a.id IN (SELECT DISTINCT trans_id
					 FROM invoice
					WHERE lower(description) LIKE $var))";
    }

    if ( $form->{notes} ) {
        $var = $dbh->quote( $form->like( lc $form->{notes} ) );
        $glwhere .= " AND lower(g.notes) LIKE $var";
        $arwhere .= " AND lower(a.notes) LIKE $var";
        $apwhere .= " AND lower(a.notes) LIKE $var";
    }

    if ( $form->{accno} ) {
        $var = $dbh->quote( $form->{accno} );
        $glwhere .= " AND c.accno = $var";
        $arwhere .= " AND c.accno = $var";
        $apwhere .= " AND c.accno = $var";
    }

    if ( $form->{gifi_accno} ) {
        $var = $dbh->quote( $form->{gifi_accno} );
        $glwhere .= " AND c.gifi_accno = $var";
        $arwhere .= " AND c.gifi_accno = $var";
        $apwhere .= " AND c.gifi_accno = $var";
    }

    if ( $form->{category} ne 'X' ) {
        $var = $dbh->quote( $form->{category} );
        $glwhere .= " AND c.category = $var";
        $arwhere .= " AND c.category = $var";
        $apwhere .= " AND c.category = $var";
    }

    if ( $form->{accno} ) {
        my $accno = $dbh->quote( $form->{accno} );

        # get category for account
        $query = qq|SELECT category, link, contra, description
					  FROM chart
					 WHERE accno = $accno|;

        (
            $form->{category}, $form->{link}, $form->{contra},
            $form->{account_description}
        ) = $dbh->selectrow_array($query);

        if ( $form->{datefrom} ) {

            $query = qq|
				SELECT SUM(ac.amount)
				  FROM acc_trans ac
				  JOIN chart c ON (ac.chart_id = c.id)
				 WHERE c.accno = $accno
				       AND ac.transdate < date | . $dbh->quote( $form->{datefrom} );

            ( $form->{balance} ) = $dbh->selectrow_array($query);
        }
    }

    if ( $form->{gifi_accno} ) {
        my $gifi = $dbh->quote( $form->{gifi_accno} );

        # get category for account
        $query = qq|SELECT c.category, c.link, c.contra, g.description
					  FROM chart c
				 LEFT JOIN gifi g ON (g.accno = c.gifi_accno)
					 WHERE c.gifi_accno = $gifi|;

        (
            $form->{category}, $form->{link}, $form->{contra},
            $form->{gifi_account_description}
        ) = $dbh->selectrow_array($query);

        if ( $form->{datefrom} ) {

            $query = qq|
				SELECT SUM(ac.amount)
				  FROM acc_trans ac
				  JOIN chart c ON (ac.chart_id = c.id)
				 WHERE c.gifi_accno = $gifi
				       AND ac.transdate < date | . $dbh->quote( $form->{datefrom} );

            ( $form->{balance} ) = $dbh->selectrow_array($query);
        }
    }

    my $false = 'FALSE';

    my %ordinal = (
        id          => 1,
        reference   => 4,
        description => 5,
        transdate   => 6,
        source      => 7,
        accno       => 9,
        department  => 15,
        memo        => 16
    );

    my @a = ( id, transdate, reference, source, description, accno );
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|SELECT g.id, 'gl' AS type, $false AS invoice, g.reference,
						  g.description, ac.transdate, ac.source,
						  ac.amount, c.accno, c.gifi_accno, g.notes, c.link,
						  '' AS till, ac.cleared, d.description AS department,
						  ac.memo, c.description AS accname
					 FROM gl AS g
					 JOIN acc_trans ac ON (g.id = ac.trans_id)
					 JOIN chart c ON (ac.chart_id = c.id)
				LEFT JOIN department d ON (d.id = g.department_id)
					WHERE $glwhere

					UNION ALL

				   SELECT a.id, 'ar' AS type, a.invoice, a.invnumber,
						  e.name, ac.transdate, ac.source,
						  ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
						  a.till, ac.cleared, d.description AS department,
						  ac.memo, c.description AS accname
					 FROM ar a
					 JOIN acc_trans ac ON (a.id = ac.trans_id)
					 JOIN chart c ON (ac.chart_id = c.id)
					 JOIN entity e ON (a.entity_id = e.id)
				LEFT JOIN department d ON (d.id = a.department_id)
					WHERE $arwhere

				UNION ALL

				   SELECT a.id, 'ap' AS type, a.invoice, a.invnumber,
						  e.name, ac.transdate, ac.source,
						  ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
						  a.till, ac.cleared, d.description AS department,
						  ac.memo, c.description AS accname
					 FROM ap a
					 JOIN acc_trans ac ON (a.id = ac.trans_id)
					 JOIN chart c ON (ac.chart_id = c.id)
					 JOIN entity e ON (a.entity_id = e.id)
				LEFT JOIN department d ON (d.id = a.department_id)
					WHERE $apwhere
				 ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {

        # gl
        if ( $ref->{type} eq "gl" ) {
            $ref->{module} = "gl";
        }

        # ap
        if ( $ref->{type} eq "ap" ) {

            if ( $ref->{invoice} ) {
                $ref->{module} = "ir";
            }
            else {
                $ref->{module} = "ap";
            }
        }

        # ar
        if ( $ref->{type} eq "ar" ) {

            if ( $ref->{invoice} ) {
                $ref->{module} = ( $ref->{till} ) ? "ps" : "is";
            }
            else {
                $ref->{module} = "ar";
            }
        }

        if ( $ref->{amount} < 0 ) {
            $ref->{debit}  = $ref->{amount} * -1;
            $ref->{credit} = 0;
        }
        else {
            $ref->{credit} = $ref->{amount};
            $ref->{debit}  = 0;
        }

        push @{ $form->{GL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;
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
						('closedto', 'revtrans')";

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        my $results = $sth->fetchall_hashref('setting_key');
        $form->{closedto} = $results->{'closedto'}->{'value'};
        $form->{revtrans} = $results->{'revtrans'}->{'value'};
        $sth->finish;

        $query = qq|SELECT g.*, d.description AS department
					  FROM gl g
				 LEFT JOIN department d ON (d.id = g.department_id)  
					 WHERE g.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        # retrieve individual rows
        $query = qq|SELECT ac.*, c.accno, c.description, p.projectnumber
					  FROM acc_trans ac
					  JOIN chart c ON (ac.chart_id = c.id)
				 LEFT JOIN project p ON (p.id = ac.project_id)
					 WHERE ac.trans_id = ?
				  ORDER BY accno|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {

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
						('closedto', 'revtrans')";

        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        my $results = $sth->fetchall_hashref('setting_key');
        $form->{closedto}  = $results->{'closedto'}->{'value'};
        $form->{revtrans}  = $results->{'revtrans'}->{'value'};
        $form->{transdate} = $results->{'revtrans'}->{'transdate'};
    }

    $sth->finish;

    # get chart of accounts
    $query = qq|SELECT accno,description
				  FROM chart
				 WHERE charttype = 'A'
			  ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_accno} }, $ref;
    }

    $sth->finish;

    # get departments
    $form->all_departments( $myconfig, $dbh );

    # get projects
    $form->all_projects( $myconfig, $dbh, $form->{transdate} );

    $dbh->commit;

}

1;
