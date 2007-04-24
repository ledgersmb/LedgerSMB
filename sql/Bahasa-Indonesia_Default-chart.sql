begin;
-- Default chart of accounts
-- sample only
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','AKTIVA LANCAR','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1060','Bank','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1065','Kas Kecil','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Piutang','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTORY','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','Inventory / Umum','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','Inventory / Aftermarket Parts','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','AKTIVA TETAP','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Perabot Kantor & Peralatan','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1825','Akumulasi Amort. Perabot & Peralatan','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Kendaraan','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link,contra) values ('1845','Akumulasi Amort. Kendaraan','A','','A','','1');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','HUTANG LANCAR','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Hutang Dagang','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2160','Hutang Pajak','A','','L','');
--insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2190','Federal Income Tax Payable','A','','L','');
--insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2210','Workers Comp Payable','A','','L','');
--insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2220','Vacation Pay Payable','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2250','Hutang Rencana Pensiun','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2260','Hutang Asuransi Karyawan','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2280','Hutang Pajak Gaji','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2310','PPn (10%)','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
--insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2320','VAT (14%)','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
--insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2330','VAT (30%)','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','HUTANG JANGKA PANJANG','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Hutang Bank','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Hutang ke Pemegang Saham','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','MODAL','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Modal Umum','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','PENDAPATAN PENJUALAN','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','Penjualan / General','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4030','Penjualan / Aftermarket Parts','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4300','PENDAPATAN KONSULTASI','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4320','Jasa Konsultasi','A','','I','AR_amount:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','PENDAPATAN LAIN','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','Jasa Pengiriman dan Pengepakan','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Bunga','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Keuntungan Selisih Kurs','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','BIAYA PENJUALAN','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','Pembelian','A','','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','COGS / General','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5030','COGS / Aftermarket Parts','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','Ongkos Kirim','A','','E','AP_amount:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','BIAYA GAJI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Biaya Gaji','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','Biaya Asuransi Karyawan','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','Biaya Rencana Pensiun','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','BIAYA UMUM DAN ADMINISTRASI','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Akunting dan Legalitas','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Iklan dan Promosi','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5650','Capital Cost Allowance Expense','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Biaya Amortisasi','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5680','Biaya Pajak Pendapatan','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','Asuransi','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','Biaya Bank dan Bunga','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','Biaya Keperluan Kantor','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','Biaya Sewa','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','Reparasi & Maintenance','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','Telephone','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','Perjalanan dan Entertainment','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','Utilitas','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','Registrasi','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5800','Licensi','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5810','Rugi Selisih Kurs','A','','E','');
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
