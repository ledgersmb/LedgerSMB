
package migration_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Assert "inventory_report" table's columns can be upgraded|,
    query => q|SELECT ir.transdate,
                      ap.invnumber as ap_invoice_number,
                      ar.invnumber as ar_invoice_number  FROM inventory_report ir
               LEFT JOIN ap ON ap.id = ir.ap_trans_id
               LEFT JOIN ar ON ar.id = ir.ar_trans_id
                WHERE NOT EXISTS
                       (SELECT 1 FROM defaults
                         WHERE setting_key = 'inv-entity-retain')|,
    description => q|
The migration checks found rows in your "inventory_report" table
with linked AR/AP transactions. The table lists affected invoice numbers.

There are two ways to migrate this pre-existing content to the new data
model. The first resulting (technically) in the cleanest solution, is not
legally compliant with any jurisdiction requiring sequentially numbered
invoices. Please select your upgrade approach.

Background: The inventory adjustment process before 1.6.0 used to create
invoices issued to the "Inventory Entity" (a dummy entity meant to be
your company). These invoices cause the correct Cost of Goods Sold (COGS)
adjustments to be posted to the books along with the inventory count
adjustments.

The 1.6.0 release introduces a different way of recording the COGS adjustments
along with the inventory count adjustments, eliminating the need for the
"Inventory Entity". In order to be able to remove this dummy entity from the
system completely, the adjustment invoices linked to it, must be removed.
(The 'Remove' choice below executes this migration scenario.)

As some jurisdictions require sequentially numbered invoices, the "Inventory
Entity" and the adjustment invoices can't be removed, requiring a different
migration strategy. In this strategy, the "Inventory Entity" will simply be
disabled by setting an end date on it. The adjustment invoices will be
annotated with a remark in the "Internal notes" that they have been modified
by the migration process. The lines of these invoices will be migrated to the
new database structure. This leaves 'empty' invoices to fill the numbering
gap.


* Remove  
    *Not* compliant with jurisdictions with sequential numbering requirements.

    Removes the adjustment invoices after moving the journal lines to
    GL transactions. Enables removing the "Inventory Entity".

* Retain  
    Compliant with jurisdictions with sequential numbering requirements.

    Retains the "Inventory Entity" and the adjustment invoices, but moves
    the invoice rows to the new database structure, leaving empty invoices,
    with an annotation in the `Internal Info` field mentioning this migration.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
           name => 'fix_inv',
           columns => [ qw( transdate ap_invoice_number ar_invoice_number ) ];

        confirm remove => 'Remove', retain => 'Retain';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
           # We set a migration strategy in the defaults table
           $dbh->do("INSERT INTO defaults VALUES ('inv-entity-remove', 'y')")
              or die "Failed to set migration strategy: " . $dbh->errstr;
        }
        elsif ($confirm eq 'retain') {
           # We set a migration strategy in the defaults table
           $dbh->do("INSERT INTO defaults VALUES ('inv-entity-retain', 'y')")
              or die "Failed to set migration strategy: " . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;



1;
