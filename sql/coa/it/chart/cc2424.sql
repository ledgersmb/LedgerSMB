begin;
--
-- Chart of Accounts for Italy
--
-- From: Daniele Giacomini <daniele@swlibero.org>
-- 13 ottobre  2003
-- 05 novembre 2003
--
-- Il codice GIFI viene usato per rappresentare il codice corrispondente
-- al bilancio riclassificato, come da codice civile, art. 2424.
-- Il codice in questione e' rappresentato separando i vari elementi
-- con un punto, aggiungendo inizialmente un numero: 1 sta per attivo,
-- 2 sta per passivo, 3 sta per conto economico.
--
-- L'abbinamento tra il piano dei conti e il codice GIFI non e' perfetto
-- e richiede un controllo ulteriore; inoltre, non sono stati risolti
-- i problemi relativi alle sottoclassificazioni previste dal codice civile,
-- che pero' non hanno un codice standard corrispondente.
--
-- La codifica GIFI è contenuta in un file separato.
--
-- Questo file e' scritto usando soltanto la codifica ASCII, per evitare
-- problemi di qualunque genere nella scelta della codifica. Pertanto,
-- le vocali accentate sono seguite da un apostrofo.
--
-- E' disponibile un cliente, un fornitore e un articolo di prova.
--
SELECT account_heading_save(NULL,'100000','ATTIVO', NULL);
SELECT account_heading_save(NULL,'101000','IMMOBILIZZAZIONI IMMATERIALI', NULL);
SELECT account__save(NULL,'101001','Costi di impianto e ampliamento','A','1.B.I.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'101002','Avviamento','A','1.B.I.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'101008','Altre immobilizzazioni immateriali','A','1.B.I.7', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'102000','IMMOBILIZZAZIONI MATERIALI', NULL);
SELECT account__save(NULL,'102001','Terreni','A','1.B.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102002','Fabbricati non strumentali','A','1.B.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102003','Fabbricati','A','1.B.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102004','Impianti e macchinari','A','1.B.II.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102006','Attrezzature commerciali','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102007','Attrezzature d''ufficio','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102008','Arredamento','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102009','Automezzi','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102021','Fondo ammortamento fabbricati','A','1.B.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102022','Fondo ammortamento impianti e macchinari','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102023','Fondo ammortamento attrezzature commerciali','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102024','Fondo ammortamento attrezzature d''ufficio','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102025','Fondo ammortamento arredamento','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'102026','Fondo ammortamento automezzi','A','1.B.II.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'103000','IMMOBILIZZAZIONI FINANZIARIE', NULL);
SELECT account__save(NULL,'103001','Prestiti a terzi','A','1.B.III.2.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'105000','RIMANENZE', NULL);
SELECT account__save(NULL,'105001','Rimanenze di merci','A','1.C.I.4', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'105002','Rimanenze di imballaggi','A','1.C.I.4', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'105003','Rimanenze di materiali di consumo','A','1.C.I.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'105011','Fondo svalutazione magazzino','A','1.C.I.4', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'106000','CLIENTI', NULL);
SELECT account__save(NULL,'106001','Crediti verso clienti','A','1.C.II.1', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account_heading_save(NULL,'111000','CREDITI COMMERCIALI', NULL);
SELECT account__save(NULL,'111002','Cambiali attive','A','1.C.II.1', NULL, false, false, string_to_array('AR_paid', ':'), false, false);
SELECT account__save(NULL,'111003','Cambiali allo sconto','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'111005','Cambiali all''incasso','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'111006','Effetti insoluti e protestati','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'111007','Crediti insoluti','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'111011','Fatture da emettere','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'111031','Fondo svalutazione crediti','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'111032','Fondo rischi su crediti','A','1.C.II.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'112000','CREDITI DIVERSI', NULL);
SELECT account__save(NULL,'112001','IVA nostro credito  4%','A','1.C.II.5', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'112002','IVA nostro credito 10%','A','1.C.II.5', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'112004','IVA nostro credito 20%','A','1.C.II.5', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'112062','Erario c/acconto IVA','A','1.C.II.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'112063','Credito per IVA','A','1.C.II.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'112071','Personale c/acconti','A','1.C.II.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'112072','Crediti v/istituti previdenziali','A','1.C.II.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'112073','Crediti per cauzioni','A','1.C.II.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'112074','Crediti diversi','A','1.C.II.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'113000','VALORI MOBILIARI', NULL);
SELECT account__save(NULL,'113001','Titoli','A','1.C.III.6', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'114000','DISPONIBILITA'' LIQUIDE', NULL);
SELECT account__save(NULL,'114001','Banca c/c','A','1.C.IV.1', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'114003','Poste c/c','A','1.C.IV.1', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'114004','Assegni','A','1.C.IV.2', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'114005','Denaro e valori in cassa','A','1.C.IV.3', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account_heading_save(NULL,'115000','RATEI E RISCONTI ATTIVI', NULL);
SELECT account__save(NULL,'115001','Ratei attivi','A','1.D', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'115002','Risconti attivi','A','1.D', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'200000','PASSIVO', NULL);
SELECT account_heading_save(NULL,'216000','PATRIMONIO NETTO', NULL);
SELECT account__save(NULL,'216001','Patrimonio netto','Q','2.A.I', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'216002','Utile d''esercizio','Q','2.A.IX', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'216003','Perdita d''esercizio','Q','2.A.IX', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'217000','FONDO ACCANTONAMENTO RISCHI E ONERI', NULL);
SELECT account__save(NULL,'217002','Fondo per imposte','L','2.B.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'217003','Fondo manutenzioni e riparazioni','L','2.B.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'217006','Altri fondi','L','2.B.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'218000','TFR LAVORO SUBORDINATO', NULL);
SELECT account__save(NULL,'218001','Debito per TFRL','L','2.C', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'219000','DEBITI DI FINAZIAMENTO', NULL);
SELECT account__save(NULL,'219001','Mutui ipotecari','L','2.D.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'219002','Finanziamenti bancari','L','2.D.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'219003','Sovvenzioni bancarie','L','2.D.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'219004','Banche c/c passivi','L','2.D.3', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'219011','Finanziamenti non bancari','L','2.D.4', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'220000','FORNITORI', NULL);
SELECT account__save(NULL,'220001','Debiti verso fornitori','L','2.D.6', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL,'225000','DEBITI COMMERCIALI', NULL);
SELECT account__save(NULL,'225002','Cambiali passive','L','2.D.6', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account__save(NULL,'225003','Fatture da ricevere','L','2.D.6', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'226000','DEBITI TRIBUTARI', NULL);
SELECT account__save(NULL,'226001','IVA nostro debito  4%','L','2.D.13', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'226002','IVA nostro debito 10%','L','2.D.13', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'226004','IVA nostro debito 20%','L','2.D.13', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'226062','Debito per IVA','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'226065','Erario c/ritenute da versarare','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'226066','Altri debiti verso l''erario','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'226067','Debiti per imposte','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'227000','DEBITI DIVERSI', NULL);
SELECT account__save(NULL,'227001','Personale c/retribuzioni','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'227002','Personale c/liquidazioni','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'227003','Debiti v/istituti previdenziali','L','2.D.12', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'227004','Debiti per cauzioni','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'227005','Debiti diversi','L','2.D.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'228000','RATEI E RISCONTI PASSIVI', NULL);
SELECT account__save(NULL,'228001','Ratei passivi','L','2.E', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'228002','Risconti passivi','L','2.E', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'300000','ALTRI CONTI PATRIMONIALI', NULL);
SELECT account_heading_save(NULL,'329000','CONTI TRANSITORI E FINALALI', NULL);
SELECT account__save(NULL,'329006','Istituti previdenziali','A','2.D.12', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'329011','Conto del patrimonio','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'329012','Bilancio di apertura','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'400000','CONTI D''ORDINE', NULL);
SELECT account_heading_save(NULL,'431000','IMPEGNI', NULL);
SELECT account__save(NULL,'431001','Beni da ricevere','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'431002','Fornitori per beni da ricevere','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'431003','Beni da consegnare','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'431004','Clienti per beni da consegnare','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'431005','Beni in leasing','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'431006','Creditori per beni in leasing','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'432000','BENI DI TERZI', NULL);
SELECT account_heading_save(NULL,'433000','BENI NOSTRI PRESSO TERZI', NULL);
SELECT account_heading_save(NULL,'434000','RISCHI', NULL);
SELECT account_heading_save(NULL,'500000','VALORE DELLA PRODUZIONE', NULL);
SELECT account_heading_save(NULL,'541000','RICAVI VENDITE E PRESTAZIONI', NULL);
SELECT account__save(NULL,'541001','Vendite di merci','I','3.A.1', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'541002','Vendite di imballaggi','I','3.A.1', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'541003','Ricavi per prestazione di servizi','I','3.A.1', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'541006','Resi su vendite','I','3.A.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'541007','Ribassi e abbuoni passivi','I','3.A.1', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'541008','Premi a clienti','I','3.B.9.e', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'541010','Rimborso spese','I','3.A.5', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account_heading_save(NULL,'542000','ALTRI RICAVI E PROVENTI', NULL);
SELECT account__save(NULL,'542001','Ricavi e proventi vari','I','3.A.5', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account__save(NULL,'542002','Fitti attivi','I','3.A.5', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account__save(NULL,'542003','Arrotondamenti positivi','I','3.A.5', NULL, false, false, string_to_array('AR_amount', ':'), false, false);
SELECT account_heading_save(NULL,'600000','COSTI DELLA PRODUZIONE', NULL);
SELECT account_heading_save(NULL,'645000','COSTI ACQUISTO MERCI E MATERIALI DI CONSUMO', NULL);
SELECT account__save(NULL,'645001','Acquisti di merci','E','3.B.6', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'645002','Acquisti di imballaggi','E','3.B.6', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'645003','Acquisti di materiali di consumo','E','3.B.6', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'645006','Resi su acquisti','E','3.B.6', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'645007','Ribassi e abbuoni attivi','E','3.B.6', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'645008','Premi da fornitori','E','3.A.5', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'646000','COSTI PER PRESTAZIONI E SERVIZI', NULL);
SELECT account__save(NULL,'646001','Costi di trasporto','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646002','Costi di energia','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646003','Costi di pubblicita''','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646004','Assicurazioni','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646005','Spese postali','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646006','Spese telefoniche','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646007','Spese legali e notarili','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646008','Spese di banca','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646009','Manutenzioni riparazioni','E','3.B.7', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'646010','Imponibile omaggi','E','3.B.9.e', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'646011','IVA c/omaggi','E','3.B.9.e', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'646021','Provvigioni passive','E','3.B.9.e', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'646022','Competenze a terzi','E','3.B.9.e', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'647000','COSTI PER GODIMENTO BENI DI TERZI', NULL);
SELECT account__save(NULL,'647001','Fitti passivi','E','3.B.8', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'647002','Canoni leasing','E','3.B.8', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'648000','COSTI PER IL PERSONALE', NULL);
SELECT account__save(NULL,'648001','Salari e stipendi','E','3.B.9.a', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'648002','Oneri sociali','E','3.B.9.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'648003','Trattamenti di fine rapporto di lavoro','E','3.B.9.c', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'648004','Trattamenti di quiescenza e simili','E','3.B.9.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'648005','Altri costi per il personale','E','3.B.9.e', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'649000','AMMORTAMENTO IMMOBILIZZAZIONI IMMATERIALI', NULL);
SELECT account__save(NULL,'649001','Ammortamento impianto e ampliamento','E','3.B.10.a', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'649002','Ammortamento avviamento','E','3.B.10.a', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'649008','Ammortamento di altre immobilizzazioni immateriali','E','3.B.10.a', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'650000','AMMORTAMENTO IMMOBILIZZAZIONI MATERIALI', NULL);
SELECT account__save(NULL,'650001','Ammortamento fabbricati','E','3.B.10.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'650002','Ammortamento impianti e macchinari','E','3.B.10.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'650003','Ammortamento attrezzature commerciali','E','3.B.10.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'650005','Ammortamento attrezzature d''ufficio','E','3.B.10.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'650006','Ammortamento arredamento','E','3.B.10.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'650007','Ammortamento automezzi','E','3.B.10.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'651000','SVALUTAZIONI', NULL);
SELECT account__save(NULL,'651003','Svalutazione magazzino','E','3.B.11', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'651004','Svalutazione crediti','E','3.B.12', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'652000','ESISTENZA INIZIALE E RIMANENZE FINALI', NULL);
SELECT account__save(NULL,'652001','Esistenza iniziale merci','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652002','Esistenza iniziale imballaggi','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652003','Esistenza iniziale materie di consumo','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652011','Rimanenze finali merci','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652012','Rimanenze finali imballaggi','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652013','Rimanenze finali materie di consumo','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652021','Variazioni merci','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652022','Variazioni imballaggi','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'652023','Variazioni materie di consumo','E','3.A.2', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'653000','ACCANTONAMENTI PER RISCHI', NULL);
SELECT account__save(NULL,'653001','Accantonamenti per rischi su crediti','E','3.B.12', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'653002','Accantonamenti su imposte','E','3.B.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'653004','Altri accantonamenti rischi-oneri','E','3.B.12', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'654000','ALTRI ACCANTONAMENTI', NULL);
SELECT account__save(NULL,'654001','Accantonamenti per spese future','E','3.B.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'654005','Accantonamenti per manutenzioni e riparazioni','E','3.B.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'654006','Altri accantonamenti','E','3.B.13', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'655000','ONERI DIVERSI', NULL);
SELECT account__save(NULL,'655001','Imposta di bollo','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'655002','Tassa di concessione governativa','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'655003','Imposte comunali','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'655005','Imposte di esercizio','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'655006','Perdite su crediti','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'655011','Oneri e perdite varie','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'655012','Arrotondamenti negativi','E','3.B.14', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'700000','PROVENTI E ONERI FINANZIARI', NULL);
SELECT account__save(NULL,'756000','PROVENTI FINANZIARI','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'756001','Interessi attivi da banche','I','3.C.16.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'756002','Interessi attivi da clienti','I','3.C.16.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'756003','Interessi attivi vari','I','3.C.16.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'756004','Interessi su titoli','I','3.C.16.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'756011','Proventi finanziari vari','I','3.C.16.d', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'756012','Utile su titoli','I','3.C.16.b', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'757000','ONERI FINANZIARI', NULL);
SELECT account__save(NULL,'757001','Interessi passivi a banche','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'757002','Interessi passivi a fornitori','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'757003','Interessi passivi su finanziamenti','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'757004','Interessi passivi su mutui','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'757005','Interessi passivi vari','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'757011','Oneri finanziari vari','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'757012','Perdite su titoli','I','3.C.17', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'800000','PROVENTI E ONERI STRAORDINARI', NULL);
SELECT account_heading_save(NULL,'860000','PROVENTI STRAORDINARI', NULL);
SELECT account__save(NULL,'860001','Plusvalenze','I','3.E.20', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'860002','Sopravvenienze e insussistenze attive','I','3.E.20', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'861000','ONERI STRAORDINARI', NULL);
SELECT account__save(NULL,'861001','Minusvalenze','I','3.E.21', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'861002','Sopravvenienze e insussistenze passive','I','3.E.21', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'900000','CONTI DI RIEPILOGO ECONOMICI', NULL);
SELECT account__save(NULL,'970001','Conto del risultato economico','I','3.E.23', NULL, false, false, string_to_array('', ':'), false, false);

INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '112001'), 0.04);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '112002'), 0.1);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '112004'), 0.2);

INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '226001'), 0.04);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '226002'), 0.1);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM account WHERE accno = '226004'), 0.2);

--
-- update defaults
--

INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id',
	(select id from account where accno = '105001'));
INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '541001'));
INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '645001'));
INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '756011'));
INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '655011'));
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR');
INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno = '114001';
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno = '114003';

