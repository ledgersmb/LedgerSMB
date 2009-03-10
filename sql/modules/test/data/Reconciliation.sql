-- To run from other transaction test scripts!

INSERT INTO chart (id, accno, description) values (-200, '-11111', 'Test Acct 1');
INSERT INTO chart (id, accno, description) values (-201, '-11112', 'Test Acct 2');

INSERT INTO entity (id, control_code, name, entity_class) values (-200, '-11111', 'Test 1', 1);

INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class) values (-200, -200, 'T-11111', 1);
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class) values (-200, -201, 'T-11112', 1);


INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-200, '-2000', '10', '10', '0', -200, '1000-01-01');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-201, '-2001', '10', '10', '0', -200, '1000-01-03');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-204, '-2002', '10', '10', '0', -200, '1000-01-01');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-205, '-2003', '10', '10', '0', -200, '1000-01-03');

INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-206, '-2004', '10', '10', '0', -201, '1000-01-01');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-207, '-2005', '10', '10', '0', -201, '1000-01-03');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-208, '-2006', '10', '10', '0', -201, '1000-01-01');
INSERT INTO ar (id, invnumber, amount, netamount, paid, entity_credit_account, transdate) values (-209, '-2007', '10', '10', '0', -201, '1000-01-03');

INSERT INTO gl (id, reference, transdate) values (-202, 'Recon gl test 1', '1000-01-01');
INSERT INTO gl (id, reference, transdate) values (-203, 'Recon gl test 2', '1000-01-01');
INSERT INTO gl (id, reference, transdate) values (-210, 'Recon gl test 3', '1000-01-03');
INSERT INTO gl (id, reference, transdate) values (-211, 'Recon gl test 4', '1000-01-03');
INSERT INTO gl (id, reference, transdate, approved) values (-212, 'Cleared gl trans', '1000-01-03', true);
INSERT INTO gl (id, reference, transdate, approved) values (-213, 'Unapproved gl trans', '1000-01-03', false);
INSERT INTO gl (id, reference, transdate, approved) values (-214, 'gl trans, unapproved lines', '1000-01-03', false);

INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-200, -200, '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared, approved) values (-200, -200, '1000-01-01', -10, '1', true, false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared, approved) values (-200, -201, '1000-01-01', 10, '1', true, false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-200, -201, '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-201, -200, '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-201, -201, '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-202, -200, '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-202, -201, '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-203, -200, '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-203, -201, '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-204, -200, '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-204, -201, '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-205, -200, '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-205, -201, '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-206, -200, '1000-01-01', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-206, -201, '1000-01-01', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-207, -200, '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-207, -201, '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-208, -200, '1000-01-01', -10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-208, -201, '1000-01-01', 10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-209, -200, '1000-01-03', -10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-209, -201, '1000-01-03', 10, '2');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-210, -200, '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-210, -201, '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-211, -200, '1000-01-03', -10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source) values (-211, -201, '1000-01-03', 10, '1');
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-212, -200, '1000-01-03', -10, '1', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-212, -201, '1000-01-03', 10, '1', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-213, -200, '1000-01-03', -10, '1', false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, cleared) values (-213, -201, '1000-01-03', 10, '1', false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, approved) values (-214, -200, '1000-01-03', -10, '1', false);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, source, approved) values (-214, -201, '1000-01-03', 10, '1', false);
