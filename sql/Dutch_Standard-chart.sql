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
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0000','Vaste Activa & Eigen Vermogen','H','0000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0010','Terreinen','A','0010','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0015','Afschrijving Terreinen','A','0015','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0200','Gebouwen','A','0200','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0205','Afschrijving Gebouwen','A','0205','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0230','Inventaris','A','0230','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0235','Afschrijving Inventaris','A','0235','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0240','Computers','A','0240','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0245','Afschrijving Computers','A','0245','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0250','Auto','A','0250','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0255','Afschrijving Auto','A','0255','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0260','Machines','A','0260','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0265','Afschrijving Machines','A','0265','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0290','Goodwill','A','0290','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0295','Afschrijving Goodwill','A','0295','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0370','Overige Leningen u/g','A','0370','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0380','Aandelen & Effecten','A','0380','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0381','Beleggingen Spaarbeleg','A','0381','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0390','Beleggingen Legiolease','A','0390','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0400','Aandelenkapitaal','A','0400','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0410','Aandelen in portefeuille','A','0410','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0420','Aandelen uit te reiken','A','0420','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0430','Agioreserve','A','0430','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0440','Winstreserve','A','0440','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0450','Herwaarderingsreserve','A','0450','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0470','Oprichtingskosten','A','0470','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0480','Winst na belasting lopend jaar','A','0480','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0500','Eigen Vermogen','A','0500','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0510','Prive','A','0510','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0550','Onverdeeld Resultaat','A','0550','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0600','Voorziening Onderhoud','A','0600','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0610','Voorziening Garantie','A','0610','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0620','Voorziening Assurantie','A','0620','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0630','Voorziening Debiteuren','A','0630','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0700','Obligatielening','A','0700','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0710','Obligaties in portefeuille','A','0710','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0720','Converteerbare Obligatielening','A','0720','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0730','Agio op Obligaties','A','0730','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0740','Disagio op Obligaties','A','0740','Q','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('0800','Hypothecaire lening o/g','A','0800','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1000','Financiele Rekeningen','H','1000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1001','Kas','A','1001','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1050','Contante Verkopen','A','1050','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1100','Interbank','A','1100','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1110','ABN-AMRO','A','1110','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1119','Postbank Plus','A','1119','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1120','Postbank Giro','A','1120','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1121','Postbank Kapitaal','A','1121','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1122','Postbank Leeuw','A','1122','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1139','Postbank Effectenrekening','A','1139','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1140','Rabobank','A','1140','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1141','Rabobank Rendementrekening','A','1141','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1160','van Lanschotbank','A','1160','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1170','Finansbank','A','1170','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1180','VISA Creditcard','A','1180','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1190','Kruisposten','A','1190','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1200','Debiteuren','A','1200','A','AR');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1205','Dubieuze Debiteuren','A','1205','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1321','Rekening Courant < A','A','1321','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1322','Rekening Courant < B','A','1322','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1340','Goederen ontvangen / GO','A','1340','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1500','Te betalen loonheffing','A','1500','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1520','Te betalen Sociale Lasten','A','1520','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1530','Te betalen Pensioenpremies','A','1530','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1600','Crediteuren','A','1600','L','AP');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1605','Nog te Ontvangen Facturen / NOF','A','1605','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1610','Te betalen tantiemes','A','1610','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1615','Te betalen Vennootschapsbelasting','A','1615','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1620','Interimdividend','A','1620','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1630','Te betalen dividend','A','1630','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1640','Te betalen dividendbelasting','A','1640','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1650','Aandeelhouders nog te storten','A','1650','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1700','Te betalen interest','A','1700','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1710','Te betalen coupons','A','1710','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1770','Uitgelote obligaties','A','1770','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1800','Te vorderen BTW hoog','A','1800','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1801','Te vorderen BTW laag','A','1801','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1810','Te betalen BTW hoog','A','1810','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1811','Te betalen BTW laag','A','1811','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1850','Saldo BTW','A','1850','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1941','Rekening Courant > A','A','1941','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1942','Rekening Courant > B','A','1942','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1960','Vooruitbetaalde bedragen','A','1960','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1970','Vooruitontvangen bedragen','A','1970','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1980','Nog te ontvangen bedragen','A','1980','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('1990','Nog te betalen bedragen','A','1990','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2000','Tussenrekeningen','H','2000','L','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2100','Vraagposten','A','2100','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2400','Onbekende betalingen','A','2400','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2800','Tussenrekening Lonen','A','2800','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('2900','Tussenrekening Beginbalans','A','2900','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3000','Voorraad Grond- en Hulpstoffen','H','3000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('3010','Voorraad Grondstof A','A','3010','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4000','Kostenrekeningen','H','4000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4001','Verbruik Grondstoffen','A','4001','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4100','Directe Loonkosten','A','4100','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4110','Indirecte Loonkosten','A','4110','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4120','Sociale Lasten','A','4120','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4130','Kosten Pensioenen','A','4130','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4190','Overige Personeelskosten','A','4190','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4200','Kosten externe medewerkers','A','4200','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4210','Kosten Personeelsuitjes','A','4210','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4220','Kantinekosten','A','4220','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4240','Lief en Leedpot externe medewerkers','A','4240','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4300','Afschrijvingskosten Gebouwen','A','4300','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4330','Afschrijvingskosten Inventaris','A','4330','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4340','Afschrijvingskosten Computers','A','4340','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4350','Afschrijvingskosten Autos','A','4350','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4360','Afschrijvingskosten Machines','A','4360','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4390','Afschrijvingskosten Goodwill','A','4390','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4400','Huurkosten','A','4400','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4410','Asurantiekosten','A','4410','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4520','Gas, Licht & Water','A','4520','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4530','Vaste Lasten','A','4530','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4540','Reparatie- & Onderhoudskosten','A','4540','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4560','Verzekering en Beveiliging Pand','A','4560','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4600','Directe Verkoopkosten','A','4600','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4650','Indirecte Verkoopkosten','A','4650','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4730','Relatiegeschenken','A','4730','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4740','Reis en Verblijfkosten','A','4740','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4800','Kasverschillen','A','4800','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4810','Voorraadverschillen','A','4810','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4900','Telefoon & Faxkosten','A','4900','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4910','Contributies & Abonnementen','A','4910','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4920','Verzekeringen Algemeen','A','4920','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4930','Kantoorartikelen','A','4930','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4931','Kantoorbenodigdheden','A','4931','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4932','Vakliteratuur','A','4932','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4940','Licenties & Software','A','4940','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4941','Administratie & Acountantskosten','A','4941','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4943','Notaris & Advocaatkosten','A','4943','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4950','Drukwerk & Papier','A','4950','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4970','Porti','A','4970','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4980','Bankkosten','A','4980','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4981','Bankprovisie Effectenhandel','A','4981','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4990','Overige Algemene Kosten','A','4990','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4991','Bijzondere baten en lasten','A','4991','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('4999','Overboekingsrekening Rubriek 4','A','4999','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5000','Verdeling Indirecte Kosten','H','5000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5400','Indirecte fabricagekosten','A','5400','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5450','Opslag Indirecte fabricagekosten','A','5450','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5500','Indirecte verkoopkosten','A','5500','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5550','Opslag Indirecte verkoopkosten','A','5550','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('5999','Overboekingsrekening Rubriek 5','A','5999','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6000','Fabricagerekeningen','H','6000','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6001','Verbruik Grondstoffen','A','6001','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6010','Directe Lonen','A','6010','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6020','Toeslag Indirecte fabricagekosten','A','6020','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6101','Standaard Verbruik Grondstoffen','A','6101','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6110','Standaard Directe Lonen','A','6110','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6120','Standaard Toeslag Indirecte fabricagekosten','A','6120','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('6999','Overboekingsrekening Rubriek 6','A','6999','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7000','Voorraden gereed product','H','7000','A','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7001','Voorraad A','A','7001','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7002','Voorraad B','A','7002','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7003','Voorraad C','A','7003','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7010','Voorraad Incourante goederen','A','7010','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7015','Afschrijving Incourante goederen','A','7015','L','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7200','Voorraad Goederen in bewerking','A','7200','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7300','Nog te Ontvangen Goederen / NOG','A','7300','A','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7350','Nog af te leveren goederen','A','7350','L','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7400','Prijsverschillen bij inkoop','A','7400','I','IC');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('7999','Overboekingsrekening Rubriek 7','A','7999','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8000','Rekeningen tbv Verkoopresultaat','H','8000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8010','Inkoopkosten algemeen','A','8010','E','AP_amount:IC_cogs:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8020','Kostprijs Verkopen A','A','8020','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8030','Kostprijs Verkopen B','A','8030','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8040','Kostprijs Verkopen C','A','8040','E','AP_amount:IC_cogs');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8100','Directe Verkoopkosten','A','8100','E','AP_amount:IC_expense');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8150','Toeslag Indirecte Verkoopkosten','E','8150','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8300','Kortingen bij Verkoop','A','8300','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8520','Opbrengst Verkopen A','A','8520','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8530','Opbrengst Verkopen B','A','8530','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8540','Opbrengst Verkopen C','A','8540','I','AR_amount:IC_sale');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('8999','Overboekingsrekening Rubriek 8','A','8999','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9000','Rekeningen tbv Resultatenrekening','H','9000','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9010','Resultaat Indirecte Kosten','A','9010','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9011','Resultaat Fabricage','A','9011','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9012','Resultaat Verkoop','A','9012','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9015','Resultaat Prijsverschillen','A','9015','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9030','Rente bate deposito','A','9030','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9040','Rente bate lening u/g','A','9040','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9050','Rente bate bank','A','9050','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9080','Rente bate Fiscus','A','9080','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9100','Rente last hypothecaire lening','A','9100','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9110','Rente last lening bank','A','9110','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9130','Rente last lening o/g','A','9130','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9150','Rente last bank','A','9150','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9180','Rente last Fiscus','A','9180','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9190','Rente last overig','A','9190','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9200','Ontvangen Dividend (bruto)','A','9200','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9205','Ingehouden Dividendbelasting','A','9205','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9210','Koersresultaat Effecten)','A','9210','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9220','Valutaresultaat','A','9220','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9300','Huuropbrengsten','A','9300','I','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9400','Resultaat tgv inhaalafschrijvingen','A','9400','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9500','Incidentele Resultaten','A','9500','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9600','Giften en Donaties','A','9600','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9700','Tantiemes','A','9700','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9800','Belasting Lopend Jaar','A','9800','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9810','Belasting Voorgaande Jaren','A','9810','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9900','Vennootschapsbelasting','A','9900','E','');
INSERT INTO chart (accno,description,charttype,gifi_accno,category,link) VALUES ('9999','Overboekingsrekening','A','9999','I','');
--
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '1800'),0.19);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1801'),0.06);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1810'),0.19);
insert into tax (chart_id,rate) values ((select id from chart where accno = '1811'),0.06);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '7001'));

 INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '8520'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '8010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '9220'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '9220'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
