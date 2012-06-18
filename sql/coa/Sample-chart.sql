begin;
-- Default chart of accounts
-- sample only
SELECT account_heading_save(NULL, '1000', 'CURRENT ASSETS', NULL);
SELECT account__save(NULL,'1060','Checking Account','A','', NULL, false,string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Petty Cash','A','', NULL, false,string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1200','Accounts Receivables','A','', NULL, false,string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Allowance for doubtful accounts','A','', NULL, false,string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1500', 'INVENTORY ASSETS', NULL);
SELECT account__save(NULL,'1520','Inventory / General','A','', NULL, false,string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Inventory / Aftermarket Parts','A','', NULL, false,string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1800', 'CAPITAL ASSETS', NULL);
SELECT account__save(NULL,'1820','Office Furniture & Equipment','A','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','Accum. Amort. -Furn. & Equip.','A','', NULL, true,string_to_array('',':'), false, false);
SELECT account__save(NULL,'1840','Vehicle','A','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','Accum. Amort. -Vehicle','A','', NULL, true,string_to_array('',':'), false, false);
SELECT account_heading_save(NULL, '2000', 'CURRENT LIABILITIES', NULL);
SELECT account__save(NULL,'2100','Accounts Payable','L','', NULL, false,string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','Corporate Taxes Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2190','Federal Income Tax Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2210','Workers Comp Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2220','Vacation Pay Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2250','Pension Plan Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2260','Employment Insurance Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2280','Payroll Taxes Payable','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','VAT (10%)','L','', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2320','VAT (14%)','L','', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2330','VAT (30%)','L','', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account_heading_save(NULL, '2600', 'LONG TERM LIABILITIES', NULL);
SELECT account__save(NULL,'2620','Bank Loans','L','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Loans from Shareholders','L','', NULL, false,string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3300', 'SHARE CAPITAL', NULL);
SELECT account__save(NULL,'3350','Common Shares','Q','', NULL, false,string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '4000', 'SALES REVENUE', NULL);
SELECT account__save(NULL,'4020','Sales / General','I','', NULL, false,string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','Sales / Aftermarket Parts','I','', NULL, false,string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '4300', 'CONSULTING REVENUE', NULL);
SELECT account__save(NULL,'4320','Consulting','I','', NULL, false,string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '4400', 'OTHER REVENUE', NULL);
SELECT account__save(NULL,'4430','Shipping & Handling','I','', NULL, false,string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Interest','I','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Foreign Exchange Gain','I','', NULL, false,string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5000', 'COST OF GOODS SOLD', NULL);
SELECT account__save(NULL,'5010','Purchases','E','', NULL, false,string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5020','COGS / General','E','', NULL, false,string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5030','COGS / Aftermarket Parts','E','', NULL, false,string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Freight','E','', NULL, false,string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5400', 'PAYROLL EXPENSES', NULL);
SELECT account__save(NULL,'5410','Wages & Salaries','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','Employment Insurance Expense','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','Pension Plan Expense','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','Workers Comp Expense','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','Employee Benefits','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5600', 'GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account__save(NULL,'5610','Accounting & Legal','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Advertising & Promotions','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Bad Debts','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5650','Capital Cost Allowance Expense','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Amortization Expense','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','Income Taxes','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Insurance','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Interest & Bank Charges','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Office Supplies','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Rent','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Repair & Maintenance','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telephone','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Travel & Entertainment','E','', NULL, false,string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Utilities','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5795','Registrations','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenses','E','', NULL, false,string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Foreign Exchange Loss','E','', NULL, false,string_to_array('', ':'), false, false);
 
SELECT cr_coa_to_account__save(accno, accno || '--' || description, false)
FROM account WHERE id IN (select account_id FROM account_link
                           WHERE description = 'AP_paid');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.1);
insert into tax (chart_id,rate) values ((select id from chart where accno = '2320'),0.14);
insert into tax (chart_id,rate) values ((select id from chart where accno = '2330'),0.3);
--
insert into  defaults (setting_key, value) 
VALUES ('inventory_accno_id', (select id from chart where accno = '1520')); 
INSERT INTO defaults (setting_key, value) 
VALUES ('income_accno_id', (select id from chart where accno = '4020')); 
INSERT INTO defaults (setting_key, value) 
VALUES ('expense_accno_id', (select id from chart where accno = '5010')); 
INSERT INTO defaults (setting_key, value) 
VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));
INSERT INTO defaults (setting_key, value) 
VALUES ('fxloss_accno_id', (select id from chart where accno = '5810'));
INSERT INTO defaults (setting_key, value) 
VALUES ('curr', 'USD:CAD:EUR');
INSERT INTO defaults (setting_key, value) 
VALUES ('weightunit', 'kg');
commit;
