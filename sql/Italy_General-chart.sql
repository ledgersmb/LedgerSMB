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
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2010000','COSTI DI RICERCA, DI SVILUPPO E DI PUBBLICITA\'','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2010005','Spese di ricerca e di sviluppo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2010010','Spese di pubblicita\'','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2015000','DIRITTI DI BREV. IND. E DIRITTI DI UTILIZZ DELLE OPERE DELL\'INGEGNO','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2015005','Brevetti','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2020005','Concessioni, licenze e diritti simili','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2025005','Avviamento','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2245000','TERRENI E FABBRICATI','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2245010','Fabbricati civili','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2250000','IMPIANTI E MACCHINARI','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2250005','Impianti generici','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2255000','ATTREZZATURE INDUSTRIALI E COMMERCIALI','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2255005','Attrezzature','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2255010','Mobili','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2255015','Macchine d\'ufficio','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2255025','Autovetture','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3005000','RIMANENZE MATERIE PRIME, SUSSIDIARIE E DI CONSUMO','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3005005','Rimanenze materie prime','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3020000','RIMANENZE PRODOTTI FINITI E MERCI','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3020005','Rimanenze prodotti finiti','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4001000','CREDITI VERSO CL. PER FATT. EM. ESIGIBILI ENTRO L\'ESER. SUCC.','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4001001','Crediti verso clienti per fatture emesse','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4064000','CREDITI VERSO ALTRI - CREDITI D\'IMPOSTA','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4064005','IRPEF acconto','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4064020','IRPEG acconto','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4064800','Credito verso erario per IVA','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400000','DISPONIBILITA\' LIQUIDE','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4480105','Banca ...c/c','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4480400','Assegni','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4480500','Cassa e valori','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5005000','CAPITALE','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5005005','Capitale sociale','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5005010','Versamenti in conto capitale','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020000','RISERVA LEGALE','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020005','Riserva legale','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5080000','UTILI (PERDITE) PORTATI A NUOVO','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5080005','Utili esercizi precedenti','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5080010','Perdite esercizi precedenti','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5090000','UTILE (PERDITA) DELL\'ESERCIZIO','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5090005','Utile dell\'esercizio','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5090010','Perdita dell\'esercizio','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6200000','TRATTAMENTO DI FINE RAPPORTO DI LAVORO SUBORDINATO','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6220005','Trattamento di fine rapporto di lavoro subordinato','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6220010','Anticipazioni erogate su trattamento di fine rapporto di lavoro subordinato','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6435000','DEBITI VERSO BANCHE ESIGIBILI ENTRO ES. SUCC.','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6435005','Banca di ... c/c','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6436000','DEBITI VERSO BANCHE ESIGIBILI OLTRE ES. SUCC.','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6436005','Mutuo banca di ...','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6450000','DEBITI VERSO FORNITORI FATT. RICEVUTE ESIGIBILI ENTRO ES. SUCC.','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6450001','Debiti verso fornitori per fatture ricevute','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470000','DEBITI TRIBUTARI','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470005','IRPEF dipendenti','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470010','IRPEF terzi','A','','L','AP_tax:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470015','IVA da versare','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470020','IVA in sospeso','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470025','IRPEG sul reddito d\'esercizio','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470030','ILOR sul reddito d\'esercizio','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6470050','Imposta patrimoniale','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6475000','DEBITI VERSO ISTITUTI PREV. ESIGIBILI ENTRO ES. SUCC.','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6475005','INPS','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6475010','INAIL','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6475020','Servizio sanitario nazionale (S.S.N.)','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6475025','ENASARCO','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480000','ALTRI DEBITI - IVA C/ERARIO','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480003','IVA su acquisti (4%)','A','','L','AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480004','IVA su acquisti (10%)','A','','L','AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480005','IVA su acquisti (20%)','A','','L','AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480006','IVA a credito su acquisti U.E.','A','','L','AP_tax');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480010','IVA su fatture emesse','A','','L','AR_tax');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480011','IVA a debito su acquisti U.E.','A','','L','AR_tax');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480015','IVA su corrispettivi','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480020','IVA versata','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480025','IVA acconto','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480030','IVA a credito','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480035','IVA ulteriore detrazione','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480040','Crediti d\'imposta diversi','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480045','IVA pro-rata indetraibile','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480050','IVA da contabilità separata','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6480055','IVA c/riepilogativo','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6600000','RATEI E RISCONTI PASSIVI','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6690005','Ratei passivi','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('6692005','Risconti passivi','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005000','COSTI PER MATERIE PRIME, SUSSIDIARIE, DI CONSUMO E DI MERCI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005005','Materie prime','A','','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005015','Merci destinate alla rivendita','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005020','Materiali di consumo destinati alla produzione','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005030','Materiali di pulizia','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005035','Combustibile per riscaldamento','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005040','Cancelleria','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005045','Materiale pubblicitario','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7005050','Carburanti e lubrificanti','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025000','SPESE DI GESTIONE','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025005','Energia elettrica','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025015','Spese telefoniche','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025025','Spese pubblicità/propaganda','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025030','Spese di assicurazione','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025040','Pulizia locali','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025055','Viaggi e soggiorni amministratori','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025060','Spese di rappresentanza per servizi interamente detraibili','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025065','Altre spese di rappresentanza','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7025100','Altri servizi','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7028000','CARBURANTI E LUBRIFICANTI PER AUTOTRAZIONE','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7028005','Carburanti e lubrificanti autovetture','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7028010','Carburanti e lubrificanti autocarri etc.','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7030000','COMPENSI PROFESSIONALI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7030005','Consulenza fiscale e tributaria','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7030015','Consulenza legale','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7030030','Compenso amministratori','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7035000','COSTI PER GODIMENTO BENI DI TERZI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7035005','Fitti passivi','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7035050','Canoni di leasing','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7040000','COSTI PER IL PERSONALE','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7040005','Salari e stipendi','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7040010','Oneri sociali INPS','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7040015','Oneri sociali INAIL','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7040020','Oneri sociali C.E.','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7043000','AMMORTAMENTI E SVALUTAZIONI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7043005','Ammortamenti immobilizzazioni immateriali','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7043100','Ammortamenti immobilizzazioni materiali','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7056000','ONERI DIVERSI DI GESTIONE','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7056010','Imposta di registro, bolli ,CC.GG., etc.','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7056015','Imposta camerale','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7056025','Tributi locali diversi','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7056040','Tassa possesso autoveicoli','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7260000','INTERESSI E ONERI FINANZIARI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7260020','Interessi passivi bancari','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7260025','Interessi passivi mutui','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7875000','IMPOSTE SUL REDDITO DELL\'ESERCIZIO','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7875005','IRPEG corrente','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('7875020','IRPEG differita','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8005000','RICAVI DELLE VENDITE','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8005005','Ricavi cessione beni','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8015000','RICAVI DELLE PRESTAZIONI','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8015005','Ricavi per prestazioni a terzi','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8015015','Noleggio impianti e macchinari','A','','I','AR_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8041000','INCREMENTI IMMOBILIZZAZIONI IMMATERIALI','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8041005','Brevetti','A','','I','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8041010','Spese di costituzione società','A','','I','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8041020','Spese pubblicità e propaganda','A','','I','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8045000','ALTRI RICAVI E PROVENTI','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('8045001','Cessione di materie prime, sussidiarie e semilavorati','A','','I','AR_amount');
--
-- foreign exchange gain / loss
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('9990000','Foreign Exchange Gain','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('9990010','Foreign Exchange Loss','A','','E','');
--
-- insert taxes
--
--Ritenuta d'acconto
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '6470010'), -0.2);
--IVA Acquisti 4%
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '6480003'), 0.04);
--IVA Acquisti 10%
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '6480004'), 0.1);
--IVA Acquisti 20%
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '6480005'), 0.2);
--IVA Fatture Emesse
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '6480010'), 0.2);
--IVA su corrispettivi
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '6480015'), 0.2);
--
-- update defaults
--
update defaults set inventory_accno_id = (select id from chart where accno = '3020005'), income_accno_id = (select id from chart where accno = '8005005'), expense_accno_id = (select id from chart where accno = '7005005'), fxgain_accno_id = (select id from chart where accno = '9990000'), fxloss_accno_id = (select id from chart where accno = '9990010'), curr = 'EUR', weightunit = 'kg';
--
