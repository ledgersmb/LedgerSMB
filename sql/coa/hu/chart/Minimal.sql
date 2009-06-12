begin;
--Hungarian chart of accounts 
-- Magyar fõkönyvi számlák, amelyek csak példaként szolgálnak
--
SELECT account_heading_save(NULL, '1', 'BEFEKTETETT ESZKÖZÖK', NULL);
SELECT account_heading_save(NULL, '2', 'KÉSZLETEK', NULL);
SELECT account_heading_save(NULL, '3', 'KÖVETELÉSEK', NULL);
SELECT account_heading_save(NULL, '4', 'KÖTELEZETTSÉGEK', NULL);
SELECT account_heading_save(NULL, '5', 'KÖLTSÉGEK', NULL);
SELECT account_heading_save(NULL, '8', 'RÁFORDÍTÁSOK', NULL);
SELECT account_heading_save(NULL, '9', 'BEVÉTELEK', NULL);
SELECT account_save(NULL,'1140','Irodai eszközök','114','A', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'1199','Irodai eszközök ÉCS','119','A', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2610','Áruk ','261','A', NULL, false,string_to_array('IC', ':'));
SELECT account_save(NULL,'3110','Vevõk','311','A', NULL, false,string_to_array('AR', ':'));
SELECT account_save(NULL,'3111','Külföldi vevõk','311','A', NULL, false,string_to_array('AR', ':'));
SELECT account_save(NULL,'3810','Pénztár 1','381','A', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'3811','Pénztár 2','381','A', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'3840','Bank 1','384','A', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'3841','Bank 2','384','A', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'4540','Belföldi Szállítók','454','L', NULL, false,string_to_array('AP', ':'));
SELECT account_save(NULL,'4541','Külföldi szállítók','454','L', NULL, false,string_to_array('AP', ':'));
SELECT account_save(NULL,'4660','Visszaigényelhetõ ÁFA 20%','466','L', NULL, false,string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4661','Visszaigényelhetõ ÁFA 12%','466','L', NULL, false,string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4662','Visszaigényelhetõ ÁFA 5%','466','L', NULL, false,string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4663','Visszaigényelhetõ ÁFA adómentes','466','L', NULL, false,string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4670','Fizetendõ ÁFA 20%','467','L', NULL, false,string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4671','Fizetendõ ÁFA 15%','467','L', NULL, false,string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4672','Fizetendõ ÁFA 5%','467','L', NULL, false,string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'4673','Fizetendõ ÁFA adómentes','467','L', NULL, false,string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_save(NULL,'5200','Bérleti díj','520','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5210','Telefon','521','E', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5990','Költségek','599','E', NULL, false,string_to_array('IC_expense', ':'));
SELECT account_save(NULL,'8140','Eladott áruk beszerzési értéke','814','E', NULL, false,string_to_array('IC_cogs', ':'));
SELECT account_save(NULL,'8700','Árfolyamveszteség','870','E', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'9110','Belföldi árbevétel','911','I', NULL, false,string_to_array('AR_amount:IC_sale:IC_income', ':'));
SELECT account_save(NULL,'9111','Külföldi árbevétel','911','I', NULL, false,string_to_array('AR_amount:IC_sale:IC_income', ':'));
SELECT account_save(NULL,'9700','Árfolyamnyereség','970','I', NULL, false,string_to_array('', ':'));
--
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4660'),'0.20','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4661'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4662'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4663'),'0','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4670'),'0.20','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4671'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4672'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM chart WHERE accno='4673'),'0','');
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', 
(SELECT id FROM chart WHERE accno = '2110'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (SELECT id FROM chart WHERE accno = '9110'));
 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM chart WHERE accno = '8140'));
 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM chart WHERE accno = '9700'));
 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM chart WHERE accno = '8700'));
 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'HUF:EUR:USD');
 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
 UPDATE defaults SET value = 'VK00000'    WHERE setting_key = 'glnumber';
 UPDATE defaults SET value = 'VSZ10000'   WHERE setting_key = 'sinumber';  
 UPDATE defaults SET value = 'SZSZ10000'  WHERE setting_key = 'vinumber';  
 UPDATE defaults SET value = 'BR10000'    WHERE setting_key = 'ponumber';  
 UPDATE defaults SET value = 'VR10000'    WHERE setting_key = 'sonumber';  
 UPDATE defaults SET value = 'AA10000'    WHERE setting_key = 'sqnumber';  
 UPDATE defaults SET value = 'AK10000'    WHERE setting_key = 'rfqnumber';  
 UPDATE defaults SET value = 'ALK0000'    WHERE setting_key = 'employeenumber';  
 UPDATE defaults SET value = 'VEVO10000'  WHERE setting_key = 'customernumber';  
 UPDATE defaults SET value = 'SZALL10000' WHERE setting_key = 'vendornumber';  
 UPDATE defaults SET value = 'PROJ10000'  WHERE setting_key = 'projectnumber';  

commit;
