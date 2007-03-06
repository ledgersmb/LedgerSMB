begin;
-- Default chart of accounts -- sample only
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2190','應付所得稅','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','長期負債','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','股份資本','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3500','保留盈餘','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','銷售盈餘','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4300','諮詢盈餘','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','其它盈餘','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','貨銷成本','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','薪資支出','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','日常及管理支出','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','呆帳備抵','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','流動資產','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','資本資產','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','累計分期付款 - 裝璜及設備.','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','累計分期付款 - 運輸工具','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','流動負債','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','銀行借款','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3600','流動盈餘','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2160','應付公司稅','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3590','保留盈餘 - 去年度','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','普通股份','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','存貨資產','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','廣告行銷','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','工具','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','辦公用品','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','權利金','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','會計法務','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','保險','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','分期支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','壞帳','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5680','所得稅','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','利息及銀行手續費','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','薪資','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','保險支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','退休金支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5440','補償金支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5470','員工福利','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4030','銷售 / 軟體','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','利息','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','運費','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','租金','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','庫存 / 軟體','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1540','庫存 / 二級市場零件','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4040','銷售 / 二級市場零件','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5030','貨銷成本 / 軟體','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','採購','A','','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5040','貨銷成本 / 二級市場零件','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','零用金','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','辦公室裝璜及設備','A','','A','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','旅費及娛樂','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','股東貸款','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','註冊費','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','電信費','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5781','網路連線費','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','維修管理費','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2311','地方稅','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','運銷費','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','庫存 / 硬體','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','貨銷成本 / 硬體','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','應付帳款','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','運輸工具','A','','A','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4330','程式設計','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','銷售 / 硬體','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4320','諮詢','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','應收帳款','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1061','支票戶頭','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2310','商品服務稅','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
--
-- exchange rate
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Foreign Exchange Gain','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5810','Foreign Exchange Loss','A','','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.07);
insert into tax (chart_id,rate) values ((select id from chart where accno = '2311'),0.08);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
