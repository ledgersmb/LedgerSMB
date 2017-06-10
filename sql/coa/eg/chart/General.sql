begin;
--
SELECT account_heading_save(NULL, '1000', 'الاصول المتداولة', NULL);
SELECT account_heading_save(NULL, '1500', 'المخزون كاصل', NULL);
SELECT account_heading_save(NULL, '1800', 'الاصول الثابتة', NULL);
SELECT account_heading_save(NULL, '2000', 'التزامات قصيرة الاجل', NULL);
SELECT account_heading_save(NULL, '2600', 'التزامات طويلة الاجل', NULL);
SELECT account__save(NULL,'2210','Workers Comp Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2220','Vacation Pay Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2250','Pension Plan Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2260','Employment Insurance Payable','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','Employment Insurance Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','Pension Plan Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','Workers Comp Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','Employee Benefits','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5650','Capital Cost Allowance Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1060','نقدية بالبنك','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','نقديةبالصندوق','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1060', '1065');

SELECT account__save(NULL,'1520','مخزون - قطع غيار كمبيوتر','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','مخزون - برامج','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','مخزون - قطع اخرى','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1840','سيارات','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1845','مخصص اهلاك سيارات','A','',NULL, true, false, '{}', false, false);
SELECT account__save(NULL,'1820','اثاث مكتبى و معدات','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1825','مخصص اهلاك اثاث مكتبى و معدات','A','',NULL, true, false, '{}', false, false);
SELECT account__save(NULL,'2310','ضريبة مبيعات (10%)','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2320','ضريبة مبيعات (14%)','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2330','ضريبة مبيعات (30%)','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1200','عملاء','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','مخصص ديون معدومة','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2100','موردين','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','ضريبة شركات مستحقة','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2190','ضريبة دخل مستحقة','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2620','قروض من البنوك','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','قروض من حملة الاسهم','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3300', 'حقوق الملكية', NULL);
SELECT account__save(NULL,'4020','مبيعات - قطع غيار','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','مبيعات برامج','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4040','مبيعات اخرى','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '4000', 'ايراد المبيعات', NULL);
SELECT account_heading_save(NULL, '4300', 'ايراد استشارات', NULL);
SELECT account__save(NULL,'4320','استشارات','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4330','برمجة','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '4400', 'ايرادات اخرى', NULL);
SELECT account__save(NULL,'4430','شحن و تعبئة','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','فائدة','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','ارباح تغيير عملة','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5000', 'تكلفة البضاعة المباعة', NULL);
SELECT account__save(NULL,'5010','مشتريات','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5020','تكلفة البضاعة المباعة - قطع غيار','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5030','تكلفة البضاعة المباعة - برامج','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5040','تكلفة البضاعة المباعة - اخرى','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','شحن','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5400', 'مصروفات الاجور', NULL);
SELECT account__save(NULL,'5410','المرتبات','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3350','الاسهم','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5600', 'مصروفات ادارية و عمومية', NULL);
SELECT account__save(NULL,'5610','قانونية و محاسبية','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','دعاية و اعلان','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','اصلاح و صيانة','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5680','ضريبة دخل','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','تامين','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','ديون معدومة ','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','مصاريف اهلاك','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5690','قوائد و مصاريف بنكية','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','مهمات مكتبية','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','تلفون','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','ايجار','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','مصاريف سفر','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5795','رسوم','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','رخص','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','خسارة تحويل عملة','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','مرافق','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'2280','ضرائب مرتبات مستحقة','L','', NULL, false, false, string_to_array('', ':'), false, false);

INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (SELECT id FROM account WHERE accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (SELECT id FROM account WHERE accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM account WHERE accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM account WHERE accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM account WHERE accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'USD:CAD:EUR');

INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno = '2310'),'0.1',NULL);
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno = '2320'),'0.14',NULL);
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno = '2330'),'0.3',NULL);

commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

