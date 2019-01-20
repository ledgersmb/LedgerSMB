package mc_migration_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Ensure that currency information is available for gl transactions|,
    query => q|
SELECT * FROM gl
 WHERE curr IS NULL
  ORDER BY transdate, id|,
    description => q|
The migration checks found that there are GL transactions marked as
fx transactions. However, the existing schema doesn't store the
transaction currency. Going forward, these values are required.

**Note** if the transaction currency isn't available, you may
set it to the default currency. After this script completes,
you may need to verify the foreign currency balances of your
accounts and post correction transactions, if you choose to
use this route.

Please provide the missing values in the table below.

|,
    tables => {
        gl => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
           name => 'gl',
           columns => [ qw( transdate reference curr description notes ) ],
           edit_columns => [ 'curr' ],
           dropdowns => {
               curr => dropdown_sql($dbh, q{SELECT * FROM currency}),
           };

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'gl';
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
