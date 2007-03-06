begin;
-- General Canadian COA
-- sample only
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','CURRENT ASSETS','H','1000','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1060','Chequing Account','A','1002','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','Petty Cash','A','1001','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Accounts Receivables','A','1060','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','Allowance for doubtful accounts','A','1063','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTORY ASSETS','H','1120','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','Inventory / General','A','1122','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','Inventory / Aftermarket Parts','A','1122','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1540','Inventory / Raw Materials','A','1122','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','CAPITAL ASSETS','H','1900','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Office Furniture & Equipment','A','1787','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','Accum. Amort. -Furn. & Equip.','A','1788','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Vehicle','A','1742','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','Accum. Amort. -Vehicle','A','1743','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','CURRENT LIABILITIES','H','2620','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Accounts Payable','A','2621','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2160','Federal Taxes Payable','A','2683','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2170','Provincial Taxes Payable','A','2684','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2310','GST','A','2685','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2320','PST','A','2686','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2380','Vacation Pay Payable','A','2624','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2390','WCB Payable','A','2627','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2400','PAYROLL DEDUCTIONS','H','2620','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2410','EI Payable','A','2627','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2420','CPP Payable','A','2627','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2450','Income Tax Payable','A','2628','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','LONG TERM LIABILITIES','H','3140','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Bank Loans','A','2701','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Loans from Shareholders','A','2780','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','SHARE CAPITAL','H','3500','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Common Shares','A','3500','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','SALES REVENUE','H','8000','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','General Sales','A','8000','I','AR_amount:IC_sale:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4030','Aftermarket Parts','A','8000','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','OTHER REVENUE','H','8090','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','Shipping & Handling','A','8457','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Interest','A','8090','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Foreign Exchange Gain / (Loss)','A','8231','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','COST OF GOODS SOLD','H','8515','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','Purchases','A','8320','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5050','Aftermarket Parts','A','8320','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','Freight','A','8457','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','PAYROLL EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Wages & Salaries','A','9060','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','EI Expense','A','8622','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','CPP Expense','A','8622','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5440','WCB Expense','A','8622','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','GENERAL & ADMINISTRATIVE EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Accounting & Legal','A','8862','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Advertising & Promotions','A','8520','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','Bad Debts','A','8590','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Amortization Expense','A','8670','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5680','Income Taxes','A','9990','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','Insurance','A','9804','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','Interest & Bank Charges','A','9805','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','Office Supplies','A','8811','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','Rent','A','9811','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','Repair & Maintenance','A','8964','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','Telephone','A','9225','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','Travel & Entertainment','A','8523','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','Utilities','A','8812','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','Licenses','A','8760','E','AP_amount');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.06);
insert into tax (chart_id,rate) values ((select id from chart where accno = '2320'),0.08);
--

INSERT INTO defaults (setting_key, value) values ('inventory_accno_id',  
	(select id from chart where accno = '1520'));
INSERT INTO defaults (setting_key, value) values ('income_accno_id',
	 (select id from chart where accno = '4020')); 
INSERT INTO defaults (setting_key, value) values ('expense_accno_id', 
	(select id from chart where accno = '5010')); 
INSERT INTO defaults (setting_key, value) values ('fxgain_accno_id', 
	(select id from chart where accno = '4450'));
INSERT INTO defaults (setting_key, value) values ('fxloss_accno_id',
 	(select id from chart where accno = '4450')); 
INSERT INTO defaults (setting_key, value) values ('curr', 'CAD:USD:EUR');
INSERT INTO defaults (setting_key, value) values ('weightunit', 'kg');
--
commit;
