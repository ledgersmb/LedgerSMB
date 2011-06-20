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
# Copyright (C) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# backend code for human resources and payroll
#
#======================================================================

package HR;

sub employees {
    my ( $self, $myconfig, $form ) = @_;

    # connect to database
    my $dbh = $form->{dbh};

    my $where = "1 = 1";
    $form->{sort} = ( $form->{sort} ) ? $form->{sort} : "first_name";
    my @a         = qw(first_name);
    my $sortorder = $form->sort_order( \@a );

    my $var;

    if ( $form->{startdatefrom} ) {
        $where .=
          " AND e.startdate >= " . $dbh->quote( $form->{startdatefrom} );
    }
    if ( $form->{startdateto} ) {
        $where .= " AND e.startddate <= " . $dbh->quote( $form->{startdateto} );
    }
    if ( $form->{first_name} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{first_name} ) );
        $where .= " AND lower(e.first_name) LIKE $var";
    }
    if ( $form->{notes} ne "" ) {
        $var = $dbh->quote( $form->like( lc $form->{notes} ) );
        $where .= " AND lower(e.notes) LIKE $var";
    }
    if ( $form->{sales} eq 'Y' ) {
        $where .= " AND e.sales = '1'";
    }
    if ( $form->{status} eq 'orphaned' ) {
        $where .= qq| AND e.login IS NULL|;
    }
    if ( $form->{status} eq 'active' ) {
        $where .= qq| AND e.enddate IS NULL|;
    }
    if ( $form->{status} eq 'inactive' ) {
        $where .= qq| AND e.enddate <= current_date|;
    }

    my $query = qq|
		   SELECT e.*, m.first_name AS manager
		     FROM employee e
		LEFT JOIN employee m ON (m.entity_id = e.manager_id)
		    WHERE $where
		 ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror( __FILE__ . ':' . __LINE__ . ':' . $query );

    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $ref->{address} = "";
        for (qw(address1 address2 city state zipcode country)) {
            $ref->{address} .= "$ref->{$_} ";
        }
        push @{ $form->{all_employee} }, $ref;
    }

    $sth->finish;
    $dbh->commit;

}

1;

