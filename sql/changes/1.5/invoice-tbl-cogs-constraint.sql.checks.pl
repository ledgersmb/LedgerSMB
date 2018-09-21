
package migration_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Assert valid Cost Of Goods Sold (COGS) data in the invoices table|,
    query => q|SELECT count(*) FROM invoice
                WHERE NOT allocated*-1 BETWEEN least(0,qty) AND greatest(qty,0)
               HAVING count(*) > 0|,
    description => q|
The migration checks found rows in your 'invoice' table which are
inconsistent with the new constraint COGS allocation constraint
being introduced by the schema change.

There's no way to correct this situation without a real risk for accounting
impact. There are also insufficient real-world examples available to the
development team to develop a generic solution to this situation.

Please contact the development list if you run into this error:

```
devel@lists.ledgersmb.org
```

We're very sorry, but there's no other path forward at this point.

|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

    },
    # *not* defining on_submit is a failure.
    # t/16-prechecks.t tests for on_submit being a coderef;
    # when not, it considers it 'not provided'
    on_submit => 1,
;



1;
