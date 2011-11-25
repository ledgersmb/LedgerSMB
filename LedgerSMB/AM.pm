
=head1 NAME

AM

=head1 SYNOPSIS

This module provides some administrative functions

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
 # Copyright (C) 2000
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 #  Contributors: Jim Rawlings <jim@your-dba.com>
 #
 #====================================================================
 #
 # This file has undergone whitespace cleanup.
 #
 #====================================================================
 #
 # Administration module
 #    Chart of Accounts
 #    template routines
 #    preferences
 #
 #====================================================================

=head1 METHODS

=over

=cut

package AM;
use LedgerSMB::Tax;
use LedgerSMB::Sysconfig;

=item AM->get_account($myconfig, $form);

Populates the $form attributes accno, description, charttype, gifi_accno,
category, link, and contra with details about the account that has the id
$form->{id}.  If there are no acc_trans entries that refer to that account,
$form->{orphaned} is made true, otherwise $form->{orphaned} is set to false.

Also populates 'inventory_accno_id', 'income_accno_id', 'expense_accno_id',
'fxgain_accno_id', and 'fxloss_accno_id' with the values from defaults.

$myconfig is unused.

=cut

sub get_account {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|
		SELECT accno, description, charttype, gifi_accno,
		       category, link, contra
		  FROM chart
		 WHERE id = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # get default accounts
    $query = qq|
		SELECT (SELECT value FROM defaults
		         WHERE setting_key = 'inventory_accno_id')
		       AS inventory_accno_id,
		       (SELECT value FROM defaults
		         WHERE setting_key = 'income_accno_id')
		       AS income_accno_id, 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'expense_accno_id')
		       AS expense_accno_id,
		       (SELECT value FROM defaults
		         WHERE setting_key = 'fxgain_accno_id')
		       AS fxgain_accno_id, 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'fxloss_accno_id')
		       AS fxloss_accno_id|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    # check if we have any transactions
    $query = qq|
		SELECT trans_id 
		  FROM acc_trans
		 WHERE chart_id = ? 
		 LIMIT 1|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );
    ( $form->{orphaned} ) = $sth->fetchrow_array();
    $form->{orphaned} = !$form->{orphaned};

    $dbh->commit;
}

=item AM->delete_account($myconfig, $form);

Deletes the account with the id $form->{id}.  Calls $form->error if there are
any acc_trans entries that reference it.  If any parts have that account for
an inventory, income, or COGS (expense) account, switch the part to using the
default account for that type.  Also deletes all tax, partstax, customertax, and
vendortax table entries for the account.

$myconfig is unused.

=cut

sub delete_account {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database, turn off AutoCommit
    my $dbh = $form->{dbh};
    my $sth;
    my $query = qq|
		SELECT count(*)
		  FROM acc_trans
		 WHERE chart_id = ?|;
    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );
    my ($rowcount) = $sth->fetchrow_array();

    if ($rowcount) {
        $form->error( "Cannot delete accounts with associated transactions!" );
    }

    # delete chart of account record
    $query = qq|
		DELETE FROM chart
		      WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    # set inventory_accno_id, income_accno_id, expense_accno_id to defaults
    $query = qq|
		UPDATE parts
		   SET inventory_accno_id = (SELECT value::int
		                               FROM defaults
					      WHERE setting_key = 
							'inventory_accno_id')
		 WHERE inventory_accno_id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);

    for (qw(income_accno_id expense_accno_id)) {
        $query = qq|
			UPDATE parts
			   SET $_ = (SELECT value::int
			               FROM defaults
			              WHERE setting_key = '$_')
			 WHERE $_ = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);
        $sth->finish;
    }

    foreach my $table (qw(partstax customertax vendortax tax)) {
        $query = qq|
			DELETE FROM $table
			      WHERE chart_id = ?|;

        $sth = $dbh->prepare($query);
        $sth->execute( $form->{id} ) || $form->dberror($query);
        $sth->finish;
    }

    # commit and redirect
    my $rc = $dbh->commit;

    $rc;
}

=item AM->gifi_accounts($myconfig, $form);

Populates the list referred to as $form->{ALL} with hashes of gifi numbers and
descriptions in order of the GIFI number.  The GIFI number referred to as
'accno'.

$myconfig is not used.

=cut

sub gifi_accounts {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
		  SELECT accno, description
		    FROM gifi
		ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{ALL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

=item AM->get_gifi($myconfig, $form);

Sets $form->{description} to the description of the GIFI number $form->{accno}.
Sets $form->{orphaned} to true if there are no entries in acc_trans that refer
to this GIFI and to false otherwise.

$myconfig is not used.

=cut

sub get_gifi {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $sth;

    my $query = qq|
		SELECT accno, description
		  FROM gifi
		 WHERE accno = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{accno} ) || $form->dberror($query);
    ( $form->{accno}, $form->{description} ) = $sth->fetchrow_array();

    $sth->finish;

    # check for transactions
    $query = qq|
		SELECT count(*) 
		  FROM acc_trans a
		  JOIN chart c ON (a.chart_id = c.id)
		  JOIN gifi g ON (c.gifi_accno = g.accno)
		 WHERE g.accno = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{accno} ) || $form->dberror($query);
    ($numrows) = $sth->fetchrow_array;
    if ( ( $numrows * 1 ) == 0 ) {
        $form->{orphaned} = 1;
    }
    else {
        $form->{orphaned} = 0;
    }

    $dbh->commit;

}

=item AM->save_gifi($myconfig, $form);

Adds or updates a GIFI record.  If $form->{id} is set, update the gifi record
that has that as an account number.  The new values for an added or updated
record are stored in $form->{accno} and $form->{description}.

$myconfig is not used.

=cut

