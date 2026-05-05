-- To run from other transaction test scripts!

/*
========================================================================
  TEST DATA FOR RECONCILIATION TESTS
========================================================================

This file sets up three independent reconciliation scenarios, each on
its own account.  The shared cast of characters is:

  Transactions used as line sources
  ----------------------------------
  AR transactions (all approved, 10 XTS each):
    -200  1000-01-01   entity_credit -200
    -201  1000-01-03   entity_credit -200
    -204  1000-01-01   entity_credit -200
    -205  1000-01-03   entity_credit -201   ← credit account 2
    -206  1000-01-01   entity_credit -201   ← credit account 2
    -207  1000-01-03   entity_credit -201   ← credit account 2
    -208  1000-01-01   entity_credit -201   ← credit account 2
    -209  1000-01-03   entity_credit -201   ← credit account 2
    -300  1000-01-01   entity_credit -200   ← unapproved lines

  GL transactions:
    -202  1000-01-01  approved   'Recon gl test 1'
    -203  1000-01-01  approved   'Recon gl test 2'
    -210  1000-01-03  approved   'Recon gl test 3'
    -211  1000-01-03  approved   'Recon gl test 4'
    -212  1000-01-03  approved   'Cleared gl trans'           ← cleared; excluded
    -213  1000-01-03  UNAPPROVED 'Unapproved gl trans'        ← unapproved trans; excluded
    -214  1000-01-03  UNAPPROVED 'gl trans, unapproved lines' ← unapproved lines; excluded

  Payment:
    -2010 / payment id -201   1000-01-03  entity_credit -201  account -11112



========================================================================
  SCENARIO 1 — "Test Act 1"  (account -11111)
========================================================================

  This account has NO payment association.
  Reconciliation lines are therefore aggregated by (source, transdate).
  Lines without a source are listed individually (not applicable here
  since all test lines carry a source).

  acc_trans lines written to -11111:
  ┌──────────┬────────────┬──────────┬────────────────────────────────┐
  │ trans_id │ transdate  │ source   │ notes                          │
  ├──────────┼────────────┼──────────┼────────────────────────────────┤
  │  -200    │ 1000-01-01 │ '1'      │ AR                             │
  │  -204    │ 1000-01-01 │ '1'      │ AR  } aggregated together      │
  │  -206    │ 1000-01-01 │ '1'      │ AR                             │
  │  -300    │ 1000-01-01 │ '1'      │ EXCLUDED: unapproved line      │
  ├──────────┼────────────┼──────────┼────────────────────────────────┤
  │  -202    │ 1000-01-01 │ 't gl 1' │ GL  } aggregated together      │
  │  -203    │ 1000-01-01 │ 't gl 1' │ GL                             │
  ├──────────┼────────────┼──────────┼────────────────────────────────┤
  │  -208    │ 1000-01-01 │ '2'      │ AR  (sole line for source '2') │
  ├──────────┼────────────┼──────────┼────────────────────────────────┤
  │  -201    │ 1000-01-03 │ '1'      │ AR                             │
  │  -207    │ 1000-01-03 │ '1'      │ AR  } aggregated together      │
  │  -210    │ 1000-01-03 │ '1'      │ GL                             │
  │  -213    │ 1000-01-03 │ '1'      │ GL  (unapproved *trans*; line  │
  │          │            │          │      itself is approved)       │
  │  -212    │ 1000-01-03 │ '1'      │ EXCLUDED: cleared line         │
  │  -214    │ 1000-01-03 │ '1'      │ EXCLUDED: unapproved line      │
  ├──────────┼────────────┼──────────┼────────────────────────────────┤
  │  -211    │ 1000-01-03 │ 't gl 1' │ GL  (sole line for 't gl 1')   │
  ├──────────┼────────────┼──────────┼────────────────────────────────┤
  │  -209    │ 1000-01-03 │ '2'      │ AR  (sole line for source '2') │
  └──────────┴────────────┴──────────┴────────────────────────────────┘

  Expected reconciliation output (6 aggregate rows):
    1000-01-01  source '1'      amount -30   (3 lines × -10)
    1000-01-01  source 't gl 1' amount -20   (2 lines × -10)
    1000-01-01  source '2'      amount -10   (1 line)
    1000-01-03  source '1'      amount -40   (4 lines × -10)
    1000-01-03  source 't gl 1' amount -10   (1 line)
    1000-01-03  source '2'      amount -10   (1 line)


========================================================================
  SCENARIO 2 — "Test Act 2"  (account -11112)
========================================================================

  This account HAS a payment (payment id -201, date 1000-01-03).
  Reconciliation behaviour:
    • AR lines: ALL acc_trans lines linked to the payment transaction
      (on the G/L account) are collapsed into a single payment line,
      regardless of their individual transdates.
    • GL lines: included only when source matches the payment
      reference AND transdate == payment_date (1000-01-03).
      GL lines with transdate != payment_date are EXCLUDED even if
      the source matches.

  acc_trans lines written to -11112:
  ┌──────────┬────────────┬──────────┬────────────────────────────────────┐
  │ open_item_id │ transdate  │ source   │ notes                              │
  ├──────────┼────────────┼──────────┼────────────────────────────────────┤
  │  -2000    │ 1000-01-01 │ '1'      │ AR → payment_links → payment -201  │
  │  -2001    │ 1000-01-03 │ '1'      │ AR → payment_links → payment -201  │
  │  -2004    │ 1000-01-01 │ '1'      │ AR → payment_links → payment -201  │
  │           (note: -206 intentionally omitted to give -11112 a          │
  │            different row count than -11111)                           │
  │  -2008    │ 1000-01-01 │ '1'      │ AR → payment_links → payment -201  │
  │  -2005    │ 1000-01-03 │ '1'      │ AR → payment_links → payment -201  │
  │  -2007    │ 1000-01-03 │ '1'      │ AR → payment_links → payment -201  │
  │  -2009    │ 1000-01-03 │ '1'      │ AR → payment_links → payment -201  │
  ├──────────┼────────────┼──────────┼────────────────────────────────────┤
  │  -210    │ 1000-01-03 │ '1'      │ GL transdate == payment_date →     │
  │  -211    │ 1000-01-03 │ '1'      │   included in the payment line     │
  │  -213    │ 1000-01-03 │ '1'      │ GL (unapproved trans, approved line│
  │          │            │          │  transdate == payment_date)        │
  ├──────────┼────────────┼──────────┼────────────────────────────────────┤
  │  -202    │ 1000-01-01 │ '1'      │ GL EXCLUDED: transdate ≠ pay. date │
  │  -203    │ 1000-01-01 │ '1'      │ GL EXCLUDED: transdate ≠ pay. date │
  ├──────────┼────────────┼──────────┼────────────────────────────────────┤
  │  -2000    │ 1000-01-01 │ '1'      │ EXCLUDED: cleared + unapproved     │
  │  -212    │ 1000-01-03 │ '1'      │ EXCLUDED: cleared                  │
  │  -214    │ 1000-01-03 │ '1'      │ EXCLUDED: unapproved line          │
  └──────────┴────────────┴──────────┴────────────────────────────────────┘

  Expected reconciliation output (1 aggregate row):
    payment -201  date 1000-01-03  total amount = sum of all included lines

 */


