
package migration_checks;


use LedgerSMB::Database::ChangeChecks;



check 'Assert fixed assets depreciation values are set (purchase_value)',
    description => q|
The migration checks found rows in your "asset_item" table which contain
an unset `purchase_value`. The result of this value being unavailable is
that depreciation routines can't work properly.

Please fix the data in the table below so the migration can add a constraint
to prevent similar erroneous data from entering the database.
    |,
    tables => {
        'asset_item' => {
            prim_key => 'id',
        },
    },
    query => qq|SELECT * FROM asset_item WHERE purchase_value IS NULL|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id tag purchase_value description ) ],
            edit_columns => [ qw( purchase_value ) ],
            table => 'asset_item';

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        save_grid $dbh, $failed_rows, name => 'fix_pv';
    };



check 'Assert fixed assets depreciation values are set (salvage_value)',
    description => q|
The migration checks found rows in your "asset_item" table which contain
an unset `salvage_value`. The result of this value being unavailable is
that depreciation routines can't work properly.

Please fix the data in the table below so the migration can add a constraint
to prevent similar erroneous data from entering the database.
    |,
    tables => {
        'asset_item' => {
            prim_key => 'id',
        },
    },
    query => qq|SELECT * FROM asset_item WHERE salvage_value IS NULL|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id tag salvage_value description ) ],
            edit_columns => [ qw( salvage_value ) ],
            table => 'asset_item';

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        save_grid $dbh, $failed_rows, name => 'fix_pv';
    };



check 'Assert fixed assets depreciation values are set (usable_life)',
    description => q|
The migration checks found rows in your "asset_item" table which contain
an unset `usable_life`. The result of this value being unavailable is
that depreciation routines can't work properly.

Please fix the data in the table below so the migration can add a constraint
to prevent similar erroneous data from entering the database.
    |,
    tables => {
        'asset_item' => {
            prim_key => 'id',
        },
    },
    query => qq|SELECT * FROM asset_item WHERE usable_life IS NULL|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id tag usable_life description ) ],
            edit_columns => [ qw( usable_life ) ],
            table => 'asset_item';

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        save_grid $dbh, $failed_rows, name => 'fix_pv';
    };



1;
