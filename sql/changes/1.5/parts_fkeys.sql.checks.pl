
package migration_checks;

use LedgerSMB::Database::ChangeChecks;


# The trick in this file is that
#
#    HAVING count(*) > 0
#
# means that the check will return no rows when count(*) == 0,
# which won't cause the check to be triggered, but any other number
# (bigger than zero) will cause the check to be triggered, without
# loading the rows failing the test (which the tests don't need anyway)


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


check q|Assert valid values for 'parts_id' column in 'makemodel' table|,
    query => q|SELECT count(*) FROM makemodel mm
                WHERE NOT EXISTS (select 1 from parts p
                                   where mm.parts_id = p.id)
               HAVING count(*) > 0|,
    description => q|
The migration checks found rows in your 'makemodel' table which
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
UPDATE makemodel mm
   SET parts_id = NULL
 WHERE NOT EXISTS (select 1 from parts p
                    where mm.parts_id = p.id)
|)
            or die 'Unable to nullify "parts_id": ' . $dbh->errstr;
    }
;


check q|Assert valid values for 'parts_id' column in 'orderitems' table|,
    query => q|SELECT count(*) FROM orderitems oi
                WHERE NOT EXISTS (select 1 from parts p
                                   where oi.parts_id = p.id)
               HAVING count(*) > 0|,
    description => q|
The migration checks found rows in your 'orderitems' table which
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
UPDATE orderitems oi
   SET parts_id = NULL
 WHERE NOT EXISTS (select 1 from parts p
                    where oi.parts_id = p.id)
|)
            or die 'Unable to nullify "parts_id": ' . $dbh->errstr;
    }
;





1;