-- ======================================================================
--  LOOKUP HELPER  (used throughout)
-- ======================================================================

CREATE OR REPLACE FUNCTION test_get_account_id(in_accno text) RETURNS int AS
  $$ SELECT id FROM account WHERE accno = $1; $$
  LANGUAGE sql;


-- ======================================================================
--  SHARED WORKFLOW (required by payments)
-- ======================================================================

INSERT INTO workflow (workflow_id, state, type)
VALUES (nextval('workflow_seq'), 'SAVED', 'whatever');


-- ======================================================================
--  ACCOUNTS
-- ======================================================================

CREATE OR REPLACE FUNCTION pg_temp.create_test_account(
    in_id          int,
    in_accno       text,
    in_description text
) RETURNS void AS $$
  INSERT INTO account (id, accno, description, category, heading, contra)
  VALUES (
    in_id,
    in_accno,
    in_description,
    'A',
    (SELECT id FROM account_heading WHERE accno = '000000000000000000000'),
    false
  );
$$ LANGUAGE sql;

SELECT pg_temp.create_test_account(-200, '-11111', 'Test Act 1');
SELECT pg_temp.create_test_account(-201, '-11112', 'Test Act 2');
SELECT pg_temp.create_test_account(-202, '-11113', 'Test Act 3');
SELECT pg_temp.create_test_account(-203, '-11123', 'Test Cash Act');


-- ======================================================================
--  ENTITIES AND CREDIT ACCOUNTS
-- ======================================================================

