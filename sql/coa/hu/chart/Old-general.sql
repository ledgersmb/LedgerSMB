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
SELECT account__save(NULL,'1140','Irodai eszközök','A','114', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1199','Irodai eszközök ÉCS','A','119', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2610','Áruk ','A','261', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'3110','Vevõk','A','311', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'3111','Külföldi vevõk','A','311', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'3810','Pénztár 1','A','381', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'3811','Pénztár 2','A','381', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'3840','Bank 1','A','384', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'3841','Bank 2','A','384', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'4540','Belföldi Szállítók','L','454', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'4541','Külföldi szállítók','L','454', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'4660','Visszaigényelhetõ ÁFA 25%','L','466', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4661','Visszaigényelhetõ ÁFA 12%','L','466', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4662','Visszaigényelhetõ ÁFA 5%','L','466', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4663','Visszaigényelhetõ ÁFA adómentes','L','466', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4670','Fizetendõ ÁFA 25%','L','467', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4671','Fizetendõ ÁFA 15%','L','467', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4672','Fizetendõ ÁFA 5%','L','467', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'4673','Fizetendõ ÁFA adómentes','L','467', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'5200','Bérleti díj','E','520', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5210','Telefon','E','521', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5990','Költségek','E','599', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'8140','Eladott áruk beszerzési értéke','E','814', NULL, false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL,'8700','Árfolyamveszteség','E','870', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'9110','Belföldi árbevétel','I','911', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'9111','Külföldi árbevétel','I','911', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'), false, false);
SELECT account__save(NULL,'9700','Árfolyamnyereség','I','970', NULL, false, false, string_to_array('', ':'), false, false);

SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE id IN (select account_id FROM account_link
                           WHERE description = 'AP_paid');
--
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4660'),'0.25','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4661'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4662'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4663'),'0','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4670'),'0.25','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4671'),'0.15','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4672'),'0.05','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4673'),'0','');
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id',
(SELECT id FROM account WHERE accno = '2110'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (SELECT id FROM account WHERE accno = '9110'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM account WHERE accno = '8140'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM account WHERE accno = '9700'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM account WHERE accno = '8700'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'HUF:EUR:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