sub save_gifi {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $form->{accno} =~ s/( |')//g;

    foreach my $item (qw(accno description)) {
        $form->{$item} =~ s/-(-+)/-/g;
        $form->{$item} =~ s/ ( )+/ /g;
    }

    my @queryargs = ( $form->{accno}, $form->{description} );

    # id is the old account number!
    if ( $form->{id} ) {
        $query = qq|
			UPDATE gifi 
			   SET accno = ?,
			       description = ?
			 WHERE accno = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
			INSERT INTO gifi (accno, description)
			     VALUES (?, ?)|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    $sth->finish;
    $dbh->commit;

}

=item AM->delete_gifi($myconfig, $form);

Deletes the gifi record with the GIFI number $form->{id}.

$myconfig is not used.

=cut

sub delete_gifi {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    # id is the old account number!
    $query = qq|
		DELETE FROM gifi
		      WHERE accno = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);
    $sth->finish;
    $dbh->commit;

}

=item AM->warehouses($myconfig, $form);

Populates the list referred to as $form->{ALL} with hashes describing
warehouses, ordered according to the logic of $form->sort_order.  Each hash has
an id and a description element.

$myconfig is not used.

=cut

sub warehouses {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->sort_order();
    my $query = qq|
		  SELECT id, description
		    FROM warehouse
		ORDER BY description $form->{direction}|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{ALL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

=item AM->get_warehouse($myconfig, $form);

Sets $form->{description} to the name of the warehouse $form->{id}.  If no
inventory is currently linked to the warehouse, set $form->{orphaned} to true,
otherwise $form->{orphaned} is false.

$myconfig is not used.

=cut

sub get_warehouse {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $sth;

    my $query = qq|
		SELECT description
		  FROM warehouse
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} ) || $form->dberror($query);
    ( $form->{description} ) = $sth->fetchrow_array;
    $sth->finish;

    # see if it is in use
    $query = qq|
		SELECT count(*) 
		  FROM inventory
		 WHERE warehouse_id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );

    ( $form->{orphaned} ) = $sth->fetchrow_array;
    if ( ( $form->{orphaned} * 1 ) == 0 ) {
        $form->{orphaned} = 1;
    }
    else {
        $form->{orphaned} = 0;
    }

    $dbh->commit;
}

=item AM->save_warehouse($myconfig, $form);

Add or update a warehouse.  If $form->{id} is set, that warehouse is updated
instead of adding a new warehouse.  In both cases, the description of the
warehouse is set to $form->{description}.

$myconfig is not used.

=cut

sub save_warehouse {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $sth;
    my @queryargs = ( $form->{description} );

    $form->{description} =~ s/-(-)+/-/g;
    $form->{description} =~ s/ ( )+/ /g;

    if ( $form->{id} ) {
        $query = qq|
			UPDATE warehouse 
			   SET description = ?
			 WHERE id = ?|;
        push @queryargs, $form->{id};
    }
    else {
        $query = qq|
			INSERT INTO warehouse (description)
			     VALUES (?)|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    $sth->finish;
    $dbh->commit;

}

=item AM->delete_warehouse($myconfig, $form);

Deletes the warehouse with the id $form->{id}.

$myconfig is not used.

=cut

sub delete_warehouse {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
		DELETE FROM warehouse
		      WHERE id = ?|;

    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);
    $dbh->commit;

}

=item AM->departments($myconfig, $form);

Populate the list referred to as $form->{ALL} with hashes of details about
departments.  The hashes all contain the id, description, and role of the
department and are ordered by the description.

$myconfig is unused.

=cut

sub departments {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->sort_order();
    my $query = qq|SELECT id, description, role
					 FROM department
				 ORDER BY description $form->{direction}|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{ALL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

=item AM->get_department($myconfig, $form);

Fills $form->{description} and $form->{role} with details about the department
with the id value of $form->{id}.  If the department has not been used as part
of a transaction referred to in dpt_trans, set $form->{orphaned} to true, 
otherwise it is set to false.

$myconfig is unused.

=cut

sub get_department {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};
    my $sth;

    my $query = qq|
		SELECT description, role
		  FROM department
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );
    ( $form->{description}, $form->{role} ) = $sth->fetchrow_array;
    $sth->finish;

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    # see if it is in use
    $query = qq|
		SELECT count(*) 
		  FROM dpt_trans
		 WHERE department_id = ? |;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );
    ( $form->{orphaned} ) = $sth->fetchrow_array;
    if ( ( $form->{orphaned} * 1 ) == 0 ) {
        $form->{orphaned} = 1;
    }
    else {
        $form->{orphaned} = 0;
    }

    $dbh->commit;
}

=item AM->save_department($myconfig, $form);

Add or update a department record.  If $form->{id} is set, the department with
that id is updated, otherwise a new department is added.  The department role
(either 'C' for cost centres or 'P' for profit centres) and description is
taken from the $form attributes 'role' and 'description'.

$myconfig is unused.

=cut

sub save_department {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{description} =~ s/-(-)+/-/g;
    $form->{description} =~ s/ ( )+/ /g;
    my $sth;
    my @queryargs = ( $form->{description}, $form->{role} );
    if ( $form->{id} ) {
        $query = qq|
			UPDATE department 
			   SET description = ?,
			       role = ?
			 WHERE id = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
			INSERT INTO department (description, role)
			     VALUES (?, ?)|;
    }

    $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    $dbh->commit;

}

=item AM->delete_department($myconfig, $form)

Deletes the department with an id of $form->{id}.

$myconfig is unused.

=cut

sub delete_department {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
		DELETE FROM department
		      WHERE id = ?|;

    $dbh->prepare($query)->execute( $form->{id} );
    $dbh->commit;

}

=item AM->business($myconfig, $form);

Populates the list referred to as $form->{ALL} with hashes containing details
about all known types of business.  Each hash contains the id, description, and
discount for businesses of this type.  The discount is represented in numeric
form, such that a 10% discount is stored and retrieved as 0.1.  The hashes are
sorted by the business description.

$myconfig is unused.

=cut

