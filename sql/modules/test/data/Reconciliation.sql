-- To run from other transaction test scripts!

INSERT INTO account(id, accno, description, category, heading, contra)
values (-200, '-11111', 'Test Act 1', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-201, '-11112', 'Test Act 1', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO entity (id, control_code, name, entity_class, country_id) values (-201, '-11111', 'Test 1', 1, 242);

INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id) values (-201, -200, 'T-11111', 1, -1000);
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id) values (-201, -201, 'T-11112', 1, -1000);


INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-200, '-2000', '10', '10', '0', -200, '1000-01-01', 'USD');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-201, '-2001', '10', '10', '0', -200, '1000-01-03', 'USD');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-204, '-2002', '10', '10', '0', -200, '1000-01-01', 'USD');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-205, '-2003', '10', '10', '0', -200, '1000-01-03', 'USD');

INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-206, '-2004', '10', '10', '0', -201, '1000-01-01', 'USD');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-207, '-2005', '10', '10', '0', -201, '1000-01-03', 'USD');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-208, '-2006', '10', '10', '0', -201, '1000-01-01', 'USD');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate, curr) values (-209, '-2007', '10', '10', '0', -201, '1000-01-03', 'USD');

INSERT INTO gl (id, reference, transdate) values (-202, 'Recon gl test 1', '1000-01-01');
INSERT INTO gl (id, reference, transdate) values (-203, 'Recon gl test 2', '1000-01-01');
INSERT INTO gl (id, reference, transdate) values (-210, 'Recon gl test 3', '1000-01-03');
INSERT INTO gl (id, reference, transdate) values (-211, 'Recon gl test 4', '1000-01-03');
INSERT INTO gl (id, reference, transdate, approved) values (-212, 'Cleared gl trans', '1000-01-03', true);
INSERT INTO gl (id, reference, transdate, approved) values (-213, 'Unapproved gl trans', '1000-01-03', false);
INSERT INTO gl (id, reference, transdate, approved) values (-214, 'gl trans, unapproved lines', '1000-01-03', false);

CREATE OR REPLACE FUNCTION test_get_account_id(in_accno text) returns int as $$ SELECT id FROM chart WHERE accno = $1; $$ language sql;

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-200, test_get_account_id('-11111'), '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared, approved) values (-200, test_get_account_id('-11111'), '1000-01-01', -10, '1', true, false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared, approved) values (-200, test_get_account_id('-11112'), '1000-01-01', 10, '1', true, false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-200, test_get_account_id('-11112'), '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-201, test_get_account_id('-11111'), '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-201, test_get_account_id('-11112'), '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-202, test_get_account_id('-11111'), '1000-01-01', -10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-202, test_get_account_id('-11112'), '1000-01-01', 10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-203, test_get_account_id('-11111'), '1000-01-01', -10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-203, test_get_account_id('-11112'), '1000-01-01', 10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-204, test_get_account_id('-11111'), '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-204, test_get_account_id('-11112'), '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-205, test_get_account_id('-11111'), '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-205, test_get_account_id('-11112'), '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-206, test_get_account_id('-11111'), '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-206, test_get_account_id('-11112'), '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-207, test_get_account_id('-11111'), '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-207, test_get_account_id('-11112'), '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-208, test_get_account_id('-11111'), '1000-01-01', -10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-208, test_get_account_id('-11112'), '1000-01-01', 10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-209, test_get_account_id('-11111'), '1000-01-03', -10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-209, test_get_account_id('-11112'), '1000-01-03', 10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-210, test_get_account_id('-11111'), '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-210, test_get_account_id('-11112'), '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-211, test_get_account_id('-11111'), '1000-01-03', -10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-211, test_get_account_id('-11112'), '1000-01-03', 10, 't gl 1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-212, test_get_account_id('-11111'), '1000-01-03', -10, '1', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-212, test_get_account_id('-11112'), '1000-01-03', 10, '1', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-213, test_get_account_id('-11111'), '1000-01-03', -10, '1', false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-213, test_get_account_id('-11112'), '1000-01-03', 10, '1', false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, approved) values (-214, test_get_account_id('-11111'), '1000-01-03', -10, '1', false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, approved) values (-214, test_get_account_id('-11112'), '1000-01-03', 10, '1', false);
