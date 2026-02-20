-- To run from other transaction test scripts!

/*

Summarizing what's happening below:

 1. Create 2 asset accounts
    Test Act 1 -- has no payments associated
      meaning: all lines will be aggregated by source, or lacking
      a source, will be listed individually
    Test Act 2 -- has a payment associated
      meaning: all lines will be aggregated into a single payment line,
      irrespective of the date on the journal lines (which *should*
      all be the same as the payment line, but in this test are not)
 2. Create an entity (to be used as counterparty)
 3. Create two credit accounts for that counterparty
    Credit accounts can issue or receive invoices
 4. Create 8 receivables, of 10 XTS (a test currency) each,
    4 created on 1000-01-01 and another 4 created on 1000-01-03
 5. Create a payment for use on 'Test Act 2'
 6. Create 7 GL transactions, of which 2 on 1000-01-01 and 5 on 1000-01-03
    5 approved, 2 unapproved
 7. Add journal lines with specific source identifiers (simulating payments)
    These journal lines are the real test cases, as they are the
    "pending transactions" inputs.

 */

INSERT INTO workflow (workflow_id, state, type)
VALUES (nextval('workflow_seq'), 'SAVED', 'whatever');


INSERT INTO account(id, accno, description, category, heading, contra)
values (-200, '-11111', 'Test Act 1', 'A',
        (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-201, '-11112', 'Test Act 2', 'A',
        (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO entity (id, control_code, name, country_id)
values (-201, '-11111', 'Test 1', 242);

INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id, curr)
values (-201, -200, 'T-11111', 1, -1000, 'XTS');
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id, curr)
values (-201, -201, 'T-11112', 1, -1000, 'XTS');


INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-200, '1000-01-01', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-200, '-2000', '10', '10', 10, 10, -200, '1000-01-01', 'XTS');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-201, '1000-01-03', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-201, '-2001', '10', '10', 10, 10, -200, '1000-01-03', 'XTS');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-204, '1000-01-01', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-204, '-2002', '10', '10', 10, 10, -200, '1000-01-01', 'XTS');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-205, '1000-01-03', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-205, '-2003', '10', '10', 10, 10, -200, '1000-01-03', 'XTS');

INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-206, '1000-01-01', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-206, '-2004', '10', '10', 10, 10, -201, '1000-01-01', 'XTS');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-207, '1000-01-03', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-207, '-2005', '10', '10', 10, 10, -201, '1000-01-03', 'XTS');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-208, '1000-01-01', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-208, '-2006', '10', '10', 10, 10, -201, '1000-01-01', 'XTS');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
VALUES (-209, '1000-01-03', 'ar', 'ar', true);
INSERT INTO ar (id, invnumber, amount_bc, netamount_bc, amount_tc, netamount_tc,
                entity_credit_account, transdate, curr)
values (-209, '-2007', '10', '10', 10, 10, -201, '1000-01-03', 'XTS');


insert into payment (id, reference, payment_class, payment_date, entity_credit_id, currency)
values (-201, 'reference-test', 2, '1000-01-03', -201, 'XTS');


INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-202, '1000-01-01', 'gl', 'gl', true);
INSERT INTO gl (id, reference, transdate) values (-202, 'Recon gl test 1', '1000-01-01');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-203, '1000-01-01', 'gl', 'gl', true);
INSERT INTO gl (id, reference, transdate) values (-203, 'Recon gl test 2', '1000-01-01');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-210, '1000-01-03', 'gl', 'gl', true);
INSERT INTO gl (id, reference, transdate) values (-210, 'Recon gl test 3', '1000-01-03');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-211, '1000-01-03', 'gl', 'gl', true);
INSERT INTO gl (id, reference, transdate) values (-211, 'Recon gl test 4', '1000-01-03');

INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-212, '1000-01-03', 'gl', 'gl', true);
INSERT INTO gl (id, reference, transdate)
values (-212, 'Cleared gl trans', '1000-01-03');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-213, '1000-01-03', 'gl', 'gl', false);
INSERT INTO gl (id, reference, transdate)
values (-213, 'Unapproved gl trans', '1000-01-03');
INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-214, '1000-01-03', 'gl', 'gl', false);
INSERT INTO gl (id, reference, transdate)
values (-214, 'gl trans, unapproved lines', '1000-01-03');

CREATE OR REPLACE FUNCTION test_get_account_id(in_accno text) returns int as $$ SELECT id FROM account WHERE accno = $1; $$ language sql;


-- Test Act 1; 1000-01-01; source '1'
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-200, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-204, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-206, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1');
-- not approved, so not included
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, cleared, approved)
values (-200, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10, '1', true, false);

