
=head1 NAME

PE

=head1 SYNOPSIS

Support functions for projects, partsgroups, and parts

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
 # Copyright (C) 2003
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
 # Project module
 # also used for partsgroups
 #
 #====================================================================

=head1 METHODS

=over

=cut

package PE;

=item PE->($myconfig, $form);

Populates the list referred to as $form->{all_project} with hashes containing
details about projects.  Each hash contains the project record's fields along
with the name of any associated customer.  If $form->{status} is 'orphaned',
only add projects that aren't referred to in any transactions, invoices,
orders, or time cards.  If $form->{status} is 'active', only projects that have
not reached their enddate are added; when $form->{status} is 'inactive', only
add projects that have reached their enddates.  When $form->{year} and
$form->{month} are set, use their values, along with that of $form->{interval},
to set the startdatefrom and startdateto attributes of $form.  These attributes
are used to prepare a date range for accepted start dates.  Both
$form->{description} and $form->{projectnumber} are used to limit the results.

Returns the number of projects added to the list.  $myconfig is unused.

=cut

sub projects {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $form->{sort} = "projectnumber" unless $form->{sort};
    my @a       = ( $form->{sort} );
    my %ordinal = (
        projectnumber => 2,
        description   => 3,
        startdate     => 4,
        enddate       => 5,
    );
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query;
    my $where = "WHERE 1=1";

    $query = qq|
		   SELECT pr.*, e.name 
		     FROM project pr
		LEFT JOIN entity_credit_account c ON (c.id = pr.credit_id)
		LEFT JOIN entity e ON (c.entity_id = e.id)|;

    if ( $form->{type} eq 'job' ) {
        $where .= qq| AND pr.id NOT IN (SELECT DISTINCT id
			            FROM parts
			            WHERE project_id > 0)|;
    }

    my $var;
    if ( $form->{projectnumber} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{projectnumber} ) );
        $where .= " AND lower(pr.projectnumber) LIKE $var";
    }
    if ( $form->{description} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $where .= " AND lower(pr.description) LIKE $var";
    }

    ( $form->{startdatefrom}, $form->{startdateto} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if $form->{year} && $form->{month};

    if ( $form->{startdatefrom} ) {
        $where .=
          " AND (pr.startdate IS NULL OR pr.startdate >= "
          . $dbh->quote( $form->{startdatefrom} ) . ")";
    }
    if ( $form->{startdateto} ) {
        $where .=
          " AND (pr.startdate IS NULL OR pr.startdate <= "
          . $dbh->quote( $form->{startdateto} ) . ")";
    }

    if ( $form->{status} eq 'orphaned' ) {
        $where .= qq| AND pr.id NOT IN (SELECT DISTINCT project_id
                                    FROM acc_trans
				    WHERE project_id > 0
                                 UNION
                                    SELECT DISTINCT project_id
		                    FROM invoice
				    WHERE project_id > 0
				 UNION
		                    SELECT DISTINCT project_id
		                    FROM orderitems
				    WHERE project_id > 0
				 UNION
		                    SELECT DISTINCT project_id
		                    FROM jcitems
				    WHERE project_id > 0)
		|;

    } elsif ( $form->{status} eq 'active' ) {
        $where .= qq| 
			AND (pr.enddate IS NULL 
			OR pr.enddate >= current_date)|;
    } elsif ( $form->{status} eq 'inactive' ) {
        $where .= qq| AND pr.enddate <= current_date|;
    }

    $query .= qq|
		 $where
		 ORDER BY $sortorder|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $i = 0;
    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_project} }, $ref;
        $i++;
    }

    $sth->finish;
    $dbh->commit;

    $i;

}

=item PE->get_project($myconfig, $form)

If $form->{id} is set, populates the $form attributes projectnumber,
description, startdate, enddate, parts_id, production, completed, and
customer_id with details from the project record and name with the associated
customer name.  If the project is not used in any transaction, invoice, order,
or time card, $form->{orphaned} is set to true, otherwise false.

Even if $form->{id} is false, PE->get_customer is run, along with any custom
SELECT queries for the table 'project'.

=cut

sub get_project {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query;
    my $sth;
    my $ref;
    my $where;

    if ( $form->{id} ) {

        $query = qq|
			   SELECT pr.*, e.name AS customer
			     FROM project pr
			LEFT JOIN entity_credit_account c 
                                  ON (c.id = pr.credit_id)
			LEFT JOIN entity e ON (c.entity_id = e.id)
			    WHERE pr.id = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);

        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

        $sth->finish;

        # check if it is orphaned
        $query = qq|
			SELECT count(*)
			  FROM acc_trans
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM invoice
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM orderitems
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM jcitems
			 WHERE project_id = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id}, $form->{id}, $form->{id}, $form->{id} )
          || $form->dberror($query);

        my $count;
        while ( ($count) = $sth->fetchrow_array ) {
            $form->{orphaned} += $count;
        }
        $sth->finish;
        $form->{orphaned} = !$form->{orphaned};
    }

    PE->get_customer( $myconfig, $form, $dbh );

    $form->run_custom_queries( 'project', 'SELECT' );

    $dbh->commit;

}

=item PE->save_project($myconfig, $form)

Updates a project, or adds a new one if $form->{id} is not set. 

The $form attributes of startdate, enddate, customer_id, description, and
projectnumber are used for the project record.  If $form->{projectnumber} is
false, a new one is obtained through $form->update_defaults.  When a new
project is added, $form->{id} is set to that new id.  Any custom queries for
UPDATE on the project table are run.

=cut

