#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Mock;
use DBI;
use JSON::MaybeXS;
use LedgerSMB::Taxes::Invoice;
use LedgerSMB::Routes::ERP::API::Invoices;
use LedgerSMB::Magic qw( EC_CUSTOMER );

plan skip_all => 'Database tests not enabled' unless $ENV{LSMB_TEST_DB};

my $dbh = DBI->connect('dbi:Pg:dbname=' . $ENV{LSMB_NEW_DB}, undef, undef,
                      { AutoCommit => 0, RaiseError => 1, PrintError => 0 });
$dbh->do(q{
    CREATE TEMP TABLE entity_credit_account (id int, entity_id int);
    CREATE TEMP TABLE eca_to_location
        (credit_id int, location_id int, location_class int);
    CREATE TEMP TABLE entity_to_location
        (entity_id int, location_id int, location_class int);
    CREATE TEMP TABLE location
        (id int, line_one text, city text, state text, mail_code text, country_id int);
    CREATE TEMP TABLE country (id int, short_name text);
    CREATE TEMP TABLE account (id int, accno text, description text);
    CREATE TEMP TABLE eca_tax (eca_id int, chart_id int);
    CREATE TEMP TABLE partstax (parts_id int, chart_id int);
    CREATE TEMP TABLE taxmodule (taxmodule_id int, taxmodulename text);
    CREATE TEMP TABLE tax
        (chart_id int, taxmodule_id int, taxnumber text, rate numeric,
         pass int, minvalue numeric, validto timestamp);
    INSERT INTO entity_credit_account VALUES (1, 10), (2, 20);
    INSERT INTO country VALUES (1, 'US');
    INSERT INTO location VALUES
        (1, 'Account street', 'Seattle', 'WA', '98101', 1),
        (2, 'Entity street', 'Tacoma', 'WA', '98402', 1);
    INSERT INTO eca_to_location VALUES (1, 1, 1);
    INSERT INTO entity_to_location VALUES (10, 2, 1);
    INSERT INTO account VALUES (1, '2150', 'Sales tax'), (2, '2160', 'Other tax');
    INSERT INTO taxmodule VALUES (1, 'Simple'), (2, 'WA');
    INSERT INTO eca_tax VALUES (1, 1), (1, 2);
    INSERT INTO partstax VALUES (1, 1), (1, 2), (3, 1);
    INSERT INTO tax VALUES (1, 1, '', .05, 0, 0, '2024-01-01'),
                          (1, 1, '', .10, 0, 0, 'infinity'),
                          (2, 1, '', .20, 1, 0, 'infinity');
});

sub invoice {
    return {
        eca => { id => 1 }, transdate => '2026-10-26', lines_total => 200,
        lines => [{ part => { id => 1 }, total => 100 },
                  { part => { id => 2 }, total => 100 }],
    };
}

subtest 'Configured providers, eligibility and successive passes' => sub {
    my $taxes = LedgerSMB::Taxes::Invoice->calculate($dbh, invoice(), 2);
    is '' . $taxes->{2150}->{amount}, '10.00', 'Only the taxable line is taxed';
    is '' . $taxes->{2160}->{amount}, '22.00', 'Second pass includes first tax';
    ok !exists $taxes->{2150}->{'base-amount'}, 'No manual tax detail generated';
    my $inv = invoice();
    $inv->{eca}->{id} = 2;
    is(LedgerSMB::Taxes::Invoice->calculate($dbh, $inv, 2), {},
        'Customer without tax eligibility is untaxed');
};

subtest 'Invoice date and provider minimum' => sub {
    my $inv = invoice();
    $inv->{transdate} = '2024-01-01';
    my $taxes = LedgerSMB::Taxes::Invoice->calculate($dbh, $inv, 2);
    is '' . $taxes->{2150}->{amount}, '5.00', 'Inclusive historical rate date';
    $dbh->do('UPDATE tax SET minvalue = 300 WHERE chart_id = 1');
    $taxes = LedgerSMB::Taxes::Invoice->calculate($dbh, invoice(), 2);
    is '' . $taxes->{2150}->{amount}, '0.00', 'Provider minimum is respected';
    $dbh->do('UPDATE tax SET minvalue = 0');
};

