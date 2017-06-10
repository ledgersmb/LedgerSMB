begin;
-- General Brazilien Portuguese COA
-- sample only
SELECT account_heading_save(NULL, '1000', 'RECURSOS ATUAIS', NULL);
SELECT account__save(NULL,'1060','Checando Cliente','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT account__save(NULL,'1065','Caixa Baixo','A','', NULL, false, false, string_to_array('AR_paid:AP_paid', ':'), false, false);
SELECT cr_coa_to_account_save(accno, accno || '--' || description)
FROM account WHERE accno in ('1060', '1065');

SELECT account__save(NULL,'1200','Contas a Receber','A','', NULL, false, false, string_to_array('AR', ':'), false, false);
SELECT account__save(NULL,'1205','Provisão para devedors duvidosos','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '1500', 'INVENTÁRIO DE CLIENTES', NULL);
SELECT account__save(NULL,'1520','Inventário / Geral','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1530','Inventário / Mercado Secundário','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account__save(NULL,'1540','Inventário / Computer Parts','A','', NULL, false, false, string_to_array('IC', ':'), false, false);
SELECT account_heading_save(NULL, '1800', 'CAPITAL ASSETS', NULL);
SELECT account__save(NULL,'1820','Escritório Móvel & Equipamentos','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1825','Accum. Amort. -Móvel. & Equip.','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1840','Veículo','A','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'1845','Accum. Amort. -Veículo','A','', NULL, true, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2000', 'BALANÇO ATUAL', NULL);
SELECT account__save(NULL,'2100','Contas a Pagar','L','', NULL, false, false, string_to_array('AP', ':'), false, false);
SELECT account__save(NULL,'2170','Taxas federais','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2310','VAT (7%)','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2320','VAT (8%)','L','', NULL, false, false, string_to_array('AR_tax:AP_tax:IC_taxpart:IC_taxservice', ':'), false, false);
SELECT account__save(NULL,'2380','Contas a pagar de férias','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2400', 'DEDUÇÕES DE FOLHA DE PAGAMENTO', NULL);
SELECT account__save(NULL,'2450','Imposto de Renda Devido','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '2600', 'Passivi exigível a longo prazo', NULL);
SELECT account__save(NULL,'2620','Empréstimo bancário','L','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'2680','Empréstimo de Acionistas','L','', NULL, false, false, string_to_array('AP_paid', ':'), false, false);
SELECT account_heading_save(NULL, '3300', 'DIVISÃO DE CAPITAL', NULL);
SELECT account__save(NULL,'3350','Divisão comum','Q','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '4000', 'VENDAS RECEITAS', NULL);
SELECT account__save(NULL,'4020','Vendas Gerais','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4030','Partes para mercado secundário','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account__save(NULL,'4040','Parte Computacional','I','', NULL, false, false, string_to_array('AR_amount:IC_sale', ':'), false, false);
SELECT account_heading_save(NULL, '4300', 'CONSULTANDO FONTES DE RENDA', NULL);
SELECT account__save(NULL,'4320','Consultando','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4330','Programando','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account__save(NULL,'4340','Loja','I','', NULL, false, false, string_to_array('AR_amount:IC_income', ':'), false, false);
SELECT account_heading_save(NULL, '4400', 'OUTRAS RENDAS', NULL);
SELECT account__save(NULL,'4430','Transporte & Taxa','I','', NULL, false, false, string_to_array('IC_income', ':'), false, false);
SELECT account__save(NULL,'4440','Juros Acumulados','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'4450','Ganho de câmbio estrangeiro','I','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5000', 'CUSTO DE VENDAS DE PRODUTOS', NULL);
SELECT account__save(NULL,'5010','Compras','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs:IC_expense', ':'), false, false);
SELECT account__save(NULL,'5050','Mercado Secundário','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5060','Parte Computacional','E','', NULL, false, false, string_to_array('AP_amount:IC_cogs', ':'), false, false);
SELECT account__save(NULL,'5100','Frete','E','', NULL, false, false, string_to_array('AP_amount:IC_expense', ':'), false, false);
SELECT account_heading_save(NULL, '5400', 'DESPESAS E FOLHA DE PAGAMENTO', NULL);
SELECT account__save(NULL,'5410','Salários','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account_heading_save(NULL, '5600', 'GERAL E DESPESAS ADMINISTRATIVAS', NULL);
SELECT account__save(NULL,'5610','Contabilidade & Leis','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5615','Publicidade & Promoções','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5620','Balanço','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5660','Amortização','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5680','Imposto de Renda','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5685','Seguro','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5690','Interesses & Encargos Bancários','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5700','Materiais de Escritório','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5760','Aluguel','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5765','Manutenção & Reparos','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5780','Telefone','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5785','Cursos & Entretenimentos','E','', NULL, false, false, string_to_array('', ':'), false, false);
SELECT account__save(NULL,'5790','Serviços Públicos','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5800','Licenciamento para exportações','E','', NULL, false, false, string_to_array('AP_amount', ':'), false, false);
SELECT account__save(NULL,'5810','Troca com Estrangeiro','E','', NULL, false, false, string_to_array('', ':'), false, false);
--
insert into tax (chart_id,rate) values ((select id from account where accno = '2310'),0.07);
insert into tax (chart_id,rate) values ((select id from account where accno = '2320'),0.08);
--
INSERT INTO defaults (setting_key, value) VALUES ('inventory_accno_id', (select id from account where accno = '1520'));

 INSERT INTO defaults (setting_key, value) VALUES ('income_accno_id', (select id from account where accno = '4020'));

 INSERT INTO defaults (setting_key, value) VALUES ('expense_accno_id', (select id from account where accno = '5010'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxgain_accno_id', (select id from account where accno = '4450'));

 INSERT INTO defaults (setting_key, value) VALUES ('fxloss_accno_id', (select id from account where accno = '5810'));

 INSERT INTO defaults (setting_key, value) VALUES ('curr', 'R  :EUR:USD');

 INSERT INTO defaults (setting_key, value) VALUES ('weightunit', 'kg');
--
commit;
UPDATE account
   SET tax = true
WHERE id
   IN (SELECT account_id
       FROM account_link
       WHERE description LIKE '%_tax');