sub save_project {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $form->{customer_id} ||= undef;

    $form->{projectnumber} =
      $form->update_defaults( $myconfig, "projectnumber", $dbh )
      unless $form->{projectnumber};
    my $enddate;
    my $startdate;
    $enddate   = $form->{enddate}   if $form->{enddate};
    $startdate = $form->{startdate} if $form->{startdate};

    if ( $form->{id} ) {

        $query = qq|
			UPDATE project
			   SET projectnumber = ?,
			       description = ?,
			       startdate = ?,
			       enddate = ?,
			       credit_id = ?
			 WHERE id = | . $dbh->quote( $form->{id} );
    }
    else {

        $query = qq|
			INSERT INTO project (projectnumber, description, 
			            startdate, enddate, credit_id)
			     VALUES (?, ?, ?, ?, ?)|;
    }
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{projectnumber},
        $form->{description}, $startdate, $enddate, $form->{customer_id} )
      || $form->dberror($query);
    if (!$form->{id}){
        $query = "SELECT currval('project_id_seq')";
        ($form->{id}) = $dbh->selectrow_array($query) || $form->dberror($query);
    }
    $form->run_custom_queries( 'project', 'UPDATE' );

    $dbh->commit;

}

=item PE->list_stock($myconfig, $form);

Populates the list referred to as $form->{all_project} with hashes that contain
details about projects.

Sets $form->{stockingdate} to the current date if it is not already set.

This function is probably unused.

$myconfig is unused.

=cut

sub list_stock {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $var;
    my $where = "1 = 1";

    if ( $form->{status} eq 'active' ) {
        $where = qq|
			(pr.enddate IS NULL OR pr.enddate >= current_date)
			AND pr.completed < pr.production|;
    } elsif ( $form->{status} eq 'inactive' ) {
        $where = qq|pr.completed = pr.production|;
    }

    if ( $form->{projectnumber} ) {
        $var = $dbh->quote( $form->like( lc $form->{projectnumber} ) );
        $where .= " AND lower(pr.projectnumber) LIKE $var";
    }

    if ( $form->{description} ) {
        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $where .= " AND lower(pr.description) LIKE $var";
    }

    $form->{sort} = "projectnumber" unless $form->{sort};
    my @a         = ( $form->{sort} );
    my %ordinal   = ( projectnumber => 2, description => 3 );
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|
		   SELECT pr.*, p.partnumber
		     FROM project pr
		     JOIN parts p ON (p.id = pr.parts_id)
		    WHERE $where
		 ORDER BY $sortorder|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_project} }, $ref;
    }
    $sth->finish;

    $query = qq|SELECT current_date|;
    ( $form->{stockingdate} ) = $dbh->selectrow_array($query)
      if !$form->{stockingdate};

    $dbh->commit;

}

=item PE->jobs($myconfig, $form);

This function is probably unused.

$myconfig is unused.

=cut

sub jobs {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $form->{sort} = "projectnumber" unless $form->{sort};
    my @a         = ( $form->{sort} );
    my %ordinal   = ( projectnumber => 2, description => 3, startdate => 4 );
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|
		   SELECT pr.*, p.partnumber, p.onhand, e.name
		     FROM project pr
		     JOIN parts p ON (p.id = pr.parts_id)
		LEFT JOIN entity_credit_account c ON (c.id = pr.credit_id)
		LEFT JOIN entity e ON (e.id = c.entity_id)
		    WHERE 1=1|;

    if ( $form->{projectnumber} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{projectnumber} ) );
        $query .= " AND lower(pr.projectnumber) LIKE $var";
    }
    if ( $form->{description} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $query .= " AND lower(pr.description) LIKE $var";
    }

    ( $form->{startdatefrom}, $form->{startdateto} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if $form->{year} && $form->{month};

    if ( $form->{startdatefrom} ) {
        $query .=
          " AND pr.startdate >= " . $dbh->quote( $form->{startdatefrom} );
    }
    if ( $form->{startdateto} ) {
        $query .= " AND pr.startdate <= " . $dbh->quote( $form->{startdateto} );
    }

    if ( $form->{status} eq 'active' ) {
        $query .= qq| AND NOT pr.production = pr.completed|;
    }
    if ( $form->{status} eq 'inactive' ) {
        $query .= qq| AND pr.production = pr.completed|;
    }
    if ( $form->{status} eq 'orphaned' ) {
        $query .= qq| 
			AND pr.completed = 0
			AND (pr.id NOT IN 
			(SELECT DISTINCT project_id
			   FROM invoice
			  WHERE project_id > 0
			 UNION
			 SELECT DISTINCT project_id
			   FROM orderitems
			  WHERE project_id > 0
			 UNION
			 SELECT DISTINCT project_id
			   FROM jcitems
			  WHERE project_id > 0)
			 )|;
    }

    $query .= qq|
		ORDER BY $sortorder|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_project} }, $ref;
    }

    $sth->finish;

    $dbh->commit;

}

=item PE->get_job($myconfig, $form);

This function is probably unused as part of Dieter's incomplete job costing.

=cut

sub get_job {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query;
    my $sth;
    my $ref;

    if ( $form->{id} ) {
        $query = qq|
			SELECT value FROM defaults 
			 WHERE setting_key = 'weightunit'|;
        ( $form->{weightunit} ) = $dbh->selectrow_array($query);

        $query = qq|
			   SELECT pr.*, p.partnumber, 
			          p.description AS partdescription, p.unit, 
			          p.listprice, p.sellprice, p.priceupdate, 
			          p.weight, p.notes, p.bin, p.partsgroup_id,
			          ch.accno AS income_accno, 
			          ch.description AS income_description, 
			          pr.credit_id, e.name AS customer, 
			          pg.partsgroup
			     FROM project pr
			LEFT JOIN parts p ON (p.id = pr.parts_id)
			LEFT JOIN chart ch ON (ch.id = p.income_accno_id)
			LEFT JOIN entity_credit_account c ON 
                                                   (c.id = pr.credit_id)
			LEFT JOIN entity e ON (e.id = c.entity_id
			LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
			    WHERE pr.id = | . $dbh->quote( $form->{id} );
    }
    else {
        $query = qq|
			SELECT value, current_date AS startdate FROM defaults
			 WHERE setting_key = 'weightunit'|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;

    if ( $form->{id} ) {

        # check if it is orphaned
        $query = qq|
			SELECT count(*)
			  FROM invoice
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM orderitems
			 WHERE project_id = ?
			UNION
			SELECT count(*)
			  FROM jcitems
			 WHERE project_id = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id}, $form->{id}, $form->{id} )
          || $form->dberror($query);

        my $count;

        while ( ($count) = $sth->fetchrow_array ) {
            $form->{orphaned} += $count;
        }
        $sth->finish;

    }

    $form->{orphaned} = !$form->{orphaned};

    $query = qq|
		  SELECT accno, description, link
		    FROM chart
		   WHERE link LIKE ?
		ORDER BY accno|;
    $sth = $dbh->prepare($query);
    $sth->execute('%IC%') || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        for ( split /:/, $ref->{link} ) {
            if (/IC/) {
                push @{ $form->{IC_links}{$_} },
                  {
                    accno       => $ref->{accno},
                    description => $ref->{description}
                  };
            }
        }
    }
    $sth->finish;

    if ( $form->{id} ) {
        $query = qq|
			SELECT ch.accno
			  FROM parts p
			  JOIN partstax pt ON (pt.parts_id = p.id)
			  JOIN chart ch ON (pt.chart_id = ch.id)
			 WHERE p.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $form->{amount}{ $ref->{accno} } = $ref->{accno};
        }
        $sth->finish;
    }

    PE->get_customer( $myconfig, $form, $dbh );

    $dbh->commit;

}

