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
#
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# backend code for customers and vendors
#
#======================================================================

package CT;

sub create_links {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};
    my $query;
    my $sth;
    my $ref;
    my $arap = ( $form->{db} eq 'customer' ) ? "ar" : "ap";
    my $ARAP = uc $arap;

    if ( $form->{id} ) {
        $query = qq|
			    SELECT ct.*, b.description AS business, s.*,
			           e.name AS employee, 
			           g.pricegroup AS pricegroup,
			           l.description AS language, ct.curr
			      FROM $form->{db} ct
			 LEFT JOIN business b ON (ct.business_id = b.id)
			 LEFT JOIN shipto s ON (ct.id = s.trans_id)
			 LEFT JOIN employee e ON (ct.employee_id = e.id)
			 LEFT JOIN pricegroup g ON (g.id = ct.pricegroup_id)
			 LEFT JOIN language l ON (l.code = ct.language_code)
			     WHERE ct.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        # check if it is orphaned
        $query = qq|
			SELECT a.id
			  FROM $arap a
			  JOIN $form->{db} ct ON (a.$form->{db}_id = ct.id)
			 WHERE ct.id = ?

			 UNION

			SELECT a.id
			  FROM oe a
			  JOIN $form->{db} ct ON (a.$form->{db}_id = ct.id)
			 WHERE ct.id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id}, $form->{id} )
          || $form->dberror($query);

        unless ( $sth->fetchrow_array ) {
            $form->{status} = "orphaned";
        }

        $sth->finish;

        # get taxes for customer/vendor
        $query = qq|
			SELECT c.accno
			  FROM chart c
			  JOIN $form->{db}tax t ON (t.chart_id = c.id)
			 WHERE t.$form->{db}_id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $form->{tax}{ $ref->{accno} }{taxable} = 1;
        }

        $sth->finish;

    }
    else {

        ( $form->{employee}, $form->{employee_id} ) = $form->get_employee($dbh);

        $query = qq|SELECT current_date|;
        ( $form->{startdate} ) = $dbh->selectrow_array($query);

    }

    # get tax labels
    $query = qq|
		   SELECT DISTINCT c.accno, c.description
		     FROM chart c
		     JOIN tax t ON (t.chart_id = c.id)
		    WHERE c.link LIKE ?
		 ORDER BY c.accno|;

    $sth = $dbh->prepare($query);
    $sth->execute("%${ARAP}_tax%") || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{taxaccounts} .= "$ref->{accno} ";
        $form->{tax}{ $ref->{accno} }{description} = $ref->{description};
    }

    $sth->finish;
    chop $form->{taxaccounts};

# get business types ## needs fixing, this is bad (SELECT * ...) with order by 2. Yuck
    $query = qq|
		   SELECT *
		     FROM business
		 ORDER BY 2|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_business} }, $ref;
    }

    $sth->finish;

    # employees/salespersons
    $form->all_employees( $myconfig, $dbh, undef,
        ( $form->{vc} eq 'customer' )
        ? 1
        : 0 );

# get language ## needs fixing, this is bad (SELECT * ...) with order by 2. Yuck
    $query = qq|
		  SELECT *
		    FROM language
		ORDER BY 2|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_language} }, $ref;
    }

    $sth->finish;

# get pricegroups ## needs fixing, this is bad (SELECT * ...) with order by 2. Yuck
    $query = qq|
		  SELECT *
		    FROM pricegroup
		ORDER BY 2|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_pricegroup} }, $ref;
    }

    $sth->finish;

    # get currencies
    $query = qq|
		SELECT value AS currencies
		  FROM defaults
		  WHERE setting_key = 'curr'|;

    ( $form->{currencies} ) = $dbh->selectrow_array($query);

    $dbh->commit;

}

