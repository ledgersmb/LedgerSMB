package mc_migration_checks;

use LedgerSMB::Database::ChangeChecks;


# Without a currency on each AR transaction, the currencies won't
# be set correctly in the acc_trans lines, which leads to issues
# when setting NOT NULL constraints after the migration completes.
check q|Assert AR transactions have currency when fx transaction|,
    query => q|SELECT * FROM ar
                WHERE curr IS NULL
                      AND EXISTS (select 1 from acc_trans at
                                   where fx_transaction
                                         and at.trans_id = ar.id)|,
    description => q|
The migration checks found some AR transactions in your database
which are marked as foreign currency transactions, yet they lack
a currency code.

Please add a foreign currency code to each transaction.
|,
    tables => {
        ar => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'ar',
            columns => [ qw( id invnumber curr amount netamount
                         entity_credit_account ) ],
            edit_columns => [ 'curr' ],
            dropdowns => {
                curr => dropdown_sql($dbh, q{SELECT * FROM currency}),
                entity_credit_account
                    => dropdown_sql($dbh, q{SELECT id, description FROM entity_credit_account WHERE entity_class = 2}), # 2 = customer
            };

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'ar',
                column_transforms => {
                    amount => 0.00,
            };
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;

# Without a currency on each AP transaction, the currencies won't
# be set correctly in the acc_trans lines, which leads to issues
# when setting NOT NULL constraints after the migration completes.
check q|Assert AP transactions have currency when fx transaction|,
    query => q|SELECT * FROM ap
                WHERE curr IS NULL
                      AND EXISTS (select 1 from acc_trans at
                                   where fx_transaction
                                         and at.trans_id = ap.id)|,
    description => q|
The migration checks found some AP transactions in your database
which are marked as foreign currency transactions, yet they lack
a currency code.

Please add a foreign currency code to each transaction.
|,
    tables => {
        ap => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'ap',
            columns => [ qw( id invnumber curr amount netamount
                         entity_credit_account ) ],
            edit_columns => [ 'curr' ],
            dropdowns => {
                curr => dropdown_sql($dbh, q{SELECT * FROM currency}),
                entity_credit_account
                    => dropdown_sql($dbh, q{SELECT id, description FROM entity_credit_account WHERE entity_class = 1}), # 1 = vendor
            };

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'ap',
                column_transforms => {
                    amount => 0.00,
            };
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Assert all required AP exchange rates are available|,
    query => q|SELECT * FROM exchangerate e
                WHERE coalesce(sell,0) = 0
                  AND EXISTS (select 1 from ap
                               where ap.transdate = e.transdate
                                 and ap.curr = e.curr)|,
    description => q|
The migration checks found that some exchange rates are missing or
0 (zero). These rates are required for correct migration AP items.

Please provide the correct rates in the table below. If you don't know
the correct rates for your situation, [the historical rates provided by
grandtrunk.net](http://currencies.apps.grandtrunk.net/) may prove
useful.
|,
    tables => {
        exchangerate => {
            prim_key => [ qw/ curr transdate / ],
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'exchangerate',
            columns => [ qw| curr transdate buy sell | ],
            edit_columns => [ 'sell' ];

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'exchangerate';
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
};


check q|Assert all required AR exchange rates are available|,
    query => q|SELECT * FROM exchangerate e
                WHERE coalesce(buy,0) = 0
                  AND EXISTS (select 1 from ar
                               where ar.transdate = e.transdate
                                 and ar.curr = e.curr)|,
    description => q|
The migration checks found that some exchange rates are missing or
zero. These rates are required for correct migration of the AR items.

Please provide the correct rates in the table below. If you don't know
the correct rates for your situation, [the historical rates provided by
grandtrunk.net](http://currencies.apps.grandtrunk.net/) may prove
useful.
|,
    tables => {
        exchangerate => {
            prim_key => [ qw/ curr transdate / ],
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'exchangerate',
            columns => [ qw| curr transdate buy sell | ],
            edit_columns => [ 'buy' ];

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'exchangerate';
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
};




1;
