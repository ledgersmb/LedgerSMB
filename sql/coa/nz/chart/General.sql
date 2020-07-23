begin;
-- New Zealand chart of accounts
-- sample only
--
SELECT account_heading_save(NULL, '10000', 'Assets', NULL);
SELECT account_heading_save(NULL, '10500', 'BANK AND CASH ACCOUNTS', (SELECT id FROM account_heading WHERE accno = '10000'));

SELECT account__save(NULL,'10501','Bank Account','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'10510','Petty Cash','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'10520','Company Credit Card','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description) FROM account WHERE accno in ('10501', '10510', '10520');

SELECT account_heading_save(NULL, '11000', 'CUSTOMERS AND SETTLEMENT ACCOUNTS', (SELECT id FROM account_heading WHERE accno = '10000'));
SELECT account__save(NULL,'11001','Accounts Receivables','A','', NULL, false, false, string_to_array('AR', ':'), false, false);

SELECT account_heading_save(NULL, '12000', 'OTHER CURRENT ASSETS', (SELECT id FROM account_heading WHERE accno = '10000'));
SELECT account__save(NULL,'12001','Allowance for doubtful accounts','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'12002','Prepayments','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'12003','Withholding tax paid','A','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '15000', 'INVENTORY ASSETS', (SELECT id FROM account_heading WHERE accno = '10000'));
SELECT account__save(NULL,'15001','Inventory','A','', NULL, false, false, string_to_array('IC', ':'), false, false);

SELECT account_heading_save(NULL, '16000', 'STATUTORY DEBTORS', (SELECT id FROM account_heading WHERE accno = '10000'));
SELECT account__save(NULL,'16001','INPUT GST','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);

SELECT account_heading_save(NULL, '18000', 'CAPITAL ASSETS', (SELECT id FROM account_heading WHERE accno = '10000'));
SELECT account__save(NULL,'18010','Land and Buildings - At Cost','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18060','Accumulated Depreciation - Land & Buildings','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18030','Office Furniture & Equipment - At Cost','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18070','Accumulated Depreciation -Furniture & Equipment','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18050','Vehicles - At Cost','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18080','Accumulated Depreciation - Vehicles','A','', NULL, true, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '20000', 'Liabilities', NULL);

SELECT account_heading_save(NULL, '20500', 'CURRENT LIABILITIES', (SELECT id FROM account_heading WHERE accno = '20000'));
SELECT account__save(NULL,'20510','Accounts Payable','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'20520','Unearned Revenue','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'20530','Unpaid Expense Claims','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'20540','Suspense Account','L','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '21000', 'STATUTORY CREDITORS', (SELECT id FROM account_heading WHERE accno = '20000'));
SELECT account__save(NULL,'21001','Corporate Taxes Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'21002','OUTPUT GST','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'21004','GST Settlement Account','L','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '22000', 'PAYROLL ACCOUNTS', (SELECT id FROM account_heading WHERE accno = '20000'));
SELECT account__save(NULL,'22010','Workers Net Salary Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'22020','PAYE Witholding Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'22030','Kiwisaver Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '26000', 'LONG TERM LIABILITIES', (SELECT id FROM account_heading WHERE accno = '20000'));
SELECT account__save(NULL,'26010','Bank Loans','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'26020','Shareholder Advances','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);

SELECT account_heading_save(NULL, '30000', 'Total Equity', NULL);

SELECT account_heading_save(NULL, '33000', 'EQUITY', (SELECT id FROM account_heading WHERE accno = '30000'));
SELECT account__save(NULL,'33010','Issued & Paid-up Capital','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'33020','Retained Earnings','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'33030','Shareholder Advances','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'33040','Shareholder Drawings','Q','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '38000', 'Net Margin (P&L Result)', (SELECT id FROM account_heading WHERE accno = '30000'));
SELECT account_heading_save(NULL, '39000', 'Gross Margin', (SELECT id FROM account_heading WHERE accno = '38000'));
SELECT account_heading_save(NULL, '40000', 'Revenue', (SELECT id FROM account_heading WHERE accno = '39000'));

SELECT account_heading_save(NULL, '40500', 'SALES REVENUE', (SELECT id FROM account_heading WHERE accno = '40000'));
SELECT account__save(NULL,'40510','Sales','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'40520','Sales - GST Zero Rated','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);

SELECT account_heading_save(NULL, '40700', 'COST OF GOODS SOLD', (SELECT id FROM account_heading WHERE accno = '40000'));
SELECT account__save(NULL,'40701','Purchases','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'40720','COGS / General','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'40730','Freight','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);

SELECT account_heading_save(NULL, '41000', 'CONSULTING REVENUE', (SELECT id FROM account_heading WHERE accno = '40000'));
SELECT account__save(NULL,'41010','Consulting','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'41020','Consulting - GST Zero Rated','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);

SELECT account_heading_save(NULL, '42000', 'OTHER REVENUE', (SELECT id FROM account_heading WHERE accno = '40000'));
SELECT account__save(NULL,'42001','Interest and Financial Income','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'42020','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'42030','Shipping & Handling','I','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '50000', 'Expenses', (SELECT id FROM account_heading WHERE accno = '38000'));

SELECT account_heading_save(NULL, '54000', 'PAYROLL EXPENSES', (SELECT id FROM account_heading WHERE accno = '50000'));
SELECT account__save(NULL,'54010','Wages & Salaries','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'54020','PAYE Tax Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'54030','Superannuation Plan Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL, '56000', 'GENERAL & ADMINISTRATIVE EXPENSES', (SELECT id FROM account_heading WHERE accno = '50000'));
SELECT account__save(NULL,'56010','Accounting & Legal','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56015','Advertising & Promotions','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56018','Bank Fees & Charges','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'56020','Depreciation Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'56025','Income Taxes','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'56030','Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56035','Office Supplies','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56040','Rent and Rates','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56045','Repair & Maintenance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56050','Telephone, Fax and Internet','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56055','Travel & Entertainment','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'56060','Utilities','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56065','Registrations','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'56070','Licenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);

SELECT account_heading_save(NULL, '58000', 'OTHER EXPENSES', (SELECT id FROM account_heading WHERE accno = '50000'));
SELECT account__save(NULL,'58001','Interest & Bank Charges','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'58002','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'58003','Bad Debts','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '16001'),0.15);
insert into tax (chart_id,rate) values ((select id from account where accno = '21002'),0.15);
--
INSERT INTO defaults (setting_key, value) VALUES ('earn_id', (select id from account where accno = '38000'));
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '15001'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '42020'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '58002'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'NZD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

commit;

 INSERT INTO currency (curr, description)
      VALUES ('NZD', 'NZD'),
             ('AUD', 'AUD'),
             ('USD', 'USD'),
             ('EUR', 'EUR');


UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

