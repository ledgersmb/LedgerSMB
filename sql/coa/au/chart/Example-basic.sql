begin;
-- Australia chart of accounts
-- sample only
--
SELECT account_heading_save(NULL, '10000', 'BANK AND CASH ACCOUNTS', NULL);
SELECT account__save(NULL,'10001','Bank Account','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'10010','Petty Cash','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('10001', '10010');

SELECT account_heading_save(NULL, '11000', 'CUSTOMERS AND SETTLEMENT ACCOUNTS', NULL);
SELECT account__save(NULL,'11001','Accounts Receivables','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account_heading_save(NULL, '12000', 'OTHER CURRENT ASSETS', NULL);
SELECT account__save(NULL,'12001','Allowance for doubtful accounts','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '15000', 'INVENTORY ASSETS', NULL);
SELECT account__save(NULL,'15001','Inventory / General','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'15002','Inventory / Aftermarket Parts','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '16000', 'STATUTORY DEBTORS', NULL);
SELECT account__save(NULL,'16001','INPUT GST','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account_heading_save(NULL, '18000', 'CAPITAL ASSETS', NULL);
SELECT account__save(NULL,'18001','Land and Buildings','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18002','Accumulated Amortization -Land & Buildings','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18003','Office Furniture & Equipment','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18004','Accumulated Amortization -Furniture & Equipment','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18005','Vehicle','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'18006','Accumulated Amortization -Vehicle','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '20000', 'CURRENT LIABILITIES', NULL);
SELECT account__save(NULL,'20001','Accounts Payable','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL, '21000', 'STATUTORY CREDITORS', NULL);
SELECT account__save(NULL,'21001','Corporate Taxes Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'21002','OUTPUT GST','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'21003','GST Settlement Account','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '22000', 'PAYROLL ACCOUNTS', NULL);
SELECT account__save(NULL,'22001','Workers Net Salary Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'22002','PAYG Witholding Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'22003','Superannuation Plan Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '26000', 'LONG TERM LIABILITIES', NULL);
SELECT account__save(NULL,'26001','Bank Loans','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'26002','Loans from Shareholders','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '33000', 'SHARE CAPITAL', NULL);
SELECT account__save(NULL,'33001','Common Shares','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '40000', 'SALES REVENUE', NULL);
SELECT account__save(NULL,'40001','Sales / General','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'40002','Sales / Aftermarket Parts','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '41000', 'CONSULTING REVENUE', NULL);
SELECT account__save(NULL,'41001','Consulting','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '42000', 'OTHER REVENUE', NULL);
SELECT account__save(NULL,'42001','Interest and Financial Income','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'42002','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '50000', 'COST OF GOODS SOLD', NULL);
SELECT account__save(NULL,'50001','Purchases','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'50002','COGS / General','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'50003','COGS / Aftermarket Parts','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'50004','Freight','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '60000', 'EXPENSES', NULL);
SELECT account_heading_save(NULL, '61000', 'PAYROLL EXPENSES', NULL);
SELECT account__save(NULL,'61001','Wages & Salaries','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'61002','PAYG Tax Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'61003','Superannuation Plan Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '62000', 'GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account__save(NULL,'62001','Accounting & Legal','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62002','Advertising & Promotions','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62003','Amortization Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'62004','Income Taxes','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'62005','Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62006','Office Supplies','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62007','Rent and Rates','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62008','Repair & Maintenance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62009','Telephone, Fax and Internet','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62010','Travel & Entertainment','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'62011','Utilities','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62012','Registrations','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'62013','Licenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '63000', 'OTHER EXPENSES', NULL);
SELECT account__save(NULL,'63001','Interest & Bank Charges','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'63002','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'63003','Bad Debts','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '16001'),0.1);
insert into tax (chart_id,rate) values ((select id from account where accno = '21002'),0.1);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '15001'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '40001'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '50001'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '42002'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '63002'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'AUD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

commit;

insert into currency (curr, description)
  values ('AUD', 'AUD'),
         ('USD', 'USD'),
         ('EUR', 'EUR');


UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