sub save_customer {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $query;
    my $sth;
    my $null;

    $form->{customernumber} =
      $form->update_defaults( $myconfig, "customernumber", $dbh )
      if !$form->{customernumber};
    # remove double spaces
    $form->{name} =~ s/  / /g;

    # remove double minus and minus at the end
    $form->{name} =~ s/--+/-/g;
    $form->{name} =~ s/-+$//;

    # assign value discount, terms, creditlimit
    $form->{discount} = $form->parse_amount( $myconfig, $form->{discount} );
    $form->{discount} /= 100;
    $form->{terms}       *= 1;
    $form->{taxincluded} *= 1;
    $form->{creditlimit} =
      $form->parse_amount( $myconfig, $form->{creditlimit} );
    if ( !$form->{creditlimit} ) {
        $form->{creditlimit} = 0;
    }

    if ( $form->{id} ) {
        $query = qq|
			DELETE FROM customertax
			 WHERE customer_id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $query = qq|
			DELETE FROM shipto
			 WHERE trans_id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $query = qq|
			SELECT id 
			  FROM customer
			 WHERE id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        if ( !$sth->fetchrow_array ) {
            $query = qq|
				INSERT INTO customer (id)
				     VALUES (?)|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);
        }

        # retrieve enddate
        if ( $form->{type} && $form->{enddate} ) {
            my $now;
            $query = qq|
				SELECT enddate, current_date AS now 
				  FROM customer|;
            ( $form->{enddate}, $now ) = $dbh->selectrow_array($query);
            $form->{enddate} = $now if $form->{enddate} lt $now;
        }

    }
    else {
        my $uid = localtime;
        $uid .= "$$";

        $query = qq|INSERT INTO customer (name)
					VALUES ('$uid')|;

        $dbh->do($query) || $form->dberror($query);

        $query = qq|SELECT id 
					  FROM customer
					 WHERE name = '$uid'|;

        ( $form->{id} ) = $dbh->selectrow_array($query);

    }

    my $employee_id;
    ( $null, $employee_id ) = split /--/, $form->{employee};
    $employee_id *= 1;

    my $pricegroup_id;
    ( $null, $pricegroup_id ) = split /--/, $form->{pricegroup};
    $pricegroup_id *= 1;

    my $business_id;
    ( $null, $business_id ) = split /--/, $form->{business};
    $business_id *= 1;

    my $language_code;
    ( $null, $language_code ) = split /--/, $form->{language};


    $query = qq|
		UPDATE customer 
		   SET customernumber = ?,
		       name = ?,
		       address1 = ?,
		       address2 = ?,
		       city = ?,
		       state = ?,
		       zipcode = ?,
		       country = ?,
		       contact = ?,
		       phone = ?,
		       fax = ?,
		       email = ?,
		       cc = ?,
		       bcc = ?,
		       notes = ?,
		       discount = ?,
		       creditlimit = ?,
		       terms = ?,
		       taxincluded = ?,
		       business_id = ?,
		       taxnumber = ?,
		       sic_code = ?,
		       iban = ?,
		       bic = ?,
		       employee_id = ?,
		       pricegroup_id = ?,
		       language_code = ?,
		       curr = ?,
		       startdate = ?,
		       enddate = ?
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    if ( !$form->{startdate} ) {
        undef $form->{startdate};
    }
    if ( !$form->{enddate} ) {
        undef $form->{enddate};
    }
    $sth->execute(
        $form->{customernumber}, $form->{name},        $form->{address1},
        $form->{address2},       $form->{city},        $form->{state},
        $form->{zipcode},        $form->{country},     $form->{contact},
        $form->{phone},          $form->{fax},         $form->{email},
        $form->{cc},             $form->{bcc},         $form->{notes},
        $form->{discount},       $form->{creditlimit}, $form->{terms},
        $form->{taxincluded},    $business_id,         $form->{taxnumber},
        $form->{sic_code},       $form->{iban},        $form->{bic},
        $employee_id,            $pricegroup_id,       $language_code,
        $form->{curr},           $form->{startdate},   $form->{enddate},
        $form->{id}
    ) || $form->dberror($query);

    # save taxes
    foreach $item ( split / /, $form->{taxaccounts} ) {

        if ( $form->{"tax_$item"} ) {
            $query = qq|
				INSERT INTO customertax (customer_id, chart_id)
				     VALUES (?, (SELECT id
				                   FROM chart
				                  WHERE accno = ?))|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id}, $item )
              || $form->dberror($query);
        }
    }

    # add shipto
    $form->add_shipto( $dbh, $form->{id} );

    $dbh->commit;
}

