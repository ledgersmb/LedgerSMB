begin;
--
-- Dutch Chart of Accounts
-- AJ Hettema, Mon, 20 Aug 2001
--
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1000','HUIDIGE ACTIVA','H','','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1061','Bank','A','','A','AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1065','Kas','A','','A','AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1200','Debiteuren','A','','A','AR');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1205','Toelage voor precaire rekeningen','A','','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1500','VOORRAAD ACTIVA','H','','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1520','Voorraad / Hardware','A','','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1530','Voorraad / Software','A','','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1540','Voorraad / Aftermarket Parts','A','','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1800','LANGE TERMIJN ACTIVA','H','','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1820','Inventaris','A','','A','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link,contra) VALUES ('1825','Afschrijving inventaris','A','','A','','1');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1840','Auto','A','','A','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link,contra) VALUES ('1845','Afschrijving auto','A','','A','','1');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2000','HUIDIGE PASSIVA','H','','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2100','Crediteuren','A','','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2160','Niet-rijks Belastingen','A','','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2170','Omzetbelasting','A','','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2190','Vennootschapsbelasting','A','','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2310','BTW hoog','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2311','BTW laag','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2600','LANGE TERMIJN PASSIVA','H','','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2620','Bank Leningen','A','','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2680','Aandelenvermogen','A','','L','AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3300','AANDELEN KAPITAAL','H','','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3350','Aandelen in portefeuille','A','','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3500','WINSTRESERVE','H','','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3590','Winstreserve voorgaande jaren','A','','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3600','Huidige winstreserve','A','','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4000','VERKOOP INKOMSTEN','H','','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4020','Verkoop / Hardware','A','','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4030','Verkoop / Software','A','','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4040','Verkoop / Aftermarket Parts','A','','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4300','CONSULTANCY INKOMSTEN','H','','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4320','Consultancy','A','','I','AR_amount:IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4330','Programmeren','A','','I','AR_amount:IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4400','ANDERE INKOMSTEN','H','','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4430','Verzend & Administratie','A','','I','IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4440','Rente','A','','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4450','Foreign Exchange Gain','A','','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5000','INKOOPPRIJS VERKOPEN','H','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5010','Inkoopkosten algemeen','A','','E','AP_amount:IC_cogs:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5020','Inkoopkosten / Hardware','A','','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5030','Inkoopkosten / Software','A','','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5040','Inkoopkosten / Aftermarket Parts','A','','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5100','Vrachtkosten','A','','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5400','PERSONEELS KOSTEN','H','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5410','Salarissen','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5420','EI Expense','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5430','CPP Expense','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5440','WCB Expense','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5470','Employee Benefits','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5600','GENERAL & ADMINISTRATIVE EXPENSES','H','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5610','Boekhouding- & Rechtkosten','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5615','Reclame- & Promotiekosten','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5620','Slechte Schulden','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5660','Afschrijvingskosten','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5680','Inkomsten Belastingen','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5685','Verzekeringen','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5690','Rente & Bankkosten','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5700','Kantoorvoorzieningen','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5760','Huurkosten','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5765','Reparatie- & Onderhoudskosten','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5780','Telefoonkosten','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5781','Internetkosten','A','','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5785','Reis- & Vermaakkosten','A','','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5790','NUTS Kosten','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5795','Registratie''s','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5800','Licenties','A','','E','AP_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5810','Foreign Exchange Loss','A','','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.19);
insert into tax (chart_id,rate) values ((select id from chart where accno = '2311'),0.06);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
