-- General French-Canadian (AKA Québécois) COA
-- sample only

-- translated and adapted from the General Canadian COA, with the help
-- of the Grand Dictionnaire Terminologique:
-- http://granddictionnaire.com/

-- Some provisions have been made for Québec-specifics, namely:
-- TVQ/TPS terminology, CSST, Assurance-emploi, RRQ, TVQ rate

INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1000', 'ACTIF COURANT', 'H', 'A', '', '1000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1060', 'Compte chèque', 'A', 'A', 'AR_paid:AP_paid', '1002');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1065', 'Petite caisse', 'A', 'A', 'AR_paid:AP_paid', '1001');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1200', 'Comptes clients', 'A', 'A', 'AR', '1060');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1205', 'Provisions pour créances douteuses', 'A', 'A', '', '1063');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1500', 'STOCKS', 'H', 'A', '', '1120');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1520', 'Stocks / Général', 'A', 'A', 'IC', '1122');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1530', 'Stocks / Pièces de rechange', 'A', 'A', 'IC', '1122');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1540', 'Stocks / Matières premières', 'A', 'A', 'IC', '1122');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1800', 'AUTRES IMMOBILISATIONS', 'H', 'A', '', '1900');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1820', 'Meubles et accessoires', 'A', 'A', '', '1787');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,contra) VALUES ('1825', 'Amortissement cumulé des meubles et des accessoires', 'A', 'A', '', '1788', '1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1840', 'Véhicules automobiles', 'A', 'A', '', '1742');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno,contra) VALUES ('1845', 'Amortissement cumulé des véhicules automobiles', 'A', 'A', '', '1743', '1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2000', 'PASSIF COURANT', 'H', 'L', '', '2620');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2100', 'Comptes fournisseurs', 'A', 'L', 'AP', '2621');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2160', 'Taxes fédérales à payer', 'A', 'L', '', '2683');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2170', 'Taxes provinciales à payer', 'A', 'L', '', '2684');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2310', 'TPS', 'A', 'L', 'AR_tax:AP_tax:IC_taxpart:IC_taxservice', '2685');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2320', 'TVQ', 'A', 'L', 'AR_tax:AP_tax:IC_taxpart:IC_taxservice', '2686');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2380', 'Indemnités de vacances à payer', 'A', 'L', '', '2624');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2390', 'CSST à payer', 'A', 'L', '', '2627');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2400', 'RETENUES SUR SALAIRE', 'H', 'L', '', '2620');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2410', 'Assurance-emploi à payer', 'A', 'L', '', '2627');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2420', 'RRQ à payer', 'A', 'L', '', '2627');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2450', 'Impôt sur le revenu à payer', 'A', 'L', '', '2628');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2600', 'PASSIF À LONG TERME', 'H', 'L', '', '3140');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2620', 'Emprunts bancaires', 'A', 'L', '', '2701');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2680', 'Emprunt auprès des actionnaires', 'A', 'L', 'AP_paid', '2780');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3300', 'CAPITAL SOCIAL', 'H', 'Q', '', '3500');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3350', 'Actions ordinaires', 'A', 'Q', '', '3500');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4000', 'REVENUS DE VENTE', 'H', 'I', '', '8000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4020', 'Ventes générales', 'A', 'I', 'AR_amount:IC_sale:IC_income', '8000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4030', 'Pièces de rechange', 'A', 'I', 'AR_amount:IC_sale', '8000');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4400', 'AUTRES REVENUS', 'H', 'I', '', '8090');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4430', 'Transport et manutention', 'A', 'I', 'IC_income', '8457');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4440', 'Intérêts', 'A', 'I', 'IC_income', '8090');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4450', 'Gain sur change', 'A', 'I', '', '8231');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5000', 'COÛT DES PRODUITS VENDUS', 'H', 'E', '', '8515');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5010', 'Achats', 'A', 'E', 'AP_amount:IC_cogs:IC_expense', '8320');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5050', 'Pièces de rechange', 'A', 'E', 'AP_amount:IC_cogs', '8320');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5100', 'Frais de transport', 'A', 'E', 'AP_amount:IC_expense', '8457');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5400', 'FRAIS DE PERSONNEL', 'H', 'E', '', '');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5410', 'Salaires', 'A', 'E', '', '9060');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5420', 'Dépenses d\'assurance-emploi', 'A', 'E', '', '8622');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5430', 'Dépenses RRQ', 'A', 'E', '', '8622');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5440', 'Dépenses CSST', 'A', 'E', '', '8622');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5600', 'DÉPENSES ADMINISTRATIVES ET GÉNÉRALES', 'H', 'E', '', '');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5610', 'Frais comptables et juridiques', 'A', 'E', 'AP_amount', '8862');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5615', 'Publicité et promotion', 'A', 'E', 'AP_amount', '8520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5620', 'Créances irrévocables', 'A', 'E', '', '8590');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5660', 'Amortissement de l\'exercice', 'A', 'E', '', '8670');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5680', 'Impôt sur le revenu', 'A', 'E', '', '9990');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5685', 'Assurances', 'A', 'E', 'AP_amount', '9804');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5690', 'Intérêts et frais bancaires', 'A', 'E', '', '9805');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5700', 'Fournitures de bureau', 'A', 'E', 'AP_amount', '8811');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5760', 'Loyer', 'A', 'E', 'AP_amount', '9811');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5780', 'Téléphone', 'A', 'E', 'AP_amount', '9225');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5785', 'Voyages et loisirs', 'A', 'E', '', '8523');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5790', 'Services publics', 'A', 'E', 'AP_amount', '8812');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5765', 'Réparation et entretien', 'A', 'E', 'AP_amount', '8964');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5800', 'Taxes d\'affaires, droits d\'adhésion et permis', 'A', 'E', 'AP_amount', '8760');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5810', 'Perte sur change', 'A', 'E', '', '8231');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.06);
insert into tax (chart_id,rate,pass) values ((select id from chart where accno = '2320'),0.075,1);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'CAD:USD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
