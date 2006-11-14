-- Australia chart of accounts
-- sample only
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('10000','BANK AND CASH ACCOUNTS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('10001','Bank Account','A','100','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('10010','Petty Cash','A','100','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('11000','CUSTOMERS AND SETTLEMENT ACCOUNTS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('11001','Accounts Receivables','A','110','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('12000','OTHER CURRENT ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('12001','Allowance for doubtful accounts','A','120','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('15000','INVENTORY ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('15001','Inventory / General','A','150','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('15002','Inventory / Aftermarket Parts','A','150','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('16000','STATUTORY DEBTORS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('16001','INPUT GST','A','160','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('18000','CAPITAL ASSETS','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('18001','Land and Buildings','A','180','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('18002','Accumulated Amortization -Land & Buildings','A','180','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('18003','Office Furniture & Equipment','A','180','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('18004','Accumulated Amortization -Furniture & Equipment','A','180','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('18005','Vehicle','A','180','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('18006','Accumulated Amortization -Vehicle','A','180','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('20000','CURRENT LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('20001','Accounts Payable','A','200','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('21000','STATUTORY CREDITORS','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('21001','Corporate Taxes Payable','A','210','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('21002','OUTPUT GST','A','210','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('21003','GST Settlement Account','A','210','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('22000','PAYROLL ACCOUNTS','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('22001','Workers Net Salary Payable','A','220','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('22002','PAYG Witholding Payable','A','220','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('22003','Superannuation Plan Payable','A','220','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('26000','LONG TERM LIABILITIES','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('26001','Bank Loans','A','260','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('26002','Loans from Shareholders','A','260','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('33000','SHARE CAPITAL','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('33001','Common Shares','A','330','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('40000','SALES REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('40001','Sales / General','A','400','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('40002','Sales / Aftermarket Parts','A','400','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('41000','CONSULTING REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('41001','Consulting','A','410','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('42000','OTHER REVENUE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('42001','Interest and Financial Income','A','420','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('42002','Foreign Exchange Gain','A','420','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('50000','COST OF GOODS SOLD','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('50001','Purchases','A','500','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('50002','COGS / General','A','500','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('50003','COGS / Aftermarket Parts','A','500','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('50004','Freight','A','500','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('54000','PAYROLL EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('54001','Wages & Salaries','A','540','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('54002','PAYG Tax Expense','A','540','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('54003','Superannuation Plan Expense','A','540','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56000','GENERAL & ADMINISTRATIVE EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56001','Accounting & Legal','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56002','Advertising & Promotions','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56003','Amortization Expense','A','560','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56004','Income Taxes','A','560','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56005','Insurance','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56006','Office Supplies','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56007','Rent and Rates','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56008','Repair & Maintenance','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56009','Telephone, Fax and Internet','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56010','Travel & Entertainment','A','560','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56011','Utilities','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56012','Registrations','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('56013','Licenses','A','560','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('58000','OTHER EXPENSES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('58001','Interest & Bank Charges','A','580','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('58002','Foreign Exchange Loss','A','580','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('58003','Bad Debts','A','580','E','');
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

