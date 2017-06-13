begin;
-- Nederlandstalig Rekeningschema conform het Decimaal Stelsel.
-- Dutch Chart of Accounts following the Decimal Standards as set by the famous Philips Accounting Department
-- PDF Tammes, Fri, 29 Mar 2002 ( remarks or questions to finance@bermuda-holding.com )
-- Just delete any accounts not needed after importing the scheme, beats entering all manually (or add -- at the beginning)
-- Account groups (first number in accountnumber defines to which group it belongs)
-- 0 : Vaste Activa, Eigen Vermogen, Voorzieningen en lang vreemd vermogen => Fixed Assets, Capital, Accruals and long term loans
-- 1 : Financiele Rekeningen => Financial Accounts
-- 2 : Tussenrekeningen => Intermediate Accounts
-- 3 : Voorraad grond- en hulpstoffen => Stocks (minerals, parts not yet assembled etc)
-- 4 : Kostenrekeningen => Costs Accounts
-- 5 : Verdeling Directe kosten => Accounts to recharge several Direct Costs to separate departments
-- 6 : Fabricagekosten => Assembly Costs
-- 7 : Voorraad gereed produkt en product in bewerking => Stocks (Trade Articles, half-finished assemblies, projects under construction)
-- 8 : Rekeningen voor vaststelling van het verkoopresultaat => Accounts for dediding Sales Result
-- 9 : Rekeningen voor vaststelling van de resultatenrekening => Accounts for dediding Profit & Loss (P/L)
-- The general idea is to allocate all costs to the 4/5/6 accounts, all stock transactions to 7 and sales related to 8. At the end of the
-- year you clean out the seperate accounts via x999 and kick the result to the relevant 9xxx series. That way you have a specialized
-- P/L in the seperate accounts and an overview/shirt version of the P/L in the 9 series, where also various results not related to normal
-- operations is recorded (tax, donations, that kind of thing. Finally the 9999 account is used to kick the result to retained earnings and
-- related accounts in the balance sheet, and we are ready for the next year
--
SELECT account_heading_save(NULL,'0000','Vaste Activa & Eigen Vermogen', NULL);
SELECT account__save(NULL,'0010','Terreinen','A','0010', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0015','Afschrijving Terreinen','A','0015', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0200','Gebouwen','A','0200', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0205','Afschrijving Gebouwen','A','0205', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0230','Inventaris','A','0230', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0235','Afschrijving Inventaris','A','0235', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0240','Computers','A','0240', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0245','Afschrijving Computers','A','0245', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0250','Auto','A','0250', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0255','Afschrijving Auto','A','0255', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0260','Machines','A','0260', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0265','Afschrijving Machines','A','0265', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0290','Goodwill','A','0290', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0295','Afschrijving Goodwill','A','0295', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0370','Overige Leningen u/g','A','0370', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0380','Aandelen & Effecten','A','0380', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0381','Beleggingen Spaarbeleg','A','0381', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0390','Beleggingen Legiolease','A','0390', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0400','Aandelenkapitaal','Q','0400', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0410','Aandelen in portefeuille','Q','0410', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0420','Aandelen uit te reiken','Q','0420', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0430','Agioreserve','Q','0430', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0440','Winstreserve','Q','0440', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0450','Herwaarderingsreserve','Q','0450', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0470','Oprichtingskosten','Q','0470', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0480','Winst na belasting lopend jaar','Q','0480', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0500','Eigen Vermogen','Q','0500', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0510','Prive','Q','0510', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0550','Onverdeeld Resultaat','Q','0550', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0600','Voorziening Onderhoud','Q','0600', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0610','Voorziening Garantie','Q','0610', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0620','Voorziening Assurantie','Q','0620', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0630','Voorziening Debiteuren','Q','0630', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0700','Obligatielening','Q','0700', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0710','Obligaties in portefeuille','Q','0710', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0720','Converteerbare Obligatielening','Q','0720', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0730','Agio op Obligaties','Q','0730', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0740','Disagio op Obligaties','Q','0740', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0800','Hypothecaire lening o/g','L','0800', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'1000','Financiele Rekeningen', NULL);
SELECT account__save(NULL,'1001','Kas','A','1001', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1050','Contante Verkopen','A','1050', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1100','Interbank','A','1100', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1110','ABN-AMRO','A','1110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1119','Postbank Plus','A','1119', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1120','Postbank Giro','A','1120', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1121','Postbank Kapitaal','A','1121', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1122','Postbank Leeuw','A','1122', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1139','Postbank Effectenrekening','A','1139', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1140','Rabobank','A','1140', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1141','Rabobank Rendementrekening','A','1141', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1160','van Lanschotbank','A','1160', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1170','Finansbank','A','1170', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1180','VISA Creditcard','A','1180', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1190','Kruisposten','A','1190', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1200','Debiteuren','A','1200', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Dubieuze Debiteuren','A','1205', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1321','Rekening Courant < A','A','1321', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1322','Rekening Courant < B','A','1322', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1340','Goederen ontvangen / GO','A','1340', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1500','Te betalen loonheffing','A','1500', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1520','Te betalen Sociale Lasten','A','1520', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1530','Te betalen Pensioenpremies','A','1530', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1600','Crediteuren','L','1600', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'1605','Nog te Ontvangen Facturen / NOF','A','1605', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1610','Te betalen tantiemes','A','1610', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1615','Te betalen Vennootschapsbelasting','A','1615', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1620','Interimdividend','A','1620', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1630','Te betalen dividend','A','1630', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1640','Te betalen dividendbelasting','A','1640', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1650','Aandeelhouders nog te storten','A','1650', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1700','Te betalen interest','A','1700', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1710','Te betalen coupons','A','1710', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1770','Uitgelote obligaties','A','1770', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1800','Te vorderen BTW hoog','L','1800', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1801','Te vorderen BTW laag','L','1801', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1810','Te betalen BTW hoog','L','1810', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1811','Te betalen BTW laag','L','1811', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1850','Saldo BTW','L','1850', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1941','Rekening Courant > A','A','1941', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1942','Rekening Courant > B','A','1942', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1960','Vooruitbetaalde bedragen','A','1960', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1970','Vooruitontvangen bedragen','A','1970', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1980','Nog te ontvangen bedragen','A','1980', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1990','Nog te betalen bedragen','A','1990', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2000','Tussenrekeningen', NULL);
SELECT account__save(NULL,'2100','Vraagposten','A','2100', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2400','Onbekende betalingen','A','2400', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2800','Tussenrekening Lonen','A','2800', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2900','Tussenrekening Beginbalans','A','2900', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3000','Voorraad Grond- en Hulpstoffen', NULL);
SELECT account__save(NULL,'3010','Voorraad Grondstof A','A','3010', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL,'4000','Kostenrekeningen', NULL);
SELECT account__save(NULL,'4001','Verbruik Grondstoffen','E','4001', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4100','Directe Loonkosten','E','4100', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4110','Indirecte Loonkosten','E','4110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4120','Sociale Lasten','E','4120', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4130','Kosten Pensioenen','E','4130', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4190','Overige Personeelskosten','E','4190', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4200','Kosten externe medewerkers','E','4200', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4210','Kosten Personeelsuitjes','E','4210', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4220','Kantinekosten','E','4220', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4240','Lief en Leedpot externe medewerkers','E','4240', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4300','Afschrijvingskosten Gebouwen','E','4300', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4330','Afschrijvingskosten Inventaris','E','4330', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4340','Afschrijvingskosten Computers','E','4340', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4350','Afschrijvingskosten Autos','E','4350', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4360','Afschrijvingskosten Machines','E','4360', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4390','Afschrijvingskosten Goodwill','E','4390', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4400','Huurkosten','E','4400', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4410','Asurantiekosten','E','4410', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4520','Gas, Licht & Water','E','4520', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4530','Vaste Lasten','E','4530', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4540','Reparatie- & Onderhoudskosten','E','4540', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4560','Verzekering en Beveiliging Pand','E','4560', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4600','Directe Verkoopkosten','E','4600', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4650','Indirecte Verkoopkosten','E','4650', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4730','Relatiegeschenken','E','4730', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4740','Reis en Verblijfkosten','E','4740', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4800','Kasverschillen','E','4800', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4810','Voorraadverschillen','E','4810', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4900','Telefoon & Faxkosten','E','4900', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4910','Contributies & Abonnementen','E','4910', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4920','Verzekeringen Algemeen','E','4920', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4930','Kantoorartikelen','E','4930', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4931','Kantoorbenodigdheden','E','4931', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4932','Vakliteratuur','E','4932', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4940','Licenties & Software','E','4940', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4941','Administratie & Acountantskosten','E','4941', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4943','Notaris & Advocaatkosten','E','4943', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4950','Drukwerk & Papier','E','4950', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4970','Porti','E','4970', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4980','Bankkosten','E','4980', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4981','Bankprovisie Effectenhandel','E','4981', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4990','Overige Algemene Kosten','E','4990', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4991','Bijzondere baten en lasten','E','4991', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4999','Overboekingsrekening Rubriek 4','E','4999', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5000','Verdeling Indirecte Kosten', NULL);
SELECT account__save(NULL,'5400','Indirecte fabricagekosten','E','5400', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5450','Opslag Indirecte fabricagekosten','I','5450', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5500','Indirecte verkoopkosten','E','5500', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5550','Opslag Indirecte verkoopkosten','I','5550', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5999','Overboekingsrekening Rubriek 5','I','5999', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6000','Fabricagerekeningen', NULL);
SELECT account__save(NULL,'6001','Verbruik Grondstoffen','E','6001', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6010','Directe Lonen','E','6010', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6020','Toeslag Indirecte fabricagekosten','E','6020', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6101','Standaard Verbruik Grondstoffen','I','6101', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6110','Standaard Directe Lonen','I','6110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6120','Standaard Toeslag Indirecte fabricagekosten','I','6120', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6999','Overboekingsrekening Rubriek 6','I','6999', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'7000','Voorraden gereed product', NULL);
SELECT account__save(NULL,'7001','Voorraad A','A','7001', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7002','Voorraad B','A','7002', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7003','Voorraad C','A','7003', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7010','Voorraad Incourante goederen','A','7010', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7015','Afschrijving Incourante goederen','L','7015', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7200','Voorraad Goederen in bewerking','A','7200', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7300','Nog te Ontvangen Goederen / NOG','A','7300', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7350','Nog af te leveren goederen','L','7350', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7400','Prijsverschillen bij inkoop','I','7400', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7999','Overboekingsrekening Rubriek 7','I','7999', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'8000','Rekeningen tbv Verkoopresultaat', NULL);
SELECT account__save(NULL,'8010','Inkoopkosten algemeen','E','8010', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'8020','Kostprijs Verkopen A','E','8020', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8030','Kostprijs Verkopen B','E','8030', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8040','Kostprijs Verkopen C','E','8040', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8100','Directe Verkoopkosten','E','8100', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'8150','Toeslag Indirecte Verkoopkosten','E','8150', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8300','Kortingen bij Verkoop','E','8300', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'8500','Opbrengsten', NULL);
SELECT account__save(NULL,'8520','Opbrengst Verkopen A','I','8520', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8530','Opbrengst Verkopen B','I','8530', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8540','Opbrengst Verkopen C','I','8540', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8999','Overboekingsrekening Rubriek 8','E','8999', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'9000','Rekeningen tbv Resultatenrekening', NULL);
SELECT account__save(NULL,'9010','Resultaat Indirecte Kosten','E','9010', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9011','Resultaat Fabricage','I','9011', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9012','Resultaat Verkoop','I','9012', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9015','Resultaat Prijsverschillen','I','9015', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9030','Rente bate deposito','I','9030', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9040','Rente bate lening u/g','I','9040', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9050','Rente bate bank','I','9050', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9080','Rente bate Fiscus','I','9080', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9100','Rente last hypothecaire lening','E','9100', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9110','Rente last lening bank','E','9110', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9130','Rente last lening o/g','E','9130', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9150','Rente last bank','E','9150', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9180','Rente last Fiscus','E','9180', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9190','Rente last overig','E','9190', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9200','Ontvangen Dividend (bruto)','I','9200', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9205','Ingehouden Dividendbelasting','E','9205', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9210','Koersresultaat Effecten)','E','9210', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9220','Valutaresultaat','E','9220', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9300','Huuropbrengsten','I','9300', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9400','Resultaat tgv inhaalafschrijvingen','E','9400', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9500','Incidentele Resultaten','E','9500', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9600','Giften en Donaties','E','9600', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9700','Tantiemes','E','9700', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9800','Belasting Lopend Jaar','E','9800', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9810','Belasting Voorgaande Jaren','E','9810', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9900','Vennootschapsbelasting','E','9900', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9999','Overboekingsrekening','I','9999', NULL, false, false, string_to_array('', ':'), false, false);
--
--
insert into tax (chart_id,rate) values ((select id from account where accno = '1800'),0.19);
insert into tax (chart_id,rate) values ((select id from account where accno = '1801'),0.06);
insert into tax (chart_id,rate) values ((select id from account where accno = '1810'),0.19);
insert into tax (chart_id,rate) values ((select id from account where accno = '1811'),0.06);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '7001'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '8520'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '8010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '9220'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '9220'));

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
FROM account WHERE accno BETWEEN '1100' AND '1180';