sub save_vendor {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    $form->{vendornumber} =
      $form->update_defaults( $myconfig, "vendornumber", $dbh )
      if !$form->{vendornumber};

    my $query;
    my $sth;
    my $null;

    # remove double spaces
    $form->{name} =~ s/  / /g;

    # remove double minus and minus at the end
    $form->{name} =~ s/--+/-/g;
    $form->{name} =~ s/-+$//;

    $form->{discount} = $form->parse_amount( $myconfig, $form->{discount} );
    $form->{discount} /= 100;
    $form->{terms}       *= 1;
    $form->{taxincluded} *= 1;
    $form->{creditlimit} =
      $form->parse_amount( $myconfig, $form->{creditlimit} );

    if ( $form->{id} ) {
        $query = qq|DELETE FROM vendortax
					 WHERE vendor_id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $query = qq|DELETE FROM shipto
					 WHERE trans_id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        $query = qq|SELECT id 
					  FROM vendor
					 WHERE id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        if ( !$sth->fetchrow_array ) {
            $query = qq|INSERT INTO vendor (id)
						VALUES (?)|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id} ) || $form->dberror($query);
        }

        # retrieve enddate
        if ( $form->{type} && $form->{enddate} ) {
            my $now;
            $query = qq|SELECT enddate, current_date AS now FROM vendor|;
            ( $form->{enddate}, $now ) = $dbh->selectrow_array($query);
            $form->{enddate} = $now if $form->{enddate} lt $now;
        }

    }
    else {
        my $uid = localtime;
        $uid .= "$$";

        $query = qq|INSERT INTO vendor (name)
					VALUES ('$uid')|;

        $dbh->do($query) || $form->dberror($query);

        $query = qq|SELECT id 
					  FROM vendor
					 WHERE name = '$uid'|;

        ( $form->{id} ) = $dbh->selectrow_array($query);

    }

    my $employee_id;
    ( $null, $employee_id ) = split /--/, $form->{employee};
    $employee_id *= 1;

    my $pricegroup_id;
    ( $null, $pricegroup_id ) = split /--/, $form->{pricegroup};
    $pricegroup_id *= 1;

    my $business_id;
    ( $null, $business_id ) = split /--/, $form->{business};
    $business_id *= 1;

    my $language_code;
    ( $null, $language_code ) = split /--/, $form->{language};


    $form->{startdate} = undef unless $form->{startdate};
    $form->{enddate}   = undef unless $form->{enddate};

    $query = qq|
		UPDATE vendor 
		   SET vendornumber = ?,
		       name = ?,
		       address1 = ?,
		       address2 = ?,
		       city = ?,
		       state = ?,
		       zipcode = ?,
		       country = ?,
		       contact = ?,
		       phone = ?,
		       fax = ?,
		       email = ?,
		       cc = ?,
		       bcc = ?,
		       notes = ?,
		       discount = ?,
		       creditlimit = ?,
		       terms = ?,
		       taxincluded = ?,
		       gifi_accno = ?,
		       business_id = ?,
		       taxnumber = ?,
		       sic_code = ?,
		       iban = ?,
		       bic = ?,
		       employee_id = ?,
		       language_code = ?,
		       pricegroup_id = ?,
		       curr = ?,
		       startdate = ?,
		       enddate = ?
       	 	 WHERE id = ?|;

    $sth = $dbh->prepare($query);

    $sth->execute(
        $form->{vendornumber}, $form->{name},        $form->{address1},
        $form->{address2},     $form->{city},        $form->{state},
        $form->{zipcode},      $form->{country},     $form->{contact},
        $form->{phone},        $form->{fax},         $form->{email},
        $form->{cc},           $form->{bcc},         $form->{notes},
        $form->{discount},     $form->{creditlimit}, $form->{terms},
        $form->{taxincluded},  $form->{gifi_accno},  $business_id,
        $form->{taxnumber},    $form->{sic_code},    $form->{iban},
        $form->{bic},          $employee_id,         $language_code,
        $pricegroup_id,        $form->{curr},        $form->{startdate},
        $form->{enddate},      $form->{id}
    ) || $form->dberror($query);

    # save taxes
    foreach $item ( split / /, $form->{taxaccounts} ) {
        if ( $form->{"tax_$item"} ) {
            $query = qq|
				INSERT INTO vendortax (vendor_id, chart_id)
				     VALUES (?, (SELECT id
				                   FROM chart
				                  WHERE accno = ?))|;

            $sth = $dbh->prepare($query);
            $sth->execute( $form->{id}, $item )
              || $form->dberror($query);
        }
    }

    # add shipto
    $form->add_shipto( $dbh, $form->{id} );

    $dbh->commit;

}