=item PE->get_customer($myconfig, $form[, $dbh]);

Populates the list referred to as $form->{all_customer} with hashes containing
the ids and names of customers unless the number of customers added would be
greater than or equal to $myconfig->{vclimit}.  $form->{startdate} and
$form->{enddate} form a date range to limit the results.  If
$form->{customer_id} is set, then the customer with that id will be in the
result set.

=cut

sub get_customer {
    my ( $self, $myconfig, $form, $dbh ) = @_;

    if ( !$dbh ) {
        $dbh = $form->{dbh};
    }

    my $query;
    my $sth;
    my $ref;

    if ( !$form->{startdate} ) {
        $query = qq|SELECT current_date|;
        ( $form->{startdate} ) = $dbh->selectrow_array($query);
    }

    my $where =
        qq|(startdate >= |
      . $dbh->quote( $form->{startdate} )
      . qq| OR startdate IS NULL OR enddate IS NULL)|;

    if ( $form->{enddate} ) {
        $where .=
            qq| AND (enddate >= |
          . $dbh->quote( $form->{enddate} )
          . qq| OR enddate IS NULL)|;
    }
    else {
        $where .= qq| AND (enddate >= current_date OR enddate IS NULL)|;
    }

    $query = qq|
		SELECT count(*)
		  FROM entity_credit_account
		 WHERE $where|;
    my ($count) = $dbh->selectrow_array($query);

    if ( $count < $myconfig->{vclimit} ) {
        $query = qq|
			SELECT id, name
			  FROM entity_credit_account
			 WHERE $where|;

        if ( $form->{customer_id} ) {
            $query .= qq|
				UNION 
				SELECT id,name
				  FROM entity_credit_account
				 WHERE id = | . $dbh->quote( $form->{customer_id} );
        }

        $query .= qq|
			ORDER BY name|;
        $sth = $dbh->prepare($query);
        $sth->execute || $form->dberror($query);

        @{ $form->{all_customer} } = ();
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            push @{ $form->{all_customer} }, $ref;
        }
        $sth->finish;
    }

}

=item PE->save_job($myconfig, $form);

Yet another save function.  This one is related to the incomplete job handling.

=cut

sub save_job {
    my ( $self, $myconfig, $form ) = @_;
    $form->{projectnumber} =
      $form->update_defaults( $myconfig, "projectnumber", $dbh )
      unless $form->{projectnumber};

    my $dbh = $form->{dbh};

    my ($income_accno) = split /--/, $form->{IC_income};

    my ( $partsgroup, $partsgroup_id ) = split /--/, $form->{partsgroup};

    if ( $form->{id} ) {
        $query = qq|
			SELECT id FROM project
			WHERE id = | . $dbh->quote( $form->{id} );
        ( $form->{id} ) = $dbh->selectrow_array($query);
    }

    if ( !$form->{id} ) {
        my $uid = localtime;
        $uid .= "$$";

        $query = qq|
			INSERT INTO project (projectnumber)
			     VALUES ('$uid')|;
        $dbh->do($query) || $form->dberror($query);

        $query = qq|
			SELECT id FROM project 
			 WHERE projectnumber = '$uid'|;
        ( $form->{id} ) = $dbh->selectrow_array($query);
    }


    $query = qq|
		UPDATE project 
		   SET projectnumber = ?,
		       description = ?,
		       startdate = ?,
		       enddate = ?,
		       parts_id = ?
		       production = ?,
		       credit_id = ?
		 WHERE id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute(
        $form->{projectnumber}, $form->{description}, $form->{startdate},
        $form->{enddate},       $form->{id},          $form->{production},
        $form->{customer_id},   $form->{id}
    ) || $form->dberror($query);

    #### add/edit assembly
    $query = qq|SELECT id FROM parts WHERE id = | . $dbh->quote( $form->{id} );
    my ($id) = $dbh->selectrow_array($query);

    if ( !$id ) {
        $query = qq|
		INSERT INTO parts (id) 
		     VALUES (| . $dbh->quote( $form->{id} ) . qq|)|;
        $dbh->do($query) || $form->dberror($query);
    }

    my $partnumber =
      ( $form->{partnumber} )
      ? $form->{partnumber}
      : $form->{projectnumber};

    $query = qq|
		UPDATE parts 
		   SET partnumber = ?,
		       description = ?,
		       priceupdate = ?,
		       listprice = ?,
		       sellprice = ?,
		       weight = ?,
		       bin = ?,
		       unit = ?,
		       notes = ?,
		       income_accno_id = (SELECT id FROM chart
		                           WHERE accno = ?),
		       partsgroup_id = ?,
		       assembly = '1',
		       obsolete = '1',
		       project_id = ?
		       WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute(
        $partnumber,
        $form->{partdescription},
        $form->{priceupdate},
        $form->parse_amount( $myconfig, $form->{listprice} ),
        $form->parse_amount( $myconfig, $form->{sellprice} ),
        $form->parse_amount( $myconfig, $form->{weight} ),
        $form->{bin},
        $form->{unit},
        $form->{notes},
        $income_accno,
        ($partsgroup_id) ? $partsgroup_id : undef,
        $form->{id},
        $form->{id}
    ) || $form->dberror($query);

    $query =
      qq|DELETE FROM partstax WHERE parts_id = | . $dbh->quote( $form->{id} );
    $dbh->do($query) || $form->dberror($query);

    $query = qq|
		INSERT INTO partstax (parts_id, chart_id)
		    VALUES (?, (SELECT id FROM chart WHERE accno = ?))|;
    $sth = $dbh->prepare($query);
    for ( split / /, $form->{taxaccounts} ) {
        if ( $form->{"IC_tax_$_"} ) {
            $sth->execute( $form->{id}, $_ )
              || $form->dberror($query);
        }
    }

    $dbh->commit;

}