INSERT INTO entity (id, control_code, name, country_id)
VALUES (-201, '-11111', 'Test 1', 242);

-- Two credit accounts on the same entity, used to give AR transactions
-- different entity_credit_account values (-200 vs -201) so that Scenario 1
-- covers both credit accounts on the same GL account.
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id, curr)
VALUES (-201, -200, 'T-11111', 1, -1000, 'XTS');
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id, curr)
VALUES (-201, -201, 'T-11112', 1, -1000, 'XTS');


INSERT INTO entity (id, control_code, name, country_id)
VALUES (-202, '-11113', 'Test 1', 242);

INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id, curr)
VALUES (-202, -202, 'T-11113', 1, -1000, 'XTS');


-- ======================================================================
--  AR TRANSACTION HELPER
--  Creates a minimal approved AR transaction together with its open item.
-- ======================================================================

CREATE OR REPLACE FUNCTION pg_temp.create_ar_transaction(
    in_trans_id           int,
    in_open_item_id       int,
    in_transdate          date,
    in_invnumber          text,
    in_entity_credit_acct int   -- which entity_credit_account this invoice belongs to
) RETURNS void AS $$
  INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
  VALUES (in_trans_id, in_transdate, 'ar', 'ar', true);

  INSERT INTO open_item (id, item_number, item_type, account_id)
  OVERRIDING SYSTEM VALUE
  VALUES (in_open_item_id, in_invnumber, 'ar',
          test_get_account_id('-11111'));  -- all AR test invoices post to account -11111

  INSERT INTO ar (trans_id, open_item_id, invnumber,
                  amount_bc, netamount_bc, amount_tc, netamount_tc,
                  entity_credit_account, curr)
  VALUES (in_trans_id, in_open_item_id, in_invnumber,
          10, 10, 10, 10, in_entity_credit_acct, 'XTS');
$$ LANGUAGE sql;

-- AR transactions for entity_credit_account -200 (credit acct 1)
SELECT pg_temp.create_ar_transaction(-200, -2000, '1000-01-01', '-2000', -200);
SELECT pg_temp.create_ar_transaction(-201, -2001, '1000-01-03', '-2001', -200);
SELECT pg_temp.create_ar_transaction(-204, -2004, '1000-01-01', '-204',  -200);
SELECT pg_temp.create_ar_transaction(-205, -2003, '1000-01-03', '-2003', -200);

-- AR transactions for entity_credit_account -201 (credit acct 2)
-- These appear alongside credit-acct-1 lines in Scenario 1's account -11111,
-- exercising that the reconciliation aggregates across both credit accounts.
SELECT pg_temp.create_ar_transaction(-206, -2006, '1000-01-01', '-2006', -201);
SELECT pg_temp.create_ar_transaction(-207, -2005, '1000-01-03', '-2005', -201);
SELECT pg_temp.create_ar_transaction(-208, -2008, '1000-01-01', '-2008', -201);
SELECT pg_temp.create_ar_transaction(-209, -2009, '1000-01-03', '-2009', -201);

-- AR transaction with an UNAPPROVED acc_trans line (trans itself is approved).
-- The acc_trans line is inserted below with approved=false, so this row must
-- be excluded from reconciliation output.
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-300, '1000-01-01', 'ar', 'ar', true);
INSERT INTO open_item (id, item_number, item_type, account_id)
OVERRIDING SYSTEM VALUE
VALUES (-3000, '-3000', 'ar', test_get_account_id('-11111'));
INSERT INTO ar (trans_id, open_item_id, invnumber,
                amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, curr)
VALUES (-300, -3000, '-3000', 10, 10, 10, 10, -200, 'XTS');


-- ======================================================================
--  GL TRANSACTION HELPER
--  Creates a GL transaction header.  acc_trans lines are inserted
--  separately because each scenario posts them to different accounts.
-- ======================================================================

CREATE OR REPLACE FUNCTION pg_temp.create_gl_transaction(
    in_trans_id  int,
    in_transdate date,
    in_approved  bool,
    in_reference text
) RETURNS void AS $$
  INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
  VALUES (in_trans_id, in_transdate, 'gl', 'gl', in_approved);

  INSERT INTO gl (id, reference)
  VALUES (in_trans_id, in_reference);
$$ LANGUAGE sql;

