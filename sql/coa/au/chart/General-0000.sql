begin;
SELECT account_heading_save(NULL, '2000', 'CURRENT LIABILITIES', NULL);
SELECT account_heading_save(NULL, '2600', 'LONG TERM LIABILITIES', NULL);
SELECT account_heading_save(NULL, '4000', 'SALES REVENUE', NULL);
SELECT account_heading_save(NULL, '5000', 'COST OF GOODS SOLD', NULL);
SELECT account_heading_save(NULL, '5400', 'PAYROLL EXPENSES', NULL);
SELECT account_heading_save(NULL, '5600', 'GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account_heading_save(NULL, '6000', 'CAR EXPENSES', NULL);
SELECT account_heading_save(NULL, '4300', 'OTHER REVENUE', NULL);
SELECT account__save(NULL,'5470','Staff Amenities','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1500', 'STOCK ON HAND', NULL);
SELECT account_heading_save(NULL, '3300', 'EQUITY', NULL);
SELECT account__save(NULL,'1520','SOH / Leather','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1000', 'CURRENT ASSETS', NULL);
SELECT account__save(NULL,'1820','Plant & Equipment - at Cost','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '1825', 'Less: Accumulated Depreciation', 'A','', null, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Motor Vehicles - at Cost','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'1845', 'Less: Accumulated Depreciation', 'A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1800', 'CAPITAL ASSETS', NULL);
SELECT account__save(NULL,'1060','Cheque Account','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);

SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno = '1060';

SELECT account__save(NULL,'1205','Less: Provision Doubtful Debts','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1210','Trade Debtors / Australia - with GST','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1220','Trade Debtors / Exports - GST free','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1230','GST / Refund','A','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1530','SOH / PVC','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','SOH / Fabrics','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1550','SOH / Metal Hardware / Fasteners / Accessories','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1560','SOH / Paint / Glue / Dye','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1570','SOH / Threads / Tapes / Cords / Laces','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1580','SOH / Other Goods','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'2100','Trade Creditors','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','Taxation - Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2210','Workers Compensation - Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2250','Superannuation - Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2260','Insurance - Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2290','GST / Payable','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2300','GST Payments / Refunds','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','GST Adjustments','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3350','Issued & Paid up Capital','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3370','Opening Account Balance','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3380','Credit Payments / Holding Account','Q','', NULL, false, false, string_to_array('AR_paid', ':'), false, false);
SELECT account__save(NULL,'4020','Sales / Manufactured Products','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','Sales / General','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'4410','Shop Labour','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4420','Design / Patternmaking','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4430','Shipping & Handling','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Interest Received','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Foreign Exchange Profit','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4460','Mark-Up / Price Adjustment','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4470','Computer Consultancy / Training','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'2620','Bank Loans','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2640','Hire Purchase','L','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'2650','Other Loans','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5020','COGS / Leather','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5030','COGS / PVC','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5040','COGS / Fabrics','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5050','COGS / Metal Hardware / Fasteners / Accessories','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5060','COGS / Paint / Glue / Dye','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5070','COGS / Threads / Tapes / Cords / Laces','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5080','COGS / Other Goods','E','', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5410','Wages','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','Superannuation','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','Workers Compensation','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5605','External labour costs','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5610','Accountancy','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5611','Legal Fees','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5613','Postage / Printing / Stationery','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5614','Freight and Cartage','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5615','Advertising & Promotions','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5620','Bad Debts','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5650','Capital Cost Allowance Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Interest Expenses','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5670','Depreciation Expenses','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','Taxation','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5686','Security','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Bank Fees And Charges','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5695','Other Fees And Charges','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5700','Office Supplies','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Rent on Land & Buildings','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Repairs & Maintenance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5766','Fixtures & Fittings','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5770','Replacements (tools, etc)','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telephone','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5782','Computer Expenses','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5783','Research & Development','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Travel, Accommodation & Conference','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Hire / Rent of Plant & Equipment ','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5795','Registration & Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5811','Electricity','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5812','Gas','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5813','Sundry Expenses','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5820','Goods & Services for own Use','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6010','M/V Commercial - Fuels / Oils / Parts','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6020','M/V Commercial - Repairs','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6040','M/V Commercial - Reg / Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6080','M/V Private Use - Interest Expenses','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6090','M/V Private Use - Other Expenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6070','M/V Private Use - Depreciation Expenses','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6050','M/V Commercial - Depreciation Expenses','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6060','M/V Commercial - Interest Expenses','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1065','Cash / Paid From Private Accounts','Q','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'3360','Payments for G & S for own Use','Q','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account__save(NULL,'5830','Discounts / Refunds / Rounding','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'3390','Retained Profits','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5840','Fines - NON DEDUCTIBLE EXPENSES','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
INSERT INTO tax (chart_id, rate, taxnumber) VALUES ((SELECT id FROM account WHERE accno = '1230'), 0.1, '');
INSERT INTO tax (chart_id, rate, taxnumber) VALUES ((SELECT id FROM account WHERE accno = '2290'), 0.1, '');
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (SELECT id FROM account WHERE accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (SELECT id FROM account WHERE accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM account WHERE accno = '5020'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM account WHERE accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM account WHERE accno = '5810'));


INSERT INTO currency (curr, description)
   VALUES
      ('AUD', 'AUD');
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'AUD');


 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

