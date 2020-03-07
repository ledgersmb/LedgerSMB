package _18_upgrade_checks;
use LedgerSMB::Database::ChangeChecks;


check q|Ensure that the transactions table contains no invalid table names|,
    query => q|
        SELECT *
        FROM transactions
        WHERE table_name IS NULL
        OR table_name NOT IN ('gl', 'ar', 'ap')
    |,
    description => q|
The upgrade process found transactions table entries with an invalid
table_name field.

This field can only be set to one of "gl", "ar" or "ap".

Please provide the missing data below and press 'Save' to fix this
issue, or manually remove the invalid rows and re-run the upgrade
process.
|,

    tables => {
        transactions => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid (
            $rows,
            name => 'transactions',
            columns => [qw(id table_name approved transdate)],
            edit_columns => [qw(table_name)],
            dropdowns => {
                table_name => {
                    'gl' => 'gl',
                    'ar' => 'ar',
                    'ap' => 'ap',
                },
            }
        );
        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'transactions';
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;

1;
