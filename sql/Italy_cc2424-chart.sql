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
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('100000', 'ATTIVO', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('101000', 'IMMOBILIZZAZIONI IMMATERIALI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('101001', 'Costi di impianto e ampliamento', 'A', '1.B.I.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('101002', 'Avviamento', 'A', '1.B.I.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('101008', 'Altre immobilizzazioni immateriali', 'A', '1.B.I.7', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102000', 'IMMOBILIZZAZIONI MATERIALI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102001', 'Terreni', 'A', '1.B.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102002', 'Fabbricati non strumentali', 'A', '1.B.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102003', 'Fabbricati', 'A', '1.B.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102004', 'Impianti e macchinari', 'A', '1.B.II.2', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102006', 'Attrezzature commerciali', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102007', 'Attrezzature d\'ufficio', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102008', 'Arredamento', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102009', 'Automezzi', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102021', 'Fondo ammortamento fabbricati', 'A', '1.B.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102022', 'Fondo ammortamento impianti e macchinari', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102023', 'Fondo ammortamento attrezzature commerciali', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102024', 'Fondo ammortamento attrezzature d\'ufficio', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102025', 'Fondo ammortamento arredamento', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('102026', 'Fondo ammortamento automezzi', 'A', '1.B.II.3', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('103000', 'IMMOBILIZZAZIONI FINANZIARIE', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('103001', 'Prestiti a terzi', 'A', '1.B.III.2.d', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('105000', 'RIMANENZE', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('105001', 'Rimanenze di merci', 'A', '1.C.I.4', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('105002', 'Rimanenze di imballaggi', 'A', '1.C.I.4', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('105003', 'Rimanenze di materiali di consumo', 'A', '1.C.I.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('105011', 'Fondo svalutazione magazzino', 'A', '1.C.I.4', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('106000', 'CLIENTI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('106001', 'Crediti verso clienti', 'A', '1.C.II.1', 'A', 'AR');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111000', 'CREDITI COMMERCIALI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111002', 'Cambiali attive', 'A', '1.C.II.1', 'A', 'AR_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111003', 'Cambiali allo sconto', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111005', 'Cambiali all\'incasso', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111006', 'Effetti insoluti e protestati', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111007', 'Crediti insoluti', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111011', 'Fatture da emettere', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111031', 'Fondo svalutazione crediti', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('111032', 'Fondo rischi su crediti', 'A', '1.C.II.1', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112000', 'CREDITI DIVERSI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112001', 'IVA nostro credito  4%', 'A', '1.C.II.5', 'A', 'AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112002', 'IVA nostro credito 10%', 'A', '1.C.II.5', 'A', 'AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112004', 'IVA nostro credito 20%', 'A', '1.C.II.5', 'A', 'AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112062', 'Erario c/acconto IVA', 'A', '1.C.II.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112063', 'Credito per IVA', 'A', '1.C.II.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112071', 'Personale c/acconti', 'A', '1.C.II.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112072', 'Crediti v/istituti previdenziali', 'A', '1.C.II.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112073', 'Crediti per cauzioni', 'A', '1.C.II.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('112074', 'Crediti diversi', 'A', '1.C.II.5', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('113000', 'VALORI MOBILIARI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('113001', 'Titoli', 'A', '1.C.III.6', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('114000', 'DISPONIBILITA\' LIQUIDE', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('114001', 'Banca c/c', 'A', '1.C.IV.1', 'A', 'AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('114003', 'Poste c/c', 'A', '1.C.IV.1', 'A', 'AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('114004', 'Assegni', 'A', '1.C.IV.2', 'A', 'AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('114005', 'Denaro e valori in cassa', 'A', '1.C.IV.3', 'A', 'AR_paid:AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('115000', 'RATEI E RISCONTI ATTIVI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('115001', 'Ratei attivi', 'A', '1.D', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('115002', 'Risconti attivi', 'A', '1.D', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('200000', 'PASSIVO', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('216000', 'PATRIMONIO NETTO', 'H', '', 'Q', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('216001', 'Patrimonio netto', 'A', '2.A.I', 'Q', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('216002', 'Utile d\'esercizio', 'A', '2.A.IX', 'Q', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('216003', 'Perdita d\'esercizio', 'A', '2.A.IX', 'Q', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('217000', 'FONDO ACCANTONAMENTO RISCHI E ONERI', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('217002', 'Fondo per imposte', 'A', '2.B.2', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('217003', 'Fondo manutenzioni e riparazioni', 'A', '2.B.3', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('217006', 'Altri fondi', 'A', '2.B.3', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('218000', 'TFR LAVORO SUBORDINATO', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('218001', 'Debito per TFRL', 'A', '2.C', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('219000', 'DEBITI DI FINAZIAMENTO', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('219001', 'Mutui ipotecari', 'A', '2.D.3', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('219002', 'Finanziamenti bancari', 'A', '2.D.3', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('219003', 'Sovvenzioni bancarie', 'A', '2.D.3', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('219004', 'Banche c/c passivi', 'A', '2.D.3', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('219011', 'Finanziamenti non bancari', 'A', '2.D.4', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('220000', 'FORNITORI', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('220001', 'Debiti verso fornitori', 'A', '2.D.6', 'L', 'AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('225000', 'DEBITI COMMERCIALI', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('225002', 'Cambiali passive', 'A', '2.D.6', 'L', 'AP_paid');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('225003', 'Fatture da ricevere', 'A', '2.D.6', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226000', 'DEBITI TRIBUTARI', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226001', 'IVA nostro debito  4%', 'A', '2.D.13', 'L', 'AR_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226002', 'IVA nostro debito 10%', 'A', '2.D.13', 'L', 'AR_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226004', 'IVA nostro debito 20%', 'A', '2.D.13', 'L', 'AR_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226062', 'Debito per IVA', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226065', 'Erario c/ritenute da versarare', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226066', 'Altri debiti verso l\'erario', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('226067', 'Debiti per imposte', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('227000', 'DEBITI DIVERSI', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('227001', 'Personale c/retribuzioni', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('227002', 'Personale c/liquidazioni', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('227003', 'Debiti v/istituti previdenziali', 'A', '2.D.12', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('227004', 'Debiti per cauzioni', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('227005', 'Debiti diversi', 'A', '2.D.13', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('228000', 'RATEI E RISCONTI PASSIVI', 'H', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('228001', 'Ratei passivi', 'A', '2.E', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('228002', 'Risconti passivi', 'A', '2.E', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('300000', 'ALTRI CONTI PATRIMONIALI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('329000', 'CONTI TRANSITORI E FINALALI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('329006', 'Istituti previdenziali', 'A', '2.D.12', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('329011', 'Conto del patrimonio', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('329012', 'Bilancio di apertura', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('400000', 'CONTI D\'ORDINE', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431000', 'IMPEGNI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431001', 'Beni da ricevere', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431002', 'Fornitori per beni da ricevere', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431003', 'Beni da consegnare', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431004', 'Clienti per beni da consegnare', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431005', 'Beni in leasing', 'A', '', 'L', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('431006', 'Creditori per beni in leasing', 'A', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('432000', 'BENI DI TERZI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('433000', 'BENI NOSTRI PRESSO TERZI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('434000', 'RISCHI', 'H', '', 'A', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('500000', 'VALORE DELLA PRODUZIONE', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541000', 'RICAVI VENDITE E PRESTAZIONI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541001', 'Vendite di merci', 'A', '3.A.1', 'I', 'AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541002', 'Vendite di imballaggi', 'A', '3.A.1', 'I', 'AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541003', 'Ricavi per prestazione di servizi', 'A', '3.A.1', 'I', 'AR_amount:IC_income');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541006', 'Resi su vendite', 'A', '3.A.1', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541007', 'Ribassi e abbuoni passivi', 'A', '3.A.1', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541008', 'Premi a clienti', 'A', '3.B.9.e', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('541010', 'Rimborso spese', 'A', '3.A.5', 'I', 'AR_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('542000', 'ALTRI RICAVI E PROVENTI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('542001', 'Ricavi e proventi vari', 'A', '3.A.5', 'I', 'AR_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('542002', 'Fitti attivi', 'A', '3.A.5', 'I', 'AR_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('542003', 'Arrotondamenti positivi', 'A', '3.A.5', 'I', 'AR_amount');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('600000', 'COSTI DELLA PRODUZIONE', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645000', 'COSTI ACQUISTO MERCI E MATERIALI DI CONSUMO', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645001', 'Acquisti di merci', 'A', '3.B.6', 'E', 'AP_amount:IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645002', 'Acquisti di imballaggi', 'A', '3.B.6', 'E', 'AP_amount:IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645003', 'Acquisti di materiali di consumo', 'A', '3.B.6', 'E', 'AP_amount:IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645006', 'Resi su acquisti', 'A', '3.B.6', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645007', 'Ribassi e abbuoni attivi', 'A', '3.B.6', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('645008', 'Premi da fornitori', 'A', '3.A.5', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646000', 'COSTI PER PRESTAZIONI E SERVIZI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646001', 'Costi di trasporto', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646002', 'Costi di energia', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646003', 'Costi di pubblicita\'', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646004', 'Assicurazioni', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646005', 'Spese postali', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646006', 'Spese telefoniche', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646007', 'Spese legali e notarili', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646008', 'Spese di banca', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646009', 'Manutenzioni riparazioni', 'A', '3.B.7', 'E', 'AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646010', 'Imponibile omaggi', 'A', '3.B.9.e', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646011', 'IVA c/omaggi', 'A', '3.B.9.e', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646021', 'Provvigioni passive', 'A', '3.B.9.e', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('646022', 'Competenze a terzi', 'A', '3.B.9.e', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('647000', 'COSTI PER GODIMENTO BENI DI TERZI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('647001', 'Fitti passivi', 'A', '3.B.8', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('647002', 'Canoni leasing', 'A', '3.B.8', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('648000', 'COSTI PER IL PERSONALE', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('648001', 'Salari e stipendi', 'A', '3.B.9.a', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('648002', 'Oneri sociali', 'A', '3.B.9.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('648003', 'Trattamenti di fine rapporto di lavoro', 'A', '3.B.9.c', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('648004', 'Trattamenti di quiescenza e simili', 'A', '3.B.9.d', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('648005', 'Altri costi per il personale', 'A', '3.B.9.e', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('649000', 'AMMORTAMENTO IMMOBILIZZAZIONI IMMATERIALI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('649001', 'Ammortamento impianto e ampliamento', 'A', '3.B.10.a', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('649002', 'Ammortamento avviamento', 'A', '3.B.10.a', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('649008', 'Ammortamento di altre immobilizzazioni immateriali', 'A', '3.B.10.a', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650000', 'AMMORTAMENTO IMMOBILIZZAZIONI MATERIALI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650001', 'Ammortamento fabbricati', 'A', '3.B.10.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650002', 'Ammortamento impianti e macchinari', 'A', '3.B.10.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650003', 'Ammortamento attrezzature commerciali', 'A', '3.B.10.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650005', 'Ammortamento attrezzature d\'ufficio', 'A', '3.B.10.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650006', 'Ammortamento arredamento', 'A', '3.B.10.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('650007', 'Ammortamento automezzi', 'A', '3.B.10.b', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('651000', 'SVALUTAZIONI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('651003', 'Svalutazione magazzino', 'A', '3.B.11', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('651004', 'Svalutazione crediti', 'A', '3.B.12', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652000', 'ESISTENZA INIZIALE E RIMANENZE FINALI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652001', 'Esistenza iniziale merci', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652002', 'Esistenza iniziale imballaggi', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652003', 'Esistenza iniziale materie di consumo', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652011', 'Rimanenze finali merci', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652012', 'Rimanenze finali imballaggi', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652013', 'Rimanenze finali materie di consumo', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652021', 'Variazioni merci', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652022', 'Variazioni imballaggi', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('652023', 'Variazioni materie di consumo', 'A', '3.A.2', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('653000', 'ACCANTONAMENTI PER RISCHI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('653001', 'Accantonamenti per rischi su crediti', 'A', '3.B.12', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('653002', 'Accantonamenti su imposte', 'A', '3.B.13', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('653004', 'Altri accantonamenti rischi-oneri', 'A', '3.B.12', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('654000', 'ALTRI ACCANTONAMENTI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('654001', 'Accantonamenti per spese future', 'A', '3.B.13', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('654005', 'Accantonamenti per manutenzioni e riparazioni', 'A', '3.B.13', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('654006', 'Altri accantonamenti', 'A', '3.B.13', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655000', 'ONERI DIVERSI', 'H', '', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655001', 'Imposta di bollo', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655002', 'Tassa di concessione governativa', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655003', 'Imposte comunali', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655005', 'Imposte di esercizio', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655006', 'Perdite su crediti', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655011', 'Oneri e perdite varie', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('655012', 'Arrotondamenti negativi', 'A', '3.B.14', 'E', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('700000', 'PROVENTI E ONERI FINANZIARI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756000', 'PROVENTI FINANZIARI', 'A', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756001', 'Interessi attivi da banche', 'A', '3.C.16.d', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756002', 'Interessi attivi da clienti', 'A', '3.C.16.d', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756003', 'Interessi attivi vari', 'A', '3.C.16.d', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756004', 'Interessi su titoli', 'A', '3.C.16.d', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756011', 'Proventi finanziari vari', 'A', '3.C.16.d', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('756012', 'Utile su titoli', 'A', '3.C.16.b', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757000', 'ONERI FINANZIARI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757001', 'Interessi passivi a banche', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757002', 'Interessi passivi a fornitori', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757003', 'Interessi passivi su finanziamenti', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757004', 'Interessi passivi su mutui', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757005', 'Interessi passivi vari', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757011', 'Oneri finanziari vari', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('757012', 'Perdite su titoli', 'A', '3.C.17', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('800000', 'PROVENTI E ONERI STRAORDINARI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('860000', 'PROVENTI STRAORDINARI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('860001', 'Plusvalenze', 'A', '3.E.20', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('860002', 'Sopravvenienze e insussistenze attive', 'A', '3.E.20', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('861000', 'ONERI STRAORDINARI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('861001', 'Minusvalenze', 'A', '3.E.21', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('861002', 'Sopravvenienze e insussistenze passive', 'A', '3.E.21', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('900000', 'CONTI DI RIEPILOGO ECONOMICI', 'H', '', 'I', '');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('970001', 'Conto del risultato economico', 'A', '3.E.23', 'I', '');

INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '112001'), 0.04);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '112002'), 0.1);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '112004'), 0.2);

INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '226001'), 0.04);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '226002'), 0.1);
INSERT INTO tax (chart_id, rate) VALUES ((SELECT id FROM chart WHERE accno = '226004'), 0.2);

--
-- update defaults
--

INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', 
	(select id from chart where accno = '105001'));
INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '541001'));
INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '645001'));
INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '756011'));
INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '655011'));
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR');
INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

