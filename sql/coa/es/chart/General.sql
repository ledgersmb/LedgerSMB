begin;
-- Chart of Accounts for Spain (Cuadro del Plan de Contabilidad español)
-- From: Federico Montesino Pouzols <fedemp@arrok.com>
-- 23 Apr 2002
--
SELECT account_heading_save(NULL, '099999999','Grupo 1: financiación básica',NULL);
SELECT account__save(NULL,'100000000','Capital','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'110000000','Reservas','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'120000000','Resultados pendientes de aplicación','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'130000000','Ingresos a distribuir en varios ejercicios','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'140000000','Provisiones para riesgos y gastos','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'150000000','Empréstitos y otras emisiones análogas','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'160000000','Deudas a largo plazo con empresas del grupo y asociadas','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'170000000','Deudas a largo plazo por prestamos recibidos y otros conceptos','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'180000000','Fianzas y depósitos recibidos a largo plazo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'190000000','Situaciones transitorias de financiación','A','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account_heading_save(NULL, '199999999','Grupo 2: inmovilizado', NULL);
SELECT account__save(NULL,'200000000','Gastos de establecimiento','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'210000000','Inmovilizaciones inmateriales','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'220000000','Inmovilizaciones materiales','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'230000000','Inmovilizaciones materiales en curso','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'240000000','Inversiones financieras en empresas del grupo y asociadas','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'250000000','Otras inversiones financieras permanentes','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'260000000','Fianzas y depósitos constituidos a largo plazo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'270000000','Gastos a distribuir en varios ejercicios','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'280000000','Amortización acumulada del inmovilizado','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'290000000','Provisiones de inmovilizado','A','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account_heading_save(NULL,'299999999','Grupo 3: existencias',NULL);
SELECT account__save(NULL,'300000000','Comerciales','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'310000000','Materias primas','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'320000000','Otros aprovisionamientos','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'330000000','Productos en curso','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'340000000','Productos semiterminados','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'350000000','Productos terminados','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'360000000','Subproductos, residuos y materiales recuperados','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'390000000','Provisiones por depreciación de existencias','A','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account_heading_save (NULL, '399999999','Grupo 4: acreedores y deudores por operaciones de tráfico', NULL);
SELECT account__save(NULL,'400000000','Proveedores','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'410000000','Acreedores varios','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'430000000','Clientes','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'431000000','Clientes, efectos comerciales a cobrar','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'440000000','Deudores varios','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'460000000','Personal','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'470000000','Administraciones públicas','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'472000000','Hacienda Pública, IVA soportado','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'472000001','IVA soportado 4%','P','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'472000002','IVA soportado 7%','P','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'472000003','IVA soportado 16%','P','', NULL, false, false, string_to_array('AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'475100000','Hacienda Pública, acreedor por retenciones practicadas','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'473000000','Hacienda Pública, retenciones y pagos a cuenta','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'477000000','Hacienda Pública, IVA repercutido','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'477000001','IVA repercutido 4%','P','', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'477000002','IVA repercutido 7%','P','', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'477000003','IVA repercutido 16%','P','', NULL, false, false, string_to_array('AR_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'480000000','Ajustes por periodificación','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'490000000','Provisiones por operaciones de tráfico','P','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account_heading_save(NULL, '499999999','Grupo 5: cuentas financieras', NULL);
SELECT account__save(NULL,'500000000','Empréstitos y otras emisiones análogas a corto plazo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'510000000','Deudas a corto plazo con empresas del grupo y asociadas','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'520000000','Deudas a corto plazo por préstamos recibidos y otros conceptos','P','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'530000000','Inversiones financieras a corto plazo en empresas del grupo y asociadas','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'540000000','Otras inversiones financieras temporales','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'550000000','Otras cuentas no bancarias','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'560000000','Fianzas y depósitos recibidos y constituidos a corto plazo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'569000000','Tesorería','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'570000000','Caja, euros','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'571000000','Caja, moneda extranjera','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'572000000','Bancos e instituciones de crédito, c/c. vista, euros','A','', NULL, false, false, string_to_array('AR_paid:AP_paid:AP_amount:AR_amount', ':'), false, false);
SELECT account__save(NULL,'573000000','Bancos e instituciones de crédito, c/c. vista, moneda extranjera','A','', NULL, false, false, string_to_array('AR_paid:AP_paid:AP_amount:AR_amount', ':'), false, false);
SELECT account__save(NULL,'574000000','Bancos e instituciones de crédito, cuentas de ahorro, euros','A','', NULL, false, false, string_to_array('AR_paid:AP_paid:AP_amount:AR_amount', ':'), false, false);
SELECT account__save(NULL,'575000000','Bancos e instituciones de crédito, cuentas de ahorro, moneda extranjera','A','', NULL, false, false, string_to_array('AR_paid:AP_paid:AP_amount:AR_amount', ':'), false, false);
SELECT account__save(NULL,'580000000','Ajustes por periodificación','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'590000000','Provisiones financieras','P','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account_heading_save(NULL, '599999999','Grupo 6: compras y gastos', NULL);
SELECT account__save(NULL,'600000000','Compras','E','', NULL, false, false, string_to_array('AP_expense:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'608000000','Devoluciones de compras y operaciones similares','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'610000000','Variación de existencias','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'620000000','Servicios exteriores','E','', NULL, false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL,'630000000','Tributos','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'640000000','Gastos de personal','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'650000000','Otros gastos de gestión','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'660000000','Gastos financieros','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'665000000','Descuentos sobre ventas por pronto pago','E','', NULL, false, false, string_to_array('IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'668000000','Diferencias negativas de cambio','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'670000000','Pérdidas procedentes del inmovilizado y gastos excepcionales','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'680000000','Dotaciones para amortizaciones','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'690000000','Dotaciones a las provisiones','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account_heading_save(NULL, '699999999','Grupo 7: ventas e ingresos', NULL);
SELECT account__save(NULL,'700000000','Ventas de servicios y productos','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'708000000','Devoluciones de ventas y operaciones similares','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'710000000','Variación de existencias','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'730000000','Trabajos realizados para la empresa','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'740000000','Subvenciones a la explotación','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'750000000','Otros ingresos de gestión','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'760000000','Ingresos financieros','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'765000000','Descuentos sobre compras por pronto pago','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'768000000','Diferencias positivas de cambio','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'770000000','Beneficios procedentes de inmovilizados e ingresos excepcionales','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'790000000','Excesos y aplicaciones de provisiones','I','', NULL, false, false, string_to_array('', ':'), false, false);
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
--
-- IVA repercutido
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000000'), 0.0);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000001'), 0.04);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000002'), 0.07);
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM chart WHERE accno  = '477000003'), 0.16);
-- Recargo equivalente: 0.5, 1 or 4%
--
-- update defaults
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '300000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from chart where accno = '700000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '600000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '768000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '668000000'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'EUR');
 INSERT INTO defaults (setting_key, value) VALUES ('weightunit' , 'Kg');
--

commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