-- Approved GL transactions (two per date, so Scenario 1 can test aggregation)
SELECT pg_temp.create_gl_transaction(-202, '1000-01-01', true,  'Recon gl test 1');
SELECT pg_temp.create_gl_transaction(-203, '1000-01-01', true,  'Recon gl test 2');
SELECT pg_temp.create_gl_transaction(-210, '1000-01-03', true,  'Recon gl test 3');
SELECT pg_temp.create_gl_transaction(-211, '1000-01-03', true,  'Recon gl test 4');

-- Edge-case GL transactions; used to verify exclusion logic
SELECT pg_temp.create_gl_transaction(-212, '1000-01-03', true,  'Cleared gl trans');           -- excluded: line is cleared
SELECT pg_temp.create_gl_transaction(-213, '1000-01-03', false, 'Unapproved gl trans');         -- excluded: transaction not approved
SELECT pg_temp.create_gl_transaction(-214, '1000-01-03', false, 'gl trans, unapproved lines');  -- excluded: acc_trans line not approved


-- ======================================================================
--  PAYMENT TRANSACTIONS
-- ======================================================================

-- Payment -201 (approved): the payment that drives Scenario 2 aggregation.
-- All acc_trans lines on account -11112 that belong to trans_id -2010 are
-- collapsed into one reconciliation row; GL lines on -11112 dated 1000-01-03
-- (== payment_date) with the same source are included in that same row.
INSERT INTO transactions (id, table_name, transdate, approved, reference, trans_type_code, workflow_id)
OVERRIDING SYSTEM VALUE
VALUES (-2010, 'payment', '1000-01-03', true, 'reference-test', 'pa',
        null --###BUG: need workflow_id
        );
INSERT INTO payment (trans_id, id, reference, payment_class, payment_date,
                     entity_credit_id, currency, account_id)
VALUES (-2010, -201, 'reference-test', 2, '1000-01-03',
        -201, 'XTS', test_get_account_id('-11123'));

-- Payment -202 (NOT approved): present only so that its acc_trans line can be
-- marked cleared+unapproved and verified as excluded from reconciliation.
INSERT INTO transactions (id, table_name, transdate, approved, reference, trans_type_code, workflow_id)
OVERRIDING SYSTEM VALUE
VALUES (-2011, 'payment', '1000-01-03', false, 'reference-test2', 'pa',
        null --###BUG: need workflow_id
        );
INSERT INTO payment (trans_id, id, reference, payment_class, payment_date,
                     entity_credit_id, currency, account_id)
VALUES (-2011, -202, 'reference-test2', 2, '1000-01-03',
        -201, 'XTS', test_get_account_id('-11123'));


-- ======================================================================
--  SCENARIO 1 — "Test Act 1"  (account -11111, no payment association)
--
--  Lines are aggregated by (transdate, source).
--  Expected output: 6 aggregate rows (see header comment).
-- ======================================================================

-- --- 1000-01-01, source '1' — 3 AR lines → aggregate amount -30 -------
-- (trans -300 also carries source '1' on this date but is excluded because
--  its acc_trans line has approved=false)
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-200, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-204, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-206, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1');

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, cleared, approved)
VALUES (-300, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1', true, false); -- EXCLUDED

-- --- 1000-01-01, source 't gl 1' — 2 GL lines → aggregate amount -20 --
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-202, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-203, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, 't gl 1');

-- --- 1000-01-01, source '2' — 1 AR line → amount -10 ------------------
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-208, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '2');

-- --- 1000-01-03, source '1' — 4 lines (AR + GL) → aggregate amount -40 -
-- Note: trans -213 is an unapproved *transaction* but its acc_trans line is
-- approved=true, so the line itself IS included.
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-201, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-207, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-210, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, cleared)
VALUES (-213, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1', false); -- included (line approved even though trans is not)

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, cleared)
VALUES (-212, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1', true);  -- EXCLUDED: cleared
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, approved)
VALUES (-214, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1', false); -- EXCLUDED: unapproved line

-- --- 1000-01-03, source 't gl 1' — 1 GL line → amount -10 -------------
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-211, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, 't gl 1');

-- --- 1000-01-03, source '2' — 1 AR line → amount -10 ------------------
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-209, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '2');


-- ======================================================================
--  SCENARIO 2 — "Test Act 2"  (account -11112, with payment -201)
--
--  All included lines collapse into a single reconciliation row.
--  Expected output: 1 aggregate row (see header comment).
-- ======================================================================

