--Hungarian chart of accounts 
-- Magyar fõkönyvi számlák, amelyek csak példaként szolgálnak
--
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1140','Irodai eszközök','A','A','','114');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1199','Irodai eszközök ÉCS','A','A','','119');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2610','Áruk ','A','A','IC','261');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3110','Vevõk','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3111','Külföldi vevõk','A','A','AR','311');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3810','Pénztár 1','A','A','AR_paid:AP_paid','381');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3811','Pénztár 2','A','A','AR_paid:AP_paid','381');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3840','Bank 1','A','A','AR_paid:AP_paid','384');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3841','Bank 2','A','A','AR_paid:AP_paid','384');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4540','Belföldi Szállítók','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4541','Külföldi szállítók','A','L','AP','454');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4660','Visszaigényelhetõ ÁFA 25%','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4661','Visszaigényelhetõ ÁFA 12%','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4662','Visszaigényelhetõ ÁFA 5%','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4663','Visszaigényelhetõ ÁFA adómentes','A','L','AP_tax:IC_taxpart:IC_taxservice','466');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4670','Fizetendõ ÁFA 25%','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4671','Fizetendõ ÁFA 15%','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4672','Fizetendõ ÁFA 5%','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4673','Fizetendõ ÁFA adómentes','A','L','AR_tax:IC_taxpart:IC_taxservice','467');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5200','Bérleti díj','A','E','AP_amount','520');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5210','Telefon','A','E','AP_amount','521');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5990','Költségek','A','E','IC_expense','599');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8140','Eladott áruk beszerzési értéke','A','E','IC_cogs','814');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8700','Árfolyamveszteség','A','E','','870');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9110','Belföldi árbevétel','A','I','AR_amount:IC_sale:IC_income','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9111','Külföldi árbevétel','A','I','AR_amount:IC_sale:IC_income','911');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9700','Árfolyamnyereség','A','I','','970');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('1','BEFEKTETETT ESZKÖZÖK','H','A','','1');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('2','KÉSZLETEK','H','A','','2');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('3','KÖVETELÉSEK','H','A','','3');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('4','KÖTELEZETTSÉGEK','H','L','','4');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('5','KÖLTSÉGEK','H','E','','5');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('8','RÁFORDÍTÁSOK','H','E','','8');
INSERT INTO chart (accno,description,charttype,category,link,gifi_accno) VALUES ('9','BEVÉTELEK','H','I','','9');
--
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4660'),'0.25','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4661'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4662'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4663'),'0','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4670'),'0.25','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4671'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4672'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4673'),'0','');
--
 SET inventory_accno_id = (SELECT id FROM chart WHERE accno = '2110'));

 INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (SELECT id FROM chart WHERE accno = '9110'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM chart WHERE accno = '8140'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM chart WHERE accno = '9700'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM chart WHERE accno = '8700'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'HUF:EUR:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