-- Test Act 1; 1000-01-01; source 't gl 1'
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-202, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10,'t gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-203, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10,'t gl 1');

-- Test Act 1; 1000-01-01; source '2'
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-208, test_get_account_id('-11111'), '1000-01-01', -10, 'XTS', -10,'2');


-- Test Act 1; 1000-01-03; source '1' (both AR and GL lines)
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-201, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-207, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-210, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, cleared)
values (-213, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1', false);
-- Don't include cleared or unapproved transactions
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, cleared)
values (-212, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, approved)
values (-214, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '1', false);


-- Test Act 1; 1000-01-03; source 't gl 1'
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-211, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10,'t gl 1');

-- Test Act 1; 1000-01-03; source '2'
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-209, test_get_account_id('-11111'), '1000-01-03', -10, 'XTS', -10, '2');


-- Test Act 2; presented as a single line,
--   because all part of the same payment (AR)
--   or with the same source and transdate==payment_date (GL)
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-200, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-201, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-204, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1');
-- id -206 intentionally left out to create a different number of rows in accounts -11111 and -11112
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-208, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10,'1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-205, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-207, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-209, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10,'1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-210, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-211, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10,'1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-213, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1');
-- Don't include GL transactions with the same source, but with a transdate unequal to the payment_date
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-202, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10,'1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-203, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10,'1');


-- Don't include cleared or unapproved transactions
select reconciliation__new_report(test_get_account_id('-11112'), 10, '1000-01-04', false,
                                  (select currval('workflow_seq')));
insert into cr_report_line (report_id, scn, their_balance, our_balance, "user", trans_type, cleared)
values (currval('cr_report_id_seq'), 'test', 10, 10, (select entity_id from users limit 1), '', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, cleared, approved)
values (-200, test_get_account_id('-11112'), '1000-01-01', 10, 'XTS', 10, '1', true, false);
insert into cr_report_line_links (report_line_id, entry_id, cleared)
values (currval('cr_report_line_id_seq'), currval('acc_trans_entry_id_seq'), true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, cleared)
values (-212, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1', true);
insert into cr_report_line_links (report_line_id, entry_id, cleared)
values (currval('cr_report_line_id_seq'), currval('acc_trans_entry_id_seq'), true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source, approved)
values (-214, test_get_account_id('-11112'), '1000-01-03', 10, 'XTS', 10, '1', false);
update cr_report set submitted = true where id = currval('cr_report_id_seq');
update cr_report set approved = true where id = currval('cr_report_id_seq');

insert into payment_links (payment_id, entry_id, type)
select -201, entry_id, 1
  from acc_trans
 where trans_id < 0
       and chart_id = test_get_account_id('-11112')
       and exists (select 1 from ar where ar.id = acc_trans.trans_id);

-- Test Act 3 - 2 payments and an adjustment, all with the same source

INSERT INTO account(id, accno, description, category, heading, contra)
values (-202, '-11113', 'Test Act 3', 'A',
        (select id from account_heading WHERE accno  = '000000000000000000000'), false);


INSERT INTO entity (id, control_code, name, country_id)
values (-202, '-11113', 'Test 1', 242);
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id, curr)
values (-202, -202, 'T-11113', 1, -1000, 'XTS');


insert into payment (id, reference, payment_class, payment_date, entity_credit_id, currency)
values (-220, 'equal-reference', 2, '1000-01-01', -202, 'XTS');
insert into payment (id, reference, payment_class, payment_date, entity_credit_id, currency)
values (-221, 'equal-reference', 2, '1000-01-01', -202, 'XTS');


INSERT INTO transactions (id, transdate, table_name, trans_type_code, approved)
            values (-220, '1000-01-01', 'gl', 'gl', true);
INSERT INTO gl (id, reference, transdate) values (-220, 'Recon adjustment test (act 3)', '1000-01-01');


INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-200, test_get_account_id('-11113'), '1000-01-01', 10, 'XTS', 10, '1');
INSERT INTO payment_links (payment_id, entry_id, type)
values (-220, currval('acc_trans_entry_id_seq'), 1);

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-201, test_get_account_id('-11113'), '1000-01-01', 10, 'XTS', 10, '1');
INSERT INTO payment_links (payment_id, entry_id, type)
values (-221, currval('acc_trans_entry_id_seq'), 1);


INSERT INTO acc_trans (trans_id, chart_id, transdate, amount_bc, curr, amount_tc,  source)
values (-220, test_get_account_id('-11113'), '1000-01-01', 10, 'XTS', 10, '1');

