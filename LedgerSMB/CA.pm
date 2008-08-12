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
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# chart of accounts
#
#======================================================================

package CA;

sub all_accounts {

    my ( $self, $myconfig, $form ) = @_;

    my $amount = ();

    # connect to database
    my $dbh = $form->{dbh};

    my $approved = ($form->{approved})? 'TRUE' : 'FALSE';

    my $query = qq|
		   SELECT accno, SUM(acc_trans.amount) AS amount
		     FROM chart
		     JOIN acc_trans ON (chart.id = acc_trans.chart_id)
		     JOIN transactions ON (acc_trans.trans_id = transactions.id)
                     JOIN (SELECT id, approved, 'ap' AS tablename FROM ap 
		          UNION
                         SELECT id, approved, 'ar' as tablename FROM ar
			 UNION 
                         SELECT id, approved, 'gl' as tablename FROM gl
		    ) g ON (g.id = acc_trans.trans_id 
				AND transactions.table_name = g.tablename)
		    WHERE ($approved OR acc_trans.approved)
			  AND (g.approved OR $approved)
		 GROUP BY accno|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        $amount{ $ref->{accno} } = $ref->{amount};
    }

    $sth->finish;

    $query = qq|
		SELECT accno, description
		  FROM gifi|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $gifi = ();

    while ( my ( $accno, $description ) = $sth->fetchrow_array ) {
        $gifi{$accno} = $description;
    }

    $sth->finish;

    $query = qq|
		    SELECT c.id, c.accno, c.description, c.charttype, 
		           c.gifi_accno, c.category, c.link
		      FROM chart c
		  ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ca = $sth->fetchrow_hashref(NAME_lc) ) {
        $ca->{amount}           = $amount{ $ca->{accno} };
        $ca->{gifi_description} = $gifi{ $ca->{gifi_accno} };

        if ( $ca->{amount} < 0 ) {
            $ca->{debit} = $ca->{amount} * -1;
        }
        else {
            $ca->{credit} = $ca->{amount};
        }

        push @{ $form->{CA} }, $ca;
    }

    $sth->finish;
    $dbh->commit;

}

