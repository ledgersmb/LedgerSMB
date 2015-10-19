begin;
-- General Canadian COA
-- sample only
SELECT account_heading_save(NULL, '1000', 'CURRENT ASSETS', NULL);
SELECT account__save(NULL,'1060','Chequing Account','A','1002', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Petty Cash','A','1001', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1060', '1065');

SELECT account__save(NULL,'1200','Accounts Receivables','A','1060', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Allowance for doubtful accounts','A','1063', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1500', 'INVENTORY ASSETS', NULL);
SELECT account__save(NULL,'1520','Inventory / General','A','1122', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Inventory / Aftermarket Parts','A','1122', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','Inventory / Raw Materials','A','1122', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1800', 'CAPITAL ASSETS', NULL);
SELECT account__save(NULL,'1820','Office Furniture & Equipment','A','1787', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','Accum. Amort. -Furn. & Equip.','A','1788', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Vehicle','A','1742', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','Accum. Amort. -Vehicle','A','1743', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2000', 'CURRENT LIABILITIES', NULL);
SELECT account__save(NULL,'2100','Accounts Payable','L','2621', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','Federal Taxes Payable','L','2683', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2170','Provincial Taxes Payable','L','2684', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','GST','L','2685', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2320','PST','L','2686', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2380','Vacation Pay Payable','L','2624', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2390','WCB Payable','L','2627', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2400', 'PAYROLL DEDUCTIONS', NULL);
SELECT account__save(NULL,'2410','EI Payable','L','2627', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2420','CPP Payable','L','2627', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2450','Income Tax Payable','L','2628', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2600', 'LONG TERM LIABILITIES', NULL);
SELECT account__save(NULL,'2620','Bank Loans','L','2701', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Loans from Shareholders','L','2780', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3300', 'SHARE CAPITAL', NULL);
SELECT account__save(NULL,'3350','Common Shares','Q','3500', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '4000', 'SALES REVENUE', NULL);
SELECT account__save(NULL,'4020','General Sales','I','8000', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'4030','Aftermarket Parts','I','8000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '4400', 'OTHER REVENUE', NULL);
SELECT account__save(NULL,'4430','Shipping & Handling','I','8457', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Interest','I','8090', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4450','Foreign Exchange Gain / (Loss)','I','8231', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5000', 'COST OF GOODS SOLD', NULL);
SELECT account__save(NULL,'5010','Purchases','E','8320', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5050','Aftermarket Parts','E','8320', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Freight','E','8457', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5400', 'PAYROLL EXPENSES', NULL);
SELECT account__save(NULL,'5410','Wages & Salaries','E','9060', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','EI Expense','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','CPP Expense','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','WCB Expense','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5600', 'GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account__save(NULL,'5610','Accounting & Legal','E','8862', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Advertising & Promotions','E','8520', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Bad Debts','E','8590', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Amortization Expense','E','8670', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','Income Taxes','E','9990', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Insurance','E','9804', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Interest & Bank Charges','E','9805', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Office Supplies','E','8811', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Rent','E','9811', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Repair & Maintenance','E','8964', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telephone','E','9225', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Travel & Entertainment','E','8523', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Utilities','E','8812', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenses','E','8760', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2310'),0.05);
insert into tax (chart_id,rate) values ((select id from account where accno = '2320'),0.08);
--

INSERT INTO defaults (setting_key, value) values ('inventory_accno_id',
	(select id from account where accno = '1520'));
INSERT INTO defaults (setting_key, value) values ('income_accno_id',
	 (select id from account where accno = '4020'));
INSERT INTO defaults (setting_key, value) values ('expense_accno_id',
	(select id from account where accno = '5010'));
INSERT INTO defaults (setting_key, value) values ('fxgain_accno_id',
	(select id from account where accno = '4450'));
INSERT INTO defaults (setting_key, value) values ('fxloss_accno_id',
 	(select id from account where accno = '4450'));
INSERT INTO defaults (setting_key, value) values ('curr', 'CAD:USD:EUR');
INSERT INTO defaults (setting_key, value) values ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