sub business {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->sort_order();
    my $query = qq|
		  SELECT id, description, discount
		    FROM business
		ORDER BY description $form->{direction}|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{ALL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

=item AM->get_business($myconfig, $form);

Places the description and discount for the business with an id of $form->{id}
into $form->{description} and $form->{discount}.

$myconfig is unused.

=cut

sub get_business {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
		SELECT description, discount
		  FROM business
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute( $form->{id} );
    ( $form->{description}, $form->{discount} ) = $sth->fetchrow_array();
    $dbh->commit;

}

=item AM->save_business($myconfig, $form);

Adds or updates a type of business.  If $form->{id} is set, the business type
with a corresponding id is updated, otherwise a new type is added.  The new
description is $form->{description}.  The discount taken as a percentage stored
in $form->{discount}, which then value is divided by 100 in place and the
multiplier is stored.  As an example, if $form->{discount} is 10 when this
function is called, it is changed to 0.1 and stored as 0.1.

$myconfig is unused.

=cut

sub save_business {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{description} =~ s/-(-)+/-/g;
    $form->{description} =~ s/ ( )+/ /g;
    $form->{discount} /= 100;

    my $sth;
    my @queryargs = ( $form->{description}, $form->{discount} );

    if ( $form->{id} ) {
        $query = qq|
			UPDATE business 
			   SET description = ?,
			       discount = ?
			 WHERE id = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|INSERT INTO business (description, discount)
						 VALUES (?, ?)|;
    }

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
    if (!$form->{id}){
        my $sth = $dbh->prepare("SELECT currval('business_id_seq')");
        $sth->execute();
        ($form->{id}) = $sth->fetchrow_array;
    }
    $dbh->commit;

}

=item AM->delete_business($myconfig, $form);

Deletes the business type with the id $form->{id}.

$myconfig is unused.

=cut

sub delete_business {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
		DELETE FROM business
		      WHERE id = ?|;

    $dbh->prepare($query)->execute( $form->{id} ) || $form->dberror($query);
    $dbh->commit;

}

=item AM->sic($myconfig, $form);

Populate the list referred to as $form->{ALL} with hashes containing SIC (some
well known systems of which are NAICS and ISIC) data from the sic table.  code
is the actual SIC code, description is a textual description of the code, and
sictype is an indicator of whether or not the entry refers to a header.  The
hashes will be sorted by either the code or description.

$myconfig is unused.

=cut

sub sic {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{sort} = "code" unless $form->{sort};
    my @a = qw(code description);

    my %ordinal = (
        code        => 1,
        description => 3
    );

    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|SELECT code, sictype, description
					 FROM sic
				 ORDER BY $sortorder|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{ALL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

=item AM->get_sic($myconfig, $form);

Retrieves the sictype and description for the SIC indicated by
$form->{code} and places the retrieved values into $form->{sictype} and
$form->{description}.

$myconfig is unused

=cut

sub get_sic {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
		SELECT code, sictype, description
		  FROM sic
		 WHERE code = | . $dbh->quote( $form->{code} );

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;
    $dbh->commit;

}

=item AM->save_sic($myconfig, $form);

Add or update a SIC entry.  If $form->{id} is set, take it as the original code
to identify the entry update, otherwise treat it as a new entry.  $form->{code},
$form->{description}, and $form->{sictype} contain the new values.  sictype is
a single character to flag whether or not the entry is for a header ('H').

$myconfig is unused.

=cut

sub save_sic {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    foreach my $item (qw(code description)) {
        $form->{$item} =~ s/-(-)+/-/g;
    }
    my $sth;
    @queryargs = ( $form->{code}, $form->{sictype}, $form->{description} );

    # if there is an id
    if ( $form->{id} ) {
        $query = qq|
			UPDATE sic 
			   SET code = ?,
			       sictype = ?,
			       description = ?
			 WHERE code = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
		INSERT INTO sic (code, sictype, description)
		     VALUES (?, ?, ?)|;

    }

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
    $dbh->commit;

}

=item AM->delete_sic($myconfig, $form);

Deletes the SIC entry with the code $form->{code}.

$myconfig is unused.

=cut

sub delete_sic {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    $query = qq|
		DELETE FROM sic
		      WHERE code = ?|;

    $dbh->prepare($query)->execute( $form->{code} );
    $dbh->commit;

}

=item AM->language($myconfig, $form);

Populates the list referred to as $form->{ALL} with hashes containing the code
and description of all languages entered in the language table.  The usual set
of $form attributes affect the order in which the hashes are entered in the
list.

These language functions are unrelated to LedgerSMB::Locale, although these
language codes are also used for non-UI templates and by LedgerSMB::PE.

$myconfig is unused.

=cut

sub language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{sort} = "code" unless $form->{sort};
    my @a = qw(code description);

    my %ordinal = (
        code        => 1,
        description => 2
    );

    my $sortorder = $form->sort_order( \@a, \%ordinal );

    my $query = qq|
		  SELECT code, description
		    FROM language
		ORDER BY $sortorder|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{ALL} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

=item AM->get_language($myconfig, $form);

Sets $form->{description} to the description of the language that has the code
$form->{code}.

$myconfig is unused.

=cut

sub get_language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
		SELECT code, description
		  FROM language
		 WHERE code = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $form->{code} ) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);

    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }

    $sth->finish;
    $dbh->commit;

}

=item AM->save_language($myconfig, $form);

Add or update a language entry.  If $form->{id} is set, the language entry that
has that as a code is updated, otherwise a new entry is added.  $form->{code}
and $form->{description} contain the new values for the entry.

$myconfig is unused.

=cut

sub save_language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $form->{code} =~ s/ //g;

    foreach my $item (qw(code description)) {
        $form->{$item} =~ s/-(-)+/-/g;
        $form->{$item} =~ s/ ( )+/-/g;
    }
    my $sth;
    my @queryargs = ( $form->{code}, $form->{description} );

    # if there is an id
    if ( $form->{id} ) {
        $query = qq|
			UPDATE language 
			   SET code = ?,
			       description = ?
			 WHERE code = ?|;
        push @queryargs, $form->{id};

    }
    else {
        $query = qq|
			INSERT INTO language (code, description)
			     VALUES (?, ?)|;
    }

    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);
    $dbh->commit;

}

=item AM->delete_language($myconfig, $form);

Deletes the language entry with the code $form->{code}.

$myconfig is unused.

=cut

sub delete_language {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    $query = qq|
		DELETE FROM language
		      WHERE code = | . $dbh->quote( $form->{code} );

    $dbh->do($query) || $form->dberror($query);

}

=item AM->recurring_transactions($myconfig, $form);

Populates lists referred to in the form of $form->{transactions}{$type}, where
the possible values for $type are 'ar', 'ap', 'gl', 'so', and 'po', with hashes
containing details about recurring transactions of the $type variety.  These
hashes have the fields module (the frontend script that governs the transaction
type), transaction (the transaction type), invoice (true if the transaction is
an invoice), description (a field that is a customer, vendor, or in the case of
a GL transaction, an arbitrary text field), amount (the cash value of the
transaction), id (the id of the recurring transaction), reference (the
reference value for the transaction), startdate (the date the recurring
sequence started), nextdate (the date of the next occurrence of the event),
enddate (the date the sequence ends), repeat (the number of units involved in
the recurrence frequency), unit (the base recurrence unit), howmany (how many
times the event occurs), payment (whether or not the event involves a payment),
recurringemail (a colon separated list of forms to email as part of the event),
recurringprint (a colon separated list of forms to print as part of the event),
overdue (how many days until the next repetition of the event), vc (vendor,
customer, or empty), exchangerate (the exchangerate involved on the day of the
original transaction), curr (the currency of the event), and expired (if there
will be no more recurrences).