=item PE->stock_assembly($myconfig, $form)

Looks like more of that job control code.  IC.pm has the functions actually
used by assemblies.

=cut

sub stock_assembly {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $ref;

    my $query = qq|SELECT * FROM project WHERE id = ?|;
    my $sth = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|SELECT COUNT(*) FROM parts WHERE project_id = ?|;
    my $rvh = $dbh->prepare($query) || $form->dberror($query);

    if ( !$form->{stockingdate} ) {
        $query = qq|SELECT current_date|;
        ( $form->{stockingdate} ) = $dbh->selectrow_array($query);
    }

    $query = qq|SELECT * FROM parts WHERE id = ?|;
    my $pth = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|
		  SELECT j.*, p.lastcost FROM jcitems j
		    JOIN parts p ON (p.id = j.parts_id)
		   WHERE j.project_id = ?
		         AND j.checkedin <= | . $dbh->quote( $form->{stockingdate} ) . qq|
		ORDER BY parts_id|;
    my $jth = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|
		INSERT INTO assembly (id, parts_id, qty, bom, adj)
		     VALUES (?, ?, ?, '0', '0')|;
    my $ath = $dbh->prepare($query) || $form->dberror($query);

    my $i = 0;
    my $sold;
    my $ship;

    while (1) {
        $i++;
        last unless $form->{"id_$i"};

        $stock = $form->parse_amount( $myconfig, $form->{"stock_$i"} );

        if ($stock) {
            $sth->execute( $form->{"id_$i"} );
            $ref = $sth->fetchrow_hashref(NAME_lc);

            if ( $stock > ( $ref->{production} - $ref->{completed} ) ) {
                $stock = $ref->{production} - $ref->{completed};
            }
            if ( ( $stock * -1 ) > $ref->{completed} ) {
                $stock = $ref->{completed} * -1;
            }

            $pth->execute( $form->{"id_$i"} );
            $pref = $pth->fetchrow_hashref(NAME_lc);

            my %assembly  = ();
            my $lastcost  = 0;
            my $sellprice = 0;
            my $listprice = 0;

            $jth->execute( $form->{"id_$i"} );
            while ( $jref = $jth->fetchrow_hashref(NAME_lc) ) {
                $assembly{qty}{ $jref->{parts_id} } +=
                  ( $jref->{qty} - $jref->{allocated} );
                $assembly{parts_id}{ $jref->{parts_id} } = $jref->{parts_id};
                $assembly{jcitems}{ $jref->{id} }        = $jref->{id};
                $lastcost +=
                  $form->round_amount(
                    $jref->{lastcost} * ( $jref->{qty} - $jref->{allocated} ),
                    2 );
                $sellprice += $form->round_amount(
                    $jref->{sellprice} * ( $jref->{qty} - $jref->{allocated} ),
                    2
                );
                $listprice += $form->round_amount(
                    $jref->{listprice} * ( $jref->{qty} - $jref->{allocated} ),
                    2
                );
            }
            $jth->finish;

            $uid = localtime;
            $uid .= "$$";

            $query = qq|
				INSERT INTO parts (partnumber)
				     VALUES ('$uid')|;
            $dbh->do($query) || $form->dberror($query);

            $query = qq|
				SELECT id
				  FROM parts
				 WHERE partnumber = '$uid'|;
            ($uid) = $dbh->selectrow_array($query);

            $lastcost = $form->round_amount( $lastcost / $stock, 2 );
            $sellprice =
              ( $pref->{sellprice} )
              ? $pref->{sellprice}
              : $form->round_amount( $sellprice / $stock, 2 );
            $listprice =
              ( $pref->{listprice} )
              ? $pref->{listprice}
              : $form->round_amount( $listprice / $stock, 2 );

            $rvh->execute( $form->{"id_$i"} );
            my ($rev) = $rvh->fetchrow_array;
            $rvh->finish;

            $query = qq|
				UPDATE parts 
				   SET partnumber = ?,
				       description = ?,
				       priceupdate = ?,
				       unit = ?,
				       listprice = ?,
				       sellprice = ?,
				       lastcost = ?,
				       weight = ?,
				       onhand = ?,
				       notes = ?,
				       assembly = '1',
				       income_accno_id = ?,
				       bin = ?,
				       project_id = ?
				 WHERE id = ?|;
            $sth = $dbh->prepare($query);
            $sth->execute(
                "$pref->{partnumber}-$rev", $pref->{partdescription},
                $form->{stockingdate},      $pref->{unit},
                $listprice,                 $sellprice,
                $lastcost,                  $pref->{weight},
                $stock,                     $pref->{notes},
                $pref->{income_accno_id},   $pref->{bin},
                $form->{"id_$i"},           $uid
            ) || $form->dberror($query);

            $query = qq|
				INSERT INTO partstax (parts_id, chart_id)
				     SELECT ?, chart_id FROM partstax
				      WHERE parts_id = ?|;
            $sth = $dbh->prepare($query);
            $sth->execute( $uid, $pref->{id} )
              || $form->dberror($query);

            $pth->finish;

            for ( keys %{ $assembly{parts_id} } ) {
                if ( $assembly{qty}{$_} ) {
                    $ath->execute(
                        $uid,
                        $assembly{parts_id}{$_},
                        $form->round_amount( $assembly{qty}{$_} / $stock, 4 )
                    );
                    $ath->finish;
                }
            }

            $form->update_balance( $dbh, "project", "completed",
                qq|id = $form->{"id_$i"}|, $stock );

            $query = qq|
				UPDATE jcitems 
				   SET allocated = qty
				 WHERE allocated != qty
				       AND checkedin <= ?
				       AND project_id = ?|;
            $sth = $dbh->prepare($query);
            $sth->execute( $form->{stockingdate}, $form->{"id_$i"} )
              || $form->dberror($query);

            $sth->finish;

        }

    }

    my $rc = $dbh->commit;

    $rc;

}

