begin;
-- sample COA for UK
--
SELECT account_heading_save(NULL, '0000', 'Minimal heading', NULL);
SELECT account__save(NULL,'0010','Freehold Property','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0011','Goodwill','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0012','Goodwill Amortisation','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0020','Plant and Machinery','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0021','Plant/Machinery Depreciation','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0030','Office Equipment','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0031','Office Equipment Depreciation','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0040','Furniture and Fixtures','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0041','Furniture/Fixture Depreciation','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0050','Motor Vehicles','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0051','Motor Vehicles Depreciation','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1001','Stock','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1002','Work in Progress','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1100','Debtors Control Account','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1102','Other Debtors','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1103','Prepayments','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1200','Bank Current Account','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1210','Bank Deposit Account','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1220','Building Society Account','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1230','Petty Cash','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1240','Company Credit Card','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1200', '1210', '1220', '1230', '1240');

SELECT account__save(NULL,'2100','Creditors Control Account','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2102','Other Creditors','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2109','Accruals','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2200','VAT - Standard rate','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2205','VAT - Reduced rate','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2209','VAT - Zero rate','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2210','P.A.Y.E. & National Insurance','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2220','Net Wages','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2250','Corporation Tax','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2300','Bank Loan','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2305','Directors loan account','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','Hire Purchase','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2330','Mortgages','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3000','Ordinary Shares','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3010','Preference Shares','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3100','Share Premium Account','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3200','Profit and Loss Account','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4000','Sales','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'4010','Export Sales','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'4009','Discounts Allowed','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4900','Miscellaneous Income','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'4904','Rent Income','I','', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account__save(NULL,'4906','Interest received','I','', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account__save(NULL,'4920','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5000','Materials Purchased','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5001','Materials Imported','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5002','Opening Stock','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5003','Closing Stock','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5200','Packaging','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5201','Discounts Taken','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5202','Carriage','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5203','Import Duty','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5204','Transport Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5205','Equipment Hire','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5220','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6000','Productive Labour','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6001','Cost of Sales Labour','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'6002','Sub-Contractors','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7000','Staff wages & salaries','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7002','Directors Remuneration','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7006','Employers N.I.','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7007','Employers Pensions','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7008','Recruitment Expenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7100','Rent','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7102','Water Rates','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7103','General Rates','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7104','Premises Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7200','Light & heat','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7300','Motor expenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7350','Travelling','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7400','Advertising','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7402','P.R. (Literature & Brochures)','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7403','U.K. Entertainment','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7404','Overseas Entertainment','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7500','Postage and Carriage','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7501','Office Stationery','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7502','Telephone','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7506','Web Site costs','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7600','Legal Fees','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7601','Audit and Accountancy Fees','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7603','Professional Fees','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7701','Office Machine Maintenance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7710','Computer expenses','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7800','Repairs and Renewals','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7801','Cleaning','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7802','Laundry','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7900','Bank Interest Paid','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7901','Bank Charges','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7903','Loan Interest Paid','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7904','H.P. Interest','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8000','Depreciation','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8005','Goodwill Amortisation','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8100','Bad Debt Write Off','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8201','Subscriptions','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8202','Clothing Costs','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8203','Training Costs','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8204','Insurance','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8205','Refreshments','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8500','Dividends','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8600','Corporation Tax','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9999','Suspense Account','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '2200'),0.20);
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '2205'),0.05);
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '2209'),0.00);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id',  (SELECT id FROM account WHERE accno = '1001'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (SELECT id FROM account WHERE accno = '4000'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM account WHERE accno = '5000'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM account WHERE accno = '4920'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM account WHERE accno = '5220'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'GBP:USD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

