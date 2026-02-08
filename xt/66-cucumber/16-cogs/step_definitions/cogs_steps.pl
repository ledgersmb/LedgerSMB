#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

Given qr/^(-?\d+) units sold/, sub {
    my $count = $1;
    my $dbh = S->{ext_lsmb}->admin_dbh;
    if (not defined S->{'the customer'}) {
        my $vc_data = S->{ext_lsmb}->create_vc('customer', 'C01');
        S->{$_} = $vc_data->{$_} for %$vc_data;
    }
    $dbh->do(
        q{
        INSERT INTO ar (invnumber, transdate, invoice, approved,
                        entity_credit_account)
             VALUES ('sale', '2020-01-02', true, true,
                     (select id from entity_credit_account
                       where meta_number=?)
                    );
        },
        {},
        S->{'the customer'},
        )
        or die $dbh->errstr;

    $dbh->do(
        q{
        INSERT INTO invoice (trans_id, parts_id, qty, sellprice, discount,
                             allocated)
               VALUES (currval('id'), (select id from parts where partnumber=?),
                       ?, ?, ?, 0);
        },
        {},
        S->{'the part'},
        $count, 0, 0)
        or die $dbh->errstr;
    $dbh->do(
        q{
        SELECT cogs__add_for_ar_line(currval('invoice_id_seq')::integer)
        }
        )
        or die $dbh->errstr;
};

When qr/^(-?\d+) units are purchased at (\d+) ([A-Z]{3,3}) each$/, sub {
    my $count = $1;
    my $price = $2;
    my $curr  = $3;
    my $dbh   = S->{ext_lsmb}->admin_dbh;

    $dbh->do(
        q{
        INSERT INTO gl (reference, transdate, approved)
                VALUES ('PUR', '2020-01-01', true)
        }
        )
        or die $dbh->errstr;
    $dbh->do(
        q{
        INSERT INTO invoice (trans_id, parts_id, qty, sellprice, discount,
                             allocated)
             VALUES (currval('id'), (select id from parts where partnumber=?),
                     ?, ?, ?, 0)
        },
        {},
        S->{'the part'},
        -$count, $price, 0)
        or die $dbh->errstr;
    $dbh->do(
        q{
        INSERT INTO acc_trans (trans_id, chart_id,
                               transdate, invoice_id, approved,
                               amount_bc, amount_tc, curr)
            VALUES (currval('id'), (select id from account where accno='3350'),
                    '2020-01-01', currval('invoice_id_seq'), true,
                    ?, ?, ?),
                   (currval('id'), (select id from account where accno='1510'),
                    '2020-01-01', currval('invoice_id_seq'), true,
                    ?, ?, ?);
        },
        {},
        $count*$price, $count*$price, $curr,
        -$count*$price, -$count*$price, $curr)
        or die $dbh->errstr;
    $dbh->do(
        q{
        SELECT cogs__add_for_ap_line(currval('invoice_id_seq')::integer)
        }
        )
        or die $dbh->errstr;
};

my $sales_count = 0;

When qr/^(-?\d+) units are sold$/, sub {
    my $count = $1;
    my $dbh = S->{ext_lsmb}->admin_dbh;
    if (not defined S->{'the customer'}) {
        my $vc_data = S->{ext_lsmb}->create_vc('customer', 'C01');
        S->{$_} = $vc_data->{$_} for %$vc_data;
    }
    $sales_count++;
    $dbh->do(
        q{
        INSERT INTO ar (invnumber, transdate, invoice, approved,
                        entity_credit_account)
             VALUES (?, '2020-01-02', true, true,
                     (select id from entity_credit_account
                       where meta_number=?)
                    );
        },
        {},
        "sale-$sales_count",
        S->{'the customer'},
        )
        or die $dbh->errstr;

    $dbh->do(
        q{
        INSERT INTO invoice (trans_id, parts_id, qty, sellprice, discount,
                             allocated)
               VALUES (currval('id'), (select id from parts where partnumber=?),
                       ?, ?, ?, 0);
        },
        {},
        S->{'the part'},
        $count, 0, 0)
        or die $dbh->errstr;
    $dbh->do(
        q{
        SELECT cogs__add_for_ar_line(currval('invoice_id_seq')::integer);
        })
        or die $dbh->errstr;
};

When qr/^(\d+) units are credited$/, sub {
    my $count = $1;
    my $dbh = S->{ext_lsmb}->admin_dbh;
    if (not defined S->{'the customer'}) {
        my $vc_data = S->{ext_lsmb}->create_vc('customer', 'C01');
        S->{$_} = $vc_data->{$_} for %$vc_data;
    }
    $sales_count++;
    $dbh->do(
        q{
        INSERT INTO ar (invnumber, transdate, invoice, approved, reverse,
                        entity_credit_account)
             VALUES (?, '2020-01-02', true, true, true,
                     (select id from entity_credit_account
                       where meta_number=?)
                    );
        },
        {},
        "sale-$sales_count",
        S->{'the customer'},
        )
        or die $dbh->errstr;

    $dbh->do(
        q{
        INSERT INTO invoice (trans_id, parts_id, qty, sellprice, discount,
                             allocated)
               VALUES (currval('id'), (select id from parts where partnumber=?),
                       ?, ?, ?, 0);
        },
        {},
        S->{'the part'},
        -$count, 0, 0)
        or die $dbh->errstr;
    $dbh->do(
        q{
        SELECT cogs__add_for_ar_line(currval('invoice_id_seq')::integer);
        })
        or die $dbh->errstr;
};


my %acc_name_map = (
    'the inventory' => 'inventory_accno_id',
    'COGS'          => 'expense_accno_id',
    );

Then qr/^(the inventory|COGS) should be at (\d+) ([A-Z]{3,3})$/, sub {
    my $account = $1;
    my $amount = $2;
    my $curr = $3;
    my $dbh = S->{ext_lsmb}->admin_dbh;

    my $rows = $dbh->selectall_arrayref(
        qq{
        select * from report__balance_sheet(null, null,'ultimo')
         where account_id = (select $acc_name_map{$account}
                               from parts where partnumber = ?)
        },
        { Slice => {} },
        S->{'the part'})
        or die $dbh->errstr;

    # the balance sheet returns technical amounts, assets/expenses as negatives
    is($rows->[0]->{amount} // 0, -1*$2, q{account balance matches expectation});
};


1;