=item PE->delete_project($myconfig, $form);

Deletes the database entry in project identified by $form->{id} and associated
translations.

$myconfig is unused.

=cut

sub delete_project {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $query = qq|DELETE FROM project WHERE id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM translation
	      WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $rc = $dbh->commit;

    $rc;

}

=item PE->delete_partsgroup($myconfig, $form);

Deletes the entry in partsgroup identified by $form->{id} and associated
translations.

$myconfig is unused.

=cut

sub delete_partsgroup {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $query = qq|DELETE FROM partsgroup WHERE id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM translation WHERE trans_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $rc = $dbh->commit;

    $rc;

}

=item PE->delete_pricegroup($myconfig, $form);

Deletes the pricegroup entry identified by $form->{id}.

$myconfig is unused.

=cut

sub delete_pricegroup {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $query = qq|DELETE FROM pricegroup WHERE id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $rc = $dbh->commit;

    $rc;

}

=item PE->delete_job($myconfig, $form);

An "enhanced" variant of PE->delete_project.  In addition to deleting the
project identified by $form->{id} and the associated translations, also deletes
all parts and assemblies with $form->{id} as a project_id.  This function adds
an audit trail entry for the table 'project' and the action 'deleted' where the
formname is taken from $form->{type}.

$myconfig is unused.

=cut

sub delete_job {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my %audittrail = (
        tablename => 'project',
        reference => $form->{id},
        formname  => $form->{type},
        action    => 'deleted',
        id        => $form->{id}
    );

    $form->audittrail( $dbh, "", \%audittrail );

    my $query = qq|DELETE FROM project WHERE id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM translation WHERE trans_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    # delete all the assemblies
    $query = qq|
		DELETE FROM assembly a 
		       JOIN parts p ON (a.id = p.id)
		      WHERE p.project_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|DELETE FROM parts WHERE project_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $rc = $dbh->commit;

    $rc;

}

=item PE->partsgroups($myconfig, $form);

Populates the list referred to as $form->{item_list} with hashes containing
the id and partsgroup (name) for all the partsgroups in the database.  If
$form->{partsgroup} is non-empty, the results are limited to the partsgroups
that contain that value in their name (case insensitive).  If $form->{status}
is 'orphaned', only partsgroups that are not associated with a part are added.
The number of partsgroups added to $form->{item_list} is returned.

$myconfig is unused.

=cut

sub partsgroups {
    my ( $self, $myconfig, $form ) = @_;

    my $var;

    my $dbh = $form->{dbh};

    $form->{sort} = "partsgroup" unless $form->{partsgroup};
    my @a         = qw(partsgroup);
    my $sortorder = $form->sort_order( \@a );

    my $query = qq|SELECT g.* FROM partsgroup g|;

    my $where = "1 = 1";

    if ( $form->{partsgroup} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{partsgroup} ) );
        $where .= " AND lower(partsgroup) LIKE $var";
    }
    $query .= qq| WHERE $where ORDER BY $sortorder|;

    if ( $form->{status} eq 'orphaned' ) {
        $query = qq|
			   SELECT g.*
			     FROM partsgroup g
			LEFT JOIN parts p ON (p.partsgroup_id = g.id)
			    WHERE $where
			EXCEPT
			   SELECT g.*
			     FROM partsgroup g
			     JOIN parts p ON (p.partsgroup_id = g.id)
			    WHERE $where
			 ORDER BY $sortorder|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $i = 0;
    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{item_list} }, $ref;
        $i++;
    }

    $sth->finish;

    $i;

}

=item PE->save_partsgroup($myconfig, $form);

Save a partsgroup record.  If $form->{id} is set, update the description of
the partsgroup with that id to be $form->{partsgroup}.  Otherwise, create a
new partsgroup with that description.

$myconfig is unused.

=cut

sub save_partsgroup {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};
    my @group = ($form->{partsgroup});

    if ( $form->{id} ) {
        $query = qq|
			UPDATE partsgroup 
			   SET partsgroup = ?
			 WHERE id = ?|;
        push @group,  $form->{id};
    }
    else {
        $query = qq|
			INSERT INTO partsgroup (partsgroup)
			     VALUES (?)|;
    }
    $dbh->do($query, undef, @group) || $form->dberror($query);

    $dbh->commit;

}

=item PE->get_partsgroup($myconfig, $form);

Sets $form->{partsgroup} to the description of the partsgroup identified by
$form->{id}.  If there are no parts entries associated with that partsgroup,
$form->{orphaned} is made true, otherwise it is set to false.

$myconfig is unused.

=cut

sub get_partsgroup {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|SELECT * FROM partsgroup WHERE id = ?|;
    my $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;

    # check if it is orphaned
    $query = qq|SELECT count(*) FROM parts WHERE partsgroup_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    ( $form->{orphaned} ) = $sth->fetchrow_array;
    $form->{orphaned} = !$form->{orphaned};

    $sth->finish;

    $dbh->commit;

}

