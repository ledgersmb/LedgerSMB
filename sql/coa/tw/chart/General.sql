begin;
-- Default chart of accounts -- sample only
SELECT account_heading_save(NULL,'1000','流動資產', NULL);
SELECT account_heading_save(NULL,'1800','資本資產', NULL);
SELECT account_heading_save(NULL,'2600','長期負債', NULL);
SELECT account_heading_save(NULL,'3300','股份資本', NULL);
SELECT account_heading_save(NULL,'3500','保留盈餘', NULL);
SELECT account_heading_save(NULL,'4000','銷售盈餘', NULL);
SELECT account_heading_save(NULL,'1500','存貨資產', NULL);
SELECT account_heading_save(NULL,'4300','諮詢盈餘', NULL);
SELECT account_heading_save(NULL,'4400','其它盈餘', NULL);
SELECT account_heading_save(NULL,'5000','貨銷成本', NULL);
SELECT account_heading_save(NULL,'5400','薪資支出', NULL);
SELECT account_heading_save(NULL,'5600','日常及管理支出', NULL);
SELECT account__save(NULL,'1205','呆帳備抵','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','累計分期付款 - 裝璜及設備.','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','累計分期付款 - 運輸工具','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2000','流動負債', NULL);
SELECT account__save(NULL,'2190','應付所得稅','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2620','銀行借款','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3600','流動盈餘','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2160','應付公司稅','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3590','保留盈餘 - 去年度','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3350','普通股份','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5615','廣告行銷','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5790','工具','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5700','辦公用品','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','權利金','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5610','會計法務','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5685','保險','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5660','分期支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5620','壞帳','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','所得稅','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5690','利息及銀行手續費','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5410','薪資','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','保險支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','退休金支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','補償金支出','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','員工福利','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4030','銷售 / 軟體','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4440','利息','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5100','運費','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5760','租金','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'1530','庫存 / 軟體','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','庫存 / 二級市場零件','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'4040','銷售 / 二級市場零件','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'5030','貨銷成本 / 軟體','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5010','採購','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5040','貨銷成本 / 二級市場零件','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'1065','零用金','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1820','辦公室裝璜及設備','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','旅費及娛樂','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','股東貸款','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account__save(NULL,'5795','註冊費','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','電信費','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5781','網路連線費','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5765','維修管理費','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'2311','地方稅','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4430','運銷費','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'1520','庫存 / 硬體','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'5020','貨銷成本 / 硬體','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'2100','應付帳款','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'1840','運輸工具','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'4330','程式設計','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4020','銷售 / 硬體','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4320','諮詢','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'1200','應收帳款','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1061','支票戶頭','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1061', '1065');

SELECT account__save(NULL,'2310','商品服務稅','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
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

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

