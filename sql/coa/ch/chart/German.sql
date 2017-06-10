begin;
-- Swiss chart of accounts
-- adapted to numeric representation of chart no.
--
SELECT account_heading_save(NULL, '10000', 'AKTIVEN', NULL);
SELECT account_heading_save(NULL, '11000', 'UMLAUFSVERMÖGEN', NULL);
SELECT account_heading_save(NULL, '11100', 'Flüssige Mittel', NULL);
SELECT account__save(NULL,'11102','Bank CS Kt. 177929-11','A','11100', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '11110', 'Forderungen', NULL);
SELECT account_heading_save(NULL, '11120', 'Vorräte und angefangene Arbeiten', NULL);
SELECT account__save(NULL,'11128','Angefangene Arbeiten','A','11120', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'11130','Aktive Rechnungsabgrenzung','A','11000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '14000', 'ANLAGEVERMÖGEN', NULL);
SELECT account_heading_save(NULL, '18000', 'AKTIVIERTER AUFWAND UND AKTIVE BERICHTIGUNGSPOSTEN', NULL);
SELECT account__save(NULL,'18182','Entwicklungsaufwand','A','18000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '20000', 'PASSIVEN', NULL);
SELECT account_heading_save(NULL, '21000', 'FREMDKAPITAL KURZFRISTIG', NULL);
SELECT account_heading_save(NULL, '21200', 'Kurzfristige Verbindlichkeiten aus Lieferungen und Leistungen', NULL);
SELECT account__save(NULL,'21201','Lieferanten','L','21200', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'21202','Personalaufwand','L','21200', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'21203','Sozialversicherungen','L','21200', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'21205','Leasing','L','21200', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL, '21210', 'Kurzfristige Finanzverbindlichkeiten', NULL);
SELECT account_heading_save(NULL, '21220', 'Andere kurzfristige Verbindlichkeiten', NULL);
SELECT account__save(NULL,'21222','MWST (3,6)','L','21220', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'21229','Gewinnausschüttung','L','21220', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '21230', 'Passive Rechnungsabgrenzung, kurzfristige Rückstellungen', NULL);
SELECT account__save(NULL,'21235','Rückstellungen','L','21230', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '24000', 'FREMDKAPITAL LANGFRISTIG', NULL);
SELECT account__save(NULL,'24256','Gesellschafter','L','24000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '28000', 'EIGENKAPITAL', NULL);
SELECT account__save(NULL,'28280','Stammkapital','Q','28000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '28290', 'Reserven, Bilanzgewinn', NULL);
SELECT account__save(NULL,'28291','Reserven','Q','28290', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'28295','Gewinnvortrag','Q','28290', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'28296','Jahresgewinn','Q','28290', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '30000', 'BETRIEBSERTRAG AUS LIEFERUNGEN UND LEISTUNGEN', NULL);
SELECT account_heading_save(NULL, '31000', 'PRODUKTIONSERTRAG', NULL);
SELECT account__save(NULL,'31001','Computer','I','31000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'31005','Übrige Produkte','I','31000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '32000', 'HANDELSERTRAG', NULL);
SELECT account__save(NULL,'32001','Hardware','I','32000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'32002','Software OSS','I','32000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'32003','Software kommerz.','I','32000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'32005','Übrige','I','32000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '34000', 'DIENSTLEISTUNGSERTRAG', NULL);
SELECT account__save(NULL,'34001','Beratung','I','34000', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'34002','Installation','I','34000', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '36000', 'ÜBRIGER ERTRAG', NULL);
SELECT account_heading_save(NULL, '37000', 'EIGENLEISTUNGEN UND EIGENVERBRAUCH', NULL);
SELECT account__save(NULL,'37001','Eigenleistungen','I','37000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'37002','Eigenverbrauch','I','37000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '38000', 'BESTANDESÄNDERUNGEN ANGEFANGENE UND FERTIGGESTELLTE ARBEITUNG AUS PRODUKTION UND DIENSTLEISTUNG', NULL);
SELECT account__save(NULL,'38001','Bestandesänderungen','I','38000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '39000', 'ERTRAGSMINDERUNGEN AUS PRODUKTIONS-, HANDELS- UND DIENSTLEISTUNGSERTRÄGEN', NULL);
SELECT account_heading_save(NULL, '40000', 'AUFWAND FÜR MATERIAL, WAREN UND DIENSTLEISTUNGEN', NULL);
SELECT account_heading_save(NULL, '41000', 'MATERIALAUFWAND', NULL);
SELECT account__save(NULL,'41001','Computer','E','41000', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'41005','Übrige Produkte','E','41000', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account_heading_save(NULL, '42000', 'HANDELSWARENAUFWAND', NULL);
SELECT account__save(NULL,'42001','Hardware','E','42000', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'42002','Software OSS','I','32000', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'42003','Software kommerz.','I','42000', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'42005','Übrige','E','42000', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account_heading_save(NULL, '44000', 'AUFWAND FÜR DRITTLEISTUNGEN', NULL);
SELECT account_heading_save(NULL, '46000', 'ÜBRIGER AUFWAND', NULL);
SELECT account_heading_save(NULL, '47000', 'DIREKTE EINKAUFSSPESEN', NULL);
SELECT account__save(NULL,'47001','Einkaufsspesen','E','47000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '48000', 'BESTANDESVERÄNDERUNGEN, MATERIAL- UND WARENVERLUSTE', NULL);
SELECT account__save(NULL,'48001','Bestandesänderungen','E','48000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '49000', 'AUFWANDMINDERUNGEN', NULL);
SELECT account__save(NULL,'49005','Aufwandminderungen','E','49000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '50000', 'PERSONALAUFWAND', NULL);
SELECT account_heading_save(NULL, '57000', 'SOZIALVERSICHERUNGSAUFWAND', NULL);
SELECT account_heading_save(NULL, '58000', 'ÜBRIGER PERSONALAUFWAND', NULL);
SELECT account__save(NULL,'58005','Sonstiger Personalaufwand','E','58000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '59000', 'ARBEITSLEISTUNGEN DRITTER', NULL);
SELECT account_heading_save(NULL, '60000', 'SONSTIGER BETRIEBSAUFWAND', NULL);
SELECT account_heading_save(NULL, '61000', 'RAUMAUFWAND', NULL);
SELECT account_heading_save(NULL, '61900', 'UNTERHALT, REPARATUREN, ERSATZ, LEASINGAUFWAND MOBILE SACHANLAGEN', NULL);
SELECT account__save(NULL,'61901','Unterhalt','E','61900', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '62000', 'FAHRZEUG- UND TRANSPORTAUFWAND', NULL);
SELECT account__save(NULL,'62002','Transportaufwand','E','62000', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '63000', 'SACHVERSICHERUNGEN, ABGABEN, GEBÜHREN, BEWILLIGUNGEN', NULL);
SELECT account_heading_save(NULL, '65000', 'VERWALTUNGS- UND INFORMATIKAUFWAND', NULL);
SELECT account_heading_save(NULL, '66000', 'WERBEAUFWAND', NULL);
SELECT account_heading_save(NULL, '67000', 'ÜBRIGER BETRIEBSAUFWAND', NULL);
SELECT account__save(NULL,'67001','Übriger Betriebsaufwand','E','67000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '68000', 'FINANZERFOLG', NULL);
SELECT account__save(NULL,'68001','Finanzaufwand','E','68000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'68002','Bankspesen','E','68000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'68005','Finanzertrag','E','68000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '69000', 'ABSCHREIBUNGEN', NULL);
SELECT account__save(NULL,'69001','Abschreibungen','E','69000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '80000', 'AUSSERORDENTLICHER UND BETRIEBSFREMDER ERFOLG, STEUERN', NULL);
SELECT account__save(NULL,'80001','Ausserordentlicher Ertrag','I','80000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'80002','Ausserordentlicher Aufwand','I','80000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '89000', 'STEUERAUFWAND', NULL);
SELECT account__save(NULL,'89001','Steuern','E','80000', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '90000', 'ABSCHLUSS', NULL);
SELECT account_heading_save(NULL, '91000', 'ERFOLGSRECHNUNG', NULL);
SELECT account_heading_save(NULL, '92000', 'BILANZ', NULL);
SELECT account_heading_save(NULL, '93000', 'GEWINNVERWENDUNG', NULL);
SELECT account_heading_save(NULL, '99000', 'SAMMEL- UND FEHLBUCHUNGEN', NULL);
SELECT account__save(NULL,'11121','Warenvorräte','A','11120', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'44001','Aufwand für Drittleistungen','E','44000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'63001','Betriebsversicherungen','E','63000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'57004','Unfallversicherung','E','57000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'57005','Krankentaggeldversicherung','E','57000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'57003','Berufliche Vorsorge','E','57000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'57002','FAK','E','57000', NULL, false, false, string_to_array('AP_amount:IC_income:IC_expense', ':'), false, false);
SELECT account__save(NULL,'65009','Übriger Verwaltungsaufwand','E','65000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'65003','Porti','E','65000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'65002','Telekomm','E','65000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'65001','Büromaterial','E','65000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'18181','Gründungsaufwand','A','18000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'50001','Löhne und Gehälter','E','50000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'50002','Erfolgsbeteiligungen','E','50000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'21216','Gesellschafter','L','21210', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'62001','Fahrzeugaufwand','E','62000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'58003','Spesen','E','58000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'65004','Fachliteratur','E','65000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'39001','Skonti','I','39000', NULL, false, false, string_to_array('IC_sale:IC_cogs:IC_income:IC_expense', ':'), false, false);
SELECT account__save(NULL,'39002','Rabatte, Preisnachlässe','I','39000', NULL, false, false, string_to_array('IC_sale:IC_cogs:IC_income:IC_expense', ':'), false, false);
SELECT account__save(NULL,'36005','Kursgewinn','I','39000', NULL, false, false, string_to_array('IC_sale:IC_cogs:IC_income', ':'), false, false);
SELECT account__save(NULL,'39006','Kursverlust','E','39000', NULL, false, false, string_to_array('IC_sale:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'39005','Verluste aus Forderungen','E','39000', NULL, false, false, string_to_array('IC_sale:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'14151','Mobiliar und Einrichtungen','A','14150', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'14152','Büromaschinen, EDV','A','14150', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'11119','Verrechnungssteuer','A','11110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'11118','MWST Vorsteuer auf Investitionen','A','11110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'36004','Versand','I','36000', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'36001','Reisezeit','I','36000', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'36002','Reise (Fahrt)','I','36000', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'11117','MWST Vorsteuer auf Aufwand','A','11110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'21228','Geschuldete Steuern','L','21220', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'21223','MWST (7,6)','L','21220', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_expense:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'57001','AHV, IV, EO, ALV','E','57000', NULL, false, false, string_to_array('AP_amount:IC_income:IC_expense', ':'), false, false);
SELECT account__save(NULL,'21221','MWST (2,4)','L','21220', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'21224','MWST (7.6) 1/2','L','21220', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_expense:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'66001','Werbeaufwand','E','66000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'21217','Privat','L','21210', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'11101','Kasse','A','11100', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'50005','Leistungen von Sozialversicherung','E','50000', NULL, false, false, string_to_array('AP_amount:IC_income:IC_expense', ':'), false, false);
SELECT account__save(NULL,'65005','Informatikaufwand','E','65000', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'39004','Rundungsdifferenzen','I','39000', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'11111','Debitoren','A','11110', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'61001','Miete','E','61000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'61002','Reinigung','E','61000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'61005','Übriger Raumaufwand','E','61000', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'36003','Essen','I','36000', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'21231','Passive Rechnungsabgrenzung','L','21230', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'67002','Produkteentwicklung','E','67000', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '21222'),0.036);
insert into tax (chart_id,rate) values ((select id from account where accno = '21223'),0.076);
insert into tax (chart_id,rate) values ((select id from account where accno = '21221'),0.024);
insert into tax (chart_id,rate) values ((select id from account where accno = '21224'),0.076);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '11121'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '34002'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '42005'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '36005'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '39006'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'CHF:EUR:USD');

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
FROM account WHERE accno = '11102';

