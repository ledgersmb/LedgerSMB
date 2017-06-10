begin;
-- Venezuela General COA
-- modify as needed
--

-- ACTIVO
SELECT account_heading_save(NULL,'1000','ACTIVO', NULL);
SELECT account__save(NULL,'1050','Caja','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1100','Banesco APD','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1110','Provincial','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1120','Venezuela','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1130','Banesco JD','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1050', '1100', '1110', '1120', '1130');

SELECT account__save(NULL,'1200','Cuentas por Cobrar','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Provisión Cuentas Incobrables','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'1500','INVENTARIO', NULL);
SELECT account__save(NULL,'1520','Mercancía en Almacén','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Mercancía en Consignación','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL,'1800','ACTIVOS CAPITALES', NULL);
SELECT account__save(NULL,'1820','Mobiliario y Equipo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','Amort. Acum. -Inv. y Equip.','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Vehículo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','Amort. Acum. -Vehículo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1850','Edificio','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1855','Amort. Acum. -Edificio','A','', NULL, false, false, string_to_array('', ':'), false, false);
-- PASIVO
SELECT account_heading_save(NULL,'2000','PASIVO CORTO PLAZO', NULL);
SELECT account__save(NULL,'2100','Cuentas por Pagar','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account_heading_save(NULL,'2600','PASIVO LARGO PLAZO', NULL);
SELECT account__save(NULL,'2620','Préstamos Bancarios','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Préstamos de Accionistas','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL,'2700','APARTADOS', NULL);
SELECT account__save(NULL,'2710','Apartados Indem. Laborales','L','', NULL, false, false, string_to_array('', ':'), false, false);
-- CAPITAL
SELECT account_heading_save(NULL,'3300','CAPITAL ACCIONARIO', NULL);
SELECT account__save(NULL,'3350','Acciones Comunes','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3400','RESERVAS', NULL);
SELECT account__save(NULL,'3410','Reserva Legal','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3420','Reserva Voluntaria','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL,'3500','UTILIDADES RETENIDAS', NULL);
SELECT account__save(NULL,'3590','Utilidades Retenidas - años anteriores','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'3600','Ganancia del Ejercicio','Q','', NULL, false, false, string_to_array('', ':'), false, false);
-- INGRESO
SELECT account_heading_save(NULL,'4000','INGRESOS PRINCIPALES', NULL);
SELECT account__save(NULL,'4020','Ventas Autopartes','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL,'4400','OTROS INGRESOS', NULL);
SELECT account__save(NULL,'4430','Shipping & Handling','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Intereses','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Ganancia en Paridad Cambiaria','I','', NULL, false, false, string_to_array('', ':'), false, false);
-- EGRESO
SELECT account_heading_save(NULL,'5000','COSTO DE VENTA', NULL);
SELECT account__save(NULL,'5010','Compras','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5020','COSTO DE VENTA: Autopartes','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Flete','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
-- HR
SELECT account_heading_save(NULL,'5400','GASTO DE PERSONAL', NULL);
SELECT account__save(NULL,'5405','Sueldos Directivo y Administradores','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5410','Sueldos Empleados','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5415','Comisiones Vendedores','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5420','Vacaciones','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5425','Bono Vacacional','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5430','Utilidades','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5435','Indemnizaciones','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5440','Movilizaciones y Traslados','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5445','Gastos de Representación','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5450','Instrucción y Mejoramiento','E','', NULL, false, false, string_to_array('', ':'), false, false);

SELECT account_heading_save(NULL,'5600','GASTOS GENERALES', NULL);
SELECT account__save(NULL,'5610','Honorarios Profesionales','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Propaganda','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5660','Gasto de Amortización','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Seguros','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Intereses y Gastos Bancarios','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Artículos de Oficina','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Alquileres','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Reparación y Mantenimiento','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Teléfono','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Viajes y Entretenimiento','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Servicios','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5795','Patentes','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Pérdidas Paridad Cambiaria','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
SELECT account__save(NULL,'2150','IVA','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'5510','ISRL','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5530','Derecho de Frente','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2150'),0.16);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5020'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'VEB:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

