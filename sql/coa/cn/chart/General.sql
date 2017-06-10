begin;
-- Default chart of accounts -- sample only
SELECT account_heading_save(NULL, '1000', '流动资产', NULL);
SELECT account_heading_save(NULL, '1800', '资本资产', NULL);
SELECT account_heading_save(NULL, '2600', '长期负债', NULL);
SELECT account_heading_save(NULL, '3300', '股份资本', NULL);
SELECT account_heading_save(NULL, '2000', '流动负债', NULL);
SELECT account_heading_save(NULL, '3500', '保留盈馀', NULL);
SELECT account_heading_save(NULL, '4000', '销售盈馀', NULL);
SELECT account_heading_save(NULL, '4300', '谘询盈馀', NULL);
SELECT account_heading_save(NULL, '4400', '其它盈馀', NULL);
SELECT account_heading_save(NULL, '5000', '货销成本', NULL);
SELECT account_heading_save(NULL, '5400', '薪资支出', NULL);
SELECT account_heading_save(NULL, '5600', '日常及管理支出', NULL);
SELECT account_heading_save(NULL, '1500', '存货资产', NULL);
SELECT account__save(NULL,'2190','应付所得税','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1205','呆帐备抵','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','累计分期付款 - 装璜及设备.','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','累计分期付款 - 运输工具','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2620','银行借款','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3600','流动盈馀','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2160','应付公司税','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3590','保留盈馀 - 去年度','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3350','普通股份','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5615','广告行销','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5790','工具','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5700','办公用品','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','权利金','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5610','会计法务','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5685','保险','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5660','分期支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5620','坏帐','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','所得税','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5690','利息及银行手续费','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5410','薪资','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','保险支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','退休金支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','补偿金支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','员工福利','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4030','销售 / 软体','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4440','利息','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5100','运费','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5760','租金','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'1530','库存 / 软体','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','库存 / 二级市场零件','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'4040','销售 / 二级市场零件','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'5030','货销成本 / 软体','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5010','采购','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5040','货销成本 / 二级市场零件','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'1065','零用金','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1820','办公室装璜及设备','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','旅费及娱乐','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','股东贷款','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account__save(NULL,'5795','注册费','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','电信费','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5781','网路连线费','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5765','维修管理费','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'2311','地方税','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4430','运销费','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'1520','库存 / 硬体','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'5020','货销成本 / 硬体','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'2100','应付帐款','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'1840','运输工具','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'4330','程式设计','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4020','销售 / 硬体','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4320','谘询','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'1200','应收帐款','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1061','支票户头','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1061', '1065');

SELECT account__save(NULL,'2310','商品服务税','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
--
-- exchange rate
SELECT account__save(NULL,'4450','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5810','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2310'),0.07);
insert into tax (chart_id,rate) values ((select id from account where accno = '2311'),0.08);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'CAD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

