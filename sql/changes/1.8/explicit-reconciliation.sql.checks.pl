
package _18_uprade_checks;

use LedgerSMB::Database::ChangeChecks;

check q|Ensure that the database doesn't contain unapproved reconciliations|,
    query => q|select r.id, accno, description, end_date, their_total
                 from cr_report r
                 join account a on a.id = r.chart_id
                where not (deleted or approved)
                order by accno, end_date|,
    description => q|
The migration procedure found un-approved reconciliations in your database.

After upgrading, the procedure to determine reconcilable lines will be
different from the procedure used before the upgrade. Because of this
difference in treatment, it's not possible to migrate unapproved
reconcilitiations (*approved* reconciliations __will__ be migrated).

Please delete the unapproved reconciliations listed in the table below
by clicking the 'Delete Unapproved Reconciliations' button.

|,
    tables => {
        add_curr => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        grid $rows,
            name => 'reconciliations',
            columns => [ qw( accno description end_date their_total ) ];

        confirm delete => 'Delete Unapproved Reconciliations';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {
            my $delete_report_lines = $dbh->prepare(
                'DELETE FROM cr_report_line WHERE report_id = ?'
            ) or die 'ERROR preparing sql to delete reconciliation report lines';

            my $delete_report = $dbh->prepare(
                'DELETE FROM cr_report WHERE id = ?'
            ) or die 'ERROR preparing sql to delete reconciliation report';

            foreach my $row(@$rows) {
                $delete_report_lines->execute($row->{id})
                    or die 'Failed to remove unapproved report: ' . $dbh->errstr;
                $delete_report->execute($row->{id})
                    or die 'Failed to remove unapproved report: ' . $dbh->errstr;
            }
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;



1;
