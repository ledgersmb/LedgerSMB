begin;
--
-- LedgerSMB Sample COA - Paraguay
-- Version: 2.4.6
-- Submitted by: Mario L. Epp
-- Date: 2005-01-03
--
--

SELECT account_heading_save(NULL, '1.000', 'ACTIVO', NULL);
SELECT account_heading_save(NULL, '1.110', 'DISPONIBLE', NULL);
SELECT account_heading_save(NULL, '1.111', 'Caja', NULL);
SELECT account_heading_save(NULL, '1.112', 'Bancos', NULL);
SELECT account_heading_save(NULL, '1.120', 'VALORES NEGOCIABLES / INVERSIONES TRANSITORIAS', NULL);
SELECT account_heading_save(NULL, '1.130', 'CRÉDITOS', NULL);
SELECT account_heading_save(NULL, '1.140', 'BIENES DE CAMBIO', NULL);
SELECT account_heading_save(NULL, '1.150', 'OTROS ACTIVOS CORRIENTES', NULL);
SELECT account_heading_save(NULL, '1.200', 'REALIZABLE A LARGO PLAZO', NULL);
SELECT account_heading_save(NULL, '1.210', 'INVERSIONES PERMANENTES', NULL);
SELECT account_heading_save(NULL, '1.220', 'CRÉDITOS', NULL);
SELECT account_heading_save(NULL, '1.300', 'ACTIVO FIJO', NULL);
SELECT account_heading_save(NULL, '1.310', 'MUEBLES, ÚTILES Y ENSERES', NULL);
SELECT account_heading_save(NULL, '1.311', 'MUEBLES Y EQUIPOS', NULL);
SELECT account_heading_save(NULL, '1.312', 'ÚTILES Y ENSERES', NULL);
SELECT account_heading_save(NULL, '1.320', 'MAQUINARIAS, HERRAMIENTAS Y EQUIPOS', NULL);
SELECT account_heading_save(NULL, '1.321', 'MAQUINARIAS', NULL);
SELECT account_heading_save(NULL, '1.322', 'HERRAMIENTAS Y EQUIPOS', NULL);
SELECT account_heading_save(NULL, '1.323', 'EQUIPOS INFORMÁTICOS', NULL);
SELECT account_heading_save(NULL, '1.330', 'TRANSPORTE TERRESTRE', NULL);
SELECT account_heading_save(NULL, '1.331', 'AUTOS, CAMIONETAS, CAMIONES O ACOPLADOS', NULL);
SELECT account_heading_save(NULL, '1.332', 'MOTOCICLETAS, TRICICLOS Y BICICLETAS', NULL);
SELECT account_heading_save(NULL, '1.333', 'BIENES PARA TRANSPORTE TERRESTRE', NULL);
SELECT account_heading_save(NULL, '1.340', 'TRANSPORTE AÉREO', NULL);
SELECT account_heading_save(NULL, '1.341', 'AVIONES Y MATERIAL DE VUELO', NULL);
SELECT account_heading_save(NULL, '1.342', 'INSTALACIONES DE TIERRA', NULL);
SELECT account_heading_save(NULL, '1.350', 'TRANSPORTE MARÍTIMO Y FLUVIAL', NULL);
SELECT account_heading_save(NULL, '1.351', 'EMBARCACIONES EN GENERAL', NULL);
SELECT account_heading_save(NULL, '1.352', 'CANOAS, BOTES Y DEMÁS BIENES', NULL);
SELECT account_heading_save(NULL, '1.360', 'TRANSPORTE FERROVIARIO', NULL);
SELECT account_heading_save(NULL, '1.361', 'MATERIALES RODANTES', NULL);
SELECT account_heading_save(NULL, '1.362', 'VÍAS Y DEMÁS BIENES', NULL);
SELECT account_heading_save(NULL, '1.370', 'INMUEBLES', NULL);
SELECT account_heading_save(NULL, '1.371', 'CONSTRUCCIONES EN INMUEBLES URBANOS', NULL);
SELECT account_heading_save(NULL, '1.372', 'CONSTRUCCIONES EN INMUEBLES RURALES', NULL);
SELECT account_heading_save(NULL, '1.373', 'CONSTRUCCIONES EN INMUEBLES AJENOS', NULL);
SELECT account_heading_save(NULL, '1.381', 'RESTANTES BIENES', NULL);
SELECT account_heading_save(NULL, '1.390', 'BIENES INTANGIBLES', NULL);
SELECT account_heading_save(NULL, '2.000', 'PASIVO', NULL);
SELECT account_heading_save(NULL, '2.100', 'CIRCULANTE', NULL);
SELECT account_heading_save(NULL, '2.110', 'DEUDAS', NULL);
SELECT account_heading_save(NULL, '2.150', 'PROVISIONES', NULL);
SELECT account_heading_save(NULL, '2.200', 'EXIGIBLE A LARGO PLAZO', NULL);
SELECT account_heading_save(NULL, '2.210', 'DEUDAS', NULL);
SELECT account_heading_save(NULL, '2.220', 'PREVISIONES', NULL);
SELECT account_heading_save(NULL, '3.000', 'PATRIMONIO NETO', NULL);
SELECT account_heading_save(NULL, '3.100', 'CAPITAL', NULL);
SELECT account_heading_save(NULL, '3.200', 'RESERVAS', NULL);
SELECT account_heading_save(NULL, '3.300', 'RESULTADOS', NULL);
SELECT account_heading_save(NULL, '4.000', 'INGRESOS', NULL);
SELECT account_heading_save(NULL, '4.100', 'INGRESOS OPERATIVOS', NULL);
SELECT account_heading_save(NULL, '4.200', 'INGRESOS NO OPERATIVOS', NULL);
SELECT account_heading_save(NULL, '4.300', 'INGRESOS EXTRAORDINARIOS', NULL);
SELECT account_heading_save(NULL, '5.000', 'EGRESOS', NULL);
SELECT account_heading_save(NULL, '5.100', 'EGRESOS OPERATIVOS', NULL);
SELECT account_heading_save(NULL, '5.110', 'COSTO DE MERCADERÍAS VENDIDAS', NULL);
SELECT account_heading_save(NULL, '5.120', 'COSTO DE SERVICIOS VENDIDOS', NULL);
SELECT account_heading_save(NULL, '5.130', 'GASTOS DE VENTAS', NULL);
SELECT account_heading_save(NULL, '5.140', 'GASTOS DE ADMINISTRACIÓN', NULL);
SELECT account_heading_save(NULL, '5.150', 'GASTOS FINANCIEROS', NULL);
SELECT account_heading_save(NULL, '5.200', 'EGRESOS NO OPERATIVOS', NULL);
SELECT account_heading_save(NULL, '5.300', 'EGRESOS EXTRAORDINARIOS', NULL);