By default, these lists are sorted in order of the date of the next occurrence
of the transaction.  This order can be affected by the usual attributes used
by $form->sort_order.

$myconfig is unused.

=cut

sub recurring_transactions {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|SELECT value FROM defaults where setting_key = 'curr'|;

    my ($defaultcurrency) = $dbh->selectrow_array($query);
    $defaultcurrency = $dbh->quote( $defaultcurrency =~ s/:.*//g );

    $form->{sort} ||= "nextdate";
    my @a         = ( $form->{sort} );
    my $sortorder = $form->sort_order( \@a );

    $query = qq|
		   SELECT 'ar' AS module, 'ar' AS transaction, a.invoice,
		          e.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 
		          'customer' AS vc,
		          ex.buy AS exchangerate, a.curr,
	                  (s.nextdate IS NULL OR s.nextdate > s.enddate) 
                          AS expired
		     FROM recurring s
		     JOIN ar a ON (a.id = s.id)
                     JOIN entity_credit_account eca 
                          ON a.entity_credit_account = eca.id
		     JOIN entity e ON (eca.entity_id = e.id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex 
		          ON (ex.curr = a.curr AND a.transdate = ex.transdate)

		    UNION

		  SELECT 'ap' AS module, 'ap' AS transaction, a.invoice,
		          e.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 'vendor' AS vc,
		          ex.sell AS exchangerate, a.curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN ap a ON (a.id = s.id)
                     JOIN entity_credit_account eca 
                          ON a.entity_credit_account = eca.id
		     JOIN entity e ON (eca.entity_id = e.id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex ON 
		          (ex.curr = a.curr AND a.transdate = ex.transdate)

		    UNION

		   SELECT 'gl' AS module, 'gl' AS transaction, FALSE AS invoice,
		          a.description, (SELECT SUM(ac.amount) 
		     FROM acc_trans ac 
		    WHERE ac.trans_id = a.id 
		      AND ac.amount > 0) AS amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, '' AS vc,
		          '1' AS exchangerate, $defaultcurrency AS curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN gl a ON (a.id = s.id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)

		    UNION

		   SELECT 'oe' AS module, 'so' AS transaction, FALSE AS invoice,
		          e.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 
		          'customer' AS vc,
		          ex.buy AS exchangerate, a.curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN oe a ON (a.id = s.id)
		     JOIN entity e ON (a.entity_id = e.id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex ON 
		          (ex.curr = a.curr AND a.transdate = ex.transdate)
		    WHERE a.quotation = '0'

		    UNION

		   SELECT 'oe' AS module, 'po' AS transaction, FALSE AS invoice,
		          e.name AS description, a.amount,
		          s.*, se.formname AS recurringemail,
		          sp.formname AS recurringprint,
		          s.nextdate - current_date AS overdue, 'vendor' AS vc,
		          ex.sell AS exchangerate, a.curr,
		          (s.nextdate IS NULL OR s.nextdate > s.enddate) 
		          AS expired
		     FROM recurring s
		     JOIN oe a ON (a.id = s.id)
		     JOIN entity e ON (a.entity_id = e.id)
		LEFT JOIN recurringemail se ON (se.id = s.id)
		LEFT JOIN recurringprint sp ON (sp.id = s.id)
		LEFT JOIN exchangerate ex ON 
		          (ex.curr = a.curr AND a.transdate = ex.transdate)
		    WHERE a.quotation = '0'

		 ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $id;
    my $transaction;
    my %e = ();
    my %p = ();

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {

        $ref->{exchangerate} ||= 1;
        $form->db_parse_numeric(sth => $sth, hashref => $ref);

        if ( $ref->{id} != $id ) {

            if (%e) {
                $form->{transactions}{$transaction}->[$i]->{recurringemail} =
                  "";
                for ( keys %e ) {
                    $form->{transactions}{$transaction}->[$i]
                      ->{recurringemail} .= "${_}:";
                }
                chop $form->{transactions}{$transaction}->[$i]
                  ->{recurringemail};
            }

            if (%p) {
                $form->{transactions}{$transaction}->[$i]->{recurringprint} =
                  "";
                for ( keys %p ) {
                    $form->{transactions}{$transaction}->[$i]
                      ->{recurringprint} .= "${_}:";
                }
                chop $form->{transactions}{$transaction}->[$i]
                  ->{recurringprint};
            }

            %e = ();
            %p = ();

            push @{ $form->{transactions}{ $ref->{transaction} } }, $ref;

            $id = $ref->{id};
            $i  = $#{ $form->{transactions}{ $ref->{transaction} } };

        }

        $transaction = $ref->{transaction};

        $e{ $ref->{recurringemail} } = 1 if $ref->{recurringemail};
        $p{ $ref->{recurringprint} } = 1 if $ref->{recurringprint};

    }

    $sth->finish;

    # this is for the last row
    if (%e) {
        $form->{transactions}{$transaction}->[$i]->{recurringemail} = "";
        for ( keys %e ) {
            $form->{transactions}{$transaction}->[$i]->{recurringemail} .=
              "${_}:";
        }
        chop $form->{transactions}{$transaction}->[$i]->{recurringemail};
    }

    if (%p) {
        $form->{transactions}{$transaction}->[$i]->{recurringprint} = "";
        for ( keys %p ) {
            $form->{transactions}{$transaction}->[$i]->{recurringprint} .=
              "${_}:";
        }
        chop $form->{transactions}{$transaction}->[$i]->{recurringprint};
    }

    $dbh->commit;

}

=item AM->recurring_details($myconfig, $form, $id);

Retrieves details about the recurring transaction $id and places them into
attributes of $form.  Sets id (the transaction id passed in, $id), reference 
(a reference string for the recurring transaction), startdate (the date the
recurrence series started on), nextdate (the date of the next occurrence of the
event), enddate (the date of the final occurrence of the event), repeat (the
number of units involved in a recurrence period), unit (the recurrence unit),
howmany (the total number of recurrences in the recurrence series), payment
(whether or not the transaction is associated with a payment), arid (true if an
ar event), apid (true if an ap event), overdue (number of days an ar event was
to the duedate), paid (number of days after an ar event it was paid), req (days
until the requirement date from the transdate of an oe event), oeid (true if an
oe event), customer_id (vendor id if sales order), vendor_id (vendor id if
puchase order), vc ('customer' if customer_id set, 'vendor' if vendor_id set),
invoice (true if both arid and arinvoice set or if both apid and apinvoice set),
recurringemail (colon separated list of forms and formats to be emailed),
message (the non-attachement message body for the emails), and recurringprint 
(colon separated list of form names, formats, and printer names).

$myconfig is unused.

=cut

sub recurring_details {

    my ( $self, $myconfig, $form, $id ) = @_;

    my $dbh   = $form->{dbh};
    my $query = qq|
		   SELECT s.*, ar.id AS arid, ar.invoice AS arinvoice,
		          ap.id AS apid, ap.invoice AS apinvoice,
		          ar.duedate - ar.transdate AS overdue,
		          ar.datepaid - ar.transdate AS paid,
		          oe.reqdate - oe.transdate AS req,
		          oe.id AS oeid,
                          CASE oe.oe_class_id
                             WHEN 1 THEN oe.entity_credit_account
                             ELSE NULL
                             END AS customer_id,
                          CASE oe.oe_class_id
                             WHEN 2 THEN oe.entity_credit_account
                             ELSE NULL
                             END AS vendor_id
		     FROM recurring s
		LEFT JOIN ar ON (ar.id = s.id)
		LEFT JOIN ap ON (ap.id = s.id)
		LEFT JOIN oe ON (oe.id = s.id)
		    WHERE s.id = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    my $ref = $sth->fetchrow_hashref(NAME_lc);
    $form->{vc} = "customer" if $ref->{customer_id};
    $form->{vc} = "vendor"   if $ref->{vendor_id};
    for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
    $sth->finish;

    $form->{invoice} = ( $form->{arid} && $form->{arinvoice} );
    $form->{invoice} = ( $form->{apid} && $form->{apinvoice} )
      unless $form->{invoice};

    $query = qq|
		SELECT * 
		  FROM recurringemail
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    $form->{recurringemail} = "";

    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{recurringemail} .= "$ref->{formname}:$ref->{format}:";
        $form->{message} = $ref->{message};
    }

    $sth->finish;

    $query = qq|
		SELECT * 
		  FROM recurringprint
		 WHERE id = ?|;

    $sth = $dbh->prepare($query);
    $sth->execute($id) || $form->dberror($query);

    $form->{recurringprint} = "";
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{recurringprint} .=
          "$ref->{formname}:$ref->{format}:$ref->{printer}:";
    }

    $sth->finish;

    chop $form->{recurringemail};
    chop $form->{recurringprint};

    for (qw(arinvoice apinvoice invnumber)) { delete $form->{$_} }
    

    $dbh->commit;

}

=item AM->update_recurring($myconfig, $form, $id)

Updates nextdate for the recurring transaction $id to the next date of the
sequence.  If the new value for nextdate is after enddate, nextdate is set to
NULL.

$myconfig is unused.

=cut

sub update_recurring {

    my ( $self, $myconfig, $form, $id ) = @_;

    my $dbh = $form->{dbh};

    $id = $dbh->quote($id);
    my $query = qq|
		SELECT nextdate, repeat, unit
		  FROM recurring
		 WHERE id = $id|;

    my ( $nextdate, $repeat, $unit ) = $dbh->selectrow_array($query);

    $nextdate = $dbh->quote($nextdate);
    my $interval = $dbh->quote("$repeat $unit");

    # check if it is the last date
    $query = qq|
		SELECT (date $nextdate + interval $interval) > enddate
		  FROM recurring
		 WHERE id = $id|;

    my ($last_repeat) = $dbh->selectrow_array($query);
    if ($last_repeat) {
        $query = qq|
    		UPDATE recurring 
    		   SET nextdate = NULL
    		 WHERE id = $id|;
    } else {
        $query = qq|
    		UPDATE recurring 
    		   SET nextdate = (date $nextdate + interval $interval)
    		 WHERE id = $id|;
    }

    $dbh->do($query) || $form->dberror($query);

    $dbh->commit;

}

=item AM->check_template_name($myconfig, $form);

Performs some sanity checking on the filename $form->{file} and calls
$form->error if the filename is disallowed.

=cut

sub check_template_name {

    my ( $self, $myconfig, $form ) = @_;

    my @allowedsuff = qw(css tex txt html xml);
    if ( $form->{file} =~ /^(.:)*?\/|:|\.\.\/|^\// ) {
        $form->error("Directory transversal not allowed.");
    }
    if ( $form->{file} =~ /^${LedgerSMB::Sysconfig::backuppath}\// ) {
        $form->error(
"Not allowed to access ${LedgerSMB::Sysconfig::backuppath}/ with this method"
        );
    }
    my $whitelisted = 0;
    for (@allowedsuff) {
        if ( $form->{file} =~ /$_$/ ) {
            $whitelisted = 1;
        }
    }
    if ( !$whitelisted ) {
        $form->error("Error:  File is of type that is not allowed.");
    }

    if ( $form->{file} !~ /^$myconfig->{templates}\// ) {
        $form->error("Not in a whitelisted directory: $form->{file}")
          unless $form->{file} =~ /^css\//;
    }
}

=item AM->load_template($myconfig, $form);

Populates $form->{body} with the contents of the file $form->{file}.

=cut

sub load_template {

    my ( $self, $myconfig, $form ) = @_;
    my $testval = 0;

    $form->{file} ||= lc "$myconfig->{templates}/$form->{template}.$form->{format}";
    $self->check_template_name( \%$myconfig, \%$form );
    open( TEMPLATE, '<', "$form->{file}" ) || ($testval = 1);
    if ($testval == 1 && ($! eq 'No such file or directory')){
      $form->error('Template not found.  
         Perhaps you meant to edit the default template instead?');
    } elsif ($testval == 1){
       $form->error("$form->{file} : $!");
    }
    while (<TEMPLATE>) {
        $form->{body} .= $_;
    }

    close(TEMPLATE);

}

=item AM->save_template($myconfig, $form);

Overwrites the file $form->{file} with the contents of $form->{body}, excluding
carriage returns.

=cut

sub save_template {

    my ( $self, $myconfig, $form ) = @_;

    $form->{file} ||= lc "$myconfig->{templates}/$form->{template}.$form->{format}";
    $self->check_template_name( \%$myconfig, \%$form );
    open( TEMPLATE, '>', "$form->{file}" )
      or $form->error("$form->{file} : $!");

    # strip
    $form->{body} =~ s/\r//g;
    print TEMPLATE $form->{body};

    close(TEMPLATE);

}

=item AM->save_preferences($myconfig, $form);

Saves the preferences for the current user.  New values are taken from the $form
attributes name, email, dateformat, signature, numberformat, vclimit, tel, fax,
company, menuwidth, countrycode, address, timeout, stylesheet, printer,
password, new_password, and old_password.  Password updates occur when
new_password and old_password differ.

=cut

sub save_preferences {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    # get username, is same as requested?
    my @queryargs;
    my $query = qq|
		SELECT login
		  FROM employee 
		 WHERE login = ?|;
    @queryargs = ( $form->{login} );
    my $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $form->dberror($query);
    my ($dbusername) = $sth->fetchrow_array;
    $sth->finish;

    return 0 if ( $dbusername ne $form->{login} );

    # update name
    $query = qq|
		UPDATE employee 
		   SET name = ?
		 WHERE login = ?|;

    @queryargs = ( $form->{name}, $form->{login} );
    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);

    # get default currency
    $query = qq|
		SELECT value, (SELECT value FROM defaults
		                WHERE setting_key = 'businessnumber')
		  FROM defaults
		 WHERE setting_key = 'curr'|;

    ( $form->{currency}, $form->{businessnumber} ) =
      $dbh->selectrow_array($query);
    $form->{currency} =~ s/:.*//;

    $dbh->commit;

    $myconfig = LedgerSMB::User->new( $form->{login} );

    map { $myconfig->{$_} = $form->{$_} if exists $form->{$_} }
      qw(name email dateformat signature numberformat vclimit tel fax
      company menuwidth countrycode address timeout stylesheet
      printer password);

    $myconfig->{password} = $form->{new_password}
      if ( $form->{old_password} ne $form->{new_password} );

    $myconfig->save_member();

    1;

}

=item AM->save_defaults($myconfig, $form, \@defaults);

Sets the values in the defaults table to values derived from $form.  glnumber,
sinumber, vinumber, sonumber, ponumber, sqnumber, rfqnumber, partnumber,
employeenumber, customernumber, vendornumber, projectnumber, yearend, curr,
weightunit, and businessnumber are taken directly from the $form value with
the corresponding name.  inventory_accno_id is the id of the account with the
number specified in $form->{IC}.  In a similar manner, income_accno_id and
$form->{IC_income}, expense_accno_id and $form->{IC_expense}, fxgain_accno_id
and $form->{FX_gain}, and fxloss_accno_id and $form->{FX_loss} are related. 

Stores the templates directory for a specific company on defaults table.

@defaults identifies the list of values to be stored in defaults.  If not 
provided, a default list is used.

=cut

sub save_defaults {

    my ( $self, $myconfig, $form, $defaults) = @_;

    for (qw(IC IC_income IC_expense FX_gain FX_loss)) {
        ( $form->{$_} ) = split /--/, $form->{$_};
    }

    my @a;
    $form->{curr} =~ s/ //g;
    for ( split /:/, $form->{curr} ) { push( @a, uc pack "A3", $_ ) if $_ }
    $form->{curr} = join ':', @a;
    # connect to database
    my $dbh = $form->{dbh};
    # save defaults
#    $sth_plain = $dbh->prepare( "
#		UPDATE defaults SET value = ? WHERE setting_key = ?" );
    $sth_accno = $dbh->prepare(
        qq|
		UPDATE defaults
                   SET value = (SELECT id
                                               FROM chart
                                              WHERE accno = ?)
		 WHERE setting_key = ?|
    );
    my %translation = (
        inventory_accno_id => 'IC',
        income_accno_id    => 'IC_income',
        expense_accno_id   => 'IC_expense',
        fxgain_accno_id    => 'FX_gain',
        fxloss_accno_id    => 'FX_loss'
    );
    if (!@{$defaults}){
       $defaults = qw(inventory_accno_id income_accno_id expense_accno_id
                      fxgain_accno_id fxloss_accno_id glnumber sinumber vinumber
                      sonumber ponumber sqnumber rfqnumber partnumber 
                      employeenumber customernumber vendornumber projectnumber 
                      yearend curr weightunit businessnumber default_country 
                      check_prefix password_duration templates vclimit)
    }
    for (@$defaults)
    {
        my $val = $form->{$_};
        if ( $translation{$_} ) {
            $val = $form->{ $translation{$_} };
        }
        if ( $_ =~ /accno/ ) {
            $sth_accno->execute( $val, $_ )
              || $form->dberror("Saving $_");
        }
        else {
				    my $found=0;
				    my $sth_defcheck=$dbh->prepare("select count(*) from defaults where setting_key='$_';") || $form->dberror("Select defaults $_");
				    $sth_defcheck->execute() || $form->dberror("execute defaults $_");
			            while(my $found1=$sth_defcheck->fetchrow()){$found=$found1;}
				    
				  if($found)
				  {
					$dbh->do("update defaults set value=" . $dbh->quote($val) . " where setting_key='$_';");
				  }
				  else
				  {
					$dbh->do("insert into defaults(value,setting_key) values( " . $dbh->quote($val) . ",'$_');"); 
				  }

        }

    }
    my $rc = $dbh->commit;

    $rc;

}

=item AM->defaultaccounts($myconfig, $form);

Retrieves the numbers of default accounts and sets $form->{defaults}{$key} to
the appropriate account numbers, where $key can be 'IC', 'IC_income', 'IC_sale',
'IC_expense', 'IC_cogs', 'FX_gain', and 'FX_loss'.

Sets the hashes refered to as $form->{accno}{IC_${type}}{$accno} to contain the
id and description of all accounts with IC elements in their link fields.  The
possible types are all the IC_* values with IC_cogs merged into IC_expense and
IC_sale merged with IC_income.

Fills the hashes referred to as $form->{accno}{FX_(gain|loss)} with the id and
description of all income and expense accounts, keyed on the account number.

$myconfig is unused.

=cut

sub defaultaccounts {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    # get defaults from defaults table
    my $query = qq|
		SELECT setting_key, value FROM defaults
		 WHERE setting_key LIKE ?|;
    my $sth = $dbh->prepare($query);
    $sth->execute('%accno_id') || $form->dberror($query);

    my $ref;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{ $ref->{setting_key} } = $ref->{value};
    }

    $form->{defaults}{IC}         = $form->{inventory_accno_id};
    $form->{defaults}{IC_income}  = $form->{income_accno_id};
    $form->{defaults}{IC_sale}    = $form->{income_accno_id};
    $form->{defaults}{IC_expense} = $form->{expense_accno_id};
    $form->{defaults}{IC_cogs}    = $form->{expense_accno_id};
    $form->{defaults}{FX_gain}    = $form->{fxgain_accno_id};
    $form->{defaults}{FX_loss}    = $form->{fxloss_accno_id};

    $sth->finish;

    $query = qq|
		SELECT id, accno, description, link
		  FROM chart
		 WHERE link LIKE '%IC%'
		 ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    my $nkey;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        foreach my $key ( split( /:/, $ref->{link} ) ) {
            if ( $key =~ /IC/ ) {
                $nkey = $key;

                if ( $key =~ /cogs/ ) {
                    $nkey = "IC_expense";
                }

                if ( $key =~ /sale/ ) {
                    $nkey = "IC_income";
                }

                %{ $form->{accno}{$nkey}{ $ref->{accno} } } = (
                    id          => $ref->{id},
                    description => $ref->{description}
                );
            }
        }
    }

    $sth->finish;

    $query = qq|
		    SELECT id, accno, description
		      FROM chart
		     WHERE (category = 'I' OR category = 'E')
		           AND charttype = 'A'
		  ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        %{ $form->{accno}{FX_gain}{ $ref->{accno} } } = (
            id          => $ref->{id},
            description => $ref->{description}
        );

        %{ $form->{accno}{FX_loss}{ $ref->{accno} } } = (
            id          => $ref->{id},
            description => $ref->{description}
        );
    }

    $sth->finish;

    $dbh->commit;

}

