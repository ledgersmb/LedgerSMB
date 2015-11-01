begin;
-- Einfacher Deutscher Kontenrahmen => Very Easy German Default Chart
-- Vorbereitet von / Prepared by Paul Tammes May 9th, 2002. Kommentar / Comments : finance@bermuda-holding.com
-- Englische Texte für eigene Zwecke und um Refernz in LedgerSMB Dokumentation zu erleichtern.
-- English terms used mostly for my own reference and to make lookup in LedgerSMB documentation easier.
-- GIFI-codes werden benutzt/misbraucht um die art der Rechnung zu deuten, Fehler nicht ausgeschlossen denn
-- Ich bin kein Deutscher Steuerberater ;-(
-- GIFI field codes re-used for following specs:
-- Link: Achtung, sehr wenig benutzt da mir die Kentnisse zum Deutschen System fehlen. Sehr gut aufpassen und wenn
-- Ihr Fehler oder Praktische TIPS hat: gerne!
-- Link: used to a minimum, update and customization may well be needed!
-- A0 	= Anlagevermögen 		/ Fixed Assets
-- A1-1 = Warenbestand			/ Inventory
-- A1-2 = Forderungen			/ Liabilities
-- A1-3 = Liquide Mittel		/ Assets
-- A1-4	= Aktive Rechnungsabgrenzung 	/ Closing Account results
-- E    = Erträge			/ Income
-- K0	= Wareneinsatz			/ COGS
-- K1   = Personalkosten		/ Salaries etc
-- K2   = Raumkosten			/ Rental etc
-- K3   = Sonstige Kosten		/ Various costs
-- NA 	= Neutrale Aufwendungen		/ Neutral Costs
-- NE	- Neutrale Erlöse		/ Neutral Income
-- P0 	= Eigenkapital			/ Equity
-- P1 	= Rückstellungen		/ Reserves
-- P2 	= Fremdkapital Langfristig	/ Liabilities Long Term
-- P3 	= Fremdkapital Kurzfristig	/ Liabilities Short Term
-- P4	= Passive Rechnungsabgrenzung	/ Closing Account results
--
-- A0
SELECT account_heading_save(NULL,'0000','ANLAGEVERMÖGEN', NULL);
SELECT account__save(NULL,'0100','Konzessionen & Lizenzen','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0135','EDV-Programme','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0440','Maschinen','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0500','Betriebsausstattung','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0520','PKW','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0650','Büroeinrichtung','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0670','GWG','A','A0', NULL, false, false, string_to_array('', ':'), false, false);
-- A1-1
SELECT account_heading_save(NULL,'1100','WARENBESTAND', NULL);
SELECT account__save(NULL,'1140','Warenbestand','A','A1-1', NULL, false, false, string_to_array('IC', ':'), false, false);
-- A1-2
SELECT account_heading_save(NULL,'1200','FORDERUNGEN', NULL);
SELECT account__save(NULL,'1201','Geleistete Anzahlungen','A','A1-2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1210','Forderungen ohne Kontokorrent','A','A1-2', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1300','Sonstige Forderungen','A','A1-2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1400','Anrechenbare Vorsteuer','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1401','Anrechenbare Vorsteuer 7%','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1402','Vorsteuer ig Erwerb','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1403','Vorsteuer ig Erwerb 16%','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1405','Anrechenbare Vorsteuer 16%','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1406','Anrechenbare Vorsteuer 15%','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1433','bezahlte Einfuhrumsatzsteuer','A','A1-2', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1370','Ungeklärte Posten','A','A1-2', NULL, false, false, string_to_array('', ':'), false, false);
-- A1-3
SELECT account_heading_save(NULL,'1600','LIQUIDE MITTEL', NULL);
SELECT account__save(NULL,'1601','Kasse','A','A1-3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1700','Postgiro','A','A1-3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1800','Bank','A','A1-3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1810','Bank USD','A','A1-3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1820','Kreditkarten','A','A1-3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1890','Geldtransit','A','A1-3', NULL, false, false, string_to_array('', ':'), false, false);
-- A1-4
SELECT account__save(NULL,'1900','Aktive Rechnungsabgrenzung','A','A1-4', NULL, false, false, string_to_array('', ':'), false, false);
-- P0
SELECT account_heading_save(NULL,'2000','EIGENKAPITAL', NULL);
SELECT account__save(NULL,'2001','Eigenkapital','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2100','Privatentnahmen','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2150','Privatsteuern','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2180','Privateinlagen','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2200','Sonderausgaben beschr.abzugsf.','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2900','Gezeichnetes Kapital','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2910','Ausstehende Einlagen','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2970','Gewinnvortrag vor Verwendung','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2978','Verlustvortrag vor Verwendung','Q','P0', NULL, false, false, string_to_array('', ':'), false, false);
-- P1
SELECT account_heading_save(NULL,'3000','RÜCKSTELLUNGEN', NULL);
SELECT account__save(NULL,'3030','Gewerbesteuerrückstellung','L','P1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3070','Sonstige Rückstellungen','L','P1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3095','Rückstellung für Abschlusskosten','L','P1', NULL, false, false, string_to_array('', ':'), false, false);
-- P2
SELECT account_heading_save(NULL,'3100','FREMDKAPITAL LANGFRISTIG', NULL);
SELECT account__save(NULL,'3160','Bankdarlehen','L','P2', NULL, false, false, string_to_array('', ':'), false, false);
-- P3
SELECT account_heading_save(NULL,'3200','FREMDKAPITAL KURZFRISTIG', NULL);
SELECT account__save(NULL,'3280','Erhaltene Anzahlungen','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3310','Kreditoren ohne Kontokorrent','L','P3', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'3500','Sonstige Verbindlichkeiten','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3560','Darlehen','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3700','Verbindl. Betr.steuern u.Abgaben','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3720','Verbindlichkeiten Löhne und Gehälter','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3730','Verbindlichkeiten Lohnsteuer','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3740','Verbindlichkeiten Sozialversicherung','L','P3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3800','Umsatzsteuer','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3801','Umsatzsteuer 7%','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3802','Umsatzsteuer ig. Erwerb','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3803','Umsatzsteuer ig. Erwerb 16%','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3805','Umsatzsteuer 16%','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3806','Umsatzsteuer 15%','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3815','Umsatzsteuer nicht fällig 16%','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3816','Umsatzsteuer nicht fällig 15%','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3820','Umsatzsteuer-Vorauszahlungen','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'3841','Umsatzsteuer Vorjahr','L','P3', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
-- P4
SELECT account__save(NULL,'3900','Aktive Rechnungsabgrenzung','L','P4', NULL, false, false, string_to_array('', ':'), false, false);
-- K0
SELECT account_heading_save(NULL,'5100','WARENEINGANG', NULL);
SELECT account__save(NULL,'5200','Wareneingang ohne Vorsteuer','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5300','Wareneingang 7%','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5400','Wareneingang 15%','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5420','ig.Erwerb 7% VoSt. und 7% USt.','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5425','ig.Erwerb 15% VoSt. und 15% USt.','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5731','Erhaltene Skonti 7% Vorsteuer','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5736','Erhaltene Skonti 15% Vorsteuer','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5800','Anschaffungsnebenkosten','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5900','Fremdarbeiten','E','K0', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
-- K1
SELECT account_heading_save(NULL,'6000','PERSONALKOSTEN', NULL);
SELECT account_heading_save(NULL,'6001','Personalkosten', NULL);
SELECT account__save(NULL,'6010','Löhne','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6020','Gehälter','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6030','Aushilfslöhne','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6040','Lohnsteuer Aushilfen','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6080','Vermögenswirksame Leistungen','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6090','Fahrtkostenerst.Whg./Arbeitsstätte','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6110','Sozialversicherung','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6120','Berufsgenossenschaft','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6130','Freiw. Soz. Aufw. LSt- u. Soz.Vers.frei','E','K1', NULL, false, false, string_to_array('', ':'), false, false);
-- K2
SELECT account_heading_save(NULL,'6300','RAUMKOSTEN', NULL);
SELECT account__save(NULL,'6310','Miete','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6315','Pacht','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6320','Heizung','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6325','Gas Strom Wasser','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6330','Reinigung','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6335','Instandhaltung betriebliche Räume','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6345','Sonstige Raumkosten','E','K2', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
-- K3
SELECT account_heading_save(NULL,'6400','SONSTIGE KOSTEN', NULL);
SELECT account__save(NULL,'6402','Abschreibungen','E','K3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6403','Kaufleasing','E','K3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6404','Sofortabschreibung GWG','E','K3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6405','Sonstige Kosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6410','Versicherung','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6420','Beiträge und Gebühren','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6430','Sonstige Abgaben','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6470','Rep. und Instandhaltung BGA','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6520','Kfz-Versicherung','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6530','Lfd. Kfz-Kosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6540','Kfz-Reparaturen','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6560','Fremdfahrzeuge','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6570','Sonstige Kfz-Kosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6600','Werbung','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6610','Kundengeschenke bis DM 75.','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6620','Kundengeschenke über DM 75.-','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6630','Repräsentationkosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6640','Bewirtungskosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6644','Nicht abzugsf.Bewirtungskosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6650','Reisekosten Arbeitnehmer','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6660','Reisekosten Arbeitnehmer 12.3%','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6665','Reisekosten Arbeitnehmer 9.8%','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6670','Reisekosten Unternehmer','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6680','Reisekosten Unternehmer 12.3%','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6685','Reisekosten Unternehmer 9.8%','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6688','Reisekosten Unternehmer 5.7%','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6690','Km-Geld-Erstattung 8.2%','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6710','Verpackungsmaterial','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6740','Ausgangsfrachten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6780','Fremdarbeiten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6800','Porto','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6805','Telefon','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6815','Bürobedarf','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6820','Zeitschriften & Bücher','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6825','Rechts- und Beratungskosten','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6835','Mieten für Einrichtungen','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6840','Mietleasing','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6845','Werkzeuge und Kleingeräte','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6850','Betriebsbedarf','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6852','Gastättenbedarf','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6855','Nebenkosten des Geldverkehrs','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6880','Aufwendungen aus Kursdifferenzen','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'6885','Erlöse aus Anlageverk.(Buchverlust)','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'7610','Gewerbesteuer','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'7685','Kfz-Steuer','E','K3', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
-- E
SELECT account_heading_save(NULL, '8100', 'ERTRÄGE', NULL);
SELECT account__save(NULL,'8120','Steuerfreie Umsätze 4 Nr. 1a UStG.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8125','Steuerfreie ig. Lieferungen 1b UStG.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8200','Erlöse ohne Umsatzsteuer','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8300','Erlöse 7% Umsatzsteuer','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8400','Erlöse 15% Umsatzsteuer','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8500','Provisionserlöse','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8630','Entnahme sonstg. Leistungen 7% USt.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8640','Entnahme sonstg. Leistungen 15% USt.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8731','Gew. Skonti 7% USt.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8736','Gew. Skonti 15% USt.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8840','Erträge aus Kursdifferenzen','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8845','Erlöse aus Anlageverk. (Buchgewinn)','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8900','Erträge aus Abgang von Anlageverm.','I','E', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
-- NA
SELECT account_heading_save(NULL,'9300','NEUTRALE AUFWENDUNGEN', NULL);
SELECT account__save(NULL,'9310','Zinsen kurzfr. Verbindlichkeiten','E','NA', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9320','Zinsen langfr. Verbindlichkeiten','E','NA', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9500','Ausserordentl.Aufwendungen','E','NA', NULL, false, false, string_to_array('', ':'), false, false);
-- NE
SELECT account_heading_save(NULL,'9600','NEUTRALE ERTRÄGE', NULL);
SELECT account_heading_save(NULL,'9610','Guthabenzinsen', NULL);
SELECT account_heading_save(NULL,'9700','Ausserordentl.Erträge', NULL);
--
-- Default settings
--
insert into tax (chart_id,rate) values ((select id from account where accno = '3801'),0.07);
insert into tax (chart_id,rate) values ((select id from account where accno = '3805'),0.16);
insert into tax (chart_id,rate) values ((select id from account where accno = '3806'),0.15);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1140'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '8120'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5800'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '8840'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '6880'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR');

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
FROM account WHERE accno BETWEEN '1700' AND '1820';

