-- Default chart of accounts -- sample only
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2190','应付所得税','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','长期负债','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','股份资本','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3500','保留盈馀','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','销售盈馀','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4300','谘询盈馀','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','其它盈馀','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','货销成本','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','薪资支出','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','日常及管理支出','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','呆帐备抵','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','流动资产','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','资本资产','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','累计分期付款 - 装璜及设备.','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','累计分期付款 - 运输工具','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','流动负债','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','银行借款','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3600','流动盈馀','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2160','应付公司税','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3590','保留盈馀 - 去年度','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','普通股份','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','存货资产','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','广告行销','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','工具','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','办公用品','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','权利金','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','会计法务','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','保险','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','分期支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5620','坏帐','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5680','所得税','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','利息及银行手续费','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','薪资','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','保险支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','退休金支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5440','补偿金支出','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5470','员工福利','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4030','销售 / 软体','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','利息','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','运费','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','租金','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','库存 / 软体','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1540','库存 / 二级市场零件','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4040','销售 / 二级市场零件','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5030','货销成本 / 软体','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','采购','A','','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5040','货销成本 / 二级市场零件','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','零用金','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','办公室装璜及设备','A','','A','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','旅费及娱乐','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','股东贷款','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','注册费','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','电信费','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5781','网路连线费','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','维修管理费','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2311','地方税','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','运销费','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','库存 / 硬体','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','货销成本 / 硬体','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','应付帐款','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','运输工具','A','','A','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4330','程式设计','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','销售 / 硬体','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4320','谘询','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','应收帐款','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1061','支票户头','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2310','商品服务税','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
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

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'CAD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