=item AM->taxes($myconfig, $form);

Retrieve details about all taxes in the database.  $form->{taxrates} refers to a
list containing hashes with the chart id (id), account number (accno),
description, rate, taxnumber, validto, pass, and taxmodulename for a tax.
$form->{taxmodule_B<id>}, where B<id> is a taxmodule_id, is set to that
taxmodule's name.

$myconfig is unused.

=cut

sub taxes {

    my ( $self, $myconfig, $form ) = @_;
    my $taxaccounts = '';

    # connect to database
    my $dbh = $form->{dbh};

    my $query = qq|
		  SELECT c.id, c.accno, c.description, 
		         t.rate * 100 AS rate, t.taxnumber, t.validto,
			 t.pass, m.taxmodulename
		    FROM chart c
		    LEFT JOIN
                     (tax t JOIN taxmodule m 
                            ON (t.taxmodule_id = m.taxmodule_id))
                    ON (c.id = t.chart_id)
                    WHERE c.tax
		ORDER BY 3, 6|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        push @{ $form->{taxrates} }, $ref;
        $taxaccounts .= " " . $ref{accno};
    }

    $sth->finish;

    $query = qq|
		SELECT taxmodule_id, taxmodulename FROM taxmodule
		ORDER BY 2|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->{ "taxmodule_" . $ref->{taxmodule_id} } = $ref->{taxmodulename};
    }

    $sth->finish;

    $dbh->commit;

}

