begin;
-- Australia chart of accounts
-- sample only
--
SELECT account_heading_save(NULL, '10000', 'BANK AND CASH ACCOUNTS', NULL);
SELECT account_save(NULL,'10001','Bank Account','A','100', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'10010','Petty Cash','A','100', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_heading_save(NULL, '11000', 'CUSTOMERS AND SETTLEMENT ACCOUNTS', NULL);
SELECT account_save(NULL,'11001','Accounts Receivables','A','110', NULL, false,string_to_array('AR', ':'));
SELECT account_heading_save(NULL, '12000', 'OTHER CURRENT ASSETS', NULL);
SELECT account_save(NULL,'12001','Allowance for doubtful accounts','A','120', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '15000', 'INVENTORY ASSETS', NULL);
SELECT account_save(NULL,'15001','Inventory / General','A','150', NULL, false,string_to_array('IC', ':'));
SELECT account_save(NULL,'15002','Inventory / Aftermarket Parts','A','150', NULL, false,string_to_array('IC', ':'));
SELECT account_heading_save(NULL, '16000', 'STATUTORY DEBTORS', NULL);
SELECT account_save(NULL,'16001','INPUT GST','L','160', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_heading_save(NULL, '18000', 'CAPITAL ASSETS', NULL);
SELECT account_save(NULL,'18001','Land and Buildings','A','180', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'18002','Accumulated Amortization -Land & Buildings','A','180', NULL, true,string_to_array('', ':'));
SELECT account_save(NULL,'18003','Office Furniture & Equipment','A','180', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'18004','Accumulated Amortization -Furniture & Equipment','A','180', NULL, true,string_to_array('', ':'));
SELECT account_save(NULL,'18005','Vehicle','A','180', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'18006','Accumulated Amortization -Vehicle','A','180', NULL, true,string_to_array('', ':'));
SELECT account_heading_save(NULL, '20000', 'CURRENT LIABILITIES', NULL);
SELECT account_save(NULL,'20001','Accounts Payable','L','200', NULL, false,string_to_array('AP', ':'));
SELECT account_heading_save(NULL, '21000', 'STATUTORY CREDITORS', NULL);
SELECT account_save(NULL,'21001','Corporate Taxes Payable','L','210', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'21002','OUTPUT GST','L','210', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'21003','GST Settlement Account','L','210', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '22000', 'PAYROLL ACCOUNTS', NULL);
SELECT account_save(NULL,'22001','Workers Net Salary Payable','L','220', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'22002','PAYG Witholding Payable','L','220', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'22003','Superannuation Plan Payable','L','220', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '26000', 'LONG TERM LIABILITIES', NULL);
SELECT account_save(NULL,'26001','Bank Loans','L','260', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'26002','Loans from Shareholders','L','260', NULL, false,string_to_array('AP_paid', ':'));
SELECT account_heading_save(NULL, '33000', 'SHARE CAPITAL', NULL);
SELECT account_save(NULL,'33001','Common Shares','Q','330', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '40000', 'SALES REVENUE', NULL);
SELECT account_save(NULL,'40001','Sales / General','I','400', NULL, false,string_to_array('AR_amount:IC_sale', ':'));
SELECT account_save(NULL,'40002','Sales / Aftermarket Parts','I','400', NULL, false,string_to_array('AR_amount:IC_sale', ':'));
SELECT account_heading_save(NULL, '41000', 'CONSULTING REVENUE', NULL);
SELECT account_save(NULL,'41001','Consulting','I','410', NULL, false,string_to_array('AR_amount:IC_income', ':'));
SELECT account_heading_save(NULL, '42000', 'OTHER REVENUE', NULL);
SELECT account_save(NULL,'42001','Interest and Financial Income','I','420', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'42002','Foreign Exchange Gain','I','420', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '50000', 'COST OF GOODS SOLD', NULL);
SELECT account_save(NULL,'50001','Purchases','E','500', NULL, false,string_to_array('AP_amount:IC_cogs:IC_expense', ':'));
SELECT account_save(NULL,'50002','COGS / General','E','500', NULL, false,string_to_array('AP_amount:IC_cogs', ':'));
SELECT account_save(NULL,'50003','COGS / Aftermarket Parts','E','500', NULL, false,string_to_array('AP_amount:IC_cogs', ':'));
SELECT account_save(NULL,'50004','Freight','E','500', NULL, false,string_to_array('AP_amount:IC_expense', ':'));
SELECT account_heading_save(NULL, '54000', 'PAYROLL EXPENSES', NULL);
SELECT account_save(NULL,'54001','Wages & Salaries','E','540', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'54002','PAYG Tax Expense','E','540', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'54003','Superannuation Plan Expense','E','540', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '56000', 'GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account_save(NULL,'56001','Accounting & Legal','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56002','Advertising & Promotions','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56003','Amortization Expense','E','560', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'56004','Income Taxes','E','560', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'56005','Insurance','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56006','Office Supplies','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56007','Rent and Rates','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56008','Repair & Maintenance','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56009','Telephone, Fax and Internet','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56010','Travel & Entertainment','E','560', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'56011','Utilities','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56012','Registrations','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'56013','Licenses','E','560', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_heading_save(NULL, '58000', 'OTHER EXPENSES', NULL);
SELECT account_save(NULL,'58001','Interest & Bank Charges','E','580', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'58002','Foreign Exchange Loss','E','580', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'58003','Bad Debts','E','580', NULL, false,string_to_array('', ':'));
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '16001'),0.1);
insert into tax (chart_id,rate) values ((select id from chart where accno = '21002'),0.1);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '15001'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '40001'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '50001'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '42002'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '58002'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'AUD:USD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

commit;