sub delete {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    # delete customer/vendor
    my $query = qq|DELETE FROM $form->{db}
					WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $dbh->commit;

}

sub search {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $where = "1 = 1";
    $form->{sort} = ( $form->{sort} ) ? $form->{sort} : "name";
    my @a         = qw(name);
    my $sortorder = $form->sort_order( \@a );

    my $var;
    my $item;

    @a = ("$form->{db}number");
    push @a, qw(name contact city state zipcode country notes phone email);

    if ( $form->{employee} ) {
        $var = $form->like( lc $form->{employee} );
        $where .= " AND lower(e.name) LIKE '$var'";
    }

    foreach $item (@a) {

        if ( $form->{$item} ne "" ) {
            $var = $form->like( lc $form->{$item} );
            $where .= " AND lower(ct.$item) LIKE '$var'";
        }
    }

    if ( $form->{address} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{address} ) );
        $where .=
" AND (lower(ct.address1) ILIKE $var)";
    }

    if ( $form->{startdatefrom} ) {
        $where .=
          " AND ct.startdate >= " . $dbh->quote( $form->{startdatefrom} );
    }

    if ( $form->{startdateto} ) {
        $where .= " AND ct.startdate <= " . $dbh->quote( $form->{startdateto} );
    }

    if ( $form->{status} eq 'active' ) {
        $where .= " AND ct.enddate IS NULL";
    }

    if ( $form->{status} eq 'inactive' ) {
        $where .= " AND ct.enddate <= current_date";
    }

    if ( $form->{status} eq 'orphaned' ) {
        $where .= qq| 
			AND ct.id NOT IN (SELECT o.$form->{db}_id
			                    FROM oe o, $form->{db} vc
			                   WHERE vc.id = o.$form->{db}_id)|;

        if ( $form->{db} eq 'customer' ) {
            $where .= qq| AND ct.id NOT IN (SELECT a.customer_id
											  FROM ar a, customer vc
											 WHERE vc.id = a.customer_id)|;
        }

        if ( $form->{db} eq 'vendor' ) {
            $where .= qq| AND ct.id NOT IN (SELECT a.vendor_id
											  FROM ap a, vendor vc
											 WHERE vc.id = a.vendor_id)|;
        }

        $form->{l_invnumber} = $form->{l_ordnumber} = $form->{l_quonumber} = "";
    }

    my $query = qq|
		   SELECT ct.*, b.description AS business,
		          e.name AS employee, g.pricegroup, 
		          l.description AS language, m.name AS manager
		     FROM $form->{db} ct
		LEFT JOIN business b ON (ct.business_id = b.id)
		LEFT JOIN employee e ON (ct.employee_id = e.id)
		LEFT JOIN employee m ON (m.id = e.managerid)
		LEFT JOIN pricegroup g ON (ct.pricegroup_id = g.id)
		LEFT JOIN language l ON (l.code = ct.language_code)
		    WHERE $where|;

    # redo for invoices, orders and quotations
    if (   $form->{l_transnumber}
        || $form->{l_invnumber}
        || $form->{l_ordnumber}
        || $form->{l_quonumber} )
    {

        my ( $ar, $union, $module );
        $query = "";
        my $transwhere;
        my $openarap = "";
        my $openoe   = "";

        if ( $form->{open} || $form->{closed} ) {
            unless ( $form->{open} && $form->{closed} ) {
                $openarap = " AND a.amount != a.paid"
                  if $form->{open};
                $openarap = " AND a.amount = a.paid"
                  if $form->{closed};
                $openoe = " AND o.closed = '0'"
                  if $form->{open};
                $openoe = " AND o.closed = '1'"
                  if $form->{closed};
            }
        }

        if ( $form->{l_transnumber} ) {

            $ar = ( $form->{db} eq 'customer' ) ? 'ar' : 'ap';
            $module = $ar;

            $transwhere = "";
            $transwhere .=
              " AND a.transdate >= " . $dbh->quote( $form->{transdatefrom} )
              if $form->{transdatefrom};
            $transwhere .=
              " AND a.transdate <= " . $dbh->quote( $form->{transdateto} )
              if $form->{transdateto};

            $query = qq|
				    SELECT ct.*, b.description AS business,
				           a.invnumber, a.ordnumber, 
				           a.quonumber, 
				           a.id AS invid, '$ar' AS module, 
				           'invoice' AS formtype, 
				           (a.amount = a.paid) AS closed, 
				           a.amount,
				           a.netamount, e.name AS employee, 
				           m.name AS manager
				      FROM $form->{db} ct
				      JOIN $ar a ON (a.$form->{db}_id = ct.id)
				 LEFT JOIN business b ON (ct.business_id = b.id)
				 LEFT JOIN employee e ON (a.employee_id = e.id)
				 LEFT JOIN employee m ON (m.id = e.managerid)
				     WHERE $where
				           AND a.invoice = '0'
				           $transwhere
				           $openarap |;

            $union = qq| UNION |;

        }

        if ( $form->{l_invnumber} ) {
            $ar     = ( $form->{db} eq 'customer' ) ? 'ar' : 'ap';
            $module = ( $ar         eq 'ar' )       ? 'is' : 'ir';

            $transwhere = "";
            $transwhere .=
              " AND a.transdate >= " . $dbh->quote( $form->{transdatefrom} )
              if $form->{transdatefrom};
            $transwhere .=
              " AND a.transdate <= " . $dbh->quote( $form->{transdateto} )
              if $form->{transdateto};

            $query .= qq|
				$union
				   SELECT ct.*, b.description AS business,
				          a.invnumber, a.ordnumber, a.quonumber,
				          a.id AS invid,
				          '$module' AS module, 
				          'invoice' AS formtype,
				          (a.amount = a.paid) AS closed, 
				          a.amount, a.netamount,
				          e.name AS employee, m.name AS manager
				     FROM $form->{db} ct
				     JOIN $ar a ON (a.$form->{db}_id = ct.id)
				LEFT JOIN business b ON (ct.business_id = b.id)
				LEFT JOIN employee e ON (a.employee_id = e.id)
				LEFT JOIN employee m ON (m.id = e.managerid)
				    WHERE $where
				          AND a.invoice = '1'
				          $transwhere
				          $openarap |;

            $union = qq| UNION|;

        }

        if ( $form->{l_ordnumber} ) {

            $transwhere = "";
            $transwhere .=
              " AND o.transdate >= " . $dbh->quote( $form->{transdatefrom} )
              if $form->{transdatefrom};
            $transwhere .=
              " AND o.transdate <= " . $dbh->quote( $form->{transdateto} )
              if $form->{transdateto};

            $query .= qq|
				$union
				   SELECT ct.*, b.description AS business,
				          ' ' AS invnumber, o.ordnumber, 
				          o.quonumber, o.id AS invid,
				          'oe' AS module, 'order' AS formtype,
				          o.closed, o.amount, o.netamount,
				          e.name AS employee, m.name AS manager
				     FROM $form->{db} ct
				     JOIN oe o ON (o.$form->{db}_id = ct.id)
				LEFT JOIN business b ON (ct.business_id = b.id)
				LEFT JOIN employee e ON (o.employee_id = e.id)
				LEFT JOIN employee m ON (m.id = e.managerid)
				    WHERE $where
				      AND o.quotation = '0'
				          $transwhere
				          $openoe |;

            $union = qq| UNION|;

        }

        if ( $form->{l_quonumber} ) {

            $transwhere = "";
            $transwhere .=
              " AND o.transdate >= " . $dbh->quote( $form->{transdatefrom} )
              if $form->{transdatefrom};
            $transwhere .=
              " AND o.transdate <= " . $dbh->quote( $form->{transdateto} )
              if $form->{transdateto};

            $query .= qq|
				$union
				   SELECT ct.*, b.description AS business,
				          ' ' AS invnumber, o.ordnumber, 
				          o.quonumber, o.id AS invid,
				          'oe' AS module, 
				          'quotation' AS formtype,
				          o.closed, o.amount, o.netamount,
				          e.name AS employee, m.name AS manager
				     FROM $form->{db} ct
				     JOIN oe o ON (o.$form->{db}_id = ct.id)
				LEFT JOIN business b ON (ct.business_id = b.id)
				LEFT JOIN employee e ON (o.employee_id = e.id)
				LEFT JOIN employee m ON (m.id = e.managerid)
				    WHERE $where
				          AND o.quotation = '1'
				          $transwhere
				          $openoe |;

        }

        $sortorder .= ", invid";
    }

    $query .= qq| ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # accounts
    $query = qq|
		SELECT c.accno
		  FROM chart c
		  JOIN $form->{db}tax t ON (t.chart_id = c.id)
		 WHERE t.$form->{db}_id = ?|;

    my $tth = $dbh->prepare($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $tth->execute( $ref->{id} );

        while ( ($item) = $tth->fetchrow_array ) {
            $ref->{taxaccount} .= "$item ";
        }

        $tth->finish;
        chop $ref->{taxaccount};

        $ref->{address} = "";

        for (qw(address1 address2 city state zipcode country)) {
            $ref->{address} .= "$ref->{$_} ";
        }
        push @{ $form->{CT} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

sub get_history {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query;
    my $where = "1 = 1";
    $form->{sort} = "partnumber" unless $form->{sort};
    my $sortorder = $form->{sort};
    my %ordinal   = ();
    my $var;
    my $table;

    # setup ASC or DESC
    $form->sort_order();

    if ( $form->{"$form->{db}number"} ne "" ) {
        $var = $dbh->( $form->like( lc $form->{"$form->{db}number"} ) );
        $where .= " AND lower(ct.$form->{db}number) LIKE $var";
    }

    if ( $form->{address} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{address} ) );
        $where .= " AND lower(ct.address1) LIKE $var";
    }

    for (qw(name contact email phone notes city state zipcode country)) {

        if ( $form->{$_} ne "" ) {
            $var = $dbh->quote( $form->like( lc $form->{$_} ) );
            $where .= " AND lower(ct.$_) LIKE $var";
        }
    }

    if ( $form->{employee} ne "" ) {
        $var = $form->like( lc $form->{employee} );
        $where .= " AND lower(e.name) LIKE '$var'";
    }

    $transwhere .=
      " AND a.transdate >= " . $dbh->quote( $form->{transdatefrom} )
      if $form->{transdatefrom};
    $transwhere .= " AND a.transdate <= " . $dbh->quote( $form->{transdateto} )
      if $form->{transdateto};

    if ( $form->{open} || $form->{closed} ) {

        unless ( $form->{open} && $form->{closed} ) {

            if ( $form->{type} eq 'invoice' ) {
                $where .= " AND a.amount != a.paid"
                  if $form->{open};
                $where .= " AND a.amount = a.paid"
                  if $form->{closed};
            }
            else {
                $where .= " AND a.closed = '0'"
                  if $form->{open};
                $where .= " AND a.closed = '1'"
                  if $form->{closed};
            }
        }
    }

    my $invnumber = 'invnumber';
    my $deldate   = 'deliverydate';
    my $buysell;
    my $sellprice = "sellprice";

    if ( $form->{db} eq 'customer' ) {
        $buysell = "buy";

        if ( $form->{type} eq 'invoice' ) {
            $where .= qq|
				AND a.invoice = '1' AND i.assemblyitem = '0'|;
            $table     = 'ar';
            $sellprice = "fxsellprice";
        }
        else {
            $table = 'oe';

            if ( $form->{type} eq 'order' ) {
                $invnumber = 'ordnumber';
                $where .= qq| AND a.quotation = '0'|;
            }
            else {
                $invnumber = 'quonumber';
                $where .= qq| AND a.quotation = '1'|;
            }

            $deldate = 'reqdate';
        }
    }

    if ( $form->{db} eq 'vendor' ) {

        $buysell = "sell";

        if ( $form->{type} eq 'invoice' ) {

            $where .= qq| AND a.invoice = '1' AND i.assemblyitem = '0'|;
            $table     = 'ap';
            $sellprice = "fxsellprice";

        }
        else {

            $table = 'oe';

            if ( $form->{type} eq 'order' ) {
                $invnumber = 'ordnumber';
                $where .= qq| AND a.quotation = '0'|;
            }
            else {
                $invnumber = 'quonumber';
                $where .= qq| AND a.quotation = '1'|;
            }

            $deldate = 'reqdate';
        }
    }

    my $invjoin = qq| JOIN invoice i ON (i.trans_id = a.id)|;

    if ( $form->{type} eq 'order' ) {
        $invjoin = qq| JOIN orderitems i ON (i.trans_id = a.id)|;
    }

    if ( $form->{type} eq 'quotation' ) {
        $invjoin = qq| JOIN orderitems i ON (i.trans_id = a.id)|;
        $where .= qq| AND a.quotation = '1'|;
    }

    %ordinal = (
        partnumber    => 9,
        description   => 12,
        "$deldate"    => 16,
        serialnumber  => 17,
        projectnumber => 18
    );

    $sortorder =
      "2 $form->{direction}, 1, 11, $ordinal{$sortorder} $form->{direction}";

    $query = qq|
		  SELECT ct.id AS ctid, ct.name, ct.address1,
		         ct.address2, ct.city, ct.state,
		         p.id AS pid, p.partnumber, a.id AS invid,
		         a.$invnumber, a.curr, i.description,
		         i.qty, i.$sellprice AS sellprice, i.discount,
		         i.$deldate, i.serialnumber, pr.projectnumber,
		         e.name AS employee, ct.zipcode, ct.country, i.unit,
		         (SELECT $buysell 
			    FROM exchangerate ex
			   WHERE a.curr = ex.curr
		                 AND a.transdate = ex.transdate) AS exchangerate
		     FROM $form->{db} ct
		     JOIN $table a ON (a.$form->{db}_id = ct.id)
		          $invjoin
		     JOIN parts p ON (p.id = i.parts_id)
		LEFT JOIN project pr ON (pr.id = i.project_id)
		LEFT JOIN employee e ON (e.id = a.employee_id)
				 WHERE $where
			  ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $ref->{address} = "";
        $ref->{exchangerate} ||= 1;
        for (qw(address1 address2 city state zipcode country)) {
            $ref->{address} .= "$ref->{$_} ";
        }
        $ref->{id} = $ref->{ctid};
        push @{ $form->{CT} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

sub pricelist {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query;

    if ( $form->{db} eq 'customer' ) {
        $query = qq|SELECT p.id, p.partnumber, p.description,
						   p.sellprice, pg.partsgroup, p.partsgroup_id,
						   m.pricebreak, m.sellprice,
						   m.validfrom, m.validto, m.curr
					  FROM partscustomer m
					  JOIN parts p ON (p.id = m.parts_id)
				 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
					 WHERE m.customer_id = ?
				  ORDER BY partnumber|;
    }

    if ( $form->{db} eq 'vendor' ) {
        $query = qq|SELECT p.id, p.partnumber AS sku, p.description,
						   pg.partsgroup, p.partsgroup_id,
						   m.partnumber, m.leadtime, m.lastcost, m.curr
					  FROM partsvendor m
					  JOIN parts p ON (p.id = m.parts_id)
				 LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
					 WHERE m.vendor_id = ?
				  ORDER BY p.partnumber|;
    }

    my $sth;
    my $ref;

    if ( $form->{id} ) {

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);

        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            push @{ $form->{all_partspricelist} }, $ref;
        }

        $sth->finish;
    }

    $query = qq|SELECT value FROM defaults where setting_key = 'curr'|;
    ( $form->{currencies} ) = $dbh->selectrow_array($query);

    $query = qq|SELECT id, partsgroup 
				  FROM partsgroup
			  ORDER BY partsgroup|;

    $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);

    $form->{all_partsgroup} = ();

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{all_partsgroup} }, $ref;
    }

    $sth->finish;

    $dbh->commit;

}