-- --- AR lines via payment transaction -2010 ----------------------------
-- All posted under trans_id -2010 (the payment transaction).  Different
-- transdates are intentional: the payment aggregation ignores transdate.
-- Trans -206 is intentionally omitted here (cf. account -11111 above) so
-- that the two accounts have a different number of raw acc_trans rows,
-- which catches any bugs that would make the results accidentally equal.
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-2010, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');

-- --- GL lines on payment_date (1000-01-03) with matching source --------
-- These are included in the same aggregate row as the AR lines above.
-- Trans -213 is unapproved at the transaction level but its line is
-- approved, so it is included (same rule as Scenario 1).
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-210, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-211, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-213, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1'); -- included (approved line, unapproved trans)

-- --- GL lines NOT on payment_date → EXCLUDED ---------------------------
-- Same source as the payment but transdate=1000-01-01 ≠ payment_date,
-- so they must not appear in the reconciliation output.
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-202, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1'); -- EXCLUDED: transdate ≠ payment_date
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-203, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1'); -- EXCLUDED: transdate ≠ payment_date

-- --- Cleared / unapproved lines → EXCLUDED -----------------------------
-- These are linked to a submitted+approved cr_report so that the cleared
-- flag is propagated correctly and the exclusion logic can be verified.
SELECT reconciliation__new_report(test_get_account_id('-11112'), 10, '1000-01-04', false,
                                  (SELECT currval('workflow_seq')));

INSERT INTO cr_report_line (report_id, scn, their_balance, our_balance, "user", trans_type, cleared)
VALUES (currval('cr_report_id_seq'), 'test', 10, 10,
        (SELECT entity_id FROM users LIMIT 1), '', true);

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, cleared, approved)
VALUES (-2011, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1', true, false); -- EXCLUDED: cleared + unapproved
INSERT INTO cr_report_line_links (report_line_id, entry_id, cleared)
VALUES (currval('cr_report_line_id_seq'), currval('acc_trans_entry_id_seq'), true);

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, cleared)
VALUES (-212, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1', true);         -- EXCLUDED: cleared
INSERT INTO cr_report_line_links (report_line_id, entry_id, cleared)
VALUES (currval('cr_report_line_id_seq'), currval('acc_trans_entry_id_seq'), true);

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source, approved)
VALUES (-214, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1', false);        -- EXCLUDED: unapproved line

UPDATE cr_report SET submitted = true WHERE id = currval('cr_report_id_seq');
UPDATE cr_report SET approved  = true WHERE id = currval('cr_report_id_seq');


-- ======================================================================
--  SCENARIO 3 — "Test Act 3"  (account -11113)
--
--  Two payments and one GL adjustment, all sharing the same source
--  and transdate, on a separate entity.  Verifies that multiple
--  payments with an identical reference do not collapse into one row.
-- ======================================================================

-- Payment A for Scenario 3
INSERT INTO transactions (transdate, table_name, trans_type_code, approved)
VALUES ('1000-01-01', 'payment', 'pa', true);
INSERT INTO payment (trans_id, id, reference, payment_class, payment_date,
                     entity_credit_id, currency, account_id)
VALUES (currval('transactions_id_seq'), -220, 'equal-reference', 2, '1000-01-01',
        -202, 'XTS', test_get_account_id('-11123'));

-- Payment B for Scenario 3 (same reference as Payment A — intentional)
INSERT INTO transactions (transdate, table_name, trans_type_code, approved)
VALUES ('1000-01-01', 'payment', 'pa', true);
INSERT INTO payment (trans_id, id, reference, payment_class, payment_date,
                     entity_credit_id, currency, account_id)
VALUES (currval('transactions_id_seq'), -221, 'equal-reference', 2, '1000-01-01',
        -202, 'XTS', test_get_account_id('-11123'));

-- GL adjustment transaction for Scenario 3 (same source as both payments)
SELECT pg_temp.create_gl_transaction(-220, '1000-01-01', true, 'Recon adjustment test (act 3)');

-- acc_trans lines for Scenario 3
-- Two AR lines (one per payment) plus one GL adjustment line, all with
-- source '1' on 1000-01-01, to verify they are presented as separate rows.
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-200, test_get_account_id('-11113'), '1000-01-01', 10, 'XTS', 10, '1');

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-201, test_get_account_id('-11113'), '1000-01-01', 10, 'XTS', 10, '1');

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc, source)
VALUES (-220, test_get_account_id('-11113'), '1000-01-01', 10, 'XTS', 10, '1');
