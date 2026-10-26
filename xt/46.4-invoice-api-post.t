#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Mock;
use DBI;
use Plack::Request;
use LedgerSMB::Routes::ERP::API::Invoices;
use LedgerSMB::Workflow::Loader;
use LedgerSMB::Workflow;

plan skip_all => 'Database tests not enabled' unless $ENV{LSMB_TEST_DB};

my $dbh = DBI->connect('dbi:Pg:dbname=' . $ENV{LSMB_NEW_DB}, undef, undef,
                      { AutoCommit => 0, RaiseError => 1, PrintError => 0 });
$dbh->do(q{
    CREATE TEMP TABLE transactions
        (id int, workflow_id int, approved boolean DEFAULT false,
         transdate date, trans_type_code text DEFAULT 'ar');
    CREATE TEMP TABLE ar (trans_id int, invoice boolean);
    CREATE TEMP TABLE ap (trans_id int, invoice boolean);
    CREATE TEMP TABLE account_checkpoint (end_date date);
    CREATE TEMP TABLE workflow
        (workflow_id int PRIMARY KEY, type text, state text, last_update timestamp);
    CREATE TEMP TABLE workflow_context (workflow_id int PRIMARY KEY, context text);
    CREATE TEMP SEQUENCE workflow_history_seq;
    CREATE TEMP TABLE workflow_history
        (workflow_hist_id int, workflow_id int, action text, description text,
         state text, workflow_user text, history_date timestamp);
    CREATE TEMP TABLE posting_test_control (allowed boolean, calls int);
    INSERT INTO posting_test_control VALUES (true, 0);
    CREATE SCHEMA invoice_api_post_test;
    SET LOCAL search_path = pg_temp, invoice_api_post_test, public;
    CREATE FUNCTION invoice_api_post_test.lsmb__is_allowed_role(text[])
        RETURNS boolean LANGUAGE sql AS 'SELECT allowed FROM posting_test_control';
    CREATE FUNCTION invoice_api_post_test.draft_approve(int)
        RETURNS boolean LANGUAGE plpgsql AS $$
        BEGIN
            UPDATE posting_test_control SET calls = calls + 1;
            UPDATE transactions SET approved = true WHERE id = $1;
            RETURN true;
        END $$;
    INSERT INTO transactions (id, workflow_id, transdate) VALUES
        (1, 11, '2026-10-26'), (2, 12, '2026-10-26'),
        (3, 13, '2026-10-26'), (4, 14, '2026-10-26'),
        (5, 15, NULL), (6, 16, '2026-10-26');
    INSERT INTO ar VALUES (1, true), (2, true), (3, true), (4, false), (5, true);
    INSERT INTO ap VALUES (6, true);
    INSERT INTO workflow SELECT workflow_id, 'AR/AP', 'SAVED', now() FROM transactions;
    UPDATE workflow SET state = 'ONHOLD' WHERE workflow_id = 12;
    INSERT INTO workflow_context VALUES (13, '{"batch-id":42}');
});

# Use the real AR/AP workflow XML, conditions, approval action and persister.
# Only the SQL role check and draft_approve are isolated test implementations.
my $factory = LedgerSMB::Workflow::Loader->load(directories => ['workflows']);
my $company;
my $methods = mock 'InvoicePostTestCompany' => (add => [
    dbh => sub { return $dbh },
    workflows => sub { return $_[0] },
    fetch => sub { return $factory->fetch_workflow($company, $_[1], $_[2]) },
]);
$company = bless {}, 'InvoicePostTestCompany';
my $request = Plack::Request->new({ HTTP_ACCEPT => 'application/json' });
my $env = { 'lsmb.db' => $dbh };

sub post_invoice {
    return LedgerSMB::Routes::ERP::API::Invoices::_post_invoice(
        $env, $request, $company, undef, { id => $_[0] });
}

subtest 'Workflow conditions cannot be bypassed by API posting' => sub {
    $dbh->do('UPDATE posting_test_control SET allowed = false');
    is post_invoice('1')->[0], 409, 'Missing draft-post permission blocks posting';
    $dbh->do('UPDATE posting_test_control SET allowed = true');
    $dbh->do(q{INSERT INTO account_checkpoint VALUES ('2026-10-26')});
    is post_invoice('1')->[0], 409, 'Closed period blocks posting';
    $dbh->do('DELETE FROM account_checkpoint');
    is post_invoice('2')->[0], 409, 'Held invoice cannot be posted';
    is post_invoice('3')->[0], 409, 'Batch member cannot be individually posted';
    is post_invoice('5')->[0], 409, 'Incomplete invoice cannot be posted';
    is $dbh->selectrow_array('SELECT calls FROM posting_test_control'), 0,
        'No approval has run';
};

subtest 'Saved invoice posts once; retries return posted state' => sub {
    my $response = post_invoice('1');
    is $response->[0], 200, 'Posting succeeded';
    is $response->[2]->{workflow}->{state}, 'POSTED', 'Result reports POSTED';
    ok $dbh->selectrow_array('SELECT approved FROM transactions WHERE id = 1'),
        'Approval action changed transaction';
    $response = post_invoice('1');
    is $response->[0], 200, 'Retry succeeds';
    is $response->[2]->{workflow}->{state}, 'POSTED', 'Retry reports POSTED';
    is $dbh->selectrow_array('SELECT calls FROM posting_test_control'), 1,
        'Approval action executed once';
    is $dbh->selectrow_array(q{SELECT count(*) FROM workflow_history WHERE action = 'approve'}),
        1, 'Only one approval history entry';
    is post_invoice('6')->[0], 200, 'Vendor invoice uses the same workflow';
};

subtest 'Invalid and non-invoice identifiers' => sub {
    is post_invoice('missing')->[0], 400, 'Invalid id rejected before querying';
    is post_invoice('99')->[0], 404, 'Missing invoice';
    is post_invoice('4')->[0], 404, 'AR transaction is not an invoice';
};

$dbh->rollback;
$dbh->disconnect;
done_testing;