=item AM->save_taxes($myconfig, $form);

Deletes B<all> entries from the tax table then re-inserts all taxes whose
accounts are part of the space separated list $form->{taxaccounts}.  Each
element of $form->{taxaccounts} is of the form 'chartid_I<i>' where chartid is
the id of the chart entry for the tax and I<i> is a numeric index.  The values
inserted for each tax are chart_id (from taxaccounts), rate (
form->{taxrate_I<i>} / 100), validto ($form->{validto_I<i>}), taxnumber
($form->{taxnumber_I<i>}), pass ($form->{pass_I<i>}), and taxmodule_id
($form->{taxmodule_id_I<i>}).

=cut

sub save_taxes {

    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    foreach my $item ( split / /, $form->{taxaccounts} ) {
        my ( $chart_id, $i ) = split /_/, $item;
        my $rate =
          $form->parse_amount( $myconfig, $form->{"taxrate_$i"} ) / 100;
        my $validto = $form->{"validto_$i"};
        $validto = 'infinity' if not $validto;
        $form->{"pass_$i"} = 0 if not $form->{"pass_$i"};
        delete $form->{"old_validto_$i"} if ! $form->{"old_validto_$i"};

        $sth = $dbh->prepare('select account__save_tax(?,?,?,?,?,?,?)');         
        my @queryargs = (
            $chart_id, $validto, $rate, $form->{"taxnumber_$i"},
            $form->{"pass_$i"}, $form->{"taxmodule_id_$i"},
            $form->{"old_validto_$i"}
        );
       $sth->execute(@queryargs) ||$form->dberror($query);

        

    }

    my $rc = $dbh->commit;

    $rc;

}

