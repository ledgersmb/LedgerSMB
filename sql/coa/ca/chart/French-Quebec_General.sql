begin;
-- General French-Canadian (AKA Québécois) COA
-- sample only

-- translated and adapted from the General Canadian COA, with the help
-- of the Grand Dictionnaire Terminologique:
-- http://granddictionnaire.com/

-- Some provisions have been made for Québec-specifics, namely:
-- TVQ/TPS terminology, CSST, Assurance-emploi, RRQ, TVQ rate

SELECT account_heading_save(NULL, '1000', 'ACTIF COURANT', NULL);
SELECT account_save(NULL,'1060','Compte chèque','1002','A', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'1065','Petite caisse','1001','A', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'1200','Comptes clients','1060','A', NULL, false,string_to_array('AR', ':'));
SELECT account_save(NULL,'1205','Provisions pour créances douteuses','1063','A', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '1500', 'INVENTAIRE', NULL);
SELECT account_save(NULL,'1520','Inventaire / Général','1122','A', NULL, false,string_to_array('IC', ':'));
SELECT account_save(NULL,'1530','Inventaire / Pièces de rechange','1122','A', NULL, false,string_to_array('IC', ':'));
SELECT account_save(NULL,'1540','Inventaire / Matières premières','1122','A', NULL, false,string_to_array('IC', ':'));
SELECT account_heading_save(NULL, '1800', 'AUTRES IMMOBILISATIONS', NULL);
SELECT account_save(NULL,'1820','Meubles et accessoires','1787','A', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'1825','Amortissement cumulé des meubles et des accessoires','A','1788', NULL, '1',string_to_array('', ':'));
SELECT account_save(NULL,'1840','Véhicules automobiles','1742','A', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'1845','Amortissement cumulé des véhicules automobiles','A','1743', NULL, '1',string_to_array('', ':'));
SELECT account_heading_save(NULL, '2000', 'PASSIF COURANT', NULL);
SELECT account_save(NULL,'2100','Comptes fournisseurs','2621','L', NULL, false,string_to_array('AP', ':'));
SELECT account_save(NULL,'2160','Taxes fédérales à payer','2683','L', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2170','Taxes provinciales à payer','2684','L', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2310','TPS','2685','L', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'2320','TVQ','2686','L', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'2380','Indemnités de vacances à payer','2624','L', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2390','CSST à payer','2627','L', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '2400', 'RETENUES SUR SALAIRE', NULL);
SELECT account_save(NULL,'2410','Assurance-emploi à payer','2627','L', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2420','RRQ à payer','2627','L', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2450','Impôt sur le revenu à payer','2628','L', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '2600', 'PASSIF À LONG TERME', NULL);
SELECT account_save(NULL,'2620','Emprunts bancaires','2701','L', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2680','Emprunt auprès des actionnaires','2780','L', NULL, false,string_to_array('AP_paid', ':'));
SELECT account_heading_save(NULL, '3300', 'CAPITAL SOCIAL', NULL);
SELECT account_save(NULL,'3350','Actions ordinaires','3500','Q', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '4000', 'REVENUS DE VENTE', NULL);
SELECT account_save(NULL,'4020','Ventes générales','8000','I', NULL, false,string_to_array('AR_amount:IC_sale:IC_income', ':'));
SELECT account_save(NULL,'4030','Pièces de rechange','8000','I', NULL, false,string_to_array('AR_amount:IC_sale', ':'));
SELECT account_heading_save(NULL, '4400', 'AUTRES REVENUS', NULL);
SELECT account_save(NULL,'4430','Transport et manutention','8457','I', NULL, false,string_to_array('IC_income', ':'));
SELECT account_save(NULL,'4440','Intérêts','8090','I', NULL, false,string_to_array('IC_income', ':'));
SELECT account_save(NULL,'4450','Gain sur change','8231','I', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '5000', 'COÛT DES PRODUITS VENDUS', NULL);
SELECT account_save(NULL,'5010','Achats','8320','E', NULL, false,string_to_array('AP_amount:IC_cogs:IC_expense', ':'));
SELECT account_save(NULL,'5050','Pièces de rechange','8320','E', NULL, false,string_to_array('AP_amount:IC_cogs', ':'));
SELECT account_save(NULL,'5100','Frais de transport','8457','E', NULL, false,string_to_array('AP_amount:IC_expense', ':'));
SELECT account_heading_save(NULL, '5400', 'FRAIS DE PERSONNEL', NULL);
SELECT account_save(NULL,'5410','Salaires','9060','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5420','Dépenses d''assurance-emploi','8622','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5430','Dépenses RRQ','8622','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5440','Dépenses CSST','8622','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5450','Dépenses FSS','8622','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5460','Dépenses RQAP','8622','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5470','Dépenses vacances','8622','E', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL, '5600', 'DÉPENSES ADMINISTRATIVES ET GÉNÉRALES', NULL);
SELECT account_save(NULL,'5610','Frais comptables et juridiques','8862','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5615','Publicité et promotion','8520','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5620','Créances irrévocables','8590','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5660','Amortissement de l''exercice','8670','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5680','Impôt sur le revenu','9990','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5685','Assurances','9804','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5690','Intérêts et frais bancaires','9805','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5700','Fournitures de bureau','8811','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5760','Loyer','9811','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5780','Téléphone','9225','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5785','Voyages et loisirs','8523','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5790','Services publics','8812','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5765','Réparation et entretien','8964','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5800','Taxes d''affaires, droits d''adhésion et permis','8760','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5810','Perte sur change','8231','E', NULL, false,string_to_array('', ':'));
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.05);
insert into tax (chart_id,rate,pass) values ((select id from chart where accno = '2320'),0.075,1);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'CAD:USD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
commit;
