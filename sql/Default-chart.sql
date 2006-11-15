begin;
-- Default chart of accounts
-- sample only
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','CURRENT ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1060','Checking Account','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','Petty Cash','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Accounts Receivables','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','Allowance for doubtful accounts','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTORY ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','Inventory / General','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','Inventory / Aftermarket Parts','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','CAPITAL ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Office Furniture & Equipment','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','Accum. Amort. -Furn. & Equip.','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Vehicle','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','Accum. Amort. -Vehicle','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','CURRENT LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Accounts Payable','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2160','Corporate Taxes Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2190','Federal Income Tax Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2210','Workers Comp Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2220','Vacation Pay Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2250','Pension Plan Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2260','Employment Insurance Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2280','Payroll Taxes Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2310','VAT (10%)','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2320','VAT (14%)','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2330','VAT (30%)','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','LONG TERM LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Bank Loans','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Loans from Shareholders','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','SHARE CAPITAL','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Common Shares','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','SALES REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','Sales / General','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4030','Sales / Aftermarket Parts','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4300','CONSULTING REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4320','Consulting','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','OTHER REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','Shipping & Handling','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Interest','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Foreign Exchange Gain','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','COST OF GOODS SOLD','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','Purchases','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','COGS / General','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5030','COGS / Aftermarket Parts','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','Freight','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','PAYROLL EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Wages & Salaries','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','Employment Insurance Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','Pension Plan Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5440','Workers Comp Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5470','Employee Benefits','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','GENERAL & ADMINISTRATIVE EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Accounting & Legal','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Advertising & Promotions','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','Bad Debts','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5650','Capital Cost Allowance Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Amortization Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5680','Income Taxes','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','Insurance','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','Interest & Bank Charges','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','Office Supplies','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','Rent','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','Repair & Maintenance','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','Telephone','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','Travel & Entertainment','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','Utilities','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','Registrations','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','Licenses','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5810','Foreign Exchange Loss','A','','E','');
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
