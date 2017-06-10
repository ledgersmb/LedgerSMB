begin;
--
-- Chart of Accounts for Italy
--
-- From: Luca Venturini <luca@yepa.com>
-- 9 Oct 2001
--
-- ('2001101'5 Conto ('6470005' diventa tassa (negativa)
-- ('2001102'5 IVA su acquisti diventa Iva su acq. (20%)
-- ('2001102'5 Introdotto un conto per ogni aliquota IVA
-- ('2001102'7 Modificato numero di conto per la Ritenuta d'acconto
-- ('2001103'1 Inseriti Fornitore-test e Consulente-test
-- ('2001111'5 Invertito i ruoli di ('6470005' e ('6470010' (erano sbagliati)
-- ('2001111'5 Eliminata l'applicabilita' della RA al cliente test
-- ('2001112'0 Aggiunto IC_expense al conto ('7005005' (mancava un conto di default per i servizi)
SELECT account_heading_save(NULL,'2010000','COSTI DI RICERCA, DI SVILUPPO E DI PUBBLICITA''', NULL);
SELECT account__save(NULL,'2010005','Spese di ricerca e di sviluppo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2010010','Spese di pubblicita''','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2015000','DIRITTI DI BREV. IND. E DIRITTI DI UTILIZZ DELLE OPERE DELL''INGEGNO', NULL);
SELECT account__save(NULL,'2015005','Brevetti','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2020005','Concessioni, licenze e diritti simili','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2025005','Avviamento','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2245000','TERRENI E FABBRICATI', NULL);
SELECT account__save(NULL,'2245010','Fabbricati civili','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2250000','IMPIANTI E MACCHINARI', NULL);
SELECT account__save(NULL,'2250005','Impianti generici','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2255000','ATTREZZATURE INDUSTRIALI E COMMERCIALI', NULL);
SELECT account__save(NULL,'2255005','Attrezzature','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2255010','Mobili','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2255015','Macchine d''ufficio','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2255025','Autovetture','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3005000','RIMANENZE MATERIE PRIME, SUSSIDIARIE E DI CONSUMO', NULL);
SELECT account__save(NULL,'3005005','Rimanenze materie prime','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3020000','RIMANENZE PRODOTTI FINITI E MERCI', NULL);
SELECT account__save(NULL,'3020005','Rimanenze prodotti finiti','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL,'4001000','CREDITI VERSO CL. PER FATT. EM. ESIGIBILI ENTRO L''ESER. SUCC.', NULL);
SELECT account__save(NULL,'4001001','Crediti verso clienti per fatture emesse','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account_heading_save(NULL,'4064000','CREDITI VERSO ALTRI - CREDITI D''IMPOSTA', NULL);
SELECT account__save(NULL,'4064005','IRPEF acconto','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4064020','IRPEG acconto','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4064800','Credito verso erario per IVA','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'4400000','DISPONIBILITA'' LIQUIDE', NULL);
SELECT account__save(NULL,'4480105','Banca ...c/c','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'4480400','Assegni','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'4480500','Cassa e valori','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account_heading_save(NULL,'5005000','CAPITALE', NULL);
SELECT account__save(NULL,'5005005','Capitale sociale','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5005010','Versamenti in conto capitale','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5020000','RISERVA LEGALE', NULL);
SELECT account__save(NULL,'5020005','Riserva legale','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5080000','UTILI (PERDITE) PORTATI A NUOVO', NULL);
SELECT account__save(NULL,'5080005','Utili esercizi precedenti','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5080010','Perdite esercizi precedenti','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5090000','UTILE (PERDITA) DELL''ESERCIZIO', NULL);
SELECT account__save(NULL,'5090005','Utile dell''esercizio','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5090010','Perdita dell''esercizio','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6200000','TRATTAMENTO DI FINE RAPPORTO DI LAVORO SUBORDINATO', NULL);
SELECT account__save(NULL,'6220005','Trattamento di fine rapporto di lavoro subordinato','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6220010','Anticipazioni erogate su trattamento di fine rapporto di lavoro subordinato','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6435000','DEBITI VERSO BANCHE ESIGIBILI ENTRO ES. SUCC.', NULL);
SELECT account__save(NULL,'6435005','Banca di ... c/c','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6436000','DEBITI VERSO BANCHE ESIGIBILI OLTRE ES. SUCC.', NULL);
SELECT account__save(NULL,'6436005','Mutuo banca di ...','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6450000','DEBITI VERSO FORNITORI FATT. RICEVUTE ESIGIBILI ENTRO ES. SUCC.', NULL);
SELECT account__save(NULL,'6450001','Debiti verso fornitori per fatture ricevute','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL,'6470000','DEBITI TRIBUTARI', NULL);
SELECT account__save(NULL,'6470005','IRPEF dipendenti','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6470010','IRPEF terzi','L','', NULL, false, false, string_to_array('AP_tax:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'6470015','IVA da versare','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'6470020','IVA in sospeso','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6470025','IRPEG sul reddito d''esercizio','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6470030','ILOR sul reddito d''esercizio','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6470050','Imposta patrimoniale','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6475000','DEBITI VERSO ISTITUTI PREV. ESIGIBILI ENTRO ES. SUCC.', NULL);
SELECT account__save(NULL,'6475005','INPS','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6475010','INAIL','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6475020','Servizio sanitario nazionale (S.S.N.)','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6475025','ENASARCO','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6480000','ALTRI DEBITI - IVA C/ERARIO', NULL);
SELECT account__save(NULL,'6480003','IVA su acquisti (4%)','L','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'6480004','IVA su acquisti (10%)','L','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'6480005','IVA su acquisti (20%)','L','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'6480006','IVA a credito su acquisti U.E.','L','', NULL, false, false, string_to_array('AP_tax', ':'), false, false);
SELECT account__save(NULL,'6480010','IVA su fatture emesse','L','', NULL, false, false, string_to_array('AR_tax', ':'), false, false);
SELECT account__save(NULL,'6480011','IVA a debito su acquisti U.E.','L','', NULL, false, false, string_to_array('AR_tax', ':'), false, false);
SELECT account__save(NULL,'6480015','IVA su corrispettivi','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480020','IVA versata','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480025','IVA acconto','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480030','IVA a credito','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480035','IVA ulteriore detrazione','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480040','Crediti d''imposta diversi','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480045','IVA pro-rata indetraibile','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480050','IVA da contabilità separata','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6480055','IVA c/riepilogativo','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6600000','RATEI E RISCONTI PASSIVI', NULL);
SELECT account__save(NULL,'6690005','Ratei passivi','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6692005','Risconti passivi','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'7005000','COSTI PER MATERIE PRIME, SUSSIDIARIE, DI CONSUMO E DI MERCI', NULL);
SELECT account__save(NULL,'7005005','Materie prime','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'7005015','Merci destinate alla rivendita','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'7005020','Materiali di consumo destinati alla produzione','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7005030','Materiali di pulizia','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7005035','Combustibile per riscaldamento','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7005040','Cancelleria','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7005045','Materiale pubblicitario','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7005050','Carburanti e lubrificanti','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'7025000','SPESE DI GESTIONE', NULL);
SELECT account__save(NULL,'7025005','Energia elettrica','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025015','Spese telefoniche','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025025','Spese pubblicità/propaganda','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025030','Spese di assicurazione','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025040','Pulizia locali','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025055','Viaggi e soggiorni amministratori','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025060','Spese di rappresentanza per servizi interamente detraibili','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025065','Altre spese di rappresentanza','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7025100','Altri servizi','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'7028000','CARBURANTI E LUBRIFICANTI PER AUTOTRAZIONE', NULL);
SELECT account__save(NULL,'7028005','Carburanti e lubrificanti autovetture','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7028010','Carburanti e lubrificanti autocarri etc.','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'7030000','COMPENSI PROFESSIONALI', NULL);
SELECT account__save(NULL,'7030005','Consulenza fiscale e tributaria','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7030015','Consulenza legale','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7030030','Compenso amministratori','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'7035000','COSTI PER GODIMENTO BENI DI TERZI', NULL);
SELECT account__save(NULL,'7035005','Fitti passivi','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7035050','Canoni di leasing','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'7040000','COSTI PER IL PERSONALE', NULL);
SELECT account__save(NULL,'7040005','Salari e stipendi','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7040010','Oneri sociali INPS','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7040015','Oneri sociali INAIL','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7040020','Oneri sociali C.E.','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'7043000','AMMORTAMENTI E SVALUTAZIONI', NULL);
SELECT account__save(NULL,'7043005','Ammortamenti immobilizzazioni immateriali','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7043100','Ammortamenti immobilizzazioni materiali','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'7056000','ONERI DIVERSI DI GESTIONE', NULL);
SELECT account__save(NULL,'7056010','Imposta di registro, bolli ,CC.GG., etc.','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7056015','Imposta camerale','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'7056025','Tributi locali diversi','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7056040','Tassa possesso autoveicoli','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'7260000','INTERESSI E ONERI FINANZIARI', NULL);
SELECT account__save(NULL,'7260020','Interessi passivi bancari','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7260025','Interessi passivi mutui','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'7875000','IMPOSTE SUL REDDITO DELL''ESERCIZIO', NULL);
SELECT account__save(NULL,'7875005','IRPEG corrente','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'7875020','IRPEG differita','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'8005000','RICAVI DELLE VENDITE', NULL);
SELECT account__save(NULL,'8005005','Ricavi cessione beni','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL,'8015000','RICAVI DELLE PRESTAZIONI', NULL);
SELECT account__save(NULL,'8015005','Ricavi per prestazioni a terzi','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'8015015','Noleggio impianti e macchinari','I','', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account_heading_save(NULL,'8041000','INCREMENTI IMMOBILIZZAZIONI IMMATERIALI', NULL);
SELECT account__save(NULL,'8041005','Brevetti','I','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8041010','Spese di costituzione società','I','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'8041020','Spese pubblicità e propaganda','I','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL,'8045000','ALTRI RICAVI E PROVENTI', NULL);
SELECT account__save(NULL,'8045001','Cessione di materie prime, sussidiarie e semilavorati','I','', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
--
-- foreign exchange gain / loss
SELECT account__save(NULL,'9990000','Foreign Exchange Gain','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9990010','Foreign Exchange Loss','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
-- insert taxes
--
--Ritenuta d'acconto
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '6470010'), -0.2);
--IVA Acquisti 4%
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '6480003'), 0.04);
--IVA Acquisti 10%
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '6480004'), 0.1);
--IVA Acquisti 20%
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '6480005'), 0.2);
--IVA Fatture Emesse
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '6480010'), 0.2);
--IVA su corrispettivi
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '6480015'), 0.2);
--
-- update defaults
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '3020005'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '8005005'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '7005005'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '9990000'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '9990010'));

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
FROM account WHERE accno = '4480105';

