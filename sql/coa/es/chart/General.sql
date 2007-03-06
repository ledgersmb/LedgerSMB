begin;
-- Chart of Accounts for Spain (Cuadro del Plan de Contabilidad español)
-- From: Federico Montesino Pouzols <fedemp@arrok.com>
-- 23 Apr 2002
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('099999999','Grupo 1: financiación básica','H','','','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('100000000','Capital','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('110000000','Reservas','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('120000000','Resultados pendientes de aplicación','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('130000000','Ingresos a distribuir en varios ejercicios','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('140000000','Provisiones para riesgos y gastos','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('150000000','Empréstitos y otras emisiones análogas','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('160000000','Deudas a largo plazo con empresas del grupo y asociadas','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('170000000','Deudas a largo plazo por prestamos recibidos y otros conceptos','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('180000000','Fianzas y depósitos recibidos a largo plazo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('190000000','Situaciones transitorias de financiación','A','','A','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('199999999','Grupo 2: inmovilizado','H','','','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('200000000','Gastos de establecimiento','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('210000000','Inmovilizaciones inmateriales','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('220000000','Inmovilizaciones materiales','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('230000000','Inmovilizaciones materiales en curso','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('240000000','Inversiones financieras en empresas del grupo y asociadas','A','', 'A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('250000000','Otras inversiones financieras permanentes','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('260000000','Fianzas y depósitos constituidos a largo plazo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('270000000','Gastos a distribuir en varios ejercicios','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('280000000','Amortización acumulada del inmovilizado','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('290000000','Provisiones de inmovilizado','A','','A','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('299999999','Grupo 3: existencias','H','','','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('300000000','Comerciales','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('310000000','Materias primas','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('320000000','Otros aprovisionamientos','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('330000000','Productos en curso','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('340000000','Productos semiterminados','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('350000000','Productos terminados','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('360000000','Subproductos, residuos y materiales recuperados','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('390000000','Provisiones por depreciación de existencias','A','','A','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('399999999','Grupo 4: acreedores y deudores por operaciones de tráfico','H','', '','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('400000000','Proveedores','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('410000000','Acreedores varios','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('430000000','Clientes','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('431000000','Clientes, efectos comerciales a cobrar','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('440000000','Deudores varios','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('460000000','Personal','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('470000000','Administraciones públicas','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('472000000','Hacienda Pública, IVA soportado','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('472000001','IVA soportado 4%','A','','P','AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('472000002','IVA soportado 7%','A','','P','AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('472000003','IVA soportado 16%','A','','P','AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('475100000','Hacienda Pública, acreedor por retenciones practicadas','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('473000000','Hacienda Pública, retenciones y pagos a cuenta','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('477000000','Hacienda Pública, IVA repercutido','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('477000001','IVA repercutido 4%','A','','P','AR_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('477000002','IVA repercutido 7%','A','','P','AR_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('477000003','IVA repercutido 16%','A','','P','AR_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('480000000','Ajustes por periodificación','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('490000000','Provisiones por operaciones de tráfico','A','','P','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('499999999','Grupo 5: cuentas financieras','H','','','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('500000000','Empréstitos y otras emisiones análogas a corto plazo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('510000000','Deudas a corto plazo con empresas del grupo y asociadas','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('520000000','Deudas a corto plazo por préstamos recibidos y otros conceptos','A','','P','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('530000000','Inversiones financieras a corto plazo en empresas del grupo y asociadas','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('540000000','Otras inversiones financieras temporales','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('550000000','Otras cuentas no bancarias','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('560000000','Fianzas y depósitos recibidos y constituidos a corto plazo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('569000000','Tesorería','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('570000000','Caja, euros','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('571000000','Caja, moneda extranjera','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('572000000','Bancos e instituciones de crédito, c/c. vista, euros','A','','A','AR_paid:AP_paid:AP_amount:AR_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('573000000','Bancos e instituciones de crédito, c/c. vista, moneda extranjera','A','','A','AR_paid:AP_paid:AP_amount:AR_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('574000000','Bancos e instituciones de crédito, cuentas de ahorro, euros','A','','A','AR_paid:AP_paid:AP_amount:AR_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('575000000','Bancos e instituciones de crédito, cuentas de ahorro, moneda extranjera','A','','A','AR_paid:AP_paid:AP_amount:AR_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('580000000','Ajustes por periodificación','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('590000000','Provisiones financieras','A','','P','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('599999999','Grupo 6: compras y gastos','H','','','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('600000000','Compras','A','','E','AP:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('608000000','Devoluciones de compras y operaciones similares','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('610000000','Variación de existencias','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('620000000','Servicios exteriores','A','','E','IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('630000000','Tributos','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('640000000','Gastos de personal','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('650000000','Otros gastos de gestión','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('660000000','Gastos financieros','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('665000000','Descuentos sobre ventas por pronto pago','A','','E','IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('668000000','Diferencias negativas de cambio','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('670000000','Pérdidas procedentes del inmovilizado y gastos excepcionales','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('680000000','Dotaciones para amortizaciones','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('690000000','Dotaciones a las provisiones','A','','E','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('699999999','Grupo 7: ventas e ingresos','H','','','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('700000000','Ventas de servicios y productos','A','','I','AR:IC_sale:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('708000000','Devoluciones de ventas y operaciones similares','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('710000000','Variación de existencias','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('730000000','Trabajos realizados para la empresa','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('740000000','Subvenciones a la explotación','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('750000000','Otros ingresos de gestión','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('760000000','Ingresos financieros','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('765000000','Descuentos sobre compras por pronto pago','A','','I','IC_sale:IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('768000000','Diferencias positivas de cambio','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('770000000','Beneficios procedentes de inmovilizados e ingresos excepcionales','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('790000000','Excesos y aplicaciones de provisiones','A','','I','');
--
-- Taxes in Spain
--
-- IVA: 4, 7 or 16%
-- IVA soportado
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000000'), 0.0);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000001'), 0.04);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000002'), 0.07);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000003'), 0.16);
-- Recargo equivalente: 0.5, 1 or 4%
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000004'), 0.005);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000005'), 0.01);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '472000006'), 0.04);
--
-- IVA repercutido
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000000'), 0.0);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000001'), 0.04);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000002'), 0.07);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000003'), 0.16);
-- Recargo equivalente: 0.5, 1 or 4%
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000004'), 0.005);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000005'), 0.01);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000006'), 0.04);
--
-- update defaults
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '300000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '700000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '600000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '768000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '668000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR');
 INSERT INTO defaults (setting_key, value) VALUES ('weightunit' , 'Kg';
--

commit;
