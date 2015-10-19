begin;
-- Kontoplan für Österreich
-- Ferdinand Gassauer, Tue, 5 Feb 2002
-- checked and completed, Thu, 7 Feb 2002, Dieter Simader
--
SELECT account_heading_save(NULL, '0000', 'AUFWENDUNGEN FÜR INGANGSETZEN UND ERWEITERN DES BETRIEBES', NULL);
SELECT account__save(NULL,'0010','Firmenwert','A','015', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '0100', 'IMMATERIELLE VERMÖGENSGEGENSTÄNDE', NULL);
SELECT account__save(NULL,'0110','Rechte','A','011', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '0200', 'GRUNDSTÜCKE', NULL);
SELECT account__save(NULL,'0210','unbebaute Grundstücke','A','020', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'0220','bebaute Grundstücke','A','021', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'0229','kum. Abschreibung bebaute Grundstücke','A','039', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '0400', 'MASCHINEN', NULL);
SELECT account__save(NULL,'0410','Maschinen','A','041', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'0419','kum. Abschreibung Maschinen','A','069', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '0500', 'FAHRZEUGE', NULL);
SELECT account__save(NULL,'0510','Fahrzeuge','A','063', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'0519','kum. Abschreibung Fahrzeuge','A','069', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '0600', 'BETRIEBS- UND GESCHÄFTSAUSSTATTUNG', NULL);
SELECT account__save(NULL,'0620','Büroeinrichtungen','A','066', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'0625','kum. Abschreibung Betriebs- und Geschäftsausstattung','A','069', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '0700', 'GELEISTETE ANZAHLUNGEN', NULL);
SELECT account_heading_save(NULL, '0800', 'FINANZANLAGEN', NULL);
SELECT account__save(NULL,'0810','Beteiligungen','A','081', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'0820','Wertpapiere','A','080', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '1100', 'ROHSTOFFE', NULL);
SELECT account__save(NULL,'1120','Vorräte - Rohstoffe','A','110-119', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1200', 'BEZOGENE TEILE', NULL);
SELECT account__save(NULL,'1220','Vorräte - bezogene Teile','A','120-129', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1300', 'HILFS- UND BETRIEBSSTOFFE', NULL);
SELECT account__save(NULL,'1320','Hilfsstoffe','A','130-134', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1350','Betriebssstoffe','A','135-139', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1400', 'UNFERTIGE ERZEUGNISSE', NULL);
SELECT account__save(NULL,'1420','Vorräte - unfertige Erzeugnisse','A','140-149', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1500', 'FERTIGE ERZEUGNISSE', NULL);
SELECT account__save(NULL,'1520','Vorräte - Hardware','A','150-159', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Vorräte - Software','A','150-159', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','Vorräte - Ersatzteile','A','150-159', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1600', 'WAREN', NULL);
SELECT account_heading_save(NULL, '1700', 'NOCH NICHT ABGERECHNETE LEISTUNGEN', NULL);
SELECT account_heading_save(NULL, '1800', 'GELEISTETE ANZAHLUNGEN', NULL);
SELECT account_heading_save(NULL, '1900', 'WERTBERICHTIGUNGEN', NULL);
SELECT account_heading_save(NULL, '2000', 'FORDEUNGEN AUS LIEFERUNGEN UND LEISTUNGEN', NULL);
SELECT account__save(NULL,'2010','Forderungen Lieferung & Leistung','A','200-207', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'2019','Wertberichtigung uneinbringliche Forderungen','A','20-21', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2300', 'SONSTIGE FORDERUNGEN', NULL);
SELECT account__save(NULL,'2320','sonstige Forderungen','A','23-24', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '2500', 'FORDERUNGEN AUS ABGABENVERRECHNUNG', NULL);
SELECT account__save(NULL,'2520','sonstige Forderungen aus Abgebenverrechnung','A','25', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '2600', 'WERTPAPIERE UND ANTEILE', NULL);
SELECT account__save(NULL,'2620','Wertpapiere Umlaufvermögen','A','26', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '2700', 'KASSABESTAND', NULL);
SELECT account__save(NULL,'2701','Kassa','A','27-28', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '2800', 'SCHECKS, GUTHABEN BEI KREDITINSTITUTEN', NULL);
SELECT account__save(NULL,'2810','Schecks','A','27-28', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'2820','Bankguthaben','A','280-288', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3100', 'LANGFRISTIGE VERBINDLICHKEITEN', NULL);
SELECT account__save(NULL,'3110','Bank Verbindlichkeiten','L','31', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3120','Kredite von Eigentümern','L','310', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3300', 'VERBINDLICHKEITEN AUS LIEFERUNGEN UND LEISTUNGEN', NULL);
SELECT account__save(NULL,'3310','Verbindlichkeiten aus Lieferungen und Leistungen','L','330-335', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL, '3500', 'VERBINDLICHKEITEN FINANZAMT', NULL);
SELECT account__save(NULL,'3510','Finanzamt Verrechnung Körperschaftssteuer','L','350-359', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3520','Finanzamt Verrechnung Umsatzsteuer','L','350-359', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3530','Mehrwertsteuer 0%','L','350-359', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3531','Mehrwertsteuer 10%','L','350-359', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3532','Mehrwertsteuer 20%','L','350-359', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3540','Vorsteuer 0%','L','350-359', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3541','Vorsteuer 10%','L','350-359', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3542','Vorsteuer 20%','L','350-359', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account_heading_save(NULL, '4000', 'UMSATZ', NULL);
SELECT account__save(NULL,'4020','Verkauf - Hardware','I','40-44', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','Verkauf - Software ','I','40-44', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4040','Verkauf - Ersatzteile','I','40-44', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '4300', 'UMSATZ BERATUNG', NULL);
SELECT account__save(NULL,'4320','Erlöse Beratung','I','40-44', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4330','Erlöse Programmierung','I','40-44', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '4600', 'SONSTIGE ERLÖSE', NULL);
SELECT account__save(NULL,'4630','Frachterlöse','I','46-49', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '5000', 'WARENEINSATZ', NULL);
SELECT account__save(NULL,'5020','Wareneinsatz / Hardware','E','500-509', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5030','Wareneinsatz / Software','E','500-509', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5040','Wareneinsatz / Ersatzteile','E','520-529', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account_heading_save(NULL, '5600', 'VERBRAUCH BRENN- UND TREIBSTOFFEN, ENERGIE UND WASSER', NULL);
SELECT account__save(NULL,'5610','Energie, Wasser','E','560-569', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '6000', 'LOHNAUFWAND', NULL);
SELECT account__save(NULL,'6010','Lohn ','E','600-619', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '6200', 'GEAHLTSAUFWAND', NULL);
SELECT account__save(NULL,'6210','Gehalt ','E','620-639', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '6500', 'GESETZLICHER SOZIALAUFWAND', NULL);
SELECT account__save(NULL,'6510','Dienstgeberanteile','E','645-649', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '6700', 'FREIWILLIGER SOZIALAUFWAND', NULL);
SELECT account__save(NULL,'6710','freiwilliger Sozialaufwand','E','660-665', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '7000', 'ABSCHREIBUNGEN', NULL);
SELECT account__save(NULL,'7010','Abschreibungen','E','700', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7020','geringwertige Wirtschaftsgüter','E','701-708', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '7100', 'SONSTIGE STEUERN', NULL);
SELECT account__save(NULL,'7110','Ertragssteuern','E','710-719', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7120','Grundsteuern','E','710-719', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '7200', 'INSTANDHALTUNGSAUFWAND', NULL);
SELECT account__save(NULL,'7210','Reparatur und Instandhaltung','E','720-729', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '7300', 'TRANSPORTKOSTEN', NULL);
SELECT account__save(NULL,'7310','Frachtaufwand','E','730-731', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '7400', 'MIET-,PACHT-,LEASING-, LIZENZAUFWAND', NULL);
SELECT account__save(NULL,'7410','Miete','E','740-743', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7411','Lizenzen','E','748-749', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '7600', 'VERWALTUNGSKOSTEN', NULL);
SELECT account__save(NULL,'7610','Beratungsaufwand','E','775-776', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7611','Büromaterialien','E','760', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7615','Werbung und Marketing','E','765-768', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7620','uneinbringliche Forderungen','E','799', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7630','Telephonkosten','E','738-739', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7631','Internetkosten','E','738-739', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'7632','Reise- und Repräsentationsaufwand','E','734-735', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7634','Registrierungsgebühren','E','748-749', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '7700', 'VERSICHERUNGEN', NULL);
SELECT account__save(NULL,'7710','Versicherung','E','770-774', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '8000', 'FINANZERTRÄGE UND FINANZAUFWENDUNGEN', NULL);
SELECT account__save(NULL,'8020','Bankzinsen und Gebühren','E','80-83', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '8100', 'BETEILIGUNGSERTRÄGE', NULL);
SELECT account__save(NULL,'8110','Erträge aus Beteiligungen','I','800-804', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '9000', 'KAPITAL', NULL);
SELECT account__save(NULL,'9010','Aktien, Geschäftsanteile','Q','900-918', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9020','nicht einbezahltes Kapital','Q','919', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '9200', 'KAPITALRÜCKLAGEN', NULL);
SELECT account__save(NULL,'9210','freie Rücklage','Q','920-929', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '9300', 'GEWINN', NULL);
SELECT account__save(NULL,'9310','Gewinnvortrag Vorjahr','Q','980', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9320','Jahresgewinn','Q','985', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '9400', 'RÜCKSTELLUNGEN', NULL);
SELECT account__save(NULL,'9420','Abfertigungsrückstellung','L','300', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9430','Urlaubsrückstellung','L','304-309', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '9700', 'EINLAGEN STILLER GESELLSCHAFTER', NULL);
SELECT account_heading_save(NULL, '9800', 'EB,SB,G+V KONTEN', NULL);
SELECT account__save(NULL,'4640','Devisengewinne','I','80-83', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8050','Devisenverluste','E','80-83', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '3530'),0.00);
insert into tax (chart_id,rate) values ((select id from account where accno = '3531'),0.10);
insert into tax (chart_id,rate) values ((select id from account where accno = '3532'),0.20);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));
INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '7610'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4640'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '8050'));

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
FROM account WHERE accno = '2810';

