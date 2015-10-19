begin;
-- General French-Canadian (AKA Québécois) COA
-- sample only

-- translated and adapted from the General Canadian COA, with the help
-- of the Grand Dictionnaire Terminologique:
-- http://granddictionnaire.com/

-- Some provisions have been made for Québec-specifics, namely:
-- TVQ/TPS terminology, CSST, Assurance-emploi, RRQ, TVQ rate

SELECT account_heading_save(NULL, '1000', 'ACTIF COURANT', NULL);
SELECT account__save(NULL,'1060','Compte chèque','A','1002', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Petite caisse','A','1001', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1060', '1065');

SELECT account__save(NULL,'1200','Comptes clients','A','1060', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Provisions pour créances douteuses','A','1063', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1500', 'INVENTAIRE', NULL);
SELECT account__save(NULL,'1520','Inventaire / Général','A','1122', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Inventaire / Pièces de rechange','A','1122', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','Inventaire / Matières premières','A','1122', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1800', 'AUTRES IMMOBILISATIONS', NULL);
SELECT account__save(NULL,'1820','Meubles et accessoires','A','1787', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','Amortissement cumulé des meubles et des accessoires','A','1788', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Véhicules automobiles','A','1742', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','Amortissement cumulé des véhicules automobiles','A','1743', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2000', 'PASSIF COURANT', NULL);
SELECT account__save(NULL,'2100','Comptes fournisseurs','L','2621', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2160','Taxes fédérales à payer','L','2683', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2170','Taxes provinciales à payer','L','2684', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','TPS','L','2685', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2320','TVQ','L','2686', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2380','Indemnités de vacances à payer','L','2624', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2390','CSST à payer','L','2627', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2400', 'RETENUES SUR SALAIRE', NULL);
SELECT account__save(NULL,'2410','Assurance-emploi à payer','L','2627', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2420','RRQ à payer','L','2627', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2450','Impôt sur le revenu à payer','L','2628', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2600', 'PASSIF À LONG TERME', NULL);
SELECT account__save(NULL,'2620','Emprunts bancaires','L','2701', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Emprunt auprès des actionnaires','L','2780', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3300', 'CAPITAL SOCIAL', NULL);
SELECT account__save(NULL,'3350','Actions ordinaires','Q','3500', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '4000', 'REVENUS DE VENTE', NULL);
SELECT account__save(NULL,'4020','Ventes générales','I','8000', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'4030','Pièces de rechange','I','8000', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '4400', 'AUTRES REVENUS', NULL);
SELECT account__save(NULL,'4430','Transport et manutention','I','8457', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Intérêts','I','8090', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4450','Gain sur change','I','8231', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5000', 'COÛT DES PRODUITS VENDUS', NULL);
SELECT account__save(NULL,'5010','Achats','E','8320', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5050','Pièces de rechange','E','8320', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Frais de transport','E','8457', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5400', 'FRAIS DE PERSONNEL', NULL);
SELECT account__save(NULL,'5410','Salaires','E','9060', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','Dépenses d''assurance-emploi','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','Dépenses RRQ','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','Dépenses CSST','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5450','Dépenses FSS','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5460','Dépenses RQAP','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5470','Dépenses vacances','E','8622', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5600', 'DÉPENSES ADMINISTRATIVES ET GÉNÉRALES', NULL);
SELECT account__save(NULL,'5610','Frais comptables et juridiques','E','8862', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Publicité et promotion','E','8520', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Créances irrévocables','E','8590', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Amortissement de l''exercice','E','8670', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','Impôt sur le revenu','E','9990', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Assurances','E','9804', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Intérêts et frais bancaires','E','9805', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Fournitures de bureau','E','8811', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Loyer','E','9811', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Téléphone','E','9225', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Voyages et loisirs','E','8523', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Services publics','E','8812', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Réparation et entretien','E','8964', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Taxes d''affaires, droits d''adhésion et permis','E','8760', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Perte sur change','E','8231', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2310'),0.05);
insert into tax (chart_id,rate,pass) values ((select id from account where accno = '2320'),0.075,1);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'CAD:USD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