sub save_pricelist {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};
    my $query = qq|
		DELETE FROM parts$form->{db}
		 WHERE $form->{db}_id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    foreach $i ( 1 .. $form->{rowcount} ) {

        if ( $form->{"id_$i"} ) {

            if ( $form->{db} eq 'customer' ) {

                for (qw(pricebreak sellprice)) {
                    $form->{"${_}_$i"} =
                      $form->parse_amount( $myconfig, $form->{"${_}_$i"} );
                }

                $query = qq|
					INSERT INTO parts$form->{db} 
					            (parts_id, customer_id,
					            pricebreak, sellprice, 
					            validfrom, validto, curr)
					     VALUES (?, ?, ?, ?, ?, ?, ?)|;
                @queryargs = (
                    $form->{"id_$i"},         $form->{id},
                    $form->{"pricebreak_$i"}, $form->{"sellprice_$i"},
                    $form->{"validfrom_$i"},  $form->{"validto_$i"},
                    $form->{"curr_$i"}
                );
            }
            else {

                for (qw(leadtime lastcost)) {
                    $form->{"${_}_$i"} =
                      $form->parse_amount( $myconfig, $form->{"${_}_$i"} );
                }

                $query = qq|
					INSERT INTO parts$form->{db} 
					            (parts_id, vendor_id,
					            partnumber, lastcost, 
					            leadtime, curr)
					     VALUES (?, ?, ?, ?, ?, ?)|;
                @queryargs = (
                    $form->{"id_$i"},         $form->{id},
                    $form->{"partnumber_$i"}, $form->{"lastcost_$i"},
                    $form->{"leadtime_$i"},   $form->{"curr_$i"}
                );

            }
            $sth = $dbh->prepare($query);
            $sth->execute(@queryargs) || $form->dberror($query);
        }

    }

    $_ = $dbh->commit;

}

