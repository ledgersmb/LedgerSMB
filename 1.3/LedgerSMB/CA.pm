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
		   SELECT accno, 
                          SUM(CASE WHEN ($approved OR acc_trans.approved) AND
                                        (g.approved OR $approved) 
                                   THEN acc_trans.amount
                                   ELSE 0 END) AS amount,
                          count(acc_trans.*) as rowcount
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
		 GROUP BY accno|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    my $rcount;
    while ( my $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $form->db_parse_numeric(sth=>$sth, hashref=>$ref);
        $amount{ $ref->{accno} } = $ref->{amount};
        $rcount{ $ref->{accno} } = $ref->{rowcount};
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
		  ORDER BY accno, c.charttype DESC|;

    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    while ( my $ca = $sth->fetchrow_hashref(NAME_lc) ) {
        $ca->{amount}           = $amount{ $ca->{accno} };
        $ca->{rowcount}           = $rcount { $ca->{accno} };
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

1;
