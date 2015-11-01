begin;
--Hungarian chart of accounts
-- Magyar fõkönyvi számlák, minimális, bővíthető igény szerint
--
SELECT account_heading_save(NULL, '1', 'BEFEKTETETT ESZKÖZÖK', NULL);
SELECT account__save(NULL,'1140','Irodai eszközök','A','', NULL, false, false, string_to_array('', ':'),false,false);
SELECT account__save(NULL,'1199','Irodai eszközök ÉCS','A','', NULL, false, false, string_to_array('', ':'),false,false);
SELECT account_heading_save(NULL, '2', 'KÉSZLETEK', NULL);
SELECT account__save(NULL,'2610','Áruk ','A','', NULL, false, false, string_to_array('IC', ':'),false,false);
SELECT account_heading_save(NULL, '3', 'KÖVETELÉSEK', NULL);
SELECT account__save(NULL,'3110','Vevõk','A','', NULL, false, false, string_to_array('AR', ':'),false,false);
SELECT account__save(NULL,'3111','Külföldi vevõk','A','', NULL, false, false, string_to_array('AR', ':'),false,false);
SELECT account__save(NULL,'3810','Pénztár 1','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'),false,false);
SELECT account__save(NULL,'3811','Pénztár 2','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'),false,false);
SELECT account__save(NULL,'3840','Bank 1','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'),false,false);
SELECT account__save(NULL,'3841','Bank 2','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'),false,false);
SELECT account_heading_save(NULL, '4', 'KÖTELEZETTSÉGEK', NULL);
SELECT account__save(NULL,'4540','Belföldi Szállítók','L','', NULL, false, false, string_to_array('AP', ':'),false,false);
SELECT account__save(NULL,'4541','Külföldi szállítók','L','', NULL, false, false, string_to_array('AP', ':'),false,false);
SELECT account__save(NULL,'4660','Visszaigényelhetõ ÁFA adómentes','L','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'),false,false);
SELECT account__save(NULL,'4661','Visszaigényelhetõ ÁFA 0%','L','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'),false,false);
SELECT account__save(NULL,'4662','Visszaigényelhetõ ÁFA 27%','L','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'),false,false);
SELECT account__save(NULL,'4670','Fizetendõ ÁFA adómentes','L','', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'),false,false);
SELECT account__save(NULL,'4671','Fizetendõ ÁFA 0%','L','', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'),false,false);
SELECT account__save(NULL,'4672','Fizetendõ ÁFA 27%','L','', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'),false,false);
SELECT account_heading_save(NULL, '5', 'KÖLTSÉGEK', NULL);
SELECT account__save(NULL,'5200','Bérleti díj','E','', NULL, false, false, string_to_array('AP_amount', ':'),false,false);
SELECT account__save(NULL,'5210','Telefon','E','', NULL, false, false, string_to_array('AP_amount', ':'),false,false);
SELECT account__save(NULL,'5990','Költségek','E','', NULL, false, false, string_to_array('IC_expense', ':'),false,false);
SELECT account_heading_save(NULL, '8', 'RÁFORDÍTÁSOK', NULL);
SELECT account__save(NULL,'8140','Eladott áruk beszerzési értéke','E','', NULL, false, false, string_to_array('IC_cogs', ':'),false,false);
SELECT account__save(NULL,'8700','Árfolyamveszteség','E','', NULL, false, false, string_to_array('', ':'),false,false);
SELECT account_heading_save(NULL, '9', 'BEVÉTELEK', NULL);
SELECT account__save(NULL,'9110','Belföldi árbevétel','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'),false,false);
SELECT account__save(NULL,'9111','Külföldi árbevétel','I','', NULL, false, false, string_to_array('AR_amount:IC_sale:IC_income', ':'),false,false);
SELECT account__save(NULL,'9700','Árfolyamnyereség','I','', NULL, false, false, string_to_array('', ':'),false,false);

SELECT cr_coa_to_account_save(accno, accno || '--' || description) FROM account WHERE id IN (select account_id FROM account_link  WHERE description = 'AP_paid');
--
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4660'),'0.00','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4661'),'0.00','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4662'),'0.27','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4670'),'0.00','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4671'),'0.00','');
INSERT INTO tax (chart_id,rate,taxnumber) VALUES ((SELECT id FROM account WHERE accno='4672'),'0.27','');
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (SELECT id FROM account WHERE accno = '2610'));

INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (SELECT id FROM account WHERE accno = '9110'));
INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (SELECT id FROM account WHERE accno = '8140'));
INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (SELECT id FROM account WHERE accno = '9700'));
INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (SELECT id FROM account WHERE accno = '8700'));
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'HUF:EUR:USD');
INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

UPDATE defaults SET value = 'K000000'    WHERE setting_key = 'glnumber';
UPDATE defaults SET value = 'VSZ10000'   WHERE setting_key = 'sinumber';
UPDATE defaults SET value = 'SSZ10000'   WHERE setting_key = 'vinumber';
UPDATE defaults SET value = 'SR10000'    WHERE setting_key = 'ponumber';
UPDATE defaults SET value = 'VR10000'    WHERE setting_key = 'sonumber';
UPDATE defaults SET value = 'VA10000'    WHERE setting_key = 'sqnumber';
UPDATE defaults SET value = 'SA10000'    WHERE setting_key = 'rfqnumber';
UPDATE defaults SET value = 'ALK0000'    WHERE setting_key = 'employeenumber';
UPDATE defaults SET value = 'V100000'    WHERE setting_key = 'customernumber';
UPDATE defaults SET value = 'S100000'    WHERE setting_key = 'vendornumber';
UPDATE defaults SET value = 'P100000'    WHERE setting_key = 'projectnumber';

commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

