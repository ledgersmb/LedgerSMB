begin;
-- Default chart of accounts
-- sample only
SELECT account_heading_save(NULL,'1000','AKTIVA LANCAR', NULL));
SELECT account_save(NULL,'1060','Bank','A','', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'1065','Kas Kecil','A','', NULL, false,string_to_array('AR_paid:AP_paid', ':'));
SELECT account_save(NULL,'1200','Piutang','A','', NULL, false,string_to_array('AR', ':'));
SELECT account_heading_save(NULL,'1500','INVENTORY', NULL));
SELECT account_save(NULL,'1520','Inventory / Umum','A','', NULL, false,string_to_array('IC', ':'));
SELECT account_save(NULL,'1530','Inventory / Aftermarket Parts','A','', NULL, false,string_to_array('IC', ':'));
SELECT account_heading_save(NULL,'1800','AKTIVA TETAP', NULL));
SELECT account_save(NULL,'1820','Perabot Kantor & Peralatan','A','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'1825','Akumulasi Amort. Perabot & Peralatan','A','', NULL, '1',string_to_array('', ':'));
SELECT account_save(NULL,'1840','Kendaraan','A','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'1845','Akumulasi Amort. Kendaraan','A','', NULL, '1',string_to_array('', ':'));
SELECT account_heading_save(NULL,'2000','HUTANG LANCAR', NULL));
SELECT account_save(NULL,'2100','Hutang Dagang','L','', NULL, false,string_to_array('AP', ':'));
SELECT account_save(NULL,'2160','Hutang Pajak','L','', NULL, false,string_to_array('', ':'));
--SELECT account_save(NULL,'2190','Federal Income Tax Payable','L','', NULL, false,string_to_array('', ':'));
--SELECT account_save(NULL,'2210','Workers Comp Payable','L','', NULL, false,string_to_array('', ':'));
--SELECT account_save(NULL,'2220','Vacation Pay Payable','L','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2250','Hutang Rencana Pensiun','L','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2260','Hutang Asuransi Karyawan','L','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2280','Hutang Pajak Gaji','L','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2310','PPn (10%)','L','', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
--SELECT account_save(NULL,'2320','VAT (14%)','L','', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
--SELECT account_save(NULL,'2330','VAT (30%)','L','', NULL, false,string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'));
SELECT account_heading_save(NULL,'2600','HUTANG JANGKA PANJANG', NULL));
SELECT account_save(NULL,'2620','Hutang Bank','L','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'2680','Hutang ke Pemegang Saham','L','', NULL, false,string_to_array('AP_paid', ':'));
SELECT account_heading_save(NULL,'3300','MODAL', NULL));
SELECT account_save(NULL,'3350','Modal Umum','Q','', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL,'4000','PENDAPATAN PENJUALAN', NULL));
SELECT account_save(NULL,'4020','Penjualan / General','I','', NULL, false,string_to_array('AR_amount:IC_sale', ':'));
SELECT account_save(NULL,'4030','Penjualan / Aftermarket Parts','I','', NULL, false,string_to_array('AR_amount:IC_sale', ':'));
SELECT account_heading_save(NULL,'4300','PENDAPATAN KONSULTASI', NULL));
SELECT account_save(NULL,'4320','Jasa Konsultasi','I','', NULL, false,string_to_array('AR_amount:IC_income', ':'));
SELECT account_heading_save(NULL,'4400','PENDAPATAN LAIN', NULL));
SELECT account_save(NULL,'4430','Jasa Pengiriman dan Pengepakan','I','', NULL, false,string_to_array('IC_income', ':'));
SELECT account_save(NULL,'4440','Bunga','I','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'4450','Keuntungan Selisih Kurs','I','', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL,'5000','BIAYA PENJUALAN', NULL));
SELECT account_save(NULL,'5010','Pembelian','E','', NULL, false,string_to_array('AP_amount:IC_cogs:IC_expense', ':'));
SELECT account_save(NULL,'5020','COGS / General','E','', NULL, false,string_to_array('AP_amount:IC_cogs', ':'));
SELECT account_save(NULL,'5030','COGS / Aftermarket Parts','E','', NULL, false,string_to_array('AP_amount:IC_cogs', ':'));
SELECT account_save(NULL,'5100','Ongkos Kirim','E','', NULL, false,string_to_array('AP_amount:IC_expense', ':'));
SELECT account_heading_save(NULL,'5400','BIAYA GAJI', NULL));
SELECT account_save(NULL,'5410','Biaya Gaji','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5420','Biaya Asuransi Karyawan','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5430','Biaya Rencana Pensiun','E','', NULL, false,string_to_array('', ':'));
SELECT account_heading_save(NULL,'5600','BIAYA UMUM DAN ADMINISTRASI', NULL));
SELECT account_save(NULL,'5610','Akunting dan Legalitas','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5615','Iklan dan Promosi','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5650','Capital Cost Allowance Expense','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5660','Biaya Amortisasi','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5680','Biaya Pajak Pendapatan','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5685','Asuransi','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5690','Biaya Bank dan Bunga','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5700','Biaya Keperluan Kantor','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5760','Biaya Sewa','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5765','Reparasi & Maintenance','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5780','Telephone','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5785','Perjalanan dan Entertainment','E','', NULL, false,string_to_array('', ':'));
SELECT account_save(NULL,'5790','Utilitas','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5795','Registrasi','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5800','Licensi','E','', NULL, false,string_to_array('AP_amount', ':'));
SELECT account_save(NULL,'5810','Rugi Selisih Kurs','E','', NULL, false,string_to_array('', ':'));
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2310'),0.1);
--insert into tax (chart_id,rate) values ((select id from chart where accno = '2320'),0.14);
--insert into tax (chart_id,rate) values ((select id from chart where accno = '2330'),0.3);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'IDR:USD:CAD:EUR');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
