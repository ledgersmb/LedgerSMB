-- Venezuela General COA
-- modify as needed
--

-- ACTIVO
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1000','ACTIVO','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1050','Caja','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1100','Banesco APD','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1110','Provincial','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1120','Venezuela','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1130','Banesco JD','A','','A','AR_paid:AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1200','Cuentas por Cobrar','A','','A','AR');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1205','Provisión Cuentas Incobrables','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1500','INVENTARIO','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1520','Mercancía en Almacén','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1530','Mercancía en Consignación','A','','A','IC');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1800','ACTIVOS CAPITALES','H','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1820','Mobiliario y Equipo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1825','Amort. Acum. -Inv. y Equip.','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1840','Vehículo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1845','Amort. Acum. -Vehículo','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1850','Edificio','A','','A','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('1855','Amort. Acum. -Edificio','A','','A','');
-- PASIVO
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2000','PASIVO CORTO PLAZO','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2100','Cuentas por Pagar','A','','L','AP');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2600','PASIVO LARGO PLAZO','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2620','Préstamos Bancarios','A','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2680','Préstamos de Accionistas','A','','L','AP_paid');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2700','APARTADOS','H','','L','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2710','Apartados Indem. Laborales','A','','L','');
-- CAPITAL
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3300','CAPITAL ACCIONARIO','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3350','Acciones Comunes','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3400','RESERVAS','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3410','Reserva Legal','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3420','Reserva Voluntaria','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3500','UTILIDADES RETENIDAS','H','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3590','Utilidades Retenidas - años anteriores','A','','Q','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('3600','Ganancia del Ejercicio','A','','Q','');
-- INGRESO
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4000','INGRESOS PRINCIPALES','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4020','Ventas Autopartes','A','','I','AR_amount:IC_sale');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4400','OTROS INGRESOS','H','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4430','Shipping & Handling','A','','I','IC_income');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4440','Intereses','A','','I','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('4450','Ganancia en Paridad Cambiaria','A','','I','');
-- EGRESO
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5000','COSTO DE VENTA','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5010','Compras','A','','E','AP_amount:IC_cogs:IC_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5020','COSTO DE VENTA: Autopartes','A','','E','AP_amount:IC_cogs');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5100','Flete','A','','E','AP_amount:IC_expense');
-- HR
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5400','GASTO DE PERSONAL','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5405','Sueldos Directivo y Administradores','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5410','Sueldos Empleados','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5415','Comisiones Vendedores','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5420','Vacaciones','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5425','Bono Vacacional','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5430','Utilidades','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5435','Indemnizaciones','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5440','Movilizaciones y Traslados','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5445','Gastos de Representación','A','','E','HR_expense');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5450','Instrucción y Mejoramiento','A','','E','HR_expense');

insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5600','GASTOS GENERALES','H','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5610','Honorarios Profesionales','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5615','Propaganda','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5660','Gasto de Amortización','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5685','Seguros','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5690','Intereses y Gastos Bancarios','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5700','Artículos de Oficina','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5760','Alquileres','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5765','Reparación y Mantenimiento','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5780','Teléfono','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5785','Viajes y Entretenimiento','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5790','Servicios','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5795','Patentes','A','','E','AP_amount');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5810','Pérdidas Paridad Cambiaria','A','','E','');
--
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('2150','IVA','A','','L','AR_tax:AP_tax:IC_taxpart:IC_taxservice');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5510','ISRL','A','','E','');
insert into chart (accno,description,charttype,gifi_accno,category,link) values ('5530','Derecho de Frente','A','','E','');
--
insert into tax (chart_id,rate) values ((select id from chart where accno = '2150'),0.16);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from chart where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from chart where accno = '5020'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from chart where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from chart where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'VEB:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');

