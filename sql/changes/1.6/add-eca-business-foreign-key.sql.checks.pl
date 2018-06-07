
package migration_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Assert foreign key from entity_credit_account to business can be added|,
    query => q|SELECT ec.class, e.control_code, eca.meta_number,
                      e.name, eca.description
                 FROM entity_credit_account eca
                 LEFT JOIN entity e on eca.entity_id = e.id
                 LEFT JOIN entity_class ec on eca.entity_class = ec.id
                WHERE eca.business_id IS NOT NULL
                      AND NOT EXISTS
                       (SELECT 1 FROM business b
                         WHERE eca.business_id = b.id)|,
    description => q|
The migration checks found rows in your "entity_credit_account" table
(where customers and vendors are stored) which refer to 'type of business'
classifications which don't exist in the "business" table -- which enumerates
the types of business.

The customers and vendors listed below, are affected. In order for the
migration to continue, these broken links must be cleaned. Please select
the 'Clean' button below to confirm.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
           name => 'fix_inv',
           columns => [ qw( class control_code meta_number name description ) ];

        confirm clean => 'Clean';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm'; # clean

        if ($confirm eq 'clean') {
           # We set a migration strategy in the defaults table
           $dbh->do(q{UPDATE entity_credit_account eca
                        SET business_id = NULL
                      WHERE NOT EXISTS
                        (SELECT 1 FROM business b
                          WHERE eca.business_id = b.id)})
              or die "Failed to clean business_id column: " . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;



1;
