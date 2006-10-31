--
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2210','Workers Comp Payable','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2220','Vacation Pay Payable','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2250','Pension Plan Payable','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2260','Employment Insurance Payable','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5420','Employment Insurance Expense','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5430','Pension Plan Expense','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5440','Workers Comp Expense','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5470','Employee Benefits','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5650','Capital Cost Allowance Expense','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1060','نقدية بالبنك','A','A','AR_paid:AP_paid','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1065','نقديةبالصندوق','A','A','AR_paid:AP_paid','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1520','مخزون - قطع غيار كمبيوتر','A','A','IC','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1530','مخزون - برامج','A','A','IC','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1540','مخزون - قطع اخرى','A','A','IC','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1840','سيارات','A','A','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1000','الاصول المتداولة','H','A','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1500','المخزون كاصل','H','A','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1800','الاصول الثابتة','H','A','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2000','التزامات قصيرة الاجل','H','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2600','التزامات طويلة الاجل','H','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,contra) VALUES ('1845','مخصص اهلاك سيارات','A','A','','','1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1820','اثاث مكتبى و معدات','A','A','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,contra) VALUES ('1825','مخصص اهلاك اثاث مكتبى و معدات','A','A','','','1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2310','ضريبة مبيعات (10%)','A','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2320','ضريبة مبيعات (14%)','A','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2330','ضريبة مبيعات (30%)','A','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1200','عملاء','A','A','AR','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1205','مخصص ديون معدومة','A','A','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2100','موردين','A','L','AP','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2160','ضريبة شركات مستحقة','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2190','ضريبة دخل مستحقة','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2620','قروض من البنوك','A','L','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2680','قروض من حملة الاسهم','A','L','AP_paid','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3300','حقوق الملكية','H','Q','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4020','مبيعات - قطع غيار','A','I','AR_amount:IC_sale','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4030','مبيعات برامج','A','I','AR_amount:IC_sale','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4040','مبيعات اخرى','A','I','AR_amount:IC_sale','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4000','ايراد المبيعات','H','I','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4300','ايراد استشارات','H','I','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4320','استشارات','A','I','AR_amount:IC_income','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4330','برمجة','A','I','AR_amount:IC_income','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4400','ايرادات اخرى','H','I','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4430','شحن و تعبئة','A','I','IC_income','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4440','فائدة','A','I','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4450','ارباح تغيير عملة','A','I','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5000','تكلفة البضاعة المباعة','H','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5010','مشتريات','A','E','AP_amount:IC_cogs:IC_expense','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5020','تكلفة البضاعة المباعة - قطع غيار','A','E','AP_amount:IC_cogs','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5030','تكلفة البضاعة المباعة - برامج','A','E','AP_amount:IC_cogs','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5040','تكلفة البضاعة المباعة - اخرى','A','E','AP_amount:IC_cogs','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5100','شحن','A','E','AP_amount:IC_expense','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5400','مصروفات الاجور','H','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5410','المرتبات','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3350','الاسهم','A','Q','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5600','مصروفات ادارية و عمومية','H','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5610','قانونية و محاسبية','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5615','دعاية و اعلان','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5765','اصلاح و صيانة','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5680','ضريبة دخل','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5685','تامين','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5620','ديون معدومة ','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5660','مصاريف اهلاك','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5690','قوائد و مصاريف بنكية','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5700','مهمات مكتبية','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5780','تلفون','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5760','ايجار','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5785','مصاريف سفر','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5795','رسوم','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5800','رخص','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5810','خسارة تحويل عملة','A','E','','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5790','مرافق','A','E','AP_amount','');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2280','ضرائب مرتبات مستحقة','A','L','','');

 SET inventory_accno_id = (SELECT id FROM chart WHERE accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (SELECT id FROM chart WHERE accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM chart WHERE accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM chart WHERE accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM chart WHERE accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'USD:CAD:EUR';

INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno = '2310'),'0.1',NULL);
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno = '2320'),'0.14',NULL);
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno = '2330'),'0.3',NULL);

