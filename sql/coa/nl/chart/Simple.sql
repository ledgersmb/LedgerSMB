begin;
--
-- Dutch Chart of Accounts
-- AJ Hettema, Mon, 20 Aug 2001
--
SELECT account_heading_save(NULL,'1000','HUIDIGE ACTIVA', NULL);
SELECT account__save(NULL,'1061','Bank','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Kas','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1200','Debiteuren','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Toelage voor precaire rekeningen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'1500','VOORRAAD ACTIVA', NULL);
SELECT account__save(NULL,'1520','Voorraad / Hardware','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Voorraad / Software','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','Voorraad / Aftermarket Parts','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL,'1800','LANGE TERMIJN ACTIVA', NULL);
SELECT account__save(NULL,'1820','Inventaris','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'1825','Afschrijving inventaris','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Auto','A','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'1845','Afschrijving auto','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2000','HUIDIGE PASSIVA', NULL);
SELECT account__save(NULL,'2100','Crediteuren','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','Niet-rijks Belastingen','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2170','Omzetbelasting','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2190','Vennootschapsbelasting','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','BTW hoog','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2311','BTW laag','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account_heading_save(NULL,'2600','LANGE TERMIJN PASSIVA', NULL);
SELECT account__save(NULL,'2620','Bank Leningen','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Aandelenvermogen','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL,'3300','AANDELEN KAPITAAL', NULL);
SELECT account__save(NULL,'3350','Aandelen in portefeuille','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3500','WINSTRESERVE', NULL);
SELECT account__save(NULL,'3590','Winstreserve voorgaande jaren','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3600','Huidige winstreserve','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'4000','VERKOOP INKOMSTEN', NULL);
SELECT account__save(NULL,'4020','Verkoop / Hardware','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','Verkoop / Software','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4040','Verkoop / Aftermarket Parts','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL,'4300','CONSULTANCY INKOMSTEN', NULL);
SELECT account__save(NULL,'4320','Consultancy','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4330','Programmeren','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL,'4400','ANDERE INKOMSTEN', NULL);
SELECT account__save(NULL,'4430','Verzend & Administratie','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Rente','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5000','INKOOPPRIJS VERKOPEN', NULL);
SELECT account__save(NULL,'5010','Inkoopkosten algemeen','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5020','Inkoopkosten / Hardware','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5030','Inkoopkosten / Software','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5040','Inkoopkosten / Aftermarket Parts','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Vrachtkosten','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL,'5400','PERSONEELS KOSTEN', NULL);
SELECT account__save(NULL,'5410','Salarissen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','EI Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','CPP Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','WCB Expense','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','Employee Benefits','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5600','GENERAL & ADMINISTRATIVE EXPENSES', NULL);
SELECT account__save(NULL,'5610','Boekhouding- & Rechtkosten','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Reclame- & Promotiekosten','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Slechte Schulden','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Afschrijvingskosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','Inkomsten Belastingen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Verzekeringen','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Rente & Bankkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Kantoorvoorzieningen','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Huurkosten','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Reparatie- & Onderhoudskosten','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telefoonkosten','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5781','Internetkosten','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5785','Reis- & Vermaakkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','NUTS Kosten','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5795','Registratie''s','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenties','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2310'),0.19);
insert into tax (chart_id,rate) values ((select id from account where accno = '2311'),0.06);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno = '1061';
