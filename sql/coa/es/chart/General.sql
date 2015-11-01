-- Create the entire COA in 1 transaction
BEGIN;


-- HEADINGS DEFINITION
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('27', NULL, '099999999', 'Grupo 1: financiación básica');
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('28', NULL, '199999999', 'Grupo 2: inmovilizado');
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('29', NULL, '299999999', 'Grupo 3: existencias');
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('30', NULL, '399999999', 'Grupo 4: acreedores y deudores por operaciones de tráfico');
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('31', NULL, '499999999', 'Grupo 5: cuentas financieras');
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('32', NULL, '599999999', 'Grupo 6: compras y gastos');
INSERT INTO account_heading (id, parent_id, accno, description)
     VALUES ('33', NULL, '699999999', 'Grupo 7: ventas e ingresos');


-- GIFI DEFINITION (need gifi before account creation)
INSERT INTO gifi (accno, description)
     VALUES ('473000000', 'Hacienda Pública, retenciones y pagos a cuenta');
INSERT INTO gifi (accno, description)
     VALUES ('472000003', 'IVA soportado alta');
INSERT INTO gifi (accno, description)
     VALUES ('472000002', 'IVA soportado medio');
INSERT INTO gifi (accno, description)
     VALUES ('410000000', 'Acreedores por prestaciones de servicios');
INSERT INTO gifi (accno, description)
     VALUES ('480000000', 'Gastos anticipados');
INSERT INTO gifi (accno, description)
     VALUES ('112000000', 'Reserva legal');
INSERT INTO gifi (accno, description)
     VALUES ('100000000', 'Capital Social');
INSERT INTO gifi (accno, description)
     VALUES ('150000000', 'Acciones o participaciones a largo plaza contabilizados como pasivo');
INSERT INTO gifi (accno, description)
     VALUES ('120000000', 'Remanente');
INSERT INTO gifi (accno, description)
     VALUES ('132000000', 'Oros subvenciones, donaciones y legados');
INSERT INTO gifi (accno, description)
     VALUES ('160300000', 'Deudas a largo plazo con empresas del grupo');
INSERT INTO gifi (accno, description)
     VALUES ('170000000', 'Deudas a largo plazo con entidades de crédito');
