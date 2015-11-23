begin;
-- Default chart of accounts
-- sample only
SELECT account_heading_save(NULL,'1000','KORTFRISTEDE AKTIVER', NULL);
SELECT account__save(NULL,'1061','Bank','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Kasse','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1061', '1065');

SELECT account__save(NULL,'1200','Indbetalinger','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Hensættelser til formodet gæld','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1210','Moms indgående','A','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account_heading_save(NULL,'1500','LAGER-AKTIVER', NULL);
SELECT account__save(NULL,'1520','Lager / udstyr','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Lager / programmel','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','Lager / tillægssalg','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1550','Lager / arrangementer','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL,'1800','AKTIVER', NULL);
SELECT account__save(NULL,'1820','Kontorinventar og -udstyr','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '1825','Samlede afskrivninger, inventar, udstyr', 'A', '', NULL, true, false, '{}'::text[], false, false);
SELECT account__save(NULL,'1840','Køretøjer','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'1845','Samlede afskrivninger, køretøjer','A','', NULL, true, false, '{}'::text[], false, false);
SELECT account_heading_save(NULL,'2000','KORTFRISTET GÆLD', NULL);
SELECT account__save(NULL,'2100','Udbetalinger','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','Selskabsskat','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2190','Afgifter','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2311','Moms udgående','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account_heading_save(NULL,'2600','LANGFRISTET GÆLD', NULL);
SELECT account__save(NULL,'2620','Banklån','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3300','AKTIEKAPITAL', NULL);
SELECT account__save(NULL,'3350','Almindelige aktier','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3500','EGENKAPITAL', NULL);
SELECT account__save(NULL,'3510','Egenkapital primo','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3600','Årets resultat','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'4000','SALGSINDTÆGT', NULL);
SELECT account__save(NULL,'4020','Salg / udstyr','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','Salg / programmel','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4040','Salg / tillægssalg','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4050','Salg / arrangementer','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL,'4300','KONSULENTINDTÆGT', NULL);
SELECT account__save(NULL,'4320','Konsulentbistand','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4330','Programmering','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL,'4400','ANDEN INDTÆGT', NULL);
SELECT account__save(NULL,'4440','Renter','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5000','SALGSOMKOSTNINGER', NULL);
SELECT account__save(NULL,'5020','Omkostninger / udstyr','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5010','Anskaffelser under 8.000','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5011','Anskaffelser over 8.000','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5030','Omkostninger / programmel','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5040','Omkostninger / tillægssalg','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5050','Omkostninger / arrangementer','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Fragt, post','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL,'5400','LØNUDGIFTER', NULL);
SELECT account__save(NULL,'5410','Lønninger og honorarer','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','ATP','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','Personalegoder','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5600','GENERELLE & ADMINISTRATIVE UDGIFTER', NULL);
SELECT account__save(NULL,'5610','Bogføring, revision, advokat','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Marketing','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Dårlige skyldnere','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Afdrag på lån','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','A-skat','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Forsikringer','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Renter og bankgebyrer','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Kontorudgifter','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Husleje','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Vedligeholdelse og reparation','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telefon','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Rejser & repræsentation','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','El, vand, varme','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenser','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '1210'),0.25);
insert into tax (chart_id,rate) values ((select id from account where accno = '2311'),0.25);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'DKK');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

