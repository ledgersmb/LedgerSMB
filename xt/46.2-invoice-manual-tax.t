#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Mock;

use DBI;
use LedgerSMB::IS;
use LedgerSMB::PGNumber;

plan skip_all => 'Database tests not enabled' unless $ENV{LSMB_TEST_DB};

my $database = $ENV{LSMB_NEW_DB} // $ENV{PGDATABASE};
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$database", undef, undef,
    { AutoCommit => 0, PrintError => 0, RaiseError => 1 }
);

# Temporary tables isolate the printing query from company data and fixtures.
$dbh->do(q{
    CREATE TEMP TABLE parts (
        id int, inventory_accno_id int, income_accno_id int,
        expense_accno_id int, assembly boolean, weight numeric
    );
    CREATE TEMP TABLE account (id int, accno text, description text);
    CREATE TEMP TABLE acc_trans (
        entry_id int, trans_id int, chart_id int,
        transdate date, amount_tc numeric
    );
    CREATE TEMP TABLE tax_extended (
        entry_id int, tax_basis numeric, rate numeric
    );
    CREATE TEMP TABLE tax (
        chart_id int, validto timestamp, taxnumber text,
        PRIMARY KEY (chart_id, validto)
    );
    INSERT INTO account VALUES (1, '2155', 'Sales tax');
    INSERT INTO acc_trans VALUES (1, 100, 1, '2026-10-26', 7);
    INSERT INTO tax_extended VALUES (1, 100, 0.07);
    INSERT INTO tax VALUES (1, '2024-01-01', 'OLD-NUMBER'),
                           (1, 'infinity', 'CURRENT-NUMBER');
});

# Only the form's formatting/settings interface is needed for printing totals.
my $form_methods = mock 'TaxPrintForm' => (
    add => [
        get_setting => sub { return 'kg' },
        round_amount => sub {
            return LedgerSMB::PGNumber->new($_[1])->ffround(-$_[2]);
        },
        format_amount => sub {
            return sprintf '%.*f', $_[3] // 0, $_[2] // 0;
        },
        dberror => sub { die $_[1] },
    ]
);
my $numbers = mock 'LedgerSMB::Num2text' => (
    override => [cardinal => sub { return '' }]
);

sub print_invoice {
    my $form = bless {
        dbh => $dbh,
        id => 100,
        transdate => '2026-10-26',
        duedate => '2026-11-01',
        rowcount => 1,
        paidaccounts => 0,
        manual_tax => 1,
        total => 100,
        lineitems => [],
    }, 'TaxPrintForm';
    IS->invoice_details({ numberformat => '1000.00' }, $form);
    return $form;
}

subtest 'Historical rates do not duplicate a saved tax' => sub {
    my $form = print_invoice();
    is $form->{tax}, ['7.00'], 'One saved tax produces one printed tax';
    is $form->{taxbase}, ['100.00'], 'Tax basis is not duplicated';
    is $form->{taxrate}, ['7'], 'The saved manual rate is retained';
    is $form->{taxnumber}, ['CURRENT-NUMBER'], 'Uses the effective tax number';
    is $form->{invtotal}, '107.00', 'Invoice total includes the tax once';
    is $form->{total}, '107.00', 'Amount due includes the tax once';
};

subtest 'The tax number follows the transaction date' => sub {
    for my $date ('2023-12-31', '2024-01-01') {
        $dbh->do(q{UPDATE acc_trans SET transdate = ?}, {}, $date);
        my $form = print_invoice();
        is $form->{taxnumber}, ['OLD-NUMBER'], "Effective number on $date";
        is $form->{invtotal}, '107.00', 'Saved amount remains unchanged';
    }
};

subtest 'Single tax rate remains supported' => sub {
    $dbh->do(q{DELETE FROM tax WHERE validto <> 'infinity'});
    my $form = print_invoice();
    is $form->{tax}, ['7.00'], 'One tax entry';
    is $form->{taxnumber}, ['CURRENT-NUMBER'], 'One tax number';
    is $form->{total}, '107.00', 'Correct amount due';
};

subtest 'Missing tax configuration does not hide a saved manual tax' => sub {
    $dbh->do(q{DELETE FROM tax});
    my $form = print_invoice();
    is $form->{tax}, ['7.00'], 'The saved tax still prints';
    is $form->{taxnumber}, [undef], 'No tax number is invented';
    is $form->{invtotal}, '107.00', 'Saved tax is still included';
};

subtest 'Distinct saved entries with equal amounts are retained' => sub {
    $dbh->do(q{
        UPDATE acc_trans SET amount_tc = 3.5;
        UPDATE tax_extended SET tax_basis = 50;
        INSERT INTO acc_trans VALUES (2, 100, 1, '2026-10-26', 3.5);
        INSERT INTO tax_extended VALUES (2, 50, 0.07);
        INSERT INTO tax VALUES (1, '2024-01-01', 'OLD-NUMBER'),
                               (1, 'infinity', 'CURRENT-NUMBER');
    });
    my $form = print_invoice();
    is $form->{tax}, ['3.50', '3.50'], 'Both saved entries print once';
    is $form->{taxbase}, ['50.00', '50.00'], 'Each saved basis prints once';
    is $form->{invtotal}, '107.00', 'Both saved amounts contribute to the total';
};

$dbh->rollback;
$dbh->disconnect;

done_testing;
