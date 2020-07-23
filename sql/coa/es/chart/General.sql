
-- Create the entire COA in 1 transaction

BEGIN;

-- HEADINGS DEFINITION
SELECT account_heading_save(NULL, '099999999', 'Grupo 1: financiación básica', NULL);
SELECT account_heading_save(NULL, '199999999', 'Grupo 2: inmovilizado', NULL);
SELECT account_heading_save(NULL, '299999999', 'Grupo 3: existencias', NULL);
SELECT account_heading_save(NULL, '399999999', 'Grupo 4: acreedores y deudores por operaciones de tráfico', NULL);
SELECT account_heading_save(NULL, '499999999', 'Grupo 5: cuentas financieras', NULL);
SELECT account_heading_save(NULL, '599999999', 'Grupo 6: compras y gastos', NULL);
SELECT account_heading_save(NULL, '699999999', 'Grupo 7: ventas e ingresos', NULL);



-- GIFI DEFINITION (need gifi before account creation)
INSERT INTO gifi (accno, description) VALUES ('110', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('111', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('115', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('119', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('127', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('133', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('138', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('152', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('159', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('161', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('168', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('175', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('176', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('177', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('188', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('190', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('191', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('195', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('198', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('199', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('200', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('208', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('209', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('211', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('218', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('219', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('222', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('223', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('225', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('227', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('233', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('237', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('238', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('242', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('249', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('250', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('255', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('258', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('260', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('267', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('268', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('269', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('271', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('273', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('274', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('277', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('279', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('284', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('289', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('290', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('292', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('295', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('300', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('305', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('307', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('312', 'missing; generated');
INSERT INTO gifi (accno, description) VALUES ('326', 'missing; generated');



-- ACCOUNTS DEFINITION
SELECT account__save(NULL, '100000000', 'Capital Social', 'Q', '188', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '101000000', 'Fondo Social', 'Q', '188', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '102000000', 'Capital', 'Q', '188', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '110000000', 'Prima de emisión o asunción', 'Q', '190', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '112000000', 'Reserva legal', 'Q', '191', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '113000000', 'Reservas voluntarias', 'Q', '191', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '114500000', 'Reservas especiales', 'Q', '191', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '118000000', 'Aportaciones de socios o propietarios', 'Q', '198', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '120000000', 'Remanente', 'Q', '195', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '121000000', 'Resultados negativos de ejercios anterios', 'Q', '195', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '129000000', 'Resultados del ejercicio', 'Q', '199', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '130000000', 'Subvenciones oficiales de capital', 'Q', '209', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '131000000', 'Donaciones y legados de capital', 'Q', '209', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '132000000', 'Oros subvenciones, donaciones y legados', 'Q', '209', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '137000000', 'Ingresos fiscales a distribuir en varios ejercicios', 'Q', '208', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '141000000', 'Provisión para impuestos', 'L', '211', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '142000000', 'Provisión para otros responsibilidades', 'L', '211', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '145000000', 'Provisión para actuaciones medioambientes', 'L', '211', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '149000000', 'Provisión para reestructuraciones', 'L', '211', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '150000000', 'Acciones o participaciones a largo plaza contabilizados como pasivo', 'L', '227', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '160300000', 'Deudas a largo plazo con empresas del grupo', 'L', '223', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '160400000', 'Deudas a largo plaza empresas asociadas', 'L', '223', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '170000000', 'Deudas a largo plazo con entidades de crédito', 'L', '218', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '171000000', 'Deudas a largo plaza', 'L', '222', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '174000000', 'Acreedores de arrendamiento financiero a largo plaza', 'L', '219', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '180000000', 'Fianzas y depósitos recibidos a largo plazo', 'L', '222', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '181000000', 'Anticipos recibidos per ventas o prestaciones de servicios', 'L', '225', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '185000000', 'Depósitos recibidos a largo plazo', 'L', '222', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '190000000', 'Acciones o participaciones emitidas', 'Q', '237', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '192000000', 'Suscriptores de acciones', 'Q', '237', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '194000000', 'Capital emitido pendiente de inscripción', 'Q', '237', (select id from account_heading where accno = '099999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '200000000', 'Inmovilizaciones intangibles', 'A', '110', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '210000000', 'Terrenos y bienes naturales', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '211000000', 'Construcciones', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '212000000', 'Instalaciones técnicas', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '213000000', 'Maquinaria', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '214000000', 'Utilaje', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '215000000', 'Otras instalaciones', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '216000000', 'Mobiliario', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '217000000', 'IT equipos para procecos de información', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '218000000', 'Elementos de transporte', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '219000000', 'Otro inmovilizado material', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '221000000', 'Inversiones en construcciones inmobiliarias', 'A', '115', (select id from account_heading where accno = '199999999'), false, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '230000000', 'Inmovilizaciones materiales en curso', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '239000000', 'Anticipos para Inmovilizaciones materiales', 'A', '111', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '240300000', 'Participaciones a largo plazo en empresas del grupo', 'A', '119', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '240400000', 'Participaciones a largo plazo en empresas asociadas', 'A', '119', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '240500000', 'Participaciones a largo plazo en partes vinculades', 'A', '119', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '242500000', 'Créditos a largo plazo a partes vinculades', 'A', '133', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '249300000', 'Desembolsos pendientes sobre participaciones a largo plazo', 'A', '119', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '250000000', 'Inversiones financieras a largo plazo en instrumentos de patrimonio', 'A', '127', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '252000000', 'Créditos a largo plazo', 'A', '133', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '253000000', 'Créditos a largo plazo por enajenación de inmovilizado', 'A', '133', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '258000000', 'Imposiciones a largo plazo', 'A', '133', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '259000000', 'Desembolsos pendientes sobre participaciones en el patrimonio neto a largo plazo', 'A', '127', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '260000000', 'Fianzas y depósitos constituidos a largo plazo', 'A', '133', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '280000000', 'Amortización acumulada del inmovilizado intangible', 'A', '110', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281100000', 'Amortización acumulada construcciones', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281200000', 'Amortización acumulada instalaciones tecnicas', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281300000', 'Amortización acumulada maquinaria', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281400000', 'Amortización acumulada utilaje', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281500000', 'Amortización acumulada otras instalaciones', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281600000', 'Amortización acumulada mobiliario', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281700000', 'Amortización acumulada IT procesos informatica', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281800000', 'Amortización acumulada elementos de transporte', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '281900000', 'Amortización acumulada otro inmovilizado material', 'A', '111', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '282000000', 'Amortización acumulada inversiones inmobiliario', 'A', '115', (select id from account_heading where accno = '199999999'), true, false, string_to_array('Asset_Dep:Fixed_Asset', ':'), false, false);
SELECT account__save(NULL, '290000000', 'Deterioro y proviciones inmobilizado intangible', 'A', '110', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '292000000', 'Deterioro y proviciones inversiones inmobiliarias', 'A', '115', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '293300000', 'Deterioro y proviciones valor participaciones largo plaza', 'A', '119', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '298000000', 'Deterioro y proviciones valor créditos a largo plazo', 'A', '133', (select id from account_heading where accno = '199999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '300000000', 'Mercaderias', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '310000000', 'Materias primas', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '320000000', 'Otros aprovisionamientos', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '330000000', 'Productos en curso', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '340000000', 'Productos semiterminados', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '350000000', 'Productos terminados', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '360000000', 'Subproductos, residuos y materiales recuperados', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL, '390000000', 'Deterioro del valor de las existencias', 'A', '138', (select id from account_heading where accno = '299999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '400000000', 'Proveedores', 'L', '242', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '403000000', 'Proveedores empresas del grupo', 'L', '242', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '404000000', 'Proveedores empresas asociadas', 'L', '242', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '406000000', 'Envases y embalajes a devolver a proveedores', 'L', '242', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '407000000', 'Anticipos a proveedores', 'L', '138', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '410000000', 'Acreedores por prestaciones de servicios', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL, '430000000', 'Clientes', 'A', '152', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '431000000', 'Clientes, efectos comerciales a cobrar', 'A', '152', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '433000000', 'Clientes empresa del grupo', 'A', '152', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '434000000', 'Clientes empresas asociadas', 'A', '152', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '436000000', 'Clientes de dudoso cobro', 'A', '152', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '438000000', 'Anticipios de clientes', 'A', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '440000000', 'Deudores varios', 'L', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '446000000', 'Deudores varios de dudoso cobros', 'L', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL, '460000000', 'Personal anticipos de renumeraciones', 'A', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '465000000', 'Personal remuneraciones pendientes de pago', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '470000000', 'Hacienda Pública, deudora por IVA a compensar', 'A', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '470100000', 'Hacienda Pública, deudora por IVA LP', 'A', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '471000000', 'Organismos de la Seguridad Social deudores', 'A', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '472000001', 'IVA soportado bajo', 'L', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000002', 'IVA soportado medio', 'L', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000003', 'IVA soportado alta', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000891', 'IVA soportado baja intracomm +', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000892', 'IVA soportado medio intracomm +', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000893', 'IVA soportado alta intracomm  +', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000991', 'IVA soportado baja intracomm -', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000992', 'IVA soportado medio intracomm -', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '472000993', 'IVA soportado alta intracomm  -', 'A', '159', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '473000000', 'Hacienda Pública, retenciones y pagos a cuenta', 'A', '159', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '475000000', 'Hacienda Pública, acreedor por IVA', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '475100000', 'Hacienda Pública, acreedor por retenciones practicadas', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '475200000', 'Hacienda Pública, acreedor por impuestos sobre sociedades', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '475400000', 'Hacienda Pública, acreedor por retenciones alquiler', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '475800000', 'Hacienda Pública, acreedor por subvenciones a reintegrar', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '476000000', 'Organismos de la Seguridad Social acreedores', 'L', '249', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '477000001', 'IVA repercutido bajo', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000002', 'IVA repercutido medio', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000003', 'IVA repercutido alto', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000891', 'IVA repercutido baja intracomm +', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000892', 'IVA repercutido medio intracomm +', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000893', 'IVA repercutido alta intracomm +', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000991', 'IVA repercutido baja intracomm -', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000992', 'IVA repercutido medio intracomm -', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '477000993', 'IVA repercutido alta intracomm -', 'L', '249', (select id from account_heading where accno = '399999999'), false, true, string_to_array('IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL, '480000000', 'Gastos anticipados', 'L', '176', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '485000000', 'Ingresos anticipados', 'L', '250', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '490000000', 'Provisiones por operaciones comerciales', 'L', '152', (select id from account_heading where accno = '399999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '500000000', 'Obligaciones y bonos a corto plazo', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '510300000', 'Deudas a corto plazo con empresas del grupo y asociadas', 'L', '238', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '520000000', 'Prestamos a corto plazo de entidades de crédito', 'L', '233', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '521000000', 'Deudas a corto plazo', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '526000000', 'Dividendos activo a pagar', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '527000000', 'Intereses a corto plaza de deudas con entidades de crédito', 'L', '233', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '530000000', 'Participaciones a corto plazo en empresas del grupo y asociadas', 'A', '161', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '542000000', 'Créditos a corto plazo', 'A', '175', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '551000000', 'Cuentas corriente con socios administradores', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '552300000', 'Cuentas corriente con empresas del grupo', 'L', '238', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '552400000', 'Cuentas corriente con empresas asociadas', 'L', '238', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '555000000', 'Partidas pendientes de aplicación', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '555500000', 'Facturas pagadas con visa', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '557000000', 'Dividende activo a cuenta', 'L', '200', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '560000000', 'Fianzas y depósitos recibidos y constituidos a corto plazo', 'L', '237', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '570000000', 'Caja, euros', 'A', '177', (select id from account_heading where accno = '499999999'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '571000000', 'Caja, moneda extranjera', 'A', '177', (select id from account_heading where accno = '499999999'), false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL, '572000000', 'Bancos e instituciones de crédito, c/c. vista, euros', 'A', '177', (select id from account_heading where accno = '499999999'), false, false, string_to_array('AR_amount:AR_paid:AP_amount:AP_paid', ':'), false, false);
SELECT account__save(NULL, '573000000', 'Bancos e instituciones de crédito, c/c. vista, moneda extranjera', 'A', '177', (select id from account_heading where accno = '499999999'), false, false, string_to_array('AR_amount:AR_paid:AP_amount:AP_paid', ':'), false, false);
SELECT account__save(NULL, '574000000', 'Bancos e instituciones de crédito, cuentas de ahorro, euros', 'A', '177', (select id from account_heading where accno = '499999999'), false, false, string_to_array('AR_amount:AR_paid:AP_amount:AP_paid', ':'), false, false);
SELECT account__save(NULL, '575000000', 'Bancos e instituciones de crédito, cuentas de ahorro, moneda extranjera', 'A', '177', (select id from account_heading where accno = '499999999'), false, false, string_to_array('AR_amount:AR_paid:AP_amount:AP_paid', ':'), false, false);
SELECT account__save(NULL, '598000000', 'Provisiones financieras', 'L', '168', (select id from account_heading where accno = '499999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '600000000', 'Compras de mercaderías', 'E', '260', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL, '606000000', 'Descuentos sobre compras por pronto pago', 'E', '260', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL, '607000000', 'Trabajos realizados por otra empresas', 'E', '260', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_cogs', ':'), false, false);
SELECT account__save(NULL, '608000000', 'Devoluciones de compras y operaciones similares', 'E', '260', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '610000000', 'Variación de existencias mercaderias', 'E', '260', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '621000000', 'Arrendamientos y cánones', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '622000000', 'Reparaciones y conservación', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '623000000', 'Servicios profesionales de contabilidat o accountant o auditor', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '623100000', 'Servicios profesionales de notaria o abogado', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '623200000', 'Servicios profesionales de asesor fiscal o empresarial', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '623500000', 'Gastos de gestión', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '623600000', 'Servicios profesionales deregistro mercantil o propiedad', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '624000000', 'Gastos de coches', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '624400000', 'Gastos de viaje y estancia', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '624700000', 'Gastos de transportes', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '625000000', 'Primas de seguros', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '626000000', 'Servicios bancarios y similares', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '627000000', 'Publicidad, propaganda, y relaciones públicas', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '628000000', 'Gastos de gas', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '628100000', 'Gastos de teléfono fija', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '628200000', 'Gastos de teléfono movil', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '628300000', 'Gastos internet', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '628400000', 'Gastos luz', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '628500000', 'Gastos aqua', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629000000', 'Otros servicios', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629100000', 'Consumo de material de oficina', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629200000', 'Calidad de miembro', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629500000', 'Correos', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629600000', 'Gastos de limopieza', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629700000', 'Gastos de representación', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629800000', 'Gastos de IT y informática', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '629900000', 'Sanciones Tributarios', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('IC_expense', ':'), false, false);
SELECT account__save(NULL, '630000000', 'Impuesto sobre beneficios', 'E', '326', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '631000000', 'Otros tributos', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '640000000', 'Sueldos y salarios', 'E', '271', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '641000000', 'Indemnizaciones', 'E', '273', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '642000000', 'Seguridad Social a cargo de la empresa', 'E', '274', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '642100000', 'Seguridad Social Autonomo pago de la empresa en nombre', 'E', '274', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '644200000', 'Otros costes de personal', 'E', '271', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '649000000', 'Otros gastos sociales', 'E', '277', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '650000000', 'Otros gastos variables', 'E', '279', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '660000000', 'Gastos financieros intereses y provisiones', 'E', '305', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '668000000', 'Diferencias negativas de cambio', 'E', '305', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '669000000', 'Otros gastos financieros', 'E', '307', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '678000000', 'Gastos excepcionales', 'E', '295', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '679000000', 'Gastos y perdidas de ejercicios anteriores', 'E', '295', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '681000000', 'Dotaciones para amortizaciones', 'E', '284', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '690000000', 'Dotaciones a las provisiones', 'E', '289', (select id from account_heading where accno = '599999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '700000000', 'Ventas de mercaderias', 'I', '255', (select id from account_heading where accno = '699999999'), false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL, '701000000', 'Ventas de productos terminados', 'I', '255', (select id from account_heading where accno = '699999999'), false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL, '704000000', 'Ventas de envases y embalajes', 'I', '255', (select id from account_heading where accno = '699999999'), false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL, '705000000', 'Prestaciones de servicios', 'I', '255', (select id from account_heading where accno = '699999999'), false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL, '706000000', 'Descuentos sobre ventas por pronto pago', 'I', '255', (select id from account_heading where accno = '699999999'), false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL, '708000000', 'Devoluciones de ventas y operaciones similares', 'I', '255', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '710000000', 'Variación de existencias', 'I', '258', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '730000000', 'Trabajos realizados para la empresa', 'I', '258', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '740000000', 'Subvenciones a la explotación', 'I', '269', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '751000000', 'Otros ingresos de gestión', 'I', '268', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '752000000', 'Ingresos por arrendamientos', 'I', '267', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '754000000', 'Ingresos por comisiones', 'I', '268', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '755000000', 'Ingresos por servicios al personal', 'I', '268', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '759000000', 'Ingresos por servicios diversos', 'I', '268', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '760300000', 'Ingresos financieros', 'I', '300', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '768000000', 'Diferencias positivas de cambio', 'I', '312', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '769000000', 'Otros ingresos financieros', 'I', '300', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '770000000', 'Beneficios procedentes de inmovilizados e ingresos excepcionales', 'I', '292', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '778000000', 'Ingresos excepcionales', 'I', '295', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '778010000', 'Ingresos y ganancias de ejercicias anteriores', 'I', '295', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '791000000', 'Reversion det. invers. material', 'I', '290', (select id from account_heading where accno = '699999999'), false, false, string_to_array('', ':'), false, false);



-- CUSTOM ACCOUNT LINK DEFINITION



-- TAX DEFINITION
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000993'), '0.21');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000893'), '0.21');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000003'), '0.21');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000991'), '0.04');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000891'), '0.04');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000001'), '0.04');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000002'), '0.1');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000992'), '0.1');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '477000892'), '0.1');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000003'), '0.21');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000993'), '0.21');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000893'), '0.21');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000991'), '0.04');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000891'), '0.04');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000001'), '0.04');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000002'), '0.1');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000992'), '0.1');
INSERT INTO tax (chart_id,rate) VALUES ((SELECT id FROM account WHERE accno = '472000892'), '0.1');



-- CURRENCIES
INSERT INTO currency (curr, description) VALUES    ('EUR', 'EUR');



-- SET UP DEFAULTS
-- FIRST Delete the Keys we intend to set

    delete from defaults
        where setting_key in ('inventory_accno_id',
                       'income_accno_id',
                       'expense_accno_id',
                       'fxgain_accno_id',
                       'fxloss_accno_id',
                       'earn_id',
                       'curr',
                       'weightunit',
                       'default_language',
                       'separate_duties',
                       'lock_description',
                       'gapless_ar',
                       'check_prefix',
                       'vclimit',
                       'decimal_places',
                       'show_creditlimit',
                       'session_timeout',
                       'password_duration',
                       'format',
                       'default_country'
                       );

-- NOW ACTUALLY SET the KEYS
INSERT INTO defaults (setting_key, value) VALUES    ('separate_duties', '1');
INSERT INTO defaults (setting_key, value) VALUES    ('check_prefix', 'CK');
INSERT INTO defaults (setting_key, value) VALUES    ('decimal_places', '2');
INSERT INTO defaults (setting_key, value) VALUES    ('curr', 'EUR');
INSERT INTO defaults (setting_key, value) VALUES    ('inventory_accno_id', (SELECT id FROM account WHERE accno = '300000000'));
INSERT INTO defaults (setting_key, value) VALUES    ('income_accno_id', (SELECT id FROM account WHERE accno = '700000000'));
INSERT INTO defaults (setting_key, value) VALUES    ('expense_accno_id', (SELECT id FROM account WHERE accno = '621000000'));
INSERT INTO defaults (setting_key, value) VALUES    ('fxgain_accno_id', (SELECT id FROM account WHERE accno = '768000000'));
INSERT INTO defaults (setting_key, value) VALUES    ('fxloss_accno_id', (SELECT id FROM account WHERE accno = '668000000'));



-- END of transaction
COMMIT;