=item AM->closedto($myconfig, $form);

Populates $form->{closedto}, $form->{revtrans}, and $form->{audittrail} with
their values in the defaults table.

$myconfig is unused.

=cut

sub closedto {
    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query = qq|
		SELECT (SELECT value FROM defaults 
		         WHERE setting_key = 'closedto'), 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'revtrans'), 
		       (SELECT value FROM defaults
		         WHERE setting_key = 'audittrail')|;

    ( $form->{closedto}, $form->{revtrans}, $form->{audittrail} ) =
      $dbh->selectrow_array($query);

    $dbh->commit;

}

=item AM->closebooks($myconfig, $form);

Updates the revtrans, closedto, and audittrail entries in the defaults table
using their corresponding $form values.  If $form->{removeaudittrail} is set,
this used to remove all audittrail entries with a transdate prior to the date
given by $form->{removeaudittrail}, but has been disabled.

$myconfig is unused.

=cut

sub closebooks {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh   = $form->{dbh};
    my $query = qq|
		UPDATE defaults SET value = ? 
		 WHERE setting_key = ?|;
    my $sth = $dbh->prepare($query);
    my $sth_closedto = $dbh->prepare(qq|
		UPDATE defaults SET value = to_char(?::date, 'YYYY-MM-DD') 
		 WHERE setting_key = ?|);
		
    for (qw(revtrans closedto audittrail)) {

        if ( $form->{$_} ) {
            $val = $form->{$_};
        }
        else {
            $val = 0;
        }
        if ($_ eq 'closedto'){
            $sth_closedto->execute( $val || undef, $_);
        } else { 
            $sth->execute( $val, $_ );
        }
    }

## SC: Disabling audit trail removal
##    if ( $form->{removeaudittrail} ) {
##        $query = qq|
##			DELETE FROM audittrail
##			 WHERE transdate < ?|;
##
##        $dbh->do($query, undef, $form->{removeaudittrail}) || $form->dberror($query);
##    }

    $dbh->commit;

}