INSERT INTO gifi (accno, description)
     VALUES ('180000000', 'Fianzas y depósitos recibidos a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('190000000', 'Acciones o participaciones emitidas');
INSERT INTO gifi (accno, description)
     VALUES ('200000000', 'Inmovilizaciones intangibles');
INSERT INTO gifi (accno, description)
     VALUES ('210000000', 'Terrenos y bienes naturales');
INSERT INTO gifi (accno, description)
     VALUES ('230000000', 'Inmovilizaciones materiales en curso');
INSERT INTO gifi (accno, description)
     VALUES ('280000000', 'Amortización acumulada del inmovilizado intangible');
INSERT INTO gifi (accno, description)
     VALUES ('250000000', 'Inversiones financieras a largo plazo en instrumentos de patrimonio');
INSERT INTO gifi (accno, description)
     VALUES ('260000000', 'Fianzas y depósitos constituidos a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('221000000', 'Inversiones en construcciones inmobiliarias');
INSERT INTO gifi (accno, description)
     VALUES ('290000000', 'Deterioro y proviciones inmobilizado intangible');
INSERT INTO gifi (accno, description)
     VALUES ('310000000', 'Materias primas');
INSERT INTO gifi (accno, description)
     VALUES ('431000000', 'Clientes, efectos comerciales a cobrar');
INSERT INTO gifi (accno, description)
     VALUES ('320000000', 'Otros aprovisionamientos');
INSERT INTO gifi (accno, description)
     VALUES ('330000000', 'Productos en curso');
INSERT INTO gifi (accno, description)
     VALUES ('340000000', 'Productos semiterminados');
INSERT INTO gifi (accno, description)
     VALUES ('350000000', 'Productos terminados');
INSERT INTO gifi (accno, description)
     VALUES ('360000000', 'Subproductos, residuos y materiales recuperados');
INSERT INTO gifi (accno, description)
     VALUES ('390000000', 'Deterioro del valor de las existencias');
INSERT INTO gifi (accno, description)
     VALUES ('400000000', 'Proveedores');
INSERT INTO gifi (accno, description)
     VALUES ('477000002', 'IVA repercutido medio');
INSERT INTO gifi (accno, description)
     VALUES ('433000000', 'Clientes empresa del grupo');
INSERT INTO gifi (accno, description)
     VALUES ('440000000', 'Deudores varios');
INSERT INTO gifi (accno, description)
     VALUES ('460000000', 'Personal anticipos de renumeraciones');
INSERT INTO gifi (accno, description)
     VALUES ('470000000', 'Hacienda Pública, deudora por IVA a compensar');
INSERT INTO gifi (accno, description)
     VALUES ('475100000', 'Hacienda Pública, acreedor por retenciones practicadas');
INSERT INTO gifi (accno, description)
     VALUES ('477000001', 'IVA repercutido bajo');
INSERT INTO gifi (accno, description)
     VALUES ('510300000', 'Deudas a corto plazo con empresas del grupo y asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('500000000', 'Obligaciones y bonos a corto plazo');
INSERT INTO gifi (accno, description)
     VALUES ('551000000', 'Cuentas corriente con socios administradores');
INSERT INTO gifi (accno, description)
     VALUES ('520000000', 'Prestamos a corto plazo de entidades de crédito');
INSERT INTO gifi (accno, description)
     VALUES ('530000000', 'Participaciones a corto plazo en empresas del grupo y asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('542000000', 'Créditos a corto plazo');
INSERT INTO gifi (accno, description)
     VALUES ('575000000', 'Bancos e instituciones de crédito, cuentas de ahorro, moneda extranjera');
INSERT INTO gifi (accno, description)
     VALUES ('560000000', 'Fianzas y depósitos recibidos y constituidos a corto plazo');
INSERT INTO gifi (accno, description)
     VALUES ('570000000', 'Caja, euros');
INSERT INTO gifi (accno, description)
     VALUES ('571000000', 'Caja, moneda extranjera');
INSERT INTO gifi (accno, description)
     VALUES ('572000000', 'Bancos e instituciones de crédito, c/c. vista, euros');
INSERT INTO gifi (accno, description)
     VALUES ('573000000', 'Bancos e instituciones de crédito, c/c. vista, moneda extranjera');
INSERT INTO gifi (accno, description)
     VALUES ('574000000', 'Bancos e instituciones de crédito, cuentas de ahorro, euros');
INSERT INTO gifi (accno, description)
     VALUES ('598000000', 'Provisiones financieras');
INSERT INTO gifi (accno, description)
     VALUES ('610000000', 'Variación de existencias mercaderias');
INSERT INTO gifi (accno, description)
     VALUES ('600000000', 'Compras de mercaderías');
INSERT INTO gifi (accno, description)
     VALUES ('608000000', 'Devoluciones de compras y operaciones similares');
INSERT INTO gifi (accno, description)
     VALUES ('650000000', 'Otros gastos variables');
INSERT INTO gifi (accno, description)
     VALUES ('621000000', 'Arrendamientos y cánones');
INSERT INTO gifi (accno, description)
     VALUES ('630000000', 'Impuesto sobre beneficios');
INSERT INTO gifi (accno, description)
     VALUES ('640000000', 'Sueldos y salarios');
INSERT INTO gifi (accno, description)
     VALUES ('681000000', 'Dotaciones para amortizaciones');
INSERT INTO gifi (accno, description)
     VALUES ('668000000', 'Diferencias negativas de cambio');
INSERT INTO gifi (accno, description)
     VALUES ('669000000', 'Otros gastos financieros');
INSERT INTO gifi (accno, description)
     VALUES ('660000000', 'Gastos financieros intereses y provisiones');
INSERT INTO gifi (accno, description)
     VALUES ('740000000', 'Subvenciones a la explotación');
INSERT INTO gifi (accno, description)
     VALUES ('690000000', 'Dotaciones a las provisiones');
INSERT INTO gifi (accno, description)
     VALUES ('700000000', 'Ventas de mercaderias');
INSERT INTO gifi (accno, description)
     VALUES ('708000000', 'Devoluciones de ventas y operaciones similares');
INSERT INTO gifi (accno, description)
     VALUES ('710000000', 'Variación de existencias');
INSERT INTO gifi (accno, description)
     VALUES ('751000000', 'Otros ingresos de gestión');
INSERT INTO gifi (accno, description)
     VALUES ('760300000', 'Ingresos financieros');
INSERT INTO gifi (accno, description)
     VALUES ('768000000', 'Diferencias positivas de cambio');
INSERT INTO gifi (accno, description)
     VALUES ('770000000', 'Beneficios procedentes de inmovilizados e ingresos excepcionales');
INSERT INTO gifi (accno, description)
     VALUES ('791000000', 'Reversion det. invers. material');
INSERT INTO gifi (accno, description)
     VALUES ('240500000', 'Participaciones a largo plazo en partes vinculades');
INSERT INTO gifi (accno, description)
     VALUES ('300000000', 'Mercaderias');
INSERT INTO gifi (accno, description)
     VALUES ('472000001', 'IVA soportado bajo');
INSERT INTO gifi (accno, description)
     VALUES ('490000000', 'Provisiones por operaciones comerciales');
INSERT INTO gifi (accno, description)
     VALUES ('730000000', 'Trabajos realizados para la empresa');
INSERT INTO gifi (accno, description)
     VALUES ('436000000', 'Clientes de dudoso cobro');
INSERT INTO gifi (accno, description)
     VALUES ('438000000', 'Anticipios de clientes');
INSERT INTO gifi (accno, description)
     VALUES ('446000000', 'Deudores varios de dudoso cobros');
INSERT INTO gifi (accno, description)
     VALUES ('101000000', 'Fondo Social');
INSERT INTO gifi (accno, description)
     VALUES ('102000000', 'Capital');
INSERT INTO gifi (accno, description)
     VALUES ('110000000', 'Prima de emisión o asunción');
INSERT INTO gifi (accno, description)
     VALUES ('113000000', 'Reservas voluntarias');
INSERT INTO gifi (accno, description)
     VALUES ('149000000', 'Provisión para reestructuraciones');
INSERT INTO gifi (accno, description)
     VALUES ('118000000', 'Aportaciones de socios o propietarios');
INSERT INTO gifi (accno, description)
     VALUES ('121000000', 'Resultados negativos de ejercios anterios');
INSERT INTO gifi (accno, description)
     VALUES ('129000000', 'Resultados del ejercicio');
INSERT INTO gifi (accno, description)
     VALUES ('130000000', 'Subvenciones oficiales de capital');
INSERT INTO gifi (accno, description)
     VALUES ('131000000', 'Donaciones y legados de capital');
INSERT INTO gifi (accno, description)
     VALUES ('137000000', 'Ingresos fiscales a distribuir en varios ejercicios');
INSERT INTO gifi (accno, description)
     VALUES ('141000000', 'Provisión para impuestos');
INSERT INTO gifi (accno, description)
     VALUES ('142000000', 'Provisión para otros responsibilidades');
INSERT INTO gifi (accno, description)
     VALUES ('145000000', 'Provisión para actuaciones medioambientes');
INSERT INTO gifi (accno, description)
     VALUES ('160400000', 'Deudas a largo plaza empresas asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('171000000', 'Deudas a largo plaza');
INSERT INTO gifi (accno, description)
     VALUES ('174000000', 'Acreedores de arrendamiento financiero a largo plaza');
INSERT INTO gifi (accno, description)
     VALUES ('181000000', 'Anticipos recibidos per ventas o prestaciones de servicios');
INSERT INTO gifi (accno, description)
     VALUES ('185000000', 'Depósitos recibidos a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('192000000', 'Suscriptores de acciones');
INSERT INTO gifi (accno, description)
     VALUES ('194000000', 'Capital emitido pendiente de inscripción');
INSERT INTO gifi (accno, description)
     VALUES ('213000000', 'Maquinaria');
INSERT INTO gifi (accno, description)
     VALUES ('211000000', 'Construcciones');
INSERT INTO gifi (accno, description)
     VALUES ('212000000', 'Instalaciones técnicas');
INSERT INTO gifi (accno, description)
     VALUES ('214000000', 'Utilaje');
INSERT INTO gifi (accno, description)
     VALUES ('216000000', 'Mobiliario');
INSERT INTO gifi (accno, description)
     VALUES ('217000000', 'IT equipos para procecos de información');
INSERT INTO gifi (accno, description)
     VALUES ('218000000', 'Elementos de transporte');
INSERT INTO gifi (accno, description)
     VALUES ('219000000', 'Otro inmovilizado material');
INSERT INTO gifi (accno, description)
     VALUES ('215000000', 'Otras instalaciones');
INSERT INTO gifi (accno, description)
     VALUES ('239000000', 'Anticipos para Inmovilizaciones materiales');
INSERT INTO gifi (accno, description)
     VALUES ('240300000', 'Participaciones a largo plazo en empresas del grupo');
INSERT INTO gifi (accno, description)
     VALUES ('240400000', 'Participaciones a largo plazo en empresas asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('252000000', 'Créditos a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('253000000', 'Créditos a largo plazo por enajenación de inmovilizado');
INSERT INTO gifi (accno, description)
     VALUES ('258000000', 'Imposiciones a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('259000000', 'Desembolsos pendientes sobre participaciones en el patrimonio neto a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('281100000', 'Amortización acumulada construcciones');
INSERT INTO gifi (accno, description)
     VALUES ('281200000', 'Amortización acumulada instalaciones tecnicas');
INSERT INTO gifi (accno, description)
     VALUES ('281300000', 'Amortización acumulada maquinaria');
INSERT INTO gifi (accno, description)
     VALUES ('281400000', 'Amortización acumulada utilaje');
INSERT INTO gifi (accno, description)
     VALUES ('281600000', 'Amortización acumulada mobiliario');
INSERT INTO gifi (accno, description)
     VALUES ('281500000', 'Amortización acumulada otras instalaciones');
INSERT INTO gifi (accno, description)
     VALUES ('281700000', 'Amortización acumulada IT procesos informatica');
INSERT INTO gifi (accno, description)
     VALUES ('281800000', 'Amortización acumulada elementos de transporte');
INSERT INTO gifi (accno, description)
     VALUES ('281900000', 'Amortización acumulada otro inmovilizado material');
INSERT INTO gifi (accno, description)
     VALUES ('282000000', 'Amortización acumulada inversiones inmobiliario');
INSERT INTO gifi (accno, description)
     VALUES ('292000000', 'Deterioro y proviciones inversiones inmobiliarias');
INSERT INTO gifi (accno, description)
     VALUES ('298000000', 'Deterioro y proviciones valor créditos a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('403000000', 'Proveedores empresas del grupo');
INSERT INTO gifi (accno, description)
     VALUES ('404000000', 'Proveedores empresas asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('406000000', 'Envases y embalajes a devolver a proveedores');
INSERT INTO gifi (accno, description)
     VALUES ('407000000', 'Anticipos a proveedores');
INSERT INTO gifi (accno, description)
     VALUES ('477000891', 'IVA repercutido baja intracomm +');
INSERT INTO gifi (accno, description)
     VALUES ('430000000', 'Clientes');
INSERT INTO gifi (accno, description)
     VALUES ('434000000', 'Clientes empresas asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('465000000', 'Personal remuneraciones pendientes de pago');
INSERT INTO gifi (accno, description)
     VALUES ('471000000', 'Organismos de la Seguridad Social deudores');
INSERT INTO gifi (accno, description)
     VALUES ('472000893', 'IVA soportado alta intracomm  +');
INSERT INTO gifi (accno, description)
     VALUES ('472000892', 'IVA soportado medio intracomm +');
INSERT INTO gifi (accno, description)
     VALUES ('472000891', 'IVA soportado baja intracomm +');
INSERT INTO gifi (accno, description)
     VALUES ('472000991', 'IVA soportado baja intracomm -');
INSERT INTO gifi (accno, description)
     VALUES ('472000992', 'IVA soportado medio intracomm -');
INSERT INTO gifi (accno, description)
     VALUES ('472000993', 'IVA soportado alta intracomm  -');
INSERT INTO gifi (accno, description)
     VALUES ('475000000', 'Hacienda Pública, acreedor por IVA');
INSERT INTO gifi (accno, description)
     VALUES ('475200000', 'Hacienda Pública, acreedor por impuestos sobre sociedades');
INSERT INTO gifi (accno, description)
     VALUES ('475800000', 'Hacienda Pública, acreedor por subvenciones a reintegrar');
INSERT INTO gifi (accno, description)
     VALUES ('476000000', 'Organismos de la Seguridad Social acreedores');
INSERT INTO gifi (accno, description)
     VALUES ('477000003', 'IVA repercutido alto');
INSERT INTO gifi (accno, description)
     VALUES ('477000892', 'IVA repercutido medio intracomm +');
INSERT INTO gifi (accno, description)
     VALUES ('477000893', 'IVA repercutido alta intracomm +');
INSERT INTO gifi (accno, description)
     VALUES ('477000992', 'IVA repercutido medio intracomm -');
INSERT INTO gifi (accno, description)
     VALUES ('114500000', 'Reservas especiales');
INSERT INTO gifi (accno, description)
     VALUES ('242500000', 'Créditos a largo plazo a partes vinculades');
INSERT INTO gifi (accno, description)
     VALUES ('249300000', 'Desembolsos pendientes sobre participaciones a largo plazo');
INSERT INTO gifi (accno, description)
     VALUES ('293300000', 'Deterioro y proviciones valor participaciones largo plaza');
INSERT INTO gifi (accno, description)
     VALUES ('470100000', 'Hacienda Pública, deudora por IVA LP');
INSERT INTO gifi (accno, description)
     VALUES ('475400000', 'Hacienda Pública, acreedor por retenciones alquiler');
INSERT INTO gifi (accno, description)
     VALUES ('477000993', 'IVA repercutido alta intracomm -');
INSERT INTO gifi (accno, description)
     VALUES ('477000991', 'IVA repercutido baja intracomm -');
INSERT INTO gifi (accno, description)
     VALUES ('485000000', 'Ingresos anticipados');
INSERT INTO gifi (accno, description)
     VALUES ('521000000', 'Deudas a corto plazo');
INSERT INTO gifi (accno, description)
     VALUES ('526000000', 'Dividendos activo a pagar');
INSERT INTO gifi (accno, description)
     VALUES ('552400000', 'Cuentas corriente con empresas asociadas');
INSERT INTO gifi (accno, description)
     VALUES ('555000000', 'Partidas pendientes de aplicación');
INSERT INTO gifi (accno, description)
     VALUES ('555500000', 'Facturas pagadas con visa');
INSERT INTO gifi (accno, description)
     VALUES ('557000000', 'Dividende activo a cuenta');
INSERT INTO gifi (accno, description)
     VALUES ('606000000', 'Descuentos sobre compras por pronto pago');
INSERT INTO gifi (accno, description)
     VALUES ('622000000', 'Reparaciones y conservación');
INSERT INTO gifi (accno, description)
     VALUES ('623000000', 'Servicios profesionales de contabilidat o accountant o auditor');
INSERT INTO gifi (accno, description)
     VALUES ('623100000', 'Servicios profesionales de notaria o abogado');
INSERT INTO gifi (accno, description)
     VALUES ('623200000', 'Servicios profesionales de asesor fiscal o empresarial');
INSERT INTO gifi (accno, description)
     VALUES ('623600000', 'Servicios profesionales deregistro mercantil o propiedad');
INSERT INTO gifi (accno, description)
     VALUES ('623500000', 'Gastos de gestión');
INSERT INTO gifi (accno, description)
     VALUES ('624000000', 'Gastos de coches');
INSERT INTO gifi (accno, description)
     VALUES ('624400000', 'Gastos de viaje y estancia');
INSERT INTO gifi (accno, description)
     VALUES ('624700000', 'Gastos de transportes');
INSERT INTO gifi (accno, description)
     VALUES ('625000000', 'Primas de seguros');
INSERT INTO gifi (accno, description)
     VALUES ('626000000', 'Servicios bancarios y similares');
INSERT INTO gifi (accno, description)
     VALUES ('627000000', 'Publicidad, propaganda, y relaciones públicas');
INSERT INTO gifi (accno, description)
     VALUES ('628000000', 'Gastos de gas');
INSERT INTO gifi (accno, description)
     VALUES ('628100000', 'Gastos de teléfono fija');
INSERT INTO gifi (accno, description)
     VALUES ('628200000', 'Gastos de teléfono movil');
INSERT INTO gifi (accno, description)
     VALUES ('628300000', 'Gastos internet');
INSERT INTO gifi (accno, description)
     VALUES ('628400000', 'Gastos luz');
INSERT INTO gifi (accno, description)
     VALUES ('628500000', 'Gastos aqua');
INSERT INTO gifi (accno, description)
     VALUES ('629000000', 'Otros servicios');
INSERT INTO gifi (accno, description)
     VALUES ('629100000', 'Consumo de material de oficina');
INSERT INTO gifi (accno, description)
     VALUES ('629200000', 'Calidad de miembro');
INSERT INTO gifi (accno, description)
     VALUES ('629500000', 'Correos');
INSERT INTO gifi (accno, description)
     VALUES ('629600000', 'Gastos de limopieza');
INSERT INTO gifi (accno, description)
     VALUES ('629700000', 'Gastos de representación');
INSERT INTO gifi (accno, description)
     VALUES ('629800000', 'Gastos de IT y informática');
INSERT INTO gifi (accno, description)
     VALUES ('629900000', 'Sanciones Tributarios');
INSERT INTO gifi (accno, description)
     VALUES ('631000000', 'Otros tributos');
INSERT INTO gifi (accno, description)
     VALUES ('641000000', 'Indemnizaciones');
INSERT INTO gifi (accno, description)
     VALUES ('642000000', 'Seguridad Social a cargo de la empresa');
INSERT INTO gifi (accno, description)
     VALUES ('642100000', 'Seguridad Social Autonomo pago de la empresa en nombre');
INSERT INTO gifi (accno, description)
     VALUES ('644200000', 'Otros costes de personal');
INSERT INTO gifi (accno, description)
     VALUES ('649000000', 'Otros gastos sociales');
INSERT INTO gifi (accno, description)
     VALUES ('678000000', 'Gastos excepcionales');
INSERT INTO gifi (accno, description)
     VALUES ('679000000', 'Gastos y perdidas de ejercicios anteriores');
INSERT INTO gifi (accno, description)
     VALUES ('701000000', 'Ventas de productos terminados');
INSERT INTO gifi (accno, description)
     VALUES ('704000000', 'Ventas de envases y embalajes');
INSERT INTO gifi (accno, description)
     VALUES ('705000000', 'Prestaciones de servicios');
INSERT INTO gifi (accno, description)
     VALUES ('706000000', 'Descuentos sobre ventas por pronto pago');
INSERT INTO gifi (accno, description)
     VALUES ('769000000', 'Otros ingresos financieros');
INSERT INTO gifi (accno, description)
     VALUES ('607000000', 'Trabajos realizados por otra empresas');
INSERT INTO gifi (accno, description)
     VALUES ('527000000', 'Intereses a corto plaza de deudas con entidades de crédito');
INSERT INTO gifi (accno, description)
     VALUES ('552300000', 'Cuentas corriente con empresas del grupo');
INSERT INTO gifi (accno, description)
     VALUES ('752000000', 'Ingresos por arrendamientos');
INSERT INTO gifi (accno, description)
     VALUES ('754000000', 'Ingresos por comisiones');
INSERT INTO gifi (accno, description)
     VALUES ('755000000', 'Ingresos por servicios al personal');
INSERT INTO gifi (accno, description)
     VALUES ('759000000', 'Ingresos por servicios diversos');
INSERT INTO gifi (accno, description)
     VALUES ('778000000', 'Ingresos excepcionales');
INSERT INTO gifi (accno, description)
     VALUES ('778010000', 'Ingresos y ganancias de ejercicias anteriores');


-- ACCOUNTS DEFINITION
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('302', '473000000', 'Hacienda Pública, retenciones y pagos a cuenta', '0', 'A', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('300', '472000003', 'IVA soportado alta', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('299', '472000002', 'IVA soportado medio', '0', 'L', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('291', '410000000', 'Acreedores por prestaciones de servicios', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('307', '480000000', 'Gastos anticipados', '0', 'L', '176',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('263', '112000000', 'Reserva legal', '0', 'Q', '191',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('262', '100000000', 'Capital Social', '0', 'Q', '188',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('267', '150000000', 'Acciones o participaciones a largo plaza contabilizados como pasivo', '0', 'L', '227',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('264', '120000000', 'Remanente', '0', 'Q', '195',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('265', '132000000', 'Oros subvenciones, donaciones y legados', '0', 'Q', '209',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('268', '160300000', 'Deudas a largo plazo con empresas del grupo', '0', 'L', '223',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('269', '170000000', 'Deudas a largo plazo con entidades de crédito', '0', 'L', '218',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('270', '180000000', 'Fianzas y depósitos recibidos a largo plazo', '0', 'L', '222',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('271', '190000000', 'Acciones o participaciones emitidas', '0', 'Q', '237',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('272', '200000000', 'Inmovilizaciones intangibles', '0', 'A', '110',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('273', '210000000', 'Terrenos y bienes naturales', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('275', '230000000', 'Inmovilizaciones materiales en curso', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('280', '280000000', 'Amortización acumulada del inmovilizado intangible', '0', 'A', '110',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('277', '250000000', 'Inversiones financieras a largo plazo en instrumentos de patrimonio', '0', 'A', '127',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('278', '260000000', 'Fianzas y depósitos constituidos a largo plazo', '0', 'A', '133',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('274', '221000000', 'Inversiones en construcciones inmobiliarias', '0', 'A', '115',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('281', '290000000', 'Deterioro y proviciones inmobilizado intangible', '0', 'A', '110',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('283', '310000000', 'Materias primas', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('293', '431000000', 'Clientes, efectos comerciales a cobrar', '0', 'A', '152',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('284', '320000000', 'Otros aprovisionamientos', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('285', '330000000', 'Productos en curso', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('286', '340000000', 'Productos semiterminados', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('287', '350000000', 'Productos terminados', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('288', '360000000', 'Subproductos, residuos y materiales recuperados', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('289', '390000000', 'Deterioro del valor de las existencias', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('290', '400000000', 'Proveedores', '0', 'L', '242',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('305', '477000002', 'IVA repercutido medio', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('292', '433000000', 'Clientes empresa del grupo', '0', 'A', '152',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('294', '440000000', 'Deudores varios', '0', 'L', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('295', '460000000', 'Personal anticipos de renumeraciones', '0', 'A', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('296', '470000000', 'Hacienda Pública, deudora por IVA a compensar', '0', 'A', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('301', '475100000', 'Hacienda Pública, acreedor por retenciones practicadas', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('304', '477000001', 'IVA repercutido bajo', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('310', '510300000', 'Deudas a corto plazo con empresas del grupo y asociadas', '0', 'L', '238',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('309', '500000000', 'Obligaciones y bonos a corto plazo', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('314', '551000000', 'Cuentas corriente con socios administradores', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('311', '520000000', 'Prestamos a corto plazo de entidades de crédito', '0', 'L', '233',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('312', '530000000', 'Participaciones a corto plazo en empresas del grupo y asociadas', '0', 'A', '161',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('313', '542000000', 'Créditos a corto plazo', '0', 'A', '175',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('322', '575000000', 'Bancos e instituciones de crédito, cuentas de ahorro, moneda extranjera', '0', 'A', '177',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('315', '560000000', 'Fianzas y depósitos recibidos y constituidos a corto plazo', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('317', '570000000', 'Caja, euros', '0', 'A', '177',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('318', '571000000', 'Caja, moneda extranjera', '0', 'A', '177',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('319', '572000000', 'Bancos e instituciones de crédito, c/c. vista, euros', '0', 'A', '177',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('320', '573000000', 'Bancos e instituciones de crédito, c/c. vista, moneda extranjera', '0', 'A', '177',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('321', '574000000', 'Bancos e instituciones de crédito, cuentas de ahorro, euros', '0', 'A', '177',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('324', '598000000', 'Provisiones financieras', '0', 'L', '168',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('327', '610000000', 'Variación de existencias mercaderias', '0', 'E', '260',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('325', '600000000', 'Compras de mercaderías', '0', 'E', '260',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('326', '608000000', 'Devoluciones de compras y operaciones similares', '0', 'E', '260',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('331', '650000000', 'Otros gastos variables', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('328', '621000000', 'Arrendamientos y cánones', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('329', '630000000', 'Impuesto sobre beneficios', '0', 'E', '326',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('330', '640000000', 'Sueldos y salarios', '0', 'E', '271',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('336', '681000000', 'Dotaciones para amortizaciones', '0', 'E', '284',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('334', '668000000', 'Diferencias negativas de cambio', '0', 'E', '305',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('333', '669000000', 'Otros gastos financieros', '0', 'E', '307',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('332', '660000000', 'Gastos financieros intereses y provisiones', '0', 'E', '305',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('342', '740000000', 'Subvenciones a la explotación', '0', 'I', '269',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('337', '690000000', 'Dotaciones a las provisiones', '0', 'E', '289',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('338', '700000000', 'Ventas de mercaderias', '0', 'I', '255',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('339', '708000000', 'Devoluciones de ventas y operaciones similares', '0', 'I', '255',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('340', '710000000', 'Variación de existencias', '0', 'I', '258',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('343', '751000000', 'Otros ingresos de gestión', '0', 'I', '268',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('344', '760300000', 'Ingresos financieros', '0', 'I', '300',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('346', '768000000', 'Diferencias positivas de cambio', '0', 'I', '312',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('347', '770000000', 'Beneficios procedentes de inmovilizados e ingresos excepcionales', '0', 'I', '292',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('348', '791000000', 'Reversion det. invers. material', '0', 'I', '290',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('276', '240500000', 'Participaciones a largo plazo en partes vinculades', '0', 'A', '119',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('282', '300000000', 'Mercaderias', '0', 'A', '138',
             '29', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('298', '472000001', 'IVA soportado bajo', '0', 'L', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('308', '490000000', 'Provisiones por operaciones comerciales', '0', 'L', '152',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('341', '730000000', 'Trabajos realizados para la empresa', '0', 'I', '258',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('410', '436000000', 'Clientes de dudoso cobro', '0', 'A', '152',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('411', '438000000', 'Anticipios de clientes', '0', 'A', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('413', '446000000', 'Deudores varios de dudoso cobros', '0', 'L', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('349', '101000000', 'Fondo Social', '0', 'Q', '188',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('350', '102000000', 'Capital', '0', 'Q', '188',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('358', '110000000', 'Prima de emisión o asunción', '0', 'Q', '190',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('352', '113000000', 'Reservas voluntarias', '0', 'Q', '191',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('357', '149000000', 'Provisión para reestructuraciones', '0', 'L', '211',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('359', '118000000', 'Aportaciones de socios o propietarios', '0', 'Q', '198',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('354', '121000000', 'Resultados negativos de ejercios anterios', '0', 'Q', '195',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('355', '129000000', 'Resultados del ejercicio', '0', 'Q', '199',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('360', '130000000', 'Subvenciones oficiales de capital', '0', 'Q', '209',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('361', '131000000', 'Donaciones y legados de capital', '0', 'Q', '209',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('362', '137000000', 'Ingresos fiscales a distribuir en varios ejercicios', '0', 'Q', '208',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('356', '141000000', 'Provisión para impuestos', '0', 'L', '211',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('363', '142000000', 'Provisión para otros responsibilidades', '0', 'L', '211',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('364', '145000000', 'Provisión para actuaciones medioambientes', '0', 'L', '211',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('365', '160400000', 'Deudas a largo plaza empresas asociadas', '0', 'L', '223',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('366', '171000000', 'Deudas a largo plaza', '0', 'L', '222',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('367', '174000000', 'Acreedores de arrendamiento financiero a largo plaza', '0', 'L', '219',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('368', '181000000', 'Anticipos recibidos per ventas o prestaciones de servicios', '0', 'L', '225',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('369', '185000000', 'Depósitos recibidos a largo plazo', '0', 'L', '222',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('371', '192000000', 'Suscriptores de acciones', '0', 'Q', '237',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('372', '194000000', 'Capital emitido pendiente de inscripción', '0', 'Q', '237',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('373', '213000000', 'Maquinaria', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('374', '211000000', 'Construcciones', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('375', '212000000', 'Instalaciones técnicas', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('376', '214000000', 'Utilaje', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('378', '216000000', 'Mobiliario', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('379', '217000000', 'IT equipos para procecos de información', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('380', '218000000', 'Elementos de transporte', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('381', '219000000', 'Otro inmovilizado material', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('377', '215000000', 'Otras instalaciones', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('382', '239000000', 'Anticipos para Inmovilizaciones materiales', '0', 'A', '111',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('383', '240300000', 'Participaciones a largo plazo en empresas del grupo', '0', 'A', '119',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('384', '240400000', 'Participaciones a largo plazo en empresas asociadas', '0', 'A', '119',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('387', '252000000', 'Créditos a largo plazo', '0', 'A', '133',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('388', '253000000', 'Créditos a largo plazo por enajenación de inmovilizado', '0', 'A', '133',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('389', '258000000', 'Imposiciones a largo plazo', '0', 'A', '133',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('390', '259000000', 'Desembolsos pendientes sobre participaciones en el patrimonio neto a largo plazo', '0', 'A', '127',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('391', '281100000', 'Amortización acumulada construcciones', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('392', '281200000', 'Amortización acumulada instalaciones tecnicas', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('393', '281300000', 'Amortización acumulada maquinaria', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('394', '281400000', 'Amortización acumulada utilaje', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('396', '281600000', 'Amortización acumulada mobiliario', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('395', '281500000', 'Amortización acumulada otras instalaciones', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('397', '281700000', 'Amortización acumulada IT procesos informatica', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('398', '281800000', 'Amortización acumulada elementos de transporte', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('399', '281900000', 'Amortización acumulada otro inmovilizado material', '0', 'A', '111',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('400', '282000000', 'Amortización acumulada inversiones inmobiliario', '0', 'A', '115',
             '28', '1', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('401', '292000000', 'Deterioro y proviciones inversiones inmobiliarias', '0', 'A', '115',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('403', '298000000', 'Deterioro y proviciones valor créditos a largo plazo', '0', 'A', '133',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('404', '403000000', 'Proveedores empresas del grupo', '0', 'L', '242',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('405', '404000000', 'Proveedores empresas asociadas', '0', 'L', '242',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('406', '406000000', 'Envases y embalajes a devolver a proveedores', '0', 'L', '242',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('407', '407000000', 'Anticipos a proveedores', '0', 'L', '138',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('430', '477000891', 'IVA repercutido baja intracomm +', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('408', '430000000', 'Clientes', '0', 'A', '152',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('409', '434000000', 'Clientes empresas asociadas', '0', 'A', '152',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('414', '465000000', 'Personal remuneraciones pendientes de pago', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('417', '471000000', 'Organismos de la Seguridad Social deudores', '0', 'A', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('420', '472000893', 'IVA soportado alta intracomm  +', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('419', '472000892', 'IVA soportado medio intracomm +', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('418', '472000891', 'IVA soportado baja intracomm +', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('421', '472000991', 'IVA soportado baja intracomm -', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('422', '472000992', 'IVA soportado medio intracomm -', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('423', '472000993', 'IVA soportado alta intracomm  -', '0', 'A', '159',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('425', '475000000', 'Hacienda Pública, acreedor por IVA', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('426', '475200000', 'Hacienda Pública, acreedor por impuestos sobre sociedades', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('428', '475800000', 'Hacienda Pública, acreedor por subvenciones a reintegrar', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('429', '476000000', 'Organismos de la Seguridad Social acreedores', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('306', '477000003', 'IVA repercutido alto', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('431', '477000892', 'IVA repercutido medio intracomm +', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('432', '477000893', 'IVA repercutido alta intracomm +', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('434', '477000992', 'IVA repercutido medio intracomm -', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('353', '114500000', 'Reservas especiales', '0', 'Q', '191',
             '27', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('385', '242500000', 'Créditos a largo plazo a partes vinculades', '0', 'A', '133',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('386', '249300000', 'Desembolsos pendientes sobre participaciones a largo plazo', '0', 'A', '119',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('402', '293300000', 'Deterioro y proviciones valor participaciones largo plaza', '0', 'A', '119',
             '28', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('416', '470100000', 'Hacienda Pública, deudora por IVA LP', '0', 'A', '159',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('427', '475400000', 'Hacienda Pública, acreedor por retenciones alquiler', '0', 'L', '249',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('435', '477000993', 'IVA repercutido alta intracomm -', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('433', '477000991', 'IVA repercutido baja intracomm -', '0', 'L', '249',
             '30', '0', '1', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('436', '485000000', 'Ingresos anticipados', '0', 'L', '250',
             '30', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('437', '521000000', 'Deudas a corto plazo', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('438', '526000000', 'Dividendos activo a pagar', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('441', '552400000', 'Cuentas corriente con empresas asociadas', '0', 'L', '238',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('442', '555000000', 'Partidas pendientes de aplicación', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('443', '555500000', 'Facturas pagadas con visa', '0', 'L', '237',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('444', '557000000', 'Dividende activo a cuenta', '0', 'L', '200',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('445', '606000000', 'Descuentos sobre compras por pronto pago', '0', 'E', '260',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('447', '622000000', 'Reparaciones y conservación', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('448', '623000000', 'Servicios profesionales de contabilidat o accountant o auditor', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('449', '623100000', 'Servicios profesionales de notaria o abogado', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('450', '623200000', 'Servicios profesionales de asesor fiscal o empresarial', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('451', '623600000', 'Servicios profesionales deregistro mercantil o propiedad', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('452', '623500000', 'Gastos de gestión', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('453', '624000000', 'Gastos de coches', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('454', '624400000', 'Gastos de viaje y estancia', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('455', '624700000', 'Gastos de transportes', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('456', '625000000', 'Primas de seguros', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('457', '626000000', 'Servicios bancarios y similares', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('458', '627000000', 'Publicidad, propaganda, y relaciones públicas', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('459', '628000000', 'Gastos de gas', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('460', '628100000', 'Gastos de teléfono fija', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('462', '628200000', 'Gastos de teléfono movil', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('463', '628300000', 'Gastos internet', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('464', '628400000', 'Gastos luz', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('465', '628500000', 'Gastos aqua', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('466', '629000000', 'Otros servicios', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('467', '629100000', 'Consumo de material de oficina', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('468', '629200000', 'Calidad de miembro', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('469', '629500000', 'Correos', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('470', '629600000', 'Gastos de limopieza', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('471', '629700000', 'Gastos de representación', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('472', '629800000', 'Gastos de IT y informática', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('473', '629900000', 'Sanciones Tributarios', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('474', '631000000', 'Otros tributos', '0', 'E', '279',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('475', '641000000', 'Indemnizaciones', '0', 'E', '273',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('476', '642000000', 'Seguridad Social a cargo de la empresa', '0', 'E', '274',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('477', '642100000', 'Seguridad Social Autonomo pago de la empresa en nombre', '0', 'E', '274',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('478', '644200000', 'Otros costes de personal', '0', 'E', '271',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('479', '649000000', 'Otros gastos sociales', '0', 'E', '277',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('480', '678000000', 'Gastos excepcionales', '0', 'E', '295',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('335', '679000000', 'Gastos y perdidas de ejercicios anteriores', '0', 'E', '295',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('481', '701000000', 'Ventas de productos terminados', '0', 'I', '255',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('482', '704000000', 'Ventas de envases y embalajes', '0', 'I', '255',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('483', '705000000', 'Prestaciones de servicios', '0', 'I', '255',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('484', '706000000', 'Descuentos sobre ventas por pronto pago', '0', 'I', '255',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('490', '769000000', 'Otros ingresos financieros', '0', 'I', '300',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('446', '607000000', 'Trabajos realizados por otra empresas', '0', 'E', '260',
             '32', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('439', '527000000', 'Intereses a corto plaza de deudas con entidades de crédito', '0', 'L', '233',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('440', '552300000', 'Cuentas corriente con empresas del grupo', '0', 'L', '238',
             '31', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('485', '752000000', 'Ingresos por arrendamientos', '0', 'I', '267',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('486', '754000000', 'Ingresos por comisiones', '0', 'I', '268',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('488', '755000000', 'Ingresos por servicios al personal', '0', 'I', '268',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('489', '759000000', 'Ingresos por servicios diversos', '0', 'I', '268',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('491', '778000000', 'Ingresos excepcionales', '0', 'I', '295',
             '33', '0', '0', '0');
INSERT INTO account (id, accno, description, is_temp, category, gifi_accno,
            heading, contra, tax, obsolete)
     VALUES ('492', '778010000', 'Ingresos y ganancias de ejercicias anteriores', '0', 'I', '295',
             '33', '0', '0', '0');


-- CUSTOM ACCOUNT LINK DEFINITION


-- ACCOUNT LINKS
INSERT INTO account_link (account_id, description)
     VALUES (325, 'IC_cogs');
INSERT INTO account_link (account_id, description)
     VALUES (445, 'IC_cogs');
INSERT INTO account_link (account_id, description)
     VALUES (328, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (447, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (448, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (449, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (450, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (451, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (452, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (453, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (454, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (455, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (456, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (457, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (458, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (459, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (460, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (462, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (463, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (464, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (465, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (466, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (467, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (468, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (469, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (470, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (471, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (472, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (473, 'IC_expense');
INSERT INTO account_link (account_id, description)
     VALUES (338, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (338, 'IC_income');
INSERT INTO account_link (account_id, description)
     VALUES (481, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (481, 'IC_income');
INSERT INTO account_link (account_id, description)
     VALUES (482, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (482, 'IC_income');
INSERT INTO account_link (account_id, description)
     VALUES (483, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (483, 'IC_income');
INSERT INTO account_link (account_id, description)
     VALUES (484, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (484, 'IC_income');
INSERT INTO account_link (account_id, description)
     VALUES (446, 'IC_cogs');
INSERT INTO account_link (account_id, description)
     VALUES (280, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (280, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (272, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (272, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (273, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (282, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (293, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (373, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (373, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (374, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (374, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (375, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (375, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (376, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (376, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (298, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (298, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (378, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (378, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (379, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (379, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (380, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (380, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (381, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (381, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (377, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (377, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (299, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (391, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (391, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (392, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (392, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (393, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (393, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (394, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (394, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (299, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (322, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (396, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (396, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (395, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (395, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (397, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (397, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (398, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (398, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (399, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (399, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (400, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (400, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (274, 'Asset_Dep');
INSERT INTO account_link (account_id, description)
     VALUES (274, 'Fixed_Asset');
INSERT INTO account_link (account_id, description)
     VALUES (322, 'AR_paid');
INSERT INTO account_link (account_id, description)
     VALUES (283, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (284, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (285, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (286, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (287, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (288, 'IC');
INSERT INTO account_link (account_id, description)
     VALUES (290, 'AP');
INSERT INTO account_link (account_id, description)
     VALUES (404, 'AP');
INSERT INTO account_link (account_id, description)
     VALUES (405, 'AP');
INSERT INTO account_link (account_id, description)
     VALUES (322, 'AP_amount');
INSERT INTO account_link (account_id, description)
     VALUES (406, 'AP');
INSERT INTO account_link (account_id, description)
     VALUES (407, 'AP');
INSERT INTO account_link (account_id, description)
     VALUES (322, 'AP_paid');
INSERT INTO account_link (account_id, description)
     VALUES (291, 'AP');
INSERT INTO account_link (account_id, description)
     VALUES (292, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (408, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (409, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (410, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (294, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (413, 'AR');
INSERT INTO account_link (account_id, description)
     VALUES (300, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (300, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (420, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (420, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (419, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (419, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (418, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (418, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (421, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (421, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (422, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (422, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (423, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (423, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (304, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (304, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (305, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (305, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (306, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (306, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (430, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (430, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (431, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (431, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (432, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (432, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (434, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (434, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (435, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (435, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (433, 'IC_taxpart');
INSERT INTO account_link (account_id, description)
     VALUES (433, 'IC_taxservice');
INSERT INTO account_link (account_id, description)
     VALUES (317, 'AR_paid');
INSERT INTO account_link (account_id, description)
     VALUES (317, 'AP_paid');
INSERT INTO account_link (account_id, description)
     VALUES (318, 'AR_paid');
INSERT INTO account_link (account_id, description)
     VALUES (318, 'AP_paid');
INSERT INTO account_link (account_id, description)
     VALUES (319, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (319, 'AR_paid');
INSERT INTO account_link (account_id, description)
     VALUES (319, 'AP_amount');
INSERT INTO account_link (account_id, description)
     VALUES (319, 'AP_paid');
INSERT INTO account_link (account_id, description)
     VALUES (320, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (320, 'AR_paid');
INSERT INTO account_link (account_id, description)
     VALUES (320, 'AP_amount');
INSERT INTO account_link (account_id, description)
     VALUES (320, 'AP_paid');
INSERT INTO account_link (account_id, description)
     VALUES (321, 'AR_amount');
INSERT INTO account_link (account_id, description)
     VALUES (321, 'AR_paid');
INSERT INTO account_link (account_id, description)
     VALUES (321, 'AP_amount');
INSERT INTO account_link (account_id, description)
     VALUES (321, 'AP_paid');


-- TAX DEFINITION
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('435', '0.21', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('432', '0.21', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('306', '0.21', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('433', '0.04', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('430', '0.04', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('304', '0.04', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('305', '0.1', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('434', '0.1', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('431', '0.1', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('300', '0.21', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('423', '0.21', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('420', '0.21', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('421', '0.04', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('418', '0.04', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('298', '0.04', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('299', '0.1', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('422', '0.1', '0', NULL, '',
             'infinity', '0', 1);
INSERT INTO tax (chart_id, rate, minvalue, maxvalue, taxnumber,
                 validto, pass, taxmodule_id)
     VALUES ('419', '0.1', '0', NULL, '',
             'infinity', '0', 1);


-- SET UP DEFAULTS
INSERT INTO defaults (setting_key, value)
     VALUES ('curr', 'EUR');
INSERT INTO defaults (setting_key, value)
     VALUES ('inventory_accno_id', '282');
INSERT INTO defaults (setting_key, value)
     VALUES ('income_accno_id', '338');
INSERT INTO defaults (setting_key, value)
     VALUES ('expense_accno_id', '328');
INSERT INTO defaults (setting_key, value)
     VALUES ('fxgain_accno_id', '346');
INSERT INTO defaults (setting_key, value)
     VALUES ('fxloss_accno_id', '334');

-- END of transaction
COMMIT;
