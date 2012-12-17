--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

ALTER TABLE ONLY public.menu_node DROP CONSTRAINT menu_node_parent_fkey;
ALTER TABLE ONLY public.menu_attribute DROP CONSTRAINT menu_attribute_node_id_fkey;
ALTER TABLE ONLY public.menu_node DROP CONSTRAINT menu_node_pkey;
ALTER TABLE ONLY public.menu_node DROP CONSTRAINT menu_node_parent_key;
ALTER TABLE ONLY public.menu_attribute DROP CONSTRAINT menu_attribute_pkey;
ALTER TABLE public.menu_node ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.menu_attribute ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE public.menu_node_id_seq;
DROP TABLE public.menu_node;
DROP SEQUENCE public.menu_attribute_id_seq;
DROP TABLE public.menu_attribute;
SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: menu_attribute; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE menu_attribute (
    node_id integer NOT NULL,
    attribute character varying NOT NULL,
    value character varying NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.menu_attribute OWNER TO postgres;

--
-- Name: TABLE menu_attribute; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE menu_attribute IS ' This table stores the callback information for each menu item.  The 
attributes are stored in key/value modelling because of the fact that this
best matches the semantic structure of the information.

Each node should have EITHER a menu or a module attribute, menu for a menu with 
sub-items, module for an executiable script.  The module attribute identifies
the perl script to be run.  The action attribute identifies the entry point.

Beyond this, any other attributes that should be passed in can be done as other
attributes.
';


--
-- Name: menu_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_attribute_id_seq OWNER TO postgres;

--
-- Name: menu_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_attribute_id_seq OWNED BY menu_attribute.id;


--
-- Name: menu_attribute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_attribute_id_seq', 681, true);


--
-- Name: menu_node; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE menu_node (
    id integer NOT NULL,
    label character varying NOT NULL,
    parent integer,
    "position" integer NOT NULL
);


ALTER TABLE public.menu_node OWNER TO postgres;

--
-- Name: TABLE menu_node; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE menu_node IS 'This table stores the tree structure of the menu.';


--
-- Name: menu_node_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE menu_node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_node_id_seq OWNER TO postgres;

--
-- Name: menu_node_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE menu_node_id_seq OWNED BY menu_node.id;


--
-- Name: menu_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('menu_node_id_seq', 253, true);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_attribute ALTER COLUMN id SET DEFAULT nextval('menu_attribute_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_node ALTER COLUMN id SET DEFAULT nextval('menu_node_id_seq'::regclass);


--
-- Data for Name: menu_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY menu_attribute (node_id, attribute, value, id) FROM stdin;
205	menu	1	574
1	menu	1	1
2	module	ar.pl	2
2	action	add	3
3	action	add	4
3	module	is.pl	5
3	type	invoice	6
4	menu	1	7
12	action	add	29
21	menu	1	50
22	action	add	52
22	module	ap.pl	51
23	action	add	53
23	type	invoice	55
23	module	ir.pl	54
24	menu	1	56
35	menu	1	83
36	module	payment.pl	84
36	action	payment	85
36	type	receipt	86
36	account_class	2	551
37	module	payment.pl	87
37	account_class	2	89
37	action	use_overpayment	88
223	module	payment.pl	607
223	account_class	1	608
223	action	use_overpayment	609
38	module	payment.pl	90
38	action	payment	91
38	type	check	92
194	module	ar.pl	538
194	action	add	539
40	module	gl.pl	96
40	action	add	97
40	transfer	1	98
41	menu	1	99
44	report	1	110
46	menu	1	111
47	menu	1	112
48	module	employee.pl	113
48	action	add	114
50	menu	1	119
51	module	oe.pl	120
51	action	add	121
51	type	sales_order	122
52	module	oe.pl	123
52	action	add	124
52	type	purchase_order	125
53	menu	1	126
54	module	oe.pl	127
54	type	sales_order	129
54	action	search	128
55	module	oe.pl	130
55	type	purchase_order	132
55	action	search	131
56	menu	1	133
57	module	oe.pl	134
57	action	search	136
58	module	oe.pl	137
58	action	search	139
57	type	generate_sales_order	135
58	type	generate_purchase_order	138
60	menu	1	550
61	module	oe.pl	140
61	action	search	141
62	module	oe.pl	143
62	action	search	144
62	type	consolidate_purchase_order	145
61	type	consolidate_sales_order	142
63	menu	1	146
64	module	oe.pl	147
64	action	search	148
65	module	oe.pl	150
65	action	search	151
66	module	oe.pl	153
66	action	search_transfer	154
67	menu	1	155
68	module	oe.pl	156
68	action	add	157
69	module	oe.pl	159
69	action	add	160
68	type	sales_quotation	158
69	type	request_quotation	161
70	menu	1	162
71	module	oe.pl	163
71	type	sales_quotation	165
71	action	search	164
72	module	oe.pl	166
7	module	reports.pl	15
64	type	ship_order	149
7	action	start_report	16
7	report_name	aging	17
27	module	reports.pl	63
27	report_name	aging	65
12	module	contact.pl	28
14	action	start_report	36
14	module	reports.pl	32
14	module_name	gl	27
15	action	start_report	33
15	report_name	purchase_history	37
34	action	start_report	81
34	report_name	purchase_history	82
34	module	reports.pl	80
5	action	start_report	9
25	action	start_report	58
72	action	search	168
72	type	request_quotation	167
73	menu	1	169
74	module	gl.pl	170
74	action	add	171
77	menu	1	182
78	module	ic.pl	183
78	action	add	184
78	item	part	185
79	module	ic.pl	186
206	module	reports.pl	575
206	action	start_report	576
38	account_class	1	39
49	action	begin_report	117
49	module	reports.pl	118
79	action	add	187
79	item	service	188
80	module	ic.pl	189
80	action	add	190
81	module	ic.pl	192
81	action	add	193
81	item	labor	194
80	item	assembly	191
82	action	add	195
82	module	pe.pl	196
83	action	add	198
83	module	pe.pl	199
84	module	ic.pl	202
5	module	invoice.pl	8
25	module	invoice.pl	57
5	report_name	invoice_search	10
25	report_name	invoice_search	59
42	module	payment.pl	100
42	action	get_search_criteria	101
42	account_class	2	102
43	action	get_search_criteria	104
43	module	payment.pl	103
43	account_class	1	105
84	action	stock_assembly	203
85	menu	1	204
86	module	ic.pl	205
86	action	search	610
86	searchitems	all	611
87	module	ic.pl	612
87	action	search	206
87	searchitems	part	210
88	module	ic.pl	211
88	action	requirements	212
89	action	search	213
89	module	ic.pl	214
89	searchitems	service	215
90	action	search	216
90	module	ic.pl	217
90	searchitems	labor	218
91	module	pe.pl	221
91	action	search	220
92	module	pe.pl	224
92	action	search	223
93	action	search	226
93	module	ic.pl	227
93	searchitems	assembly	228
94	action	search	229
94	module	ic.pl	230
94	searchitems	component	231
95	menu	1	232
96	module	pe.pl	233
96	action	translation	234
96	translation	description	235
97	module	pe.pl	236
97	action	translation	237
97	translation	partsgroup	238
98	menu	1	239
99	module	pe.pl	240
99	action	add	241
99	type	project	242
100	module	jc.pl	243
100	action	add	244
99	project	project	245
100	project	project	246
100	type	timecard	247
101	menu	1	248
102	module	pe.pl	249
102	action	project_sales_order	250
103	menu	1	255
104	module	pe.pl	256
104	type	project	258
104	action	search	257
106	module	jc.pl	263
106	action	search	264
106	type	timecard	265
106	project	project	266
107	menu	1	268
108	module	pe.pl	269
108	action	translation	270
108	translation	project	271
109	menu	1	272
110	action	chart_of_accounts	274
113	action	report	281
113	module	rp.pl	282
113	report	balance_sheet	283
114	action	report	284
114	module	rp.pl	285
114	report	inv_activity	286
115	action	recurring_transactions	287
115	module	am.pl	288
116	menu	1	289
119	module	bp.pl	290
119	action	search	291
119	type	check	292
119	vc	vendor	293
117	module	bp.pl	294
117	action	search	295
117	vc	customer	297
118	module	bp.pl	298
118	action	search	299
118	vc	customer	300
120	module	bp.pl	302
120	action	search	303
120	vc	customer	304
121	module	bp.pl	306
121	action	search	307
121	vc	customer	308
122	module	bp.pl	310
122	action	search	311
122	vc	customer	312
120	type	work_order	305
121	type	sales_quotation	309
122	type	packing_list	313
123	module	bp.pl	314
123	action	search	315
123	vc	customer	316
123	type	pick_list	317
124	module	bp.pl	318
124	action	search	319
124	vc	vendor	321
124	type	purchase_order	320
125	module	bp.pl	322
125	action	search	323
125	vc	vendor	325
126	module	bp.pl	326
126	action	search	327
126	vc	vendor	329
127	module	bp.pl	330
127	action	search	331
127	type	timecard	332
125	type	bin_list	324
76	module	reports.pl	180
76	action	start_report	181
117	type	invoice	296
118	type	sales_order	301
110	module	journal.pl	273
126	type	request_quotation	328
127	vc	employee	333
128	menu	1	334
130	module	am.pl	338
130	taxes	audit_control	341
130	action	taxes	343
132	module	account.pl	346
132	action	yearend_info	347
139	module	am.pl	357
140	module	am.pl	358
139	action	add_gifi	361
140	action	list_gifi	362
141	menu	1	363
142	module	am.pl	364
143	module	am.pl	365
142	action	add_warehouse	366
131	module	configuration.pl	339
111	report_name	trial_balance	277
111	action	start_report	275
131	action	defaults_screen	342
143	action	list_warehouse	367
144	module	business_unit.pl	368
144	action	list_classes	370
147	menu	1	372
148	module	am.pl	373
149	module	am.pl	374
112	action	start_report	278
112	module	reports.pl	279
112	report_name	income_statement	280
148	action	add_business	375
149	action	list_business	376
150	menu	1	377
151	module	am.pl	378
152	module	am.pl	379
151	action	add_language	380
152	action	list_language	381
153	menu	1	382
154	module	am.pl	383
155	module	am.pl	384
154	action	add_sic	385
155	action	list_sic	386
156	menu	1	387
157	module	am.pl	388
158	module	am.pl	389
159	module	am.pl	390
160	module	am.pl	391
161	module	am.pl	392
162	module	am.pl	393
163	module	am.pl	394
164	module	am.pl	395
165	module	am.pl	396
166	module	am.pl	397
167	module	am.pl	398
168	module	am.pl	399
169	module	am.pl	400
170	module	am.pl	401
171	module	am.pl	402
241	module	am.pl	642
157	action	list_templates	403
158	action	list_templates	404
159	action	list_templates	405
160	action	list_templates	406
161	action	list_templates	407
162	action	list_templates	408
163	action	list_templates	409
164	action	list_templates	410
165	action	list_templates	411
166	action	list_templates	412
167	action	list_templates	413
168	action	list_templates	414
169	action	list_templates	415
170	action	list_templates	416
171	action	list_templates	417
241	action	list_templates	643
157	template	income_statement	418
158	template	balance_sheet	419
159	template	invoice	420
160	template	ar_transaction	421
161	template	ap_transaction	422
162	template	packing_list	423
163	template	pick_list	424
164	template	sales_order	425
165	template	work_order	426
166	template	purchase_order	427
167	template	bin_list	428
168	template	statement	429
169	template	quotation	430
170	template	rfq	431
171	template	timecard	432
241	template	letterhead	644
157	format	HTML	433
158	format	HTML	434
159	format	HTML	435
160	format	HTML	436
161	format	HTML	437
162	format	HTML	438
163	format	HTML	439
164	format	HTML	440
165	format	HTML	441
166	format	HTML	442
167	format	HTML	443
168	format	HTML	444
169	format	HTML	445
170	format	HTML	446
171	format	HTML	447
241	format	HTML	645
172	menu	1	448
173	action	list_templates	449
174	action	list_templates	450
175	action	list_templates	451
176	action	list_templates	452
177	action	list_templates	453
178	action	list_templates	454
179	action	list_templates	455
180	action	list_templates	456
181	action	list_templates	457
182	action	list_templates	458
183	action	list_templates	459
184	action	list_templates	460
185	action	list_templates	461
186	action	list_templates	462
187	action	list_templates	463
242	action	list_templates	646
173	module	am.pl	464
174	module	am.pl	465
175	module	am.pl	466
176	module	am.pl	467
177	module	am.pl	468
178	module	am.pl	469
179	module	am.pl	470
180	module	am.pl	471
181	module	am.pl	472
182	module	am.pl	473
183	module	am.pl	474
184	module	am.pl	475
185	module	am.pl	476
186	module	am.pl	477
187	module	am.pl	478
242	module	am.pl	647
173	format	LATEX	479
174	format	LATEX	480
175	format	LATEX	481
176	format	LATEX	482
177	format	LATEX	483
178	format	LATEX	484
179	format	LATEX	485
180	format	LATEX	486
181	format	LATEX	487
182	format	LATEX	488
183	format	LATEX	489
184	format	LATEX	490
185	format	LATEX	491
186	format	LATEX	492
187	format	LATEX	493
242	format	LATEX	648
173	template	invoice	506
174	template	ar_transaction	507
175	template	ap_transaction	508
176	template	packing_list	509
177	template	pick_list	510
178	template	sales_order	511
179	template	work_order	512
180	template	purchase_order	513
181	template	bin_list	514
182	template	statement	515
185	template	quotation	518
186	template	rfq	519
187	template	timecard	520
183	template	check	516
184	template	receipt	517
242	template	letterhead	649
188	menu	1	521
189	module	am.pl	522
189	action	list_templates	523
189	template	pos_invoice	524
189	format	TEXT	525
190	action	display_stylesheet	526
190	module	am.pl	527
193	module	login.pl	532
193	action	logout	533
193	target	_top	534
192	new	1	531
0	menu	1	535
136	menu	1	536
195	action	add	540
195	module	is.pl	541
196	action	add	543
196	module	ap.pl	544
197	action	add	545
197	module	ir.pl	547
196	type	debit_note	549
194	type	credit_note	548
195	type	credit_invoice	542
197	type	debit_invoice	546
202	batch_type	payment_reversal	570
204	batch_type	receipt_reversal	573
200	menu	1	552
198	action	create_batch	554
198	module	vouchers.pl	553
199	module	vouchers.pl	559
199	action	create_batch	560
201	module	vouchers.pl	562
201	action	create_batch	563
203	module	vouchers.pl	565
203	action	create_batch	566
202	module	vouchers.pl	568
202	action	create_batch	569
204	module	vouchers.pl	571
204	action	create_batch	572
201	batch_type	payment	564
199	batch_type	ap	561
45	module	recon.pl	106
45	action	new_report	107
44	module	recon.pl	108
44	action	search	109
211	module	recon.pl	587
211	action	search	588
211	hide_status	1	589
211	approved	0	590
211	submitted	1	591
198	batch_type	ar	555
191	module	user.pl	528
191	action	preference_screen	529
217	menu	1	597
218	action	add_taxform	598
218	module	taxform.pl	599
137	module	account.pl	355
137	action	new	359
219	menu	1	600
220	module	admin.pl	601
220	action	new_user	602
221	module	admin.pl	603
221	action	search_users	604
222	module	admin.pl	605
222	action	list_sessions	606
225	module	taxform.pl	613
225	action	list_all	614
226	module	taxform.pl	615
227	menu	1	616
228	menu	1	617
229	menu	1	618
230	action	asset_category_screen	620
231	action	asset_category_search	622
232	action	asset_screen	624
233	action	asset_search	626
234	module	asset.pl	627
234	action	new_report	628
235	module	asset.pl	630
236	menu	1	632
237	module	asset.pl	633
237	action	display_nbv	634
232	module	asset.pl	623
230	module	asset.pl	619
231	module	asset.pl	621
233	module	asset.pl	625
234	depreciation	1	629
238	action	new_report	636
238	module	asset.pl	635
239	module	asset.pl	637
239	action	search_reports	638
239	depreciation	1	639
240	module	asset.pl	640
240	action	search_reports	641
235	action	begin_import	631
249	menu	1	668
243	module	import_csv.pl	650
243	action	begin_import	651
243	type	ap_multi	652
244	module	import_csv.pl	653
244	action	begin_import	654
244	type	ar_multi	655
245	module	import_csv.pl	656
245	action	begin_import	657
245	type	gl	658
246	module	import_csv.pl	659
246	action	begin_import	660
246	type	chart	661
247	module	import_csv.pl	662
247	action	begin_import	663
247	type	gifi	664
248	module	import_csv.pl	665
248	action	begin_import	666
248	type	sic	667
83	type	pricegroup	200
82	type	partsgroup	197
91	type	partsgroup	222
92	type	pricegroup	225
203	batch_type	receipt	567
250	menu	1	669
7	module_name	gl	671
7	entity_class	2	672
27	entity_class	1	673
76	report_name	gl	530
27	action	start_report	64
27	module_name	gl	674
251	menu	1	675
252	module	budgets.pl	676
253	module	reports.pl	677
252	action	new_budget	678
253	report_name	budget_search	680
253	module_name	gl	681
253	action	start_report	679
76	module_name	gl	670
19	menu	1	11
14	report_name	contact_search	31
20	module	vouchers.pl	72
20	action	create_batch	73
20	batch_type	sales_invoice	74
39	module	vouchers.pl	75
39	action	create_batch	76
39	batch_type	vendor_invoice	77
15	module	reports.pl	35
34	entity_class	1	20
15	entity_class	2	19
5	entity_class	2	12
25	entity_class	1	13
210	module	reports.pl	586
65	type	receive_order	34
49	module_name	gl	115
49	entity_class	3	43
206	module_name	gl	14
206	report_name	unapproved	18
206	search_type	batches	30
210	action	start_report	585
210	module_name	gl	44
210	report_name	unapproved	45
49	report_name	contact_search	116
111	module	reports.pl	276
111	module_name	gl	40
210	search_type	drafts	46
6	menu	1	38
6	module	menu.pl	41
8	module	reports.pl	42
8	action	start_report	47
8	report_name	customer_margin	48
8	module_name	gl	49
11	module	reports.pl	60
11	action	start_report	61
11	report_name	invoice_margin	78
112	module_name	gl	79
9	module	invoice.pl	21
9	action	start_report	22
9	entity_class	2	24
10	module	invoice.pl	25
10	action	start_report	26
10	entity_class	1	67
9	report_name	invoice_outstanding	23
10	report_name	invoice_outstanding	66
\.


--
-- Data for Name: menu_node; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY menu_node (id, label, parent, "position") FROM stdin;
206	Batches	205	1
14	Search	19	2
12	Add Contact	19	3
15	Customer History	4	6
34	Vendor History	24	6
110	Chart of Accounts	73	5
137	Add Accounts	73	6
0	Top-level	\N	0
20	Invoice Vouchers	249	2
2	Add Transaction	1	1
7	AR Aging	4	3
39	Invoice Vouchers	250	2
5	Search	1	7
22	Add Transaction	21	1
27	AP Aging	24	3
25	Search	21	7
36	Receipt	35	1
38	Payment	35	3
223	Use Overpayment	35	4
37	Use AR Overpayment	35	2
42	Receipts	41	1
43	Payments	41	2
44	Reconciliation	41	3
47	Employees	46	1
48	Add Employee	47	1
49	Search	47	2
51	Sales Order	50	1
52	Purchase Order	50	2
53	Reports	50	3
54	Sales Orders	53	1
55	Purchase Orders	53	2
57	Sales Orders	56	1
58	Purchase Orders	56	2
56	Generate	50	4
60	Consolidate	50	5
61	Sales Orders	60	1
62	Purchase Orders	60	2
64	Ship	63	1
65	Receive	63	2
66	Transfer	63	3
68	Quotation	67	1
69	RFQ	67	2
70	Reports	67	3
71	Quotations	70	1
72	RFQs	70	2
74	Journal Entry	73	1
78	Add Part	77	1
79	Add Service	77	2
80	Add Assembly	77	3
81	Add Overhead	77	4
82	Add Group	77	5
83	Add Pricegroup	77	6
84	Stock Assembly	77	7
85	Reports	77	8
86	All Items	85	1
87	Parts	85	2
88	Requirements	85	3
89	Services	85	4
90	Labor	85	5
91	Groups	85	6
92	Pricegroups	85	7
93	Assembly	85	8
94	Components	85	9
95	Translations	77	9
96	Description	95	1
97	Partsgroup	95	2
99	Add Project	98	1
100	Add Timecard	98	2
101	Generate	98	3
102	Sales Orders	101	1
103	Reports	98	4
104	Search	103	1
106	Time Cards	103	3
107	Translations	98	5
108	Description	107	1
111	Trial Balance	109	2
113	Balance Sheet	109	4
114	Inventory Activity	109	5
117	Sales Invoices	116	1
118	Sales Orders	116	2
119	Checks	116	3
120	Work Orders	116	4
121	Quotations	116	5
122	Packing Lists	116	6
123	Pick Lists	116	7
124	Purchase Orders	116	8
125	Bin Lists	116	9
126	RFQs	116	10
127	Time Cards	116	11
130	Taxes	128	2
131	Defaults	128	3
142	Add Warehouse	141	1
143	List Warehouse	141	2
148	Add Business	147	1
149	List Businesses	147	2
151	Add Language	150	1
152	List Languages	150	2
154	Add SIC	153	1
155	List SIC	153	2
157	Income Statement	156	1
158	Balance Sheet	156	2
159	Invoice	156	3
160	AR Transaction	156	4
161	AP Transaction	156	5
162	Packing List	156	6
163	Pick List	156	7
164	Sales Order	156	8
165	Work Order	156	9
166	Purchase Order	156	10
167	Bin List	156	11
168	Statement	156	12
169	Quotation	156	13
170	RFQ	156	14
171	Timecard	156	15
241	Letterhead	156	16
173	Invoice	172	1
174	AR Transaction	172	2
175	AP Transaction	172	3
176	Packing List	172	4
177	Pick List	172	5
178	Sales Order	172	6
179	Work Order	172	7
180	Purchase Order	172	8
181	Bin List	172	9
182	Statement	172	10
205	Transaction Approval	0	6
1	AR	0	2
21	AP	0	4
35	Cash	0	5
183	Check	172	11
184	Receipt	172	12
185	Quotation	172	13
186	RFQ	172	14
187	Timecard	172	15
242	Letterhead	172	16
189	POS Invoice	188	1
19	Contacts	0	1
246	Import Chart	73	7
136	GIFI	128	7
4	Reports	1	9
249	Vouchers	1	8
24	Reports	21	9
250	Vouchers	21	8
200	Vouchers	35	5
40	Transfer	35	6
41	Reports	35	8
45	Reconciliation	35	7
132	Year End	73	3
112	Income Statement	6	1
203	Receipts	200	3
204	Reverse Receipts	200	4
201	Payments	200	1
202	Reverse Payment	200	2
210	Drafts	205	2
211	Reconciliation	205	3
218	Add Tax Form	217	1
219	Admin Users	128	5
188	Text Templates	128	15
172	LaTeX Templates	128	14
156	HTML Templates	128	13
153	SIC	128	12
150	Language	128	11
147	Type of Business	128	10
144	Reporting Units	128	9
141	Warehouses	128	8
220	Add User	219	1
221	Search Users	219	2
222	Sessions	219	3
225	List Tax Forms	217	2
226	Reports	217	3
228	Asset Classes	227	1
229	Assets	227	2
230	Add Class	228	1
231	List Classes	228	2
232	Add Assets	229	1
233	Search Assets	229	2
235	Import	229	3
234	Depreciate	229	4
237	Net Book Value	236	1
238	Disposal	229	5
236	Reports	229	11
239	Depreciation	236	2
240	Disposal	236	3
243	Import Batch	21	3
23	Vendor Invoice	21	4
196	Debit Note	21	5
197	Debit Invoice	21	6
244	Import Batch	1	3
3	Sales Invoice	1	4
194	Credit Note	1	5
195	Credit Invoice	1	6
245	Import	73	2
76	Reports	73	4
139	Add GIFI	136	4
140	List GIFI	136	5
247	Import GIFI	136	6
248	Import	153	3
198	AR Voucher	249	1
199	AP Voucher	250	1
252	Add Budget	251	1
253	Search	251	2
251	Budgets	0	7
46	HR	0	8
50	Order Entry	0	9
63	Shipping	0	10
67	Quotations	0	11
73	General Journal	0	12
77	Goods and Services	0	13
98	Projects	0	14
109	Reports	0	15
115	Recurring Transactions	0	16
217	Tax Forms	0	17
227	Fixed Assets	0	19
193	Logout	0	25
192	New Window	0	24
191	Preferences	0	23
190	Stylesheet	0	22
128	System	0	21
116	Batch Printing	0	20
6	Profit and Loss	109	1
8	Customer Margin	6	10
11	Invoice Margin	6	11
9	Outstanding	4	1
10	Outstanding	24	1
\.


--
-- Name: menu_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_pkey PRIMARY KEY (node_id, attribute);


--
-- Name: menu_node_parent_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_key UNIQUE (parent, "position");


--
-- Name: menu_node_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_pkey PRIMARY KEY (id);


--
-- Name: menu_attribute_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_node_id_fkey FOREIGN KEY (node_id) REFERENCES menu_node(id);


--
-- Name: menu_node_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_fkey FOREIGN KEY (parent) REFERENCES menu_node(id);


--
-- Name: menu_attribute; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE menu_attribute FROM PUBLIC;
REVOKE ALL ON TABLE menu_attribute FROM postgres;
GRANT ALL ON TABLE menu_attribute TO postgres;
GRANT SELECT ON TABLE menu_attribute TO PUBLIC;


--
-- Name: menu_node; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE menu_node FROM PUBLIC;
REVOKE ALL ON TABLE menu_node FROM postgres;
GRANT ALL ON TABLE menu_node TO postgres;
GRANT SELECT ON TABLE menu_node TO PUBLIC;


--
-- PostgreSQL database dump complete
--