sub all_transactions {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $approved = ($form->{approved})? 'TRUE' : 'FALSE';

    # get chart_id
    my $query = qq|
		SELECT id 
		  FROM chart
		 WHERE accno = ?|;

    my $accno = $form->{accno};

    if ( $form->{accounttype} eq 'gifi' ) {
        $query = qq|
			SELECT id 
			  FROM chart
			 WHERE gifi_accno = ?|;
        $accno = $form->{gifi_accno};
    }

    my $sth = $dbh->prepare($query);
    $sth->execute($accno) || $form->dberror($query);

    my @id = ();

    while ( my ($id) = $sth->fetchrow_array ) {
        push @id, $id;
    }

    $sth->finish;

    my $fromdate_where;
    my $todate_where;
    
    ( $form->{fromdate}, $form->{todate} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if !$form->{fromdate} && !$form->{todate};

    my $fdate;
    if ( $form->{fromdate} ) {
        $fromdate_where = qq| AND ac.transdate >= ? |;
        $fdate          = $form->{fromdate};
    }
    my $tdate;
    if ( $form->{todate} ) {
        $todate_where .= qq| AND ac.transdate <= ? |;
        $tdate = $form->{todate};
    }

    my $false = 'FALSE';

    # Oracle workaround, use ordinal positions
    my %ordinal = (
        transdate   => 4,
        reference   => 2,
        description => 3
    );

    my @a = qw(transdate reference description);
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $null;
    my $department_id;
    my $dpt_where;
    my $dpt_join;
    my $union;

    ( $null, $department_id ) = split /--/, $form->{department};

    my $d_id;
    if ($department_id) {
        $dpt_join  = qq| JOIN department t ON (t.id = a.department_id) |;
        $dpt_where = qq| AND t.id = ? |;
        $d_id      = $department_id;
    }

    my $project;
    my $project_id;
    my $p_id;
    if ( $form->{projectnumber} ) {
        ( $null, $project_id ) = split /--/, $form->{projectnumber};
        $project = qq| AND ac.project_id = ? |;
        $p_id    = $project_id;
    }

    @queryargs = ();

    if ( $form->{accno} || $form->{gifi_accno} ) {

        # get category for account
        $query = qq|
			SELECT description, category, link, contra
			  FROM chart
			 WHERE accno = ?|;

        $accno = $form->{accno};
        if ( $form->{accounttype} eq 'gifi' ) {
            $query = qq|
				SELECT description, category, link, contra
				  FROM chart
				 WHERE gifi_accno = ?
				       AND charttype = 'A'|;
            $accno = $form->{gifi_accno};
        }

        $sth = $dbh->prepare($query);
        $sth->execute($accno);
        (
            $form->{description}, $form->{category},
            $form->{link},        $form->{contra}
        ) = $sth->fetchrow_array;

        if ( $form->{fromdate} ) {

            if ($department_id) {

                # get beginning balance
                $query = "";
                $union = "";

                for (qw(ar ap gl)) {

                    if ( $form->{accounttype} eq 'gifi' ) {
                        $query = qq| 
							$union
							SELECT SUM(ac.amount)
							  FROM acc_trans ac
							  JOIN $_ a 
							       ON 
							       (a.id = 
							       ac.trans_id)
							  JOIN chart c 
							       ON 
							       (ac.chart_id = 
							       c.id)
							 WHERE c.gifi_accno = ?
							       AND ac.transdate 
							       < ?
							       AND 
							       a.department_id 
							       = ?
							       AND ($approved OR
							           (a.approved
							       AND ac.approved))
								 $project |;

                        push @queryargs, $form->{gifi_accno}, $form->{fromdate},
                          $form->{department_id};
                        if ($p_id) {
                            push @queryargs, $p_id;
                        }
                    }
                    else {

                        $query .= qq| 
							$union
							SELECT SUM(ac.amount)
							  FROM acc_trans ac
							  JOIN $_ a ON 
							       (a.id = 
							       ac.trans_id)
							  JOIN chart c ON 
							       (ac.chart_id = 
							       c.id)
							 WHERE c.accno = ?
							       AND ac.transdate 
							       < ?
							       AND 
							       a.department_id 
							       = ?
							       AND ($approved OR
							           (a.approved
							       AND ac.approved))
							       $project |;
                        push @queryargs, $form->{accno}, $form->{fromdate},
                          $department_id;
                        if ($p_id) {
                            push @queryargs, $p_id;
                        }
                    }

                    $union = qq| UNION ALL |;
                }

            }
            else {

                if ( $form->{accounttype} eq 'gifi' ) {
                    $query = qq|
						SELECT SUM(ac.amount)
						  FROM acc_trans ac
						  JOIN chart c ON 
						       (ac.chart_id = c.id)
						  JOIN transactions t ON 
						       (t.id = ac.trans_id)
						  JOIN (SELECT id, approved
						               'ar' AS tablename
						          FROM ar
						        UNION 
						        SELECT id, approved, 
							       'ap' AS tablename
						          FROM ap
						        UNION 
						        SELECT id, approved, 
							       'gl' AS tablename
						          FROM gl
						        ) a ON 
						       (a.tablename = t.table_name
						       AND a.id = t.id)
						 WHERE c.gifi_accno = ?
						       AND ac.transdate < ?
						       AND ($approved OR
							   (a.approved
							       AND ac.approved))
						$project |;
                    @queryargs = ( $form->{gifi_accno}, $form->{fromdate} );
                    if ($p_id) {
                        push @query_ags, $p_id;
                    }
                }
                else {
                    $query = qq|
						SELECT SUM(ac.amount)
						  FROM acc_trans ac
						  JOIN chart c 
						       ON (ac.chart_id = c.id)
						  JOIN transactions t ON 
						       (t.id = ac.trans_id)
						  JOIN (SELECT id, approved, 
						               'ar' AS tablename
						          FROM ar
						        UNION 
						        SELECT id, approved, 
							       'ap' AS tablename
						          FROM ap
						        UNION 
						        SELECT id, approved, 
							       'gl' AS tablename
						          FROM gl
						        ) a ON 
						       (a.tablename = t.table_name
						       AND a.id = t.id)
						 WHERE c.accno = ?
						       AND ac.transdate < ?
						       AND ($approved OR
							   (a.approved
							       AND ac.approved))
						$project |;
                    @queryargs = ( $form->{accno}, $form->{fromdate} );
                    if ($p_id) {
                        push @queryargs, $p_id;
                    }
                }
            }

            $sth = $dbh->prepare($query);
            $sth->execute(@queryargs);
            my @balance = $sth->fetchrow_array;
            $form->db_parse_numeric(sth=>$sth, arrayref=>\@balance);
            ( $form->{balance} ) = @balance; 
            $sth->finish;
            @queryargs = ();
        }
    }

    $query = "";
    $union = "";

    foreach my $id (@id) {

        # get all transactions
        $query .= qq|
			$union
			SELECT a.id, a.reference, a.description, ac.transdate,
			       $false AS invoice, ac.amount, 'gl' as module, 
			       ac.cleared, ac.source, '' AS till, ac.chart_id
			  FROM gl a
			  JOIN acc_trans ac ON (ac.trans_id = a.id)
			$dpt_join
			 WHERE ac.chart_id = ?
			$fromdate_where
			$todate_where
			$dpt_where
			       AND ($approved OR (a.approved AND ac.approved))
			$project|;
        push @queryargs, $id;
        if ($fdate) {
            push @queryargs, $fdate;
        }
        if ($tdate) {
            push @queryargs, $tdate;
        }
        if ($d_id) {
            push @queryargs, $d_id;
        }
        if ($p_id) {
            push @queryargs, $p_id;
        }
        $query .= qq|

			UNION ALL

			SELECT a.id, a.invnumber, e.name, ac.transdate,
			       a.invoice, ac.amount, 'ar' as module, ac.cleared,
			       ac.source, a.till, ac.chart_id
			  FROM ar a
			  JOIN acc_trans ac ON (ac.trans_id = a.id)
			  JOIN entity e ON (a.entity_id = e.id)
			$dpt_join
			 WHERE ac.chart_id = ?
			       AND ($approved OR (a.approved AND ac.approved))
			$fromdate_where
			$todate_where
			$dpt_where
			$project|;

        push @queryargs, $id;
        if ($fdate) {
            push @queryargs, $fdate;
        }
        if ($tdate) {
            push @queryargs, $tdate;
        }
        if ($d_id) {
            push @queryargs, $d_id;
        }
        if ($p_id) {
            push @queryargs, $p_id;
        }

        $query .= qq|
			 UNION ALL

			SELECT a.id, a.invnumber, e.name, ac.transdate,
			       a.invoice, ac.amount, 'ap' as module, ac.cleared,
			       ac.source, a.till, ac.chart_id
			  FROM ap a
			  JOIN acc_trans ac ON (ac.trans_id = a.id)
			  JOIN entity e ON (a.entity_id = e.id)
			$dpt_join
			 WHERE ac.chart_id = ?
			       AND ($approved OR (a.approved AND ac.approved))
			$fromdate_where
			$todate_where
			$dpt_where
			$project |;

        push @queryargs, $id;
        if ($fdate) {
            push @queryargs, $fdate;
        }
        if ($tdate) {
            push @queryargs, $tdate;
        }
        if ($d_id) {
            push @queryargs, $d_id;
        }
        if ($p_id) {
            push @queryargs, $p_id;
        }
        $union = qq| UNION ALL |;
    }

    $query .= qq| ORDER BY $sortorder |;

    $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);

    $query = qq|SELECT c.id, c.accno 
				  FROM chart c
				  JOIN acc_trans ac ON (ac.chart_id = c.id)
				 WHERE ac.amount >= 0
				   AND (c.link = 'AR' OR c.link = 'AP')
				   AND ac.approved OR $approved
				   AND ac.trans_id = ?|;

    my $dr = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|SELECT c.id, c.accno 
				  FROM chart c
				  JOIN acc_trans ac ON (ac.chart_id = c.id)
				 WHERE ac.amount < 0
				   AND (c.link = 'AR' OR c.link = 'AP')
				   AND ac.approved OR $approved
				   AND ac.trans_id = ?|;

    my $cr = $dbh->prepare($query) || $form->dberror($query);

    my $accno;
    my $chart_id;
    my %accno;

    while ( my $ca = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ca);
        # gl
        if ( $ca->{module} eq "gl" ) {
            $ca->{module} = "gl";
        }

        # ap
        if ( $ca->{module} eq "ap" ) {
            $ca->{module} = ( $ca->{invoice} ) ? 'ir' : 'ap';
            $ca->{module} = 'ps' if $ca->{till};
        }

        # ar
        if ( $ca->{module} eq "ar" ) {
            $ca->{module} = ( $ca->{invoice} ) ? 'is' : 'ar';
            $ca->{module} = 'ps' if $ca->{till};
        }

        if ( $ca->{amount} ) {
            %accno = ();

            if ( $ca->{amount} < 0 ) {
                $ca->{debit}  = $ca->{amount} * -1;
                $ca->{credit} = 0;
                $dr->execute( $ca->{id} );
                $ca->{accno} = ();

                while ( my @dr_results = $dr->fetchrow_array ) {
                    $form->db_parse_numeric(sth=>$dr, arrayref=>\@dr_results);
                    ($chart_id, $accno) = @dr_results;
                    $accno{$accno} = 1 if $chart_id ne $ca->{chart_id};
                }

                $dr->finish;

                for ( sort keys %accno ) { push @{ $ca->{accno} }, "$_ " }

            }
            else {

                $ca->{credit} = $ca->{amount};
                $ca->{debit}  = 0;

                $cr->execute( $ca->{id} );
                $ca->{accno} = ();

                while ( my @cr_results = $cr->fetchrow_array ) {
                    $form->db_parse_numeric(sth=>$cr, arrayref=>\@cr_results);
                    ($chart_id, $accno) = @cr_results;
                    $accno{$accno} = 1 if $chart_id ne $ca->{chart_id};
                }

                $cr->finish;

                for ( keys %accno ) { push @{ $ca->{accno} }, "$_ " }

            }

            push @{ $form->{CA} }, $ca;
        }
    }

    $sth->finish;
    $dbh->commit;

}

1;

