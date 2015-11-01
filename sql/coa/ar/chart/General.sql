begin;
-- Plan de Cuenta para SRL Argentina
-- Sumario
SELECT account_heading_save(NULL, '0.','SUMARIO',NULL);
SELECT account__save(NULL, '0.01','A Cobrar','A','', (SELECT id FROM account WHERE accno LIKE '0.'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '0.02','A Pagar','A','', (SELECT id FROM account WHERE accno LIKE '0.'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '0.03','Inventario','A','', (SELECT id FROM account WHERE accno LIKE '0.'), false, false, string_to_array('IC', ':'), false, false);
-- Activo
SELECT account_heading_save(NULL, '1.','ACTIVO',NULL);
SELECT account_heading_save(NULL, '1.1.','CORRIENTE',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account_heading_save(NULL, '1.1.1.','CAJAS - BANCOS',(SELECT id FROM account_heading WHERE accno LIKE '1.1.'));
SELECT account__save(NULL, '1.1.1.01','Caja Chica Suc1','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.1.02','Caja Chica Suc2','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.1.10','Tesoreria','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.1.20','Caja Ahorro Banco1','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.1.21','Caja Ahorro Banco2','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.1.30','Cuenta Corriente Banco1','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '1.1.1.31','Cuenta Corriente Banco2','A','', (SELECT id FROM account WHERE accno LIKE '1.1.1.'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '1.1.2.','CREDITO A CLIENTES',(SELECT id FROM account_heading WHERE accno LIKE '1.1.'));
SELECT account__save(NULL, '1.1.2.01','Cliente1','A','', (SELECT id FROM account WHERE accno LIKE '1.1.2.'), false, false, string_to_array('AR_overpayment:AR_amount', ':'), false, false);
SELECT account__save(NULL, '1.1.2.02','Cliente2','A','', (SELECT id FROM account WHERE accno LIKE '1.1.2.'), false, false, string_to_array('AR_overpayment:AR_amount', ':'), false, false);
SELECT account__save(NULL, '1.1.2.03','Cliente3','A','', (SELECT id FROM account WHERE accno LIKE '1.1.2.'), false, false, string_to_array('AR_overpayment:AR_amount', ':'), false, false);
SELECT account__save(NULL, '1.1.2.04','Cliente4','A','', (SELECT id FROM account WHERE accno LIKE '1.1.2.'), false, false, string_to_array('AR_overpayment:AR_amount', ':'), false, false);
SELECT account_heading_save(NULL, '1.1.3.','RIESGO DE CREDITO',(SELECT id FROM account_heading WHERE accno LIKE '1.1.'));
SELECT account__save(NULL, '1.1.3.01','Incobrables','A','', (SELECT id FROM account WHERE accno LIKE '1.1.3.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1.1.4.','OTROS A COBRAR	 ',(SELECT id FROM account_heading WHERE accno LIKE '1.1.'));
SELECT account__save(NULL, '1.1.4.01','Anticipos a empleados','A','', (SELECT id FROM account WHERE accno LIKE '1.1.4.'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.1.4.02','Anticipos a proveedores','A','', (SELECT id FROM account WHERE accno LIKE '1.1.4.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1.1.5.','IMPUESTOS A FAVOR',(SELECT id FROM account_heading WHERE accno LIKE '1.1.'));
SELECT account__save(NULL, '1.1.5.01','IVA','A','', (SELECT id FROM account WHERE accno LIKE '1.1.5.'), false, true, string_to_array('AP_tax', ':'), false, false);
SELECT account_heading_save(NULL, '1.1.6.','INVENTARIO',(SELECT id FROM account_heading WHERE accno LIKE '1.1.'));
SELECT account__save(NULL, '1.1.6.01','Articulos','A','', (SELECT id FROM account WHERE accno LIKE '1.1.6.'), false, false, string_to_array('IC_sale:AR_amount', ':'), false, false);
SELECT account__save(NULL, '1.1.6.02','Manufacturas','A','', (SELECT id FROM account WHERE accno LIKE '1.1.6.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1.2.','FIJO',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account_heading_save(NULL, '1.2.1.','PROPIEDADES INMOBILIARIAS',(SELECT id FROM account_heading WHERE accno LIKE '1.2.'));
SELECT account__save(NULL, '1.2.1.01','Oficina Comercial','A','', (SELECT id FROM account WHERE accno LIKE '1.2.1.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account_heading_save(NULL, '1.2.2.','FLOTA DE VEHICULOS',(SELECT id FROM account_heading WHERE accno LIKE '1.2.'));
SELECT account__save(NULL, '1.2.2.01','Camion','A','', (SELECT id FROM account WHERE accno LIKE '1.2.2.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.2.2.02','Camioneta','A','', (SELECT id FROM account WHERE accno LIKE '1.2.2.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.2.2.03','Auto','A','', (SELECT id FROM account WHERE accno LIKE '1.2.2.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.2.2.04','Moto','A','', (SELECT id FROM account WHERE accno LIKE '1.2.2.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account_heading_save(NULL, '1.2.3.','MAQUINARIA Y MUEBLES',(SELECT id FROM account_heading WHERE accno LIKE '1.2.'));
SELECT account__save(NULL, '1.2.3.01','Herramientas','A','', (SELECT id FROM account WHERE accno LIKE '1.2.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '1.2.3.02','Muebles Oficina','A','', (SELECT id FROM account WHERE accno LIKE '1.2.3.'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account_heading_save(NULL, '1.2.4.','DEPRECIACION ACUMULADA',(SELECT id FROM account_heading WHERE accno LIKE '1.2.'));
SELECT account__save(NULL, '1.2.4.01','(-)Vehiculos','A','', (SELECT id FROM account WHERE accno LIKE '1.2.4.'), false, false, string_to_array('Asset_Dep', ':'), false, false);
SELECT account__save(NULL, '1.2.4.02','(-)Herramientas','A','', (SELECT id FROM account WHERE accno LIKE '1.2.4.'), false, false, string_to_array('Asset_Dep', ':'), false, false);
SELECT account__save(NULL, '1.2.4.03','(-)Muebles Oficina','A','', (SELECT id FROM account WHERE accno LIKE '1.2.4.'), false, false, string_to_array('Asset_Dep', ':'), false, false);
SELECT account_heading_save(NULL, '1.3.','OTROS ACTIVOS',(SELECT id FROM account_heading WHERE accno LIKE '1.'));
SELECT account_heading_save(NULL, '1.3.1.','PROMOCION',(SELECT id FROM account_heading WHERE accno LIKE '1.3.'));
SELECT account__save(NULL, '1.3.1.01','Folleteria','A','', (SELECT id FROM account WHERE accno LIKE '1.3.1.'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.3.1.02','Anuncios','A','', (SELECT id FROM account WHERE accno LIKE '1.3.1.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1.3.2.','INVESTIGACION',(SELECT id FROM account_heading WHERE accno LIKE '1.3.'));
SELECT account__save(NULL, '1.3.2.01','Mercadeo','A','', (SELECT id FROM account WHERE accno LIKE '1.3.2.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1.3.3.','DEPOSITOS EN GARANTIA',(SELECT id FROM account_heading WHERE accno LIKE '1.3.'));
SELECT account__save(NULL, '1.3.3.01','Alquiler de propiedades','A','', (SELECT id FROM account WHERE accno LIKE '1.3.3.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1.3.4.','AMORTIZACION ACUMULADA',(SELECT id FROM account_heading WHERE accno LIKE '1.3.'));
SELECT account__save(NULL, '1.3.4.01','(-)Amortizacion','A','', (SELECT id FROM account WHERE accno LIKE '1.3.4.'), false, false, string_to_array('', ':'), false, false);
-- Pasivo
SELECT account_heading_save(NULL, '2.','PASIVO',NULL);
SELECT account_heading_save(NULL, '2.1.','CORRIENTE',(SELECT id FROM account_heading WHERE accno LIKE '2.'));
SELECT account_heading_save(NULL, '2.1.1.','CUENTAS POR PAGAR',(SELECT id FROM account_heading WHERE accno LIKE '2.1.'));
SELECT account__save(NULL, '2.1.1.01','Proveedores','L','', (SELECT id FROM account WHERE accno LIKE '2.1.1.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '2.1.1.02','Sueldos','L','', (SELECT id FROM account WHERE accno LIKE '2.1.1.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '2.1.1.03','Servicios','L','', (SELECT id FROM account WHERE accno LIKE '2.1.1.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '2.1.2.','IMPUESTOS',(SELECT id FROM account_heading WHERE accno LIKE '2.1.'));
SELECT account__save(NULL, '2.1.2.01','Ganancias (9% - 35%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.2.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.2.02','Bienes Personales (0,5% - 1,25%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.2.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.2.03','Ganancia Mi­nima Presunta (1%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.2.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.1.2.04','Valor Agregado (IVA 10,5% - 27%)','L','', (SELECT id FROM account WHERE accno LIKE '2.1.2.'), false, true, string_to_array('IC_taxservice:IC_taxpart:AR_tax', ':'), false, false);
SELECT account_heading_save(NULL, '2.2.','LARGO PLAZO',(SELECT id FROM account_heading WHERE accno LIKE '2.'));
SELECT account_heading_save(NULL, '2.2.1.','CREDITOS',(SELECT id FROM account_heading WHERE accno LIKE '2.2.'));
SELECT account__save(NULL, '2.2.1.01','Hipotecario Banco Nacion','L','', (SELECT id FROM account WHERE accno LIKE '2.2.1.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '2.2.2.','OTROS PASIVOS',(SELECT id FROM account_heading WHERE accno LIKE '2.2.'));
-- Patrimonio
SELECT account_heading_save(NULL, '3.','PATRIMONIO',NULL);
SELECT account_heading_save(NULL, '3.1.','PATRIMONIO NETO',(SELECT id FROM account_heading WHERE accno LIKE '3.'));
SELECT account_heading_save(NULL, '3.1.1.','CAPITAL SUSCRITO',(SELECT id FROM account_heading WHERE accno LIKE '3.1.'));
SELECT account__save(NULL, '3.1.1.01','Capital Social','Q','', (SELECT id FROM account WHERE accno LIKE '3.1.1.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '3.1.2.','RESERVAS',(SELECT id FROM account_heading WHERE accno LIKE '3.1.'));
SELECT account__save(NULL, '3.1.2.01','Reserva Legal','Q','', (SELECT id FROM account WHERE accno LIKE '3.1.2.'), false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '3.1.3.','UTILIDADES',(SELECT id FROM account_heading WHERE accno LIKE '3.1.'));
-- Ingresos
SELECT account_heading_save(NULL, '4.','INGRESOS',NULL);
SELECT account_heading_save(NULL, '4.1.','OPERACIONALES',(SELECT id FROM account_heading WHERE accno LIKE '4.'));
SELECT account_heading_save(NULL, '4.1.1.','VENTAS',(SELECT id FROM account_heading WHERE accno LIKE '4.1.'));
SELECT account__save(NULL, '4.1.1.01','Servicio','I','', (SELECT id FROM account WHERE accno LIKE '4.1.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account__save(NULL, '4.1.1.02','Articulo','I','', (SELECT id FROM account WHERE accno LIKE '4.1.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account__save(NULL, '4.1.1.03','Manufactura','I','', (SELECT id FROM account WHERE accno LIKE '4.1.1.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account_heading_save(NULL, '4.1.2.','VENTAS EXCENTAS',(SELECT id FROM account_heading WHERE accno LIKE '4.1.'));
SELECT account__save(NULL, '4.1.2.01','Exportaciones','I','', (SELECT id FROM account WHERE accno LIKE '4.1.2.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account__save(NULL, '4.1.2.02','Sin IVA','I','', (SELECT id FROM account WHERE accno LIKE '4.1.2.'), false, false, string_to_array('IC_income:AR_amount', ':'), false, false);
SELECT account_heading_save(NULL, '4.1.3.','DEVOLUCIONES',(SELECT id FROM account_heading WHERE accno LIKE '4.1.'));
SELECT account_heading_save(NULL, '4.2.','NO OPERACIONALES',(SELECT id FROM account_heading WHERE accno LIKE '4.'));
SELECT account_heading_save(NULL, '4.2.1.','OTROS INGRESOS	 ',(SELECT id FROM account_heading WHERE accno LIKE '4.2.'));
SELECT account__save(NULL, '4.2.1.01','Intereses ganados','I','', (SELECT id FROM account WHERE accno LIKE '4.2.1.'), false, false, string_to_array('asset_gain', ':'), false, false);
SELECT account__save(NULL, '4.2.1.02','Venta de activo fijo','I','', (SELECT id FROM account WHERE accno LIKE '4.2.1.'), false, false, string_to_array('asset_gain', ':'), false, false);
SELECT account__save(NULL, '4.2.1.03','Rentas','I','', (SELECT id FROM account WHERE accno LIKE '4.2.1.'), false, false, string_to_array('asset_gain', ':'), false, false);
SELECT account__save(NULL, '4.2.1.04','Cambio de moneda ganado','I','', (SELECT id FROM account WHERE accno LIKE '4.2.1.'), false, false, string_to_array('', ':'), false, false);
-- Gastos
SELECT account_heading_save(NULL, '5.','GASTOS	 ',NULL);
SELECT account_heading_save(NULL, '5.1.','COSTO',(SELECT id FROM account_heading WHERE accno LIKE '5.'));
SELECT account_heading_save(NULL, '5.1.1.','VENTAS',(SELECT id FROM account_heading WHERE accno LIKE '5.1.'));
SELECT account__save(NULL, '5.1.1.01','Servicio','E','', (SELECT id FROM account WHERE accno LIKE '5.1.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL, '5.1.1.02','Articulo','E','', (SELECT id FROM account WHERE accno LIKE '5.1.1.'), false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL, '5.1.1.03','Manufactura','E','', (SELECT id FROM account WHERE accno LIKE '5.1.1.'), false, false, string_to_array('AP_amount:asset_loss', ':'), false, false);
SELECT account_heading_save(NULL, '5.2.','ADMINISTRACION',(SELECT id FROM account_heading WHERE accno LIKE '5.'));
SELECT account_heading_save(NULL, '5.2.1.','RECURSOS HUMANOS',(SELECT id FROM account_heading WHERE accno LIKE '5.2.'));
SELECT account__save(NULL, '5.2.1.01','Sueldos','E','', (SELECT id FROM account WHERE accno LIKE '5.2.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.1.02','Salarios','E','', (SELECT id FROM account WHERE accno LIKE '5.2.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.1.03','Vacaciones','E','', (SELECT id FROM account WHERE accno LIKE '5.2.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.1.04','Aportes','E','', (SELECT id FROM account WHERE accno LIKE '5.2.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.1.05','Adelantos','E','', (SELECT id FROM account WHERE accno LIKE '5.2.1.'), false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5.2.2.','COMISIONES',(SELECT id FROM account_heading WHERE accno LIKE '5.2.'));
SELECT account__save(NULL, '5.2.2.01','Ventas','E','', (SELECT id FROM account WHERE accno LIKE '5.2.2.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '5.2.2.02','Publicidad','E','', (SELECT id FROM account WHERE accno LIKE '5.2.2.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account_heading_save(NULL, '5.2.3.','SERVICIOS',(SELECT id FROM account_heading WHERE accno LIKE '5.2.'));
SELECT account__save(NULL, '5.2.3.01','Alquiler inmobiliario','E','', (SELECT id FROM account WHERE accno LIKE '5.2.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.3.02','Electricidad','E','', (SELECT id FROM account WHERE accno LIKE '5.2.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.3.03','Gas','E','', (SELECT id FROM account WHERE accno LIKE '5.2.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.3.04','Municipal','E','', (SELECT id FROM account WHERE accno LIKE '5.2.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.3.05','Telefonia','E','', (SELECT id FROM account WHERE accno LIKE '5.2.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.3.06','Internet','E','', (SELECT id FROM account WHERE accno LIKE '5.2.3.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5.2.4.','MANTENIMIENTO',(SELECT id FROM account_heading WHERE accno LIKE '5.2.'));
SELECT account__save(NULL, '5.2.4.01','Inmobiliario','E','', (SELECT id FROM account WHERE accno LIKE '5.2.4.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.4.02','Flota de vehiculos','E','', (SELECT id FROM account WHERE accno LIKE '5.2.4.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.4.03','Combustible vehiculos','E','', (SELECT id FROM account WHERE accno LIKE '5.2.4.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account__save(NULL, '5.2.4.04','Varios','E','', (SELECT id FROM account WHERE accno LIKE '5.2.4.'), false, false, string_to_array('AP_amount:asset_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5.2.5.','OTROS GASTOS',(SELECT id FROM account_heading WHERE accno LIKE '5.2.'));
SELECT account__save(NULL, '5.2.5.01','Contribucion Escuela regional','E','', (SELECT id FROM account WHERE accno LIKE '5.2.5.'), false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL, '5.2.5.02','Cambio de moneda perdido','E','', (SELECT id FROM account WHERE accno LIKE '5.2.5.'), false, false, string_to_array('', ':'), false, false);
commit;
BEGIN;
-- Impuestos
-- Ganancias
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.2.01'), 0.09);
-- Bienes Personales
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.2.02'), 0.05);
-- Ganancia Minima Presunta
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.2.03'), 0.01);
-- IVA
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '2.1.2.04'), 0.21);
-- IVA Favor
INSERT INTO "tax" ("chart_id", "rate") VALUES ((SELECT id FROM account WHERE accno  = '1.1.5.01'), 0.21);

SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE id IN (select account_id FROM account_link
                           WHERE description = 'AP_paid');
-- Sistema
-- Predeterminados
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '0.03'));
INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4.1.1.03'));
INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5.1.1.03'));
INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4.2.1.04'));
INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5.2.5.02'));
INSERT INTO defaults (setting_key, value) VALUES ('default_country', '12');
INSERT INTO defaults (setting_key, value) VALUES ('default_language', 'es_AR');
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'ARS:USD:EUR');
INSERT INTO defaults (setting_key, value) VALUES ('weightunit' , 'Kg');
--

-- Hardcode
-- INSERT INTO language (code, description) VALUES ('es_AR', 'Spanish (Argentina)');

commit;