=item AM->earningsaccounts($myconfig, $form);

Populates the list referred to as $form->{chart} with hashes containing the
account number (accno) and the description of all equity accounts, ordered by
the account number.

$myconfig is unused.

=cut

sub earningsaccounts {

    my ( $self, $myconfig, $form ) = @_;

    my ( $query, $sth, $ref );

    # connect to database
    my $dbh = $form->{dbh};

    # get chart of accounts
    $query = qq|
		    SELECT accno,description
		      FROM chart
		     WHERE charttype = 'A'
		           AND category = 'Q'
		  ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    $form->{chart} = [];

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        push @{ $form->{chart} }, $ref;
    }

    $sth->finish;
    $dbh->commit;
}

=item AM->post_yearend($myconfig, $form);

Posts the termination of a financial year.  Makes use of the $form attributes
login, reference, notes, description, and transdate to populate the gl table
entry.  The id of the gl transaction is placed in $form->{id}.  

For every accno_$i in $form, where $i is between 1 and $form->{rowcount}, an
acc_trans entry will be added if credit_$i or debit_$i is non-zero.

A new yearend entry is populated with the id and transdate of the gl
transaction.

Adds an entry to the audittrail.

$myconfig is unused.

=cut

sub post_yearend {

    my ( $self, $myconfig, $form ) = @_;

    my $dbh = $form->{dbh};

    my $query;
    my @queryargs;
    my $uid = localtime;
    $uid .= "$$";

    $query = qq|
		INSERT INTO gl (reference, person_id)
		     VALUES (?, (SELECT id FROM person WHERE entity_id = (select entity_id from users where username = current_user)))|;

    $dbh->prepare($query)->execute( $uid)
      || $form->dberror($query);

    $query = qq|
		SELECT id 
		  FROM gl
		 WHERE reference = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute($uid);
    ( $form->{id} ) = $sth->fetchrow_array;

    $query = qq|
		UPDATE gl 
		   SET reference = ?,
		       description = ?,
		       notes = ?,
		       transdate = ?,
		       department_id = 0
		 WHERE id = ?|;

    @queryargs = (
        $form->{reference}, $form->{description}, $form->{notes},
        $form->{transdate}, $form->{id}
    );
    $dbh->prepare($query)->execute(@queryargs) || $form->dberror($query);

    my $amount;
    my $accno;
    $query = qq|
		INSERT INTO acc_trans (trans_id, chart_id, amount, transdate, 
		            source)
		     VALUES (?, (SELECT id
		                   FROM chart
		                  WHERE accno = ?),
		            ?, ?, ?)|;

    # insert acc_trans transactions
    for my $i ( 1 .. $form->{rowcount} ) {

        # extract accno
        ($accno) = split( /--/, $form->{"accno_$i"} );
        $amount = 0;

        if ( $form->{"credit_$i"} ) {
            $amount = $form->{"credit_$i"};
        }

        if ( $form->{"debit_$i"} ) {
            $amount = $form->{"debit_$i"} * -1;
        }

        # if there is an amount, add the record
        if ($amount) {
            my @args = (
                $form->{id}, $accno, $amount, $form->{transdate},
                $form->{reference}
            );

            $dbh->prepare($query)->execute(@args)
              || $form->dberror($query);
        }
    }

    $query = qq|
		INSERT INTO yearend (trans_id, transdate)
		     VALUES (?, ?)|;

    $dbh->prepare($query)->execute( $form->{id}, $form->{transdate} )
      || $form->dberror($query);

    my %audittrail = (
        tablename => 'gl',
        reference => $form->{reference},
        formname  => 'yearend',
        action    => 'posted',
        id        => $form->{id}
    );

    $form->audittrail( $dbh, "", \%audittrail );

    # commit and redirect
    my $rc = $dbh->commit;

    $rc;

}

=item AM->get_all_defaults($form);

Retrieves all settings from defaults and sets the appropriate $form values.
Also runs AM->defaultaccounts.

=cut

sub get_all_defaults {
    my ( $self, $form ) = @_;
    my $dbh   = $form->{dbh};
    my $query = "select setting_key, value FROM defaults";
    $sth = $dbh->prepare($query);
    $sth->execute;
    while ( ( $skey, $value ) = $sth->fetchrow_array() ) {
        $form->{$skey} = $value;
    }
    $sth->finish;
    $query = "select id, name from country order by name";
    $sth = $dbh->prepare($query);
    $sth->execute;
    $form->{countries} = [];
    while ($ref = $sth->fetchrow_hashref('NAME_lc')) {
        push @{$form->{countries}}, $ref;
    }
    $sth->finish;
    #HV do not know if i can use 'sub language' here which fills $form->{ALL}
    $query = "select code,description from language order by code";
    $sth = $dbh->prepare($query);
    $sth->execute;
    $form->{languages} = [];
    while ($ref = $sth->fetchrow_hashref('NAME_lc')) {
        push @{$form->{languages}}, $ref;
    }
    $sth->finish;

    $self->defaultaccounts( undef, $form );
    $dbh->commit;
    my $dirname = "./templates";
    my $subdircount = 0;
}

=item AM->get_templates_directories;

This functions gets all the directories from $LedgerSMB::Sysconfig::templates to list all the possible
non-Ui templates.

=cut
sub get_templates_directories {
my ( $self, $form ) = @_;
my $subdircount = 0;
my @dirarray;
opendir ( DIR, $LedgerSMB::Sysconfig::templates) || $form->error("Error while opening file: ./".$LedgerSMB::Sysconfig::templates);
while( (my $name = readdir(DIR))){
                 next if ($name =~ /\./);
                 if (-d $LedgerSMB::Sysconfig::templates.'/'.$name) {
                         $dirarray[$subdircount++] = $name;
                 }
}
closedir(DIR);
@{$form->{templates_directories}} = @dirarray;
}


1;

=back

