-- US_General COA
-- modify as needed
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','CURRENT ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1060','Checking Account','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','Petty Cash','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Accounts Receivables','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','Allowance for doubtful accounts','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTORY ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1510','Inventory','A','','A','IC');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','CAPITAL ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Office Furniture & Equipment','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','Accum. Amort. -Furn. & Equip.','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Vehicle','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','Accum. Amort. -Vehicle','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','CURRENT LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Accounts Payable','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','LONG TERM LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Bank Loans','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Loans from Shareholders','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','SHARE CAPITAL','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Common Shares','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3500','RETAINED EARNINGS','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3590','Retained Earnings - prior years','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','SALES REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4010','Sales','A','','I','AR_amount:IC_sale');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','OTHER REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','Shipping & Handling','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Interest','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Foreign Exchange Gain','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','COST OF GOODS SOLD','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','Purchases','A','','E','AP_amount:IC_cogs:IC_expense');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','Freight','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','PAYROLL EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Wages & Salaries','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','GENERAL & ADMINISTRATIVE EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Accounting & Legal','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Advertising & Promotions','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','Bad Debts','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Amortization Expense','A','','E','');
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
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2110','Accrued Income Tax - Federal','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2120','Accrued Income Tax - State','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2130','Accrued Franchise Tax','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2140','Accrued Real & Personal Prop Tax','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2150','Sales Tax','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2160','Accrued Use Tax Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2210','Accrued Wages','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2220','Accrued Comp Time','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2230','Accrued Holiday Pay','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2240','Accrued Vacation Pay','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2310','Accr. Benefits - 401K','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2320','Accr. Benefits - Stock Purchase','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2330','Accr. Benefits - Med, Den','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2340','Accr. Benefits - Payroll Taxes','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2350','Accr. Benefits - Credit Union','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2360','Accr. Benefits - Savings Bond','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2370','Accr. Benefits - Garnish','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2380','Accr. Benefits - Charity Cont.','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','Wages - Overtime','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','Benefits - Comp Time','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5440','Benefits - Payroll Taxes','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5450','Benefits - Workers Comp','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5460','Benefits - Pension','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5470','Benefits - General Benefits','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5510','Inc Tax Exp - Federal','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5520','Inc Tax Exp - State','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5530','Taxes - Real Estate','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5540','Taxes - Personal Property','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5550','Taxes - Franchise','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5560','Taxes - Foreign Withholding','A','','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2150'),0.05);
--
update defaults set inventory_accno_id = (select id from chart where accno = '1510'), income_accno_id = (select id from chart where accno = '4010'), expense_accno_id = (select id from chart where accno = '5010'), fxgain_accno_id = (select id from chart where accno = '4450'), fxloss_accno_id = (select id from chart where accno = '5810'), curr = 'USD:CAD:EUR', weightunit = 'lbs';
--