=item PE->pricegroups($myconfig, $form);

Populates the list referred to as $form->{item_list} with hashes containing
details (id and pricegroup (description)) about pricegroups.  All the groups
are added unless $form->{pricegroup} is set, in which case it will search for
groups with that description, or $form->{status} is 'orphaned', which limits
the results to those not related to any customers (partscustomer table).  The
return value is the number of pricegroups added to the list.

$myconfig is unused.

=cut

sub pricegroups {
    my ( $self, $myconfig, $form ) = @_;

    my $var;

    my $dbh = $form->{dbh};

    $form->{sort} = "pricegroup" unless $form->{sort};
    my @a         = qw(pricegroup);
    my $sortorder = $form->sort_order( \@a );

    my $query = qq|SELECT g.* FROM pricegroup g|;

    my $where = "1 = 1";

    if ( $form->{pricegroup} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{pricegroup} ) );
        $where .= " AND lower(pricegroup) LIKE $var";
    }
    $query .= qq|
		WHERE $where ORDER BY $sortorder|;

    if ( $form->{status} eq 'orphaned' ) {
        $query = qq|
			SELECT g.*
			  FROM pricegroup g
			 WHERE $where
			       AND g.id NOT IN (SELECT DISTINCT pricegroup_id
			                          FROM partscustomer
			                         WHERE pricegroup_id > 0)
		ORDER BY $sortorder|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $i = 0;
    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{item_list} }, $ref;
        $i++;
    }

    $sth->finish;
    $dbh->commit;

    $i;

}

=item PE->save_pricegroup($myconfig, $form);

Adds or updates a pricegroup.  If $form->{id} is set, update the pricegroup
value using $form->{pricegroup}.  If $form->{id} is not set, adds a new
pricegroup with a pricegroup value of $form->{pricegroup}.

$myconfig is unused.

=cut

sub save_pricegroup {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    if ( $form->{id} ) {
        $query = qq|
			UPDATE pricegroup SET
			       pricegroup = ?
			 WHERE id = | . $dbh->quote( $form->{id} );
    }
    else {
        $query = qq|
			INSERT INTO pricegroup (pricegroup)
			VALUES (?)|;
    }
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{pricegroup} ) || $form->dberror($query);

    $dbh->commit;

}

=item PE->get_pricegroup($myconfig, $form);

Sets $form->{pricegroup} to the description of the pricegroup identified by
$form->{id}.  If the pricegroup is not mentioned in partscustomer,
$form->{orphaned} is set true, otherwise false.

=cut

sub get_pricegroup {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|SELECT * FROM pricegroup WHERE id = ?|;
    my $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;

    # check if it is orphaned
    $query = "SELECT count(*) FROM partscustomer WHERE pricegroup_id = ?";
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    ( $form->{orphaned} ) = $sth->fetchrow_array;
    $form->{orphaned} = !$form->{orphaned};

    $sth->finish;

    $dbh->commit;

}

=item PE::description_translations('', $myconfig, $form);

Populates the list referred to as $form->{translations} with hashes detailing
non-obsolete goods and services and their translated descriptions.  The main
details hash immediately precedes its set of translations and has the
attributes id, partnumber, and description.  The translations have the
attributes id (same as in the main hash), language, translation, and code.

When $form->{id} is set, only adds an entry for the item having that id, but
also populates $form->{all_language} using PE::get_language.  The attributes
partnumber and description are searchable and if set, will limit the results to
only those that match them.

$myconfig is unused.  $form->{trans_id} is set to the last encountered part id.

=cut

sub description_translations {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh   = $form->{dbh};
    my $where = "1 = 1";
    my $var;
    my $ref;

    for (qw(partnumber description)) {
        if ( $form->{$_} ) {
            $var = $dbh->quote( $form->like( lc $form->{$_} ) );
            $where .= " AND lower(p.$_) LIKE $var";
        }
    }

    $where .= " AND p.obsolete = '0'";
    $where .= " AND p.id = " . $dbh->quote( $form->{id} ) if $form->{id};

    my %ordinal = ( 'partnumber' => 2, 'description' => 3 );

    my @a = qw(partnumber description);
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|
		  SELECT l.description AS language, 
		         t.description AS translation, l.code
		    FROM translation t
		    JOIN language l ON (l.code = t.language_code)
		   WHERE trans_id = ?
		ORDER BY 1|;
    my $tth = $dbh->prepare($query);

    $query = qq|
		  SELECT p.id, p.partnumber, p.description
		    FROM parts p
		   WHERE $where
		ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $tra;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{translations} }, $ref;

        # get translations for description
        $tth->execute( $ref->{id} ) || $form->dberror;

        while ( $tra = $tth->fetchrow_hashref(NAME_lc) ) {
            $form->{trans_id} = $ref->{id};
            $tra->{id}        = $ref->{id};
            push @{ $form->{translations} }, $tra;
        }
        $tth->finish;

    }
    $sth->finish;

    &get_language( "", $dbh, $form ) if $form->{id};

    $dbh->commit;

}

=item PE::partsgroup_translations("", $myconfig, $form)

Populates the list referred to as $form->{translations} with hashrefs containing
details about partsgroups and their translated names.  A master hash contains
the id and description of the partsgroup and is immediately followed by its
translation hashes, which  contain the language, translation, and code of the
translation.  The list contains the details for all partsgroups unless
$form->{description} is set, in which case only partsgroups with a matching
description are included, or $form->{id} is set.  When $form->{id} is set, only
translations for the partgroup with that are included and $form->{all_language}
is populated by get_language.

$myconfig is unused.  $form->{trans_id} is set to the last id encountered.

=cut

