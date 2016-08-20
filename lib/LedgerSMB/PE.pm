# SLATED TO BE GREATLY REDUCED IN 1.4

=head1 NAME

LedgerSMB::PE - Support functions for projects, partsgroups, and parts

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

    $query = qq|DELETE FROM translation_partsgroup WHERE trans_id = ?|;
    $sth   = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

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
    my $dbh = $form->{dbh};
    my $sth = $dbh->prepare("select * from partsgroup__search(null)");
    $sth->execute;

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
        $form->{parent}  = undef unless $form->{parent};
        $query = qq|
            INSERT INTO partsgroup (partsgroup, parent)
                 VALUES (?, ?)|;
        push @group, $form->{parent};
    }
    $dbh->do($query, undef, @group) || $form->dberror($query);

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
            FROM parts_translation t
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
            FROM partsgroup_translation t
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
            FROM business_unit_translation t
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

    my %tables = (
        partsgroup => 'partsgroup_translation',
        description => 'parts_translation'
    );

    my $table = $tables{$form->{translation}};

    # table is whitelisted below, so safe.
    my $query = qq|DELETE FROM $table WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    $query = qq|
        INSERT INTO $table (trans_id, language_code, description)
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
}

=item PE::delete_translation("", $myconfig, $form);

Deletes all translation entries that have the trans_id of $form->{id}.

$myconfig is unused.

=cut

sub delete_translation {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my %tables = (
        partsgroup => 'partsgroup_translation',
        description => 'parts_translation'
    );

    my $table = $tables{$form->{translation}};

    # table is whitelisted below, so safe.
    my $query = qq|DELETE FROM $table WHERE trans_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

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
    $sth->execute( $form->{customer_id} );# || $form->dberror($query);
    my ($curr) = $sth->fetchrow_array;# || $form->dberror($query);
    $form->{currency} = $curr;
    $curr || $form->error('No currency found');
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

    $form->all_business_units( $transdate, undef, 'Timecards');
    $form->{all_project} = $form->{b_units}->{2};

    $form->all_employees( $myconfig, $dbh, $transdate );

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
        $where .= " AND j.business_unit_id = $var";
    }

    if ( $form->{employee} ) {
        ( $null, $var ) = split /--/, $form->{employee};
        $var = $dbh->quote($var);
        $where .= " AND j.person_id = $var";
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
                  j.business_unit_id as project_id,
                          j.checkedin::date AS transdate,
                  j.notes, c.legal_name AS customer,
                          pr.description as projectnumber,
                  p.partnumber
             FROM jcitems j
             JOIN business_unit pr ON (pr.id = j.business_unit_id)
             JOIN parts p ON (p.id = j.parts_id)
        LEFT JOIN entity_credit_account eca ON (eca.id = pr.credit_id)
                LEFT JOIN company c ON eca.entity_id = c.entity_id
            WHERE j.allocated != j.qty $where
         ORDER BY pr.description, c.legal_name, j.checkedin::date|;
    if ( $form->{summary} ) {
        $query =~ s/j\.description/p\.description/;
        $query =~ s/c\.name,/c\.name, j\.parts_id, /;
    }

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    # tax accounts
    $query = qq|
        SELECT c.accno
          FROM account c
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
          JOIN account c ON (c.id = t.chart_id)|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{taxaccounts} .= "$ref->{accno} ";
        $form->{"$ref->{accno}_rate"} = $ref->{rate};
    }
    chop $form->{taxaccounts};
    $sth->finish;

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

}

1;

=back

