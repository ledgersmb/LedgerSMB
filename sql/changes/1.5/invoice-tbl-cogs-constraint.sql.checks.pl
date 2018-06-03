
package migration_checks;

use LedgerSMB::Database::ChangeChecks;



break me here; this file is far from committable;

check q|Assert valid values for 'parts_id' column in 'partscustomer' table|,
    query => q|SELECT count(*) FROM partscustomer pc
                WHERE NOT EXISTS (select 1 from parts p
                                   where pc.parts_id = p.id)
               HAVING count(*) > 0|,
    description => q|
The migration checks found rows in your 'partscustomer' table which
contain references to non-existing parts data. The migration wants to
create a constraint which makes sure this can't occur anymore, going forward,
but the existing (meaningless) data prevents creation of this constraint.

Click 'Proceed' to confirm deletion of the invalid data preventing creation.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        confirm proceed => 'Proceed';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        $dbh->do(q|
UPDATE partscustomer pc
   SET parts_id = NULL
 WHERE NOT EXISTS (select 1 from parts p
                    where pc.parts_id = p.id)
|)
            or die 'Unable to nullify "parts_id": ' . $dbh->errstr;
    }
;



1;