sub partsgroup_translations {
    my ( $self, $myconfig, $form ) = @_;
    my $dbh = $form->{dbh};

    my $where = "1 = 1";
    my $ref;
    my $var;

    if ( $form->{description} ) {
        $var = $dbh->quote( $form->like( lc $form->{description} ) );
        $where .= " AND lower(p.partsgroup) LIKE $var";
    }
    $where .= " AND p.id = " . $dbh->quote( $form->{id} ) if $form->{id};

    my $query = qq|
		  SELECT l.description AS language, 
		         t.description AS translation, l.code
		    FROM translation t
		    JOIN language l ON (l.code = t.language_code)
		   WHERE trans_id = ?
		ORDER BY 1|;
    my $tth = $dbh->prepare($query);

    $form->sort_order();

    $query = qq|
		  SELECT p.id, p.partsgroup AS description
		    FROM partsgroup p
		   WHERE $where
		ORDER BY 2 $form->{direction}|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $tra;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{translations} }, $ref;

        # get translations for partsgroup
        $tth->execute( $ref->{id} ) || $form->dberror;

        while ( $tra = $tth->fetchrow_hashref(NAME_lc) ) {
            $form->{trans_id} = $ref->{id};
            push @{ $form->{translations} }, $tra;
        }
        $tth->finish;

    }
    $sth->finish;

    &get_language( "", $dbh, $form ) if $form->{id};

    $dbh->commit;

}

=item PE::project_translations("", $myconfig, $form)

Populates the list referred to as $form->{translations} with hashrefs containing
details about projects and their translated names.  A master hash contains the
id, project number, and description of the project and is immediately followed
by its translation hashes, which have the same id as the master and also
contain the language, translation, and code of the translation.  The list
contains the details for all projects unless $form->{description} or 
$form->{projectnumber} is set, in which case only projects that match the
appropriate field are included, or $form->{id} is set.  When $form->{id} is
set, only translations for the project with that id are included and
$form->{all_language} is populated by get_language.

$myconfig is unused.  $form->{trans_id} is set to the last encountered id.

=cut
sub project_translations {
    my ( $self, $myconfig, $form ) = @_;
    my $dbh = $form->{dbh};

    my $where = "1 = 1";
    my $var;
    my $ref;

    for (qw(projectnumber description)) {
        if ( $form->{$_} ) {
            $var = $dbh->quote( $form->like( lc $form->{$_} ) );
            $where .= " AND lower(p.$_) LIKE $var";
        }
    }

    $where .= " AND p.id = " . $dbh->quote( $form->{id} ) if $form->{id};

    my %ordinal = ( 'projectnumber' => 2, 'description' => 3 );

    my @a = qw(projectnumber description);
    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|
		  SELECT l.description AS language, 
		         t.description AS translation, l.code
		    FROM translation t
		    JOIN language l ON (l.code = t.language_code)
		   WHERE trans_id = ?
		ORDER BY 1|;
    my $tth = $dbh->prepare($query);

    $query = qq|
		  SELECT p.id, p.projectnumber, p.description
		    FROM project p
		   WHERE $where
		ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $tra;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{translations} }, $ref;

        # get translations for description
        $tth->execute( $ref->{id} ) || $form->dberror;

        while ( $tra = $tth->fetchrow_hashref(NAME_lc) ) {
            $form->{trans_id} = $ref->{id};
            $tra->{id}        = $ref->{id};
            push @{ $form->{translations} }, $tra;
        }
        $tth->finish;

    }
    $sth->finish;

    &get_language( "", $dbh, $form ) if $form->{id};

    $dbh->commit;

}

=item PE::get_language("", $dbh, $form)

Populates the list referred to as $form->{all_language} with hashes containing
the code and description of all languages registered with the system in the
language table.

=cut

sub get_language {
    my ( $self, $dbh, $form ) = @_;

    my $query = qq|SELECT * FROM language ORDER BY 2|;
    my $sth   = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_language} }, $ref;
    }
    $sth->finish;

}

=item PE::save_translation("", $myconfig, $form);

Deletes all translations with the trans_id (part id, project id, or partsgroup
id) of $form->{id} then adds new entries for $form->{id}.  The number of
translation entries is obtained from $form->{translation_rows}.  The actual
translation entries are derived from $form->{language_code_I<i>} and
$form->{translation_I<i>}, where I<i> is some integer between 1 and
$form->{translation_rows} inclusive.

$myconfig is unused.

=cut

sub save_translation {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|DELETE FROM translation WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|
		INSERT INTO translation (trans_id, language_code, description)
		     VALUES (?, ?, ?)|;
    my $sth = $dbh->prepare($query) || $form->dberror($query);

    foreach my $i ( 1 .. $form->{translation_rows} ) {
        if ( $form->{"language_code_$i"} ne "" ) {
            $sth->execute(
                $form->{id},
                $form->{"language_code_$i"},
                $form->{"translation_$i"}
            );
            $sth->finish;
        }
    }
    $dbh->commit;

}

=item PE::delete_translation("", $myconfig, $form);

Deletes all translation entries that have the trans_id of $form->{id}.

$myconfig is unused.

=cut

sub delete_translation {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|DELETE FROM translation WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $dbh->commit;

}

=item PE->timecard_get_currency($form);

Sets $form->{currency} to the currency set for the customer who has the id
$form->{customer_id}.

=cut

sub timecard_get_currency {
    my $self  = shift @_;
    my $form  = shift @_;
    my $dbh   = $form->{dbh};
    my $query = qq|SELECT curr FROM entity_credit_account WHERE id = ?|;
    my $sth   = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute( $form->{customer_id} ) || $form->dberror($query);
    my ($curr) = $sth->fetchrow_array || $form->dberror($query);
    $form->{currency} = $curr;
}

=item PE::project_sales_order("", $myconfig, $form)

Executes $form->all_years, $form->all_projects, and $form->all_employees, with
a limiting transdate of the current date.

=cut

sub project_sales_order {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|SELECT current_date|;
    my ($transdate) = $dbh->selectrow_array($query);

    $form->all_years( $myconfig, $dbh );

    $form->all_projects( $myconfig, $dbh, $transdate );

    $form->all_employees( $myconfig, $dbh, $transdate );

    $dbh->commit;

}