sub retrieve_item {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $i = $form->{rowcount};
    my $var;
    my $null;

    my $where = "WHERE p.obsolete = '0'";

    if ( $form->{db} eq 'vendor' ) {

        # parts, services, labor
        $where .= " AND p.assembly = '0'";
    }

    if ( $form->{db} eq 'customer' ) {

        # parts, assemblies, services
        $where .= " AND p.income_accno_id > 0";
    }

    if ( $form->{"partnumber_$i"} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{"partnumber_$i"} ) );
        $where .= " AND lower(p.partnumber) LIKE $var";
    }

    if ( $form->{"description_$i"} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{"description_$i"} ) );
        $where .= " AND lower(p.description) LIKE $var";
    }

    if ( $form->{"partsgroup_$i"} ne "" ) {
        ( $null, $var ) = split /--/, $form->{"partsgroup_$i"};
        $var = $dbh->quote($var);
        $where .= qq| AND p.partsgroup_id = $var|;
    }

    my $query = qq|
		   SELECT p.id, p.partnumber, p.description, p.sellprice,
		          p.lastcost, p.unit, pg.partsgroup, p.partsgroup_id
		     FROM parts p
		LEFT JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
		          $where
		 ORDER BY partnumber|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    my $ref;
    $form->{item_list} = ();

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{item_list} }, $ref;
    }

    $sth->finish;
    $dbh->commit;
}

1;