subtest 'WA lookup receives billing address and preserves jurisdiction' => sub {
    require './utils/wa-tax-service/WA.pm';
    local $INC{'LedgerSMB/Taxes/WA.pm'} = $INC{'./utils/wa-tax-service/WA.pm'};
    my @urls;
    my $http = mock 'HTTP::Tiny' => (override => [get => sub {
        push @urls, $_[1];
        return { success => 1, content => '<response rate="0.1035" loccode="1726" />' };
    }]);
    $dbh->do('DELETE FROM eca_tax WHERE chart_id = 2');
    $dbh->do('UPDATE tax SET taxmodule_id = 2 WHERE chart_id = 1');
    my $inv = invoice();
    push $inv->{lines}->@*, { part => { id => 3 }, total => 50 };
    my $taxes = LedgerSMB::Taxes::Invoice->calculate($dbh, $inv, 2);
    is '' . $taxes->{2150}->{amount}, '15.53', 'Address rate, not fallback rate';
    is $taxes->{2150}->{source}, '1726', 'Jurisdiction saved as accounting source';
    is scalar @urls, 1, 'Provider caches lookup across lines';
    like $urls[0], qr/addr=Account%20street/, 'Account billing address preferred';
    like $urls[0], qr/city=Seattle/, 'City provided';
    like $urls[0], qr/zip=98101/, 'Postal code provided';
    $dbh->do('DELETE FROM eca_to_location');
    LedgerSMB::Taxes::Invoice->calculate($dbh, invoice(), 2);
    like $urls[-1], qr/addr=Entity%20street/, 'Falls back to entity billing address';
};

subtest 'WA service failure keeps existing provider fallback policy' => sub {
    local $INC{'LedgerSMB/Taxes/WA.pm'} = $INC{'./utils/wa-tax-service/WA.pm'};
    my $http = mock 'HTTP::Tiny' => (override => [get => sub {
        return { success => 0, content => 'Test service unavailable' };
    }]);
    my $taxes = LedgerSMB::Taxes::Invoice->calculate($dbh, invoice(), 2);
    is '' . $taxes->{2150}->{amount}, '10.00', 'Uses provider configured fallback';
};

