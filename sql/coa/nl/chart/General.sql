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
SELECT account__save(NULL,'0010','Terreinen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0015','Afschrijving Terreinen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0200','Gebouwen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0205','Afschrijving Gebouwen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0230','Inventaris','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0235','Afschrijving Inventaris','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0240','Computers','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0245','Afschrijving Computers','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0250','Auto','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0255','Afschrijving Auto','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0260','Machines','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0265','Afschrijving Machines','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0290','Goodwill','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0295','Afschrijving Goodwill','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0370','Overige Leningen u/g','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0380','Aandelen & Effecten','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0381','Beleggingen Spaarbeleg','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0390','Beleggingen Legiolease','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0400','Aandelenkapitaal','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0410','Aandelen in portefeuille','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0420','Aandelen uit te reiken','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0430','Agioreserve','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0440','Winstreserve','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0450','Herwaarderingsreserve','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0470','Oprichtingskosten','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0480','Winst na belasting lopend jaar','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0500','Eigen Vermogen','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0510','Prive','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0550','Onverdeeld Resultaat','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0600','Voorziening Onderhoud','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0610','Voorziening Garantie','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0620','Voorziening Assurantie','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0630','Voorziening Debiteuren','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0700','Obligatielening','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0710','Obligaties in portefeuille','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0720','Converteerbare Obligatielening','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0730','Agio op Obligaties','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0740','Disagio op Obligaties','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'0800','Hypothecaire lening o/g','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'1000','Financiele Rekeningen', NULL);
SELECT account__save(NULL,'1001','Kas','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1050','Contante Verkopen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1100','Interbank','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1110','ABN-AMRO','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1119','Postbank Plus','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1120','Postbank Giro','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1121','Postbank Kapitaal','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1122','Postbank Leeuw','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1139','Postbank Effectenrekening','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1140','Rabobank','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1141','Rabobank Rendementrekening','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1160','van Lanschotbank','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1170','Finansbank','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1180','VISA Creditcard','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1190','Kruisposten','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1200','Debiteuren','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Dubieuze Debiteuren','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1321','Rekening Courant < A','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1322','Rekening Courant < B','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1340','Goederen ontvangen / GO','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1500','Te betalen loonheffing','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1520','Te betalen Sociale Lasten','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1530','Te betalen Pensioenpremies','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1600','Crediteuren','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'1605','Nog te Ontvangen Facturen / NOF','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1610','Te betalen tantiemes','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1615','Te betalen Vennootschapsbelasting','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1620','Interimdividend','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1630','Te betalen dividend','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1640','Te betalen dividendbelasting','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1650','Aandeelhouders nog te storten','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1700','Te betalen interest','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1710','Te betalen coupons','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1770','Uitgelote obligaties','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1800','Te vorderen BTW hoog','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1801','Te vorderen BTW laag','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1810','Te betalen BTW hoog','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1811','Te betalen BTW laag','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'1850','Saldo BTW','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1941','Rekening Courant > A','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1942','Rekening Courant > B','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1960','Vooruitbetaalde bedragen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1970','Vooruitontvangen bedragen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1980','Nog te ontvangen bedragen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1990','Nog te betalen bedragen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'2000','Tussenrekeningen', NULL);
SELECT account__save(NULL,'2100','Vraagposten','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2400','Onbekende betalingen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2800','Tussenrekening Lonen','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2900','Tussenrekening Beginbalans','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3000','Voorraad Grond- en Hulpstoffen', NULL);
SELECT account__save(NULL,'3010','Voorraad Grondstof A','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL,'4000','Kostenrekeningen', NULL);
SELECT account__save(NULL,'4001','Verbruik Grondstoffen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4100','Directe Loonkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4110','Indirecte Loonkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4120','Sociale Lasten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4130','Kosten Pensioenen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4190','Overige Personeelskosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4200','Kosten externe medewerkers','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4210','Kosten Personeelsuitjes','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4220','Kantinekosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4240','Lief en Leedpot externe medewerkers','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4300','Afschrijvingskosten Gebouwen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4330','Afschrijvingskosten Inventaris','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4340','Afschrijvingskosten Computers','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4350','Afschrijvingskosten Autos','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4360','Afschrijvingskosten Machines','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4390','Afschrijvingskosten Goodwill','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4400','Huurkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4410','Asurantiekosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4520','Gas, Licht & Water','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4530','Vaste Lasten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4540','Reparatie- & Onderhoudskosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4560','Verzekering en Beveiliging Pand','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4600','Directe Verkoopkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4650','Indirecte Verkoopkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4730','Relatiegeschenken','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4740','Reis en Verblijfkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4800','Kasverschillen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4810','Voorraadverschillen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4900','Telefoon & Faxkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4910','Contributies & Abonnementen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4920','Verzekeringen Algemeen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4930','Kantoorartikelen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4931','Kantoorbenodigdheden','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4932','Vakliteratuur','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4940','Licenties & Software','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4941','Administratie & Acountantskosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4943','Notaris & Advocaatkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4950','Drukwerk & Papier','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4970','Porti','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4980','Bankkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4981','Bankprovisie Effectenhandel','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4990','Overige Algemene Kosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4991','Bijzondere baten en lasten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4999','Overboekingsrekening Rubriek 4','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'5000','Verdeling Indirecte Kosten', NULL);
SELECT account__save(NULL,'5400','Indirecte fabricagekosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5450','Opslag Indirecte fabricagekosten','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5500','Indirecte verkoopkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5550','Opslag Indirecte verkoopkosten','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5999','Overboekingsrekening Rubriek 5','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'6000','Fabricagerekeningen', NULL);
SELECT account__save(NULL,'6001','Verbruik Grondstoffen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6010','Directe Lonen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6020','Toeslag Indirecte fabricagekosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6101','Standaard Verbruik Grondstoffen','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6110','Standaard Directe Lonen','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6120','Standaard Toeslag Indirecte fabricagekosten','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'6999','Overboekingsrekening Rubriek 6','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'7000','Voorraden gereed product', NULL);
SELECT account__save(NULL,'7001','Voorraad A','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7002','Voorraad B','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7003','Voorraad C','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7010','Voorraad Incourante goederen','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7015','Afschrijving Incourante goederen','L','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7200','Voorraad Goederen in bewerking','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7300','Nog te Ontvangen Goederen / NOG','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7350','Nog af te leveren goederen','L','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7400','Prijsverschillen bij inkoop','I','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'7999','Overboekingsrekening Rubriek 7','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'8000','Rekeningen tbv Verkoopresultaat', NULL);
SELECT account__save(NULL,'8010','Inkoopkosten algemeen','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'8020','Kostprijs Verkopen A','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8030','Kostprijs Verkopen B','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8040','Kostprijs Verkopen C','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8100','Directe Verkoopkosten','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL,'8150','Toeslag Indirecte Verkoopkosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'8300','Kortingen bij Verkoop','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'8500','Opbrengsten', NULL);
SELECT account__save(NULL,'8520','Opbrengst Verkopen A','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8530','Opbrengst Verkopen B','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8540','Opbrengst Verkopen C','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'8999','Overboekingsrekening Rubriek 8','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'9000','Rekeningen tbv Resultatenrekening', NULL);
SELECT account__save(NULL,'9010','Resultaat Indirecte Kosten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9011','Resultaat Fabricage','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9012','Resultaat Verkoop','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9015','Resultaat Prijsverschillen','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9030','Rente bate deposito','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9040','Rente bate lening u/g','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9050','Rente bate bank','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9080','Rente bate Fiscus','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9100','Rente last hypothecaire lening','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9110','Rente last lening bank','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9130','Rente last lening o/g','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9150','Rente last bank','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9180','Rente last Fiscus','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9190','Rente last overig','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9200','Ontvangen Dividend (bruto)','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9205','Ingehouden Dividendbelasting','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9210','Koersresultaat Effecten)','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9220','Valutaresultaat','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9300','Huuropbrengsten','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9400','Resultaat tgv inhaalafschrijvingen','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9500','Incidentele Resultaten','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9600','Giften en Donaties','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9700','Tantiemes','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9800','Belasting Lopend Jaar','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9810','Belasting Voorgaande Jaren','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9900','Vennootschapsbelasting','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9999','Overboekingsrekening','I','', NULL, false, false, string_to_array('', ':'), false, false);
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


INSERT INTO currency (curr, description)
   VALUES
      ('EUR', 'EUR'),
      ('USD', 'USD');
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
FROM account WHERE accno IN ('1100', '1110', '1119', '1120', '1121', '1122',
                             '1139', '1140', '1141', '1160', '1170', '1180');

