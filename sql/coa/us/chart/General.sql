begin;
-- US_General COA
-- modify as needed
--
SELECT account_heading_save(NULL,'1000','CURRENT ASSETS', NULL);
SELECT account__save(NULL,'1060','Checking Account','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Petty Cash','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1060', '1065');

SELECT account__save(NULL,'1200','Accounts Receivables','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Allowance for doubtful accounts','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'1500','INVENTORY ASSETS', NULL);
SELECT account__save(NULL,'1510','Inventory','A','', NULL, false, false, string_to_array('IC', ':'), false, false);

SELECT account_heading_save(NULL,'1800','CAPITAL ASSETS', NULL);
SELECT account__save(NULL,'1820','Office Furniture & Equipment','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','Accum. Amort. -Furn. & Equip.','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Vehicle','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','Accum. Amort. -Vehicle','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2000','CURRENT LIABILITIES', NULL);
SELECT account__save(NULL,'2100','Accounts Payable','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL,'2600','LONG TERM LIABILITIES', NULL);
SELECT account__save(NULL,'2620','Bank Loans','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Loans from Shareholders','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL,'3300','SHARE CAPITAL', NULL);
SELECT account__save(NULL,'3350','Common Shares','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3500','RETAINED EARNINGS', NULL);
SELECT account__save(NULL,'3590','Retained Earnings - prior years','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'4000','SALES REVENUE', NULL);
SELECT account__save(NULL,'4010','Sales','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);

SELECT account_heading_save(NULL,'4400','OTHER REVENUE', NULL);
SELECT account__save(NULL,'4430','Shipping & Handling','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Interest','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5000','COST OF GOODS SOLD', NULL);
SELECT account__save(NULL,'5010','Purchases','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);

SELECT account__save(NULL,'5100','Freight','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL,'5400','PAYROLL EXPENSES', NULL);
SELECT account__save(NULL,'5410','Wages & Salaries','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5600','GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account__save(NULL,'5610','Accounting & Legal','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Advertising & Promotions','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Bad Debts','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Amortization Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Interest & Bank Charges','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Office Supplies','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Rent','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Repair & Maintenance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telephone','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Travel & Entertainment','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Utilities','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5795','Registrations','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account__save(NULL,'2110','Accrued Income Tax - Federal','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2120','Accrued Income Tax - State','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2130','Accrued Franchise Tax','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2140','Accrued Real & Personal Prop Tax','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2150','Sales Tax','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2160','Accrued Use Tax Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2210','Accrued Wages','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2220','Accrued Comp Time','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2230','Accrued Holiday Pay','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2240','Accrued Vacation Pay','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','Accr. Benefits - 401K','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2320','Accr. Benefits - Stock Purchase','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2330','Accr. Benefits - Med, Den','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2340','Accr. Benefits - Payroll Taxes','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2350','Accr. Benefits - Credit Union','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2360','Accr. Benefits - Savings Bond','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2370','Accr. Benefits - Garnish','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2380','Accr. Benefits - Charity Cont.','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','Wages - Overtime','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','Benefits - Comp Time','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','Benefits - Payroll Taxes','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5450','Benefits - Workers Comp','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5460','Benefits - Pension','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','Benefits - General Benefits','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5510','Inc Tax Exp - Federal','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5520','Inc Tax Exp - State','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5530','Taxes - Real Estate','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5540','Taxes - Personal Property','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5550','Taxes - Franchise','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5560','Taxes - Foreign Withholding','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2150'),0.05);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1510'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4010'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'USD:CAD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'lbs');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

