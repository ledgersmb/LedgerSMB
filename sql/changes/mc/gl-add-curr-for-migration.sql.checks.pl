package mc_migration_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Ensure that currency information is available for gl transactions|,
    # Note that the alter table here is a 9.6-ism (IF NOT EXISTS)
    # also note that the addition of the column will only be run if the
    # check is run, which is only in case the actual change script hasn't.
    query => q|
ALTER TABLE gl ADD COLUMN IF NOT EXISTS curr char(3);

SELECT * FROM gl
 WHERE EXISTS (select 1 from acc_trans at where at.trans_id = gl.id
                                                and at.fx_transaction)
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
