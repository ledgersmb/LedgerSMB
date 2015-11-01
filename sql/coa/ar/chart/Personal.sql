begin;
-- Plan de Cuentas para uso personal en Argentina
-- Sumario
SELECT account_heading_save(NULL, '0.','SUMARIO',NULL);
SELECT account__save(NULL, '0.00','A Cobrar','A','', (SELECT id FROM account WHERE accno LIKE '0.'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '0.10','A Pagar','A','', (SELECT id FROM account WHERE accno LIKE '0.'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '0.20','Inventario','A','', (SELECT id FROM account WHERE accno LIKE '0.'), false, false, string_to_array('IC', ':'), false, false);
-- Activo
SELECT account_heading_save(NULL, '1.','ACTIVO',NULL);
SELECT account_heading_save(NULL, '1.1.','CORRIENTE',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account__save(NULL, '1.1.00','Efectivo','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.10','Caja Seguridad','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.20','Caja Ahorro Banco1','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.21','Caja Ahorro Banco2','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.30','TC Banco1','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.31','TC Banco2','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.40','Credito a Terceros','A','', (SELECT id FROM account WHERE accno LIKE '1.1.'), false, false, string_to_array('AR_overpayment:AR_amount', ':'), false, false);
SELECT account_heading_save(NULL, '1.2.','INVENTARIO',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account__save(NULL, '1.2.00','Articulos','A','', (SELECT id FROM account WHERE accno LIKE '1.2.'), false, false, string_to_array('IC_sale:AR_amount', ':'), false, false);
SELECT account__save(NULL, '1.2.10','Manufacturas','A','', (SELECT id FROM account WHERE accno LIKE '1.2.'), false, false, string_to_array('IC_sale:AR_amount', ':'), false, false);
SELECT account_heading_save(NULL, '1.3.','NO CORRIENTE',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account__save(NULL, '1.3.00','Propiedades','A','', (SELECT id FROM account WHERE accno LIKE '1.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.3.10','Vehiculos','A','', (SELECT id FROM account WHERE accno LIKE '1.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.3.20','Muebles','A','', (SELECT id FROM account WHERE accno LIKE '1.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.3.30','Electrodomesticos','A','', (SELECT id FROM account WHERE accno LIKE '1.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.3.40','Herramientas','A','', (SELECT id FROM account WHERE accno LIKE '1.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.3.100','(-)Depresiacion','A','', (SELECT id FROM account WHERE accno LIKE '1.3.'), false, false, string_to_array('Asset_Dep', ':'), false, false);
SELECT account_heading_save(NULL, '1.4.','OTROS',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account__save(NULL, '1.4.00','(-)Amortizacion','A','', (SELECT id FROM account WHERE accno LIKE '1.4.'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.4.10','IVA a Favor','A','', (SELECT id FROM account WHERE accno LIKE '1.4.'), false, true, string_to_array('AP_tax', ':'), false, false);
SELECT account__save(NULL, '1.4.20','Depositos de Alquiler','A','', (SELECT id FROM account WHERE accno LIKE '1.4.'), false, false, string_to_array('', ':'), false, false);
-- Pasivo
SELECT account_heading_save(NULL, '2.','PASIVO',NULL);
SELECT account_heading_save(NULL, '2.1.','CORRIENTE',(SELECT id FROM account_heading WHERE accno LIKE '2.'));
SELECT account__save(NULL, '2.1.00','Servicios','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '2.1.10','Proveedores','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '2.1.20','Ganancias (9% - 35%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.21','Jubilacion (11%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.22','Jubilacion INSSJP (3%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.23','Servicio Social (3%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.24','Bienes Personales (0,5% - 1,25%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.25','Valor Agregado (IVA 10,5% - 27%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.26','Ingresos Brutos (3%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account_heading_save(NULL, '2.2.','LARGO PLAZO',(SELECT id FROM account_heading WHERE accno LIKE '2.'));
SELECT account__save(NULL, '2.2.00','Hipotecario Banco X','L','', (SELECT id FROM account WHERE accno LIKE '2.2.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '2.3.','OTROS PASIVOS',(SELECT id FROM account_heading WHERE accno LIKE '2.'));
-- Patrimonio
SELECT account_heading_save(NULL, '3.','PATRIMONIO',NULL);
SELECT account_heading_save(NULL, '3.1.','PATRIMONIO NETO',(SELECT id FROM account_heading WHERE accno LIKE '3.'));
SELECT account__save(NULL, '3.1.00','Capital Social','Q','', (SELECT id FROM account WHERE accno LIKE '3.1.'), false, false, string_to_array('', ':'), false, false);
-- Ingresos
SELECT account_heading_save(NULL, '4.','INGRESOS',NULL);
SELECT account_heading_save(NULL, '4.1.','OPERACIONALES',(SELECT id FROM account_heading WHERE accno LIKE '4.'));
SELECT account__save(NULL, '4.1.00','Acreditacion de Haberes','I','', (SELECT id FROM account WHERE accno LIKE '4.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account__save(NULL, '4.1.10','Servicios Prestados','I','', (SELECT id FROM account WHERE accno LIKE '4.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account__save(NULL, '4.1.20','Articulos Vendidos','I','', (SELECT id FROM account WHERE accno LIKE '4.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account__save(NULL, '4.1.30','Manufacturas Vendidas','I','', (SELECT id FROM account WHERE accno LIKE '4.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account_heading_save(NULL, '4.2.','NO OPERACIONALES',(SELECT id FROM account_heading WHERE accno LIKE '4.'));
SELECT account__save(NULL, '4.2.00','Intereses Ganados','I','', (SELECT id FROM account WHERE accno LIKE '4.2.'), false, false, string_to_array('asset_gain', ':'), false, false);
SELECT account__save(NULL, '4.2.10','Venta de Activo Fijo','I','', (SELECT id FROM account WHERE accno LIKE '4.2.'), false, false, string_to_array('asset_gain', ':'), false, false);
SELECT account__save(NULL, '4.2.20','Rentas','I','', (SELECT id FROM account WHERE accno LIKE '4.2.'), false, false, string_to_array('asset_gain', ':'), false, false);
SELECT account__save(NULL, '4.2.30','Cambio de Moneda Ganado','I','', (SELECT id FROM account WHERE accno LIKE '4.2.'), false, false, string_to_array('asset_gain', ':'), false, false);
-- Gastos
SELECT account_heading_save(NULL, '5.','GASTOS	 ',NULL);
SELECT account_heading_save(NULL, '5.1.','COSTO',(SELECT id FROM account_heading WHERE accno LIKE '5.'));
SELECT account__save(NULL, '5.1.00','Servicios','E','', (SELECT id FROM account WHERE accno LIKE '5.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL, '5.1.10','Articulos','E','', (SELECT id FROM account WHERE accno LIKE '5.1.'), false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL, '5.1.20','Manufacturas','E','', (SELECT id FROM account WHERE accno LIKE '5.1.'), false, false, string_to_array('AP_amount:asset_loss', ':'), false, false);
SELECT account_heading_save(NULL, '5.2.','SERVICIOS',(SELECT id FROM account_heading WHERE accno LIKE '5.'));
SELECT account__save(NULL, '5.2.00','Alquiler inmobiliario','E','', (SELECT id FROM account WHERE accno LIKE '5.2.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.01','Electricidad','E','', (SELECT id FROM account WHERE accno LIKE '5.2.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.02','Gas','E','', (SELECT id FROM account WHERE accno LIKE '5.2.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.03','Municipal','E','', (SELECT id FROM account WHERE accno LIKE '5.2.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.04','Telefonia','E','', (SELECT id FROM account WHERE accno LIKE '5.2.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.05','Internet','E','', (SELECT id FROM account WHERE accno LIKE '5.2.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5.3.','MANTENIMIENTO',(SELECT id FROM account_heading WHERE accno LIKE '5.'));
SELECT account__save(NULL, '5.3.00','Propiedades','E','', (SELECT id FROM account WHERE accno LIKE '5.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.3.10','Vehiculos','E','', (SELECT id FROM account WHERE accno LIKE '5.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.3.20','Varios','E','', (SELECT id FROM account WHERE accno LIKE '5.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5.4.','OTROS GASTOS',(SELECT id FROM account_heading WHERE accno LIKE '5.'));
SELECT account__save(NULL, '5.4.00','Vacaciones','E','', (SELECT id FROM account WHERE accno LIKE '5.4.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '5.4.10','Cooperadora Escuela','E','', (SELECT id FROM account WHERE accno LIKE '5.4.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '5.4.20','Cambio de Moneda Perdido','E','', (SELECT id FROM account WHERE accno LIKE '5.4.'), false, false, string_to_array('AP_amount', ':'), false, false);
commit;
BEGIN;
-- Impuestos
-- Ganancias (9% - 35%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.20'), 0.09);
-- Jubilacion (11%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.21'), 0.11);
-- Jubilacion INSSJP (3%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.22'), 0.03);
-- Servicio Social (3%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.23'), 0.03);
-- Bienes Personales (0,5% - 1,25%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.24'), 0.01);
-- Valor Agregado (IVA 10,5% - 27%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.25'), 0.21);
-- Ingresos Brutos (3%)
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.26'), 0.03);
-- IVA Favor
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '1.4.10'), 0.21);

SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE id IN (select account_id FROM account_link
                           WHERE description = 'AP_paid');
-- Sistema
-- Predeterminados
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '0.20'));
INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4.1.00'));
INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5.1.00'));
INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4.2.30'));
INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5.4.20'));
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'ARS:USD:EUR');
INSERT INTO defaults (setting_key, value) VALUES ('weightunit' , 'Kg');
--

-- Hardcode
-- INSERT INTO language (code, description) VALUES ('es_AR', 'Spanish (Argentina)');

commit;