=item PE->get_jcitems($myconfig, $form);

This function is used as part of the sales order generation accessible from the
projects interface, to generate the list of possible orders.

Populates the list referred to as $form->{jcitems} with hashes containing
details about sales orders that can be generated that relate to projects.  Each
of the hashes has the attributes id (timecard id), description (timecard
description), qty (unallocated chargeable hours), sellprice (hourly rate),
parts_id (service id), customer_id, project_id, transdate (date on timecard),
notes, customer (customer name), projectnumber, partnumber, taxaccounts (space
separated list that contains the account numbers of taxes that apply to the
service), and amount (qty*sellprice).  If $form->{summary} is true, the
description field contains the service description instead of the timecard
description.

All possible, unconsolidated sales orders are normally listed.  If
$form->{projectnumber} is set, only orders associated with the project are
listed.  $form->{employee} limits the list to timecards with the given employee.
When $form->{year} and $form->{month} are set, the transdatefrom and transdateto
attributes are populated with values derived from the year, month, and interval
$form attributes.  $form->{transdatefrom} is used to limit the results to
time cards checked in on or after that date.  $form->{transdateto} limits to
time cards checked out on or before the provided date.  $form->{vc} must be
'customer'.

Regardless of the values added to $form->{jcitems}, this function sets
$form->{currency} and $form->{defaultcurrency} to the first currency mentioned
in defaults.  It also fills  $form->{taxaccounts} with a space separated list
of the account numbers of all tax accounts and for each accno forms a
$form->{${accno}_rate} attribute that contains the tax's rate as expressed in
the tax table.

$myconfig is unused.

=cut

sub get_jcitems {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $null;
    my $var;
    my $where;

    if ( $form->{projectnumber} ) {
        ( $null, $var ) = split /--/, $form->{projectnumber};
        $var = $dbh->quote($var);
        $where .= " AND j.project_id = $var";
    }

    if ( $form->{employee} ) {
        ( $null, $var ) = split /--/, $form->{employee};
        $var = $dbh->quote($var);
        $where .= " AND j.employee_id = $var";
    }

    ( $form->{transdatefrom}, $form->{transdateto} ) =
      $form->from_to( $form->{year}, $form->{month}, $form->{interval} )
      if $form->{year} && $form->{month};

    if ( $form->{transdatefrom} ) {
        $where .=
          " AND j.checkedin >= " . $dbh->quote( $form->{transdatefrom} );
    }
    if ( $form->{transdateto} ) {
        $where .=
            " AND j.checkedout <= (date "
          . $dbh->quote( $form->{transdateto} )
          . " + interval '1 days')";
    }

    my $query;
    my $ref;
# XXX Note that this is aimed at current customer functionality only.  In the 
# future, this will be more generaly constructed.
    $query = qq|
		   SELECT j.id, j.description, j.qty - j.allocated AS qty,
		          j.sellprice, j.parts_id, pr.credit_id as customer_id, 
		          j.project_id, j.checkedin::date AS transdate, 
		          j.notes, c.legal_name AS customer, pr.projectnumber, 
		          p.partnumber
		     FROM jcitems j
		     JOIN project pr ON (pr.id = j.project_id)
		     JOIN parts p ON (p.id = j.parts_id)
		LEFT JOIN entity_credit_account eca ON (eca.id = pr.credit_id)
                LEFT JOIN company c ON eca.entity_id = c.entity_id
		    WHERE pr.parts_id IS NULL
		          AND j.allocated != j.qty $where
		 ORDER BY pr.projectnumber, c.name, j.checkedin::date|;
    if ( $form->{summary} ) {
        $query =~ s/j\.description/p\.description/;
        $query =~ s/c\.name,/c\.name, j\.parts_id, /;
    }
    
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # tax accounts
    $query = qq|
		SELECT c.accno
		  FROM chart c
		  JOIN partstax pt ON (pt.chart_id = c.id)
		 WHERE pt.parts_id = ?|;
    my $tth = $dbh->prepare($query) || $form->dberror($query);
    my $ptref;

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {

        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        $tth->execute( $ref->{parts_id} );
        $ref->{taxaccounts} = "";
        while ( $ptref = $tth->fetchrow_hashref(NAME_lc) ) {
            $ref->{taxaccounts} .= "$ptref->{accno} ";
        }
        $tth->finish;
        chop $ref->{taxaccounts};

        $ref->{amount} = $ref->{sellprice} * $ref->{qty};

        push @{ $form->{jcitems} }, $ref;
    }

    $sth->finish;

    $query = qq|SELECT value FROM defaults WHERE setting_key = 'curr'|;
    ( $form->{currency} ) = $dbh->selectrow_array($query);
    $form->{currency} =~ s/:.*//;
    $form->{defaultcurrency} = $form->{currency};

    $query = qq|
		SELECT c.accno, t.rate
		  FROM tax t
		  JOIN chart c ON (c.id = t.chart_id)|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{taxaccounts} .= "$ref->{accno} ";
        $form->{"$ref->{accno}_rate"} = $ref->{rate};
    }
    chop $form->{taxaccounts};
    $sth->finish;

    $dbh->commit;

}

=item PE->allocate_projectitems($myconfig, $form);

Updates the jcitems table to adjust the allocated quantities of time.  The
time cards, and allocated time, to update is obtained from the various space
separated lists $form->{jcitems_I<i>}, where I<i> is between 1 and the value of
$form->{rowcount}.  Each element of those space separated lists is a colon
separated pair where the first element is the time card id and the second
element is the increase in allocated hours.

$myconfig is unused.

=cut

sub allocate_projectitems {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    for my $i ( 1 .. $form->{rowcount} ) {
        for ( split / /, $form->{"jcitems_$i"} ) {
            my ( $id, $qty ) = split /:/, $_;
            $form->update_balance( $dbh, 'jcitems', 'allocated', "id = $id",
                $qty );
        }
    }

    $rc = $dbh->commit;

    $rc;

}

1;

=back