subtest 'Invoice API persists automatic and manual taxes differently' => sub {
    $dbh->do(q{
        CREATE TEMP TABLE currency (curr text);
        INSERT INTO currency VALUES ('USD');
        CREATE TEMP TABLE transactions
            (id serial, approved boolean, transdate date, trans_type_code text,
             notes text, description text, workflow_id int);
        CREATE TEMP TABLE open_item
            (id serial, item_number text, item_type text, account_id int);
        CREATE TEMP TABLE ar
            (trans_id int, open_item_id int, invoice boolean, invnumber text,
             ordnumber text, quonumber text, ponumber text, amount_bc numeric,
             netamount_bc numeric, curr text, amount_tc numeric, netamount_tc numeric,
             taxincluded boolean, crdate date, duedate date, notes text,
             shippingpoint text, shipvia text, person_id int, language_code text,
             entity_credit_account int);
        CREATE TEMP TABLE invoice
            (id serial, trans_id int, parts_id int, description text, qty numeric,
             sellprice numeric, precision int, fxsellprice numeric, discount numeric,
             unit text, deliverydate date, serialnumber text, vendor_sku text, notes text);
        CREATE TEMP TABLE acc_trans
            (entry_id serial, approved boolean, trans_id int, invoice_id int,
             chart_id int, amount_bc numeric, amount_tc numeric, curr text,
             transdate date, source text, memo text, open_item_id int);
        CREATE TEMP TABLE tax_extended (entry_id int, tax_basis numeric, rate numeric);
        ALTER TABLE ar ADD on_hold boolean, ADD reverse boolean,
            ADD is_return boolean, ADD force_closed boolean;
        CREATE TEMP TABLE ap (LIKE ar);
        CREATE TEMP TABLE account_link (account_id int, description text);
        INSERT INTO account VALUES (100, '1200', 'Receivables');
        INSERT INTO account_link VALUES (100, 'AR'), (1, 'AR_tax');
        ALTER TABLE entity_credit_account ADD entity_class int,
            ADD meta_number text, ADD description text, ADD pay_to_name text,
            ADD creditlimit numeric;
        UPDATE entity_credit_account SET entity_class = 2;
        CREATE TEMP TABLE entity (id int, name text, control_code text);
        INSERT INTO entity VALUES (10, 'Test customer', 'TEST');
        CREATE SCHEMA invoice_api_tax_test;
        SET LOCAL search_path = pg_temp, invoice_api_tax_test, public;
        CREATE FUNCTION invoice_api_tax_test.pricematrix__for_customer(int, int, date, numeric, text)
            RETURNS TABLE (sellprice numeric) LANGUAGE sql AS 'SELECT 100::numeric WHERE false';
        CREATE FUNCTION invoice_api_tax_test.credit_limit__used(int)
            RETURNS numeric LANGUAGE sql AS 'SELECT 0::numeric';
    });
    my @actions;
    my $factory = mock 'InvoiceAPITestCompany' => (add => [
        configuration => sub { return $_[0] },
        coa_nodes => sub { return $_[0] },
        get => sub { return bless { id => 'A-100' }, 'InvoiceAPITestAccount' },
        workflows => sub { return $_[0] },
        create => sub { return $_[0] },
        fetch => sub { return $_[0] },
        state => sub { return 'SAVED' },
        get_current_actions => sub { return () },
        id => sub { return 1 },
        execute_action => sub { push @actions, $_[1]; return },
    ]);
    my $eca = mock 'LedgerSMB::Entity::Credit_Account' => (override => [
        get_by_id => sub {
            return bless { id => 1, entity_class => EC_CUSTOMER }, ref $_[0];
        },
    ]);
    my $part = mock 'LedgerSMB::Part' => (override => [
        get_by_partnumber => sub {
            return { id => 1, sellprice => 100, income_accno_id => 200 };
        },
        get_by_id => sub { return { partnumber => 'SERVICE' } },
    ]);
    my $settings = mock 'LedgerSMB::Setting' => (override => [get => sub { return 1 }]);
    my $http = mock 'HTTP::Tiny' => (override => [get => sub {
        return { success => 1, content => '<response rate="0.1035" loccode="1726" />' };
    }]);
    local $INC{'LedgerSMB/Taxes/WA.pm'} = $INC{'./utils/wa-tax-service/WA.pm'};
    my $env = { 'lsmb.db' => $dbh, 'lsmb.settings' => { decimal_places => 2 } };
    my $company = bless {}, 'InvoiceAPITestCompany';
    my $app = mock 'LedgerSMB::Company' => (override => [new => sub { return $company }]);
    LedgerSMB::Router::router('erp/api')->hooks(before => sub { return });
    for my $manual (0, 1, 2) {
        my $body = {
            eca => { type => 'customer', id => 1 }, currency => 'USD',
            account => { accno => '1200' }, 'invoice-number' => "TEST-$manual",
            dates => { book => '2026-10-26' },
            lines => [{ part => { number => 'SERVICE' }, price => 100,
                        price_fixated => \1, discount_type => '%', discount => 0 }],
            ($manual ? (taxes => $manual == 2 ? {} : {
                sales => { tax => { category => '2150' },
                           amount => 7, 'base-amount' => 100 } }) : ()),
        };
        my $json = JSON::MaybeXS->new->encode($body);
        open my $input, '<', \$json or die "Cannot open JSON input: $!";
        my $response = LedgerSMB::Router::router('erp/api')->dispatch({
            %$env, 'lsmb.app' => $dbh, REQUEST_METHOD => 'POST', PATH_INFO => '/invoices',
            QUERY_STRING => '', CONTENT_TYPE => 'application/json',
            CONTENT_LENGTH => length $json, 'psgi.input' => $input,
        });
        is $response->[0], 201, 'Invoice created';
        diag $response->[2]->[0] if $response->[0] != 201;
        my ($id) = $response->[1]->[1] =~ m{\./(\d+)};
        is $dbh->selectrow_array('SELECT count(*) FROM tax_extended te JOIN acc_trans ac USING (entry_id) WHERE trans_id = ?', {}, $id),
            $manual == 1 ? 1 : 0, $manual ? 'Manual details retained' : 'Automatic mode retained';
        my $amount = $dbh->selectrow_array('SELECT amount_tc FROM ar WHERE trans_id = ?', {}, $id);
        is $amount, $manual == 2 ? '100.00' : $manual ? '107.00' : '110.35',
            'Saved invoice includes correct tax';
        is $dbh->selectrow_array('SELECT sum(amount_tc) FROM acc_trans WHERE trans_id = ?', {}, $id),
            '0.00', 'Accounting entries balance';
        my $retrieved = LedgerSMB::Routes::ERP::API::Invoices::_get_invoices_by_id(
            $env, undef, $company, undef, { id => $id });
        is sprintf('%.2f', $retrieved->[2]->{total}), $amount,
            'API retrieval includes saved tax';
        is $retrieved->[2]->{workflow}->{state}, 'SAVED', 'Invoice remains saved';
    }
    is \@actions, ['post', 'post', 'post'], 'Creation only saves; does not approve invoices';
};

$dbh->rollback;
$dbh->disconnect;
done_testing;