SELECT account__save(NULL, '1.111.01', 'Recaudaciones a depositar', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.111.02', 'Fondo fijo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.111.03', 'Valores a depositar', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.111.04', 'Monedas extranjeras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.112.01', 'Cuenta Corriente', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.112.02', 'Caja de Ahorro', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.120.01', 'Títulos y acciones', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.120.02', 'Títulos públicos', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.120.03', 'Depósito a plazo fijo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.120.04', 'Previsión fluctuaciones y desvalorizaciones (regularizadora)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.131', 'Créditos por ventas', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.132', 'Otros créditos', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.141', 'Mercaderías de reventa', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.142', 'Mercaderías en proceso de producción', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.151', 'Muestras y otros materiales de propaganda', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.152', 'Combustibles', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.153', 'Repuestos', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.154', 'Embalajes y envases', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.155', 'Materiales de oficina', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.156', 'Materiales diversos', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.211', 'Títulos públicos', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.212', 'Debenturas', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.213', 'Inversiones en otras empresas', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.214', 'Previsión fluctuaciones y desvalorzaciones', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.221', 'Créditos por ventas', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.222', 'Otros créditos', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.311.01', 'Muebles y equipos - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.311.02', 'Muebles y equipos - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.311.03', 'Muebles y equipos - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.311.04', 'Muebles y equipos - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.312.01', 'Útiles y enseres - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.312.02', 'Útiles y enseres - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.312.03', 'Útiles y enseres - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.312.04', 'Útiles y enseres - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.321.01', 'Maquinarias - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.321.02', 'Maquinarias - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.321.03', 'Maquinarias - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.321.04', 'Maquinarias - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.322.01', 'Herramientas y Equipos - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.322.02', 'Herramientas y Equipos - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.322.03', 'Herramientas y Equipos - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.322.04', 'Herramientas y Equipos - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.323.01', 'Equipos informáticos - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.323.02', 'Equipos informáticos - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.323.03', 'Equipos informáticos - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.323.04', 'Equipos informáticos - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.331.01', 'Autos, camionetas, camiones o acoplados - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.331.02', 'Autos, camionetas, camiones o acoplados - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.331.03', 'Autos, camionetas, camiones o acoplados - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.331.04', 'Autos, camionetas, camiones o acoplados - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.332.01', 'Motocicletas, triciclos y bicicletas - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.332.02', 'Motocicletas, triciclos y bicicletas - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.332.03', 'Motocicletas, triciclos y bicicletas - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.332.04', 'Motocicletas, triciclos y bicicletas - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.333.01', 'Bienes para transporte terrestre - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.333.02', 'Bienes para transporte terrestre - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.333.03', 'Bienes para transporte terrestre - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.333.04', 'Bienes para transporte terrestre - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.341.01', 'Aviones y material de vuelo - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.341.02', 'Aviones y material de vuelo - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.341.03', 'Aviones y material de vuelo - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.341.04', 'Aviones y material de vuelo - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.342.01', 'Instalaciones de tierra - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.342.02', 'Instalaciones de tierra - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.342.03', 'Instalaciones de tierra - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.342.04', 'Instalaciones de tierra - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.351.01', 'Embarcaciones en general - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.351.02', 'Embarcaciones en general - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.351.03', 'Embarcaciones en general - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.351.04', 'Embarcaciones en general - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.352.01', 'Canoas, botes y demás bienes - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.352.02', 'Canoas, botes y demás bienes - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.352.03', 'Canoas, botes y demás bienes - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.352.04', 'Canoas, botes y demás bienes - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.361.01', 'Materiales rodantes - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.361.02', 'Materiales rodantes - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.361.03', 'Materiales rodantes - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.361.04', 'Materiales rodantes - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.362.01', 'Vías y demás bienes - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.362.02', 'Vías y demás bienes - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.362.03', 'Vías y demás bienes - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.362.04', 'Vías y demás bienes - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.371.01', 'Construcciones en inmuebles urbanos - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.371.02', 'Construcciones en inmuebles urbanos - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.371.03', 'Construcciones en inmuebles urbanos - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.371.04', 'Construcciones en inmuebles urbanos - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.372.01', 'Construcciones en inmuebles rurales - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.372.02', 'Construcciones en inmuebles rurales - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.372.03', 'Construcciones en inmuebles rurales - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.372.04', 'Construcciones en inmuebles rurales - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.373.01', 'Construcciones en inmuebles ajenos - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.373.02', 'Construcciones en inmuebles ajenos - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.373.03', 'Construcciones en inmuebles ajenos - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.373.04', 'Construcciones en inmuebles ajenos - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.381.01', 'Restantes bienes - Costo de origen', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.381.02', 'Restantes bienes - Mejoras', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.381.03', 'Restantes bienes - Revalúo', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.381.04', 'Restantes bienes - (Depreciaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.391', 'Llave de negocio', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.392', 'Marcas registradas', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.393', 'Concesiones', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.394', 'Patente de invención', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.395', 'Gastos de constitución y organización', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.396', 'Gastos de reorganización', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.397', 'Gastos de proyectos de inversión', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.398', 'Gastos de desarrollo e investigación', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '1.399', '(Amortizaciones acumuladas)', 'A', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.111', 'Acreedores por compras', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.112', 'Deudas bancarias y financieras', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.113', 'Otras deudas', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.151', 'IVA a pagar', 'L', '', NULL, false, false, string_to_array('AR_tax', ':'), false, false);
SELECT account__save(NULL, '2.211', 'Acreedores por compras', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.212', 'Deudas bancarias y financieras', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.213', 'Otras deudas', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.221', 'Previsición para indemnización por despidos', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '2.222', 'Previsición para indemnización por accidente', 'L', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '3.210', 'Reserva legal', 'Q', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '3.220', 'Reserva de revalúo', 'Q', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '3.230', 'Prima de emisión', 'Q', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '3.240', 'Reserva estatutaria', 'Q', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '3.310', 'Resultados acumulados', 'Q', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '3.320', 'Resultados del ejercicio', 'Q', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.110', 'Venta de mercadrías', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.120', 'Venta de servicios', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.130', 'Otros ingresos operativos', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.130.01', 'Intereses ganados', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.130.02', 'Descuentos obtenidos', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.130.03', 'Comisiones obtenidas', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.210', 'Utilidad en venta de bienes de uso', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.220', 'Alquileres ganados', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.230', 'Incobrables recuperados', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.240', 'Utilidad en venta de bienes intangibles', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.250', 'Utilidades varias', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.310', 'Utilidad en venta de bienes de uso', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.320', 'Donaciones y premios', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.330', 'Premios', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '4.340', 'Diferencias de cambios positivos', 'I', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.110.01', 'Costo de ventas sección 1', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.110.20', 'Costo de ventas producto 1', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.110.40', 'Costo de ventas diversas', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.110.60', 'Costo de ventas productos elaborados', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.120.01', 'Costo de servicios', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.130.01', 'Comisiones sobre ventas', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.130.02', 'Publicidad y propaganda', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.130.03', 'Gastos de viajes', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.130.04', 'Gastos de exportación', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.130.05', 'Otros gastos de ventas', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.01', 'Aguinaldos', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.02', 'Alquileres pagados', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.03', 'Depreciación bienes de uso', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.04', 'Depreciación bienes intangibles', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.05', 'Bonificación familiar', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.06', 'Créditos incobrables', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.07', 'Aporte patronal sobre salarios', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.08', 'Fletes y acarreos', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.09', 'Luz, teléfono y agua', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.10', 'Impuestos, tasas y contribuciones', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.11', 'Seguros', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.12', 'Gastos de útiles e impresos', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.13', 'Sueldos y jornales', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.14', 'Remuneración personal superior', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.15', 'Honorarios profesionales', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.16', 'Gastos de representación', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.17', 'Gastos de cobranza', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.18', 'Gastos judiciales', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.140.19', 'Otros gastos de administración', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.150.01', 'Intereses pagados', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.150.02', 'Gastos bancarios', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.150.03', 'Otros gastos financieros', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.210', 'Bajas bienes de uso', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.220', 'Gastos inmuebles alquileres', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.230', 'Pérdidas en ventas bienes de uso', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.240', 'Otros resultados negativos no operativos', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.310', 'Pérdidas en ventas bienes de uso', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.320', 'Donaciones y contribuciones negativas', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.330', 'Indemnizaciones a terceros', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.340', 'Diferencias de cambios negativos', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL, '5.350', 'Otros resultados negativos extraordinarios', 'E', '', NULL, false, false, string_to_array('', ':'), false, false);

--
INSERT INTO tax (chart_id,rate) VALUES ((select id from account where accno = '2.151'),'0.1');
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id',
                (select id from account where accno = '1.141'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4.110'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5.110.01'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4.340'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5.340'));


INSERT INTO currency (curr, description)
   VALUES
      ('PYG', 'PYG'),
      ('USD', 'USD'),
      ('EUR', 'EUR');
INSERT INTO defaults (setting_key, value) VALUES ('curr', 'PYG');


 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');
