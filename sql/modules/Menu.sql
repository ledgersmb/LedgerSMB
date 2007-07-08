CREATE TABLE menu_node (
    id serial NOT NULL,
    label character varying NOT NULL,
    parent integer,
    "position" integer NOT NULL
);


ALTER TABLE public.menu_node OWNER TO ledgersmb;

--
-- Name: menu_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ledgersmb
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('menu_node', 'id'), 193, true);


--
-- Data for Name: menu_node; Type: TABLE DATA; Schema: public; Owner: ledgersmb
--

COPY menu_node (id, label, parent, "position") FROM stdin;
0	Top-level	\N	0
1	AR	0	1
2	Add Transaction	1	1
3	Sales Invoice	1	2
4	Reports	1	3
5	Transactions	4	1
6	Outstanding	4	2
7	AR Aging	4	3
9	Taxable Sales	4	4
10	Non-Taxable	4	5
11	Customers	1	4
12	Add Customer	11	1
13	Reports	11	2
14	Search	13	1
15	History	13	2
16	Point of Sale	0	2
17	Sale	16	1
18	Open	16	2
19	Receipts	16	3
20	Close Till	16	4
21	AP	0	3
22	Add Transaction	21	1
23	Vendor Invoice	21	2
24	Reports	21	3
25	Transactions	24	1
26	Outstanding	24	2
27	AP Aging	24	3
28	Taxable	24	4
29	Non-taxable	24	5
30	Vendors	21	4
31	Add Vendor	30	1
32	Reports	30	2
33	Search	32	1
34	History	32	2
35	Cash	0	4
36	Receipt	35	1
38	Payment	35	3
37	Receipts	35	2
39	Payments	35	4
40	Transfer	35	5
42	Receipts	41	1
43	Payments	41	2
44	Reconciliation	41	3
41	Reports	35	7
45	Reconciliation	35	6
46	HR	0	5
47	Employees	46	1
48	Add Employee	47	1
49	Search	47	2
50	Order Entry	0	6
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
63	Shipping	0	7
64	Ship	63	1
65	Receive	63	2
66	Transfer	63	3
67	Quotations	0	8
68	Quotation	67	1
69	RFQ	67	2
70	Reports	67	3
71	Quotations	70	1
72	RFQs	70	2
73	General Journal	0	9
74	Journal Entry	73	1
75	Adjust Till	73	2
76	Reports	73	3
77	Goods and Services	0	10
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
98	Projects	0	11
99	Add Project	98	1
100	Add Timecard	98	2
101	Generate	98	3
102	Sales Orders	101	1
103	Reports	98	4
104	Search	103	1
105	Transactions	103	2
106	Time Cards	103	3
107	Translations	98	5
108	Description	107	1
109	Reports	0	12
110	Chart of Accounts	109	1
111	Trial Balance	109	2
112	Income Statement	109	3
113	Balance Sheet	109	4
114	Inventory Activity	109	5
115	Recurring Transactions	0	13
116	Batch Printing	0	14
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
128	System	0	15
129	Audit Control	128	1
130	Taxes	128	2
131	Defaults	128	3
132	Yearend	128	4
133	Backup	128	5
134	Send to File	133	1
135	Send to Email	133	2
136	Chart of Accounts	128	6
137	Add Accounts	136	1
138	List Accounts	136	2
139	Add GIFI	136	3
140	List GIFI	136	4
141	Warehouses	128	7
142	Add Warehouse	141	1
143	List Warehouse	141	2
144	Departments	128	8
145	Add Department	144	1
146	List Departments	144	2
147	Type of Business	128	9
148	Add Business	147	1
149	List Businesses	147	2
150	Language	128	10
151	Add Language	150	1
152	List Languages	150	2
153	SIC	128	11
154	Add SIC	153	1
155	List SIC	153	2
156	HTML Templates	128	12
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
172	LaTeX Templates	128	13
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
183	Check	172	11
184	Receipt	172	12
185	Quotation	172	13
186	RFQ	172	14
187	Timecard	172	15
188	Text Templates	128	14
189	POS Invoice	188	1
190	Stylesheet	0	16
191	Preferences	0	17
192	New Window	0	18
193	Logout	0	19
\.


--
-- Name: menu_node_parent_key; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_key UNIQUE (parent, "position");


--
-- Name: menu_node_pkey; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_pkey PRIMARY KEY (id);


--
-- Name: menu_node_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ledgersmb
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_fkey FOREIGN KEY (parent) REFERENCES menu_node(id);



CREATE TABLE menu_attribute (
    node_id integer NOT NULL,
    attribute character varying NOT NULL,
    value character varying NOT NULL,
    id serial NOT NULL
);


--
-- Name: menu_attribute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ledgersmb
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('menu_attribute', 'id'), 534, true);


--
-- Data for Name: menu_attribute; Type: TABLE DATA; Schema: public; Owner: ledgersmb
--

COPY menu_attribute (node_id, attribute, value, id) FROM stdin;
1	menu	1	1
2	module	ar.pl	2
2	action	add	3
3	action	add	4
3	module	is.pl	5
3	type	invoice	6
4	menu	1	7
5	module	ar.pl	8
5	action	search	9
5	nextsub	transactions	10
6	module	ar.pl	12
6	action	search	13
6	nextsub	transactions	14
7	module	rp.pl	15
7	action	report	16
7	report	ar_aging	17
9	module	rp.pl	21
9	action	report	22
9	report	tax_collected	23
10	module	rp.pl	24
10	action	report	25
10	report	nontaxable_sales	26
11	menu	1	27
12	module	ct.pl	28
12	action	add	29
12	db	customer	30
13	menu	1	31
14	module	ct.pl	32
14	db	customer	34
15	module	ct.pl	35
15	action	add	36
15	db	customer	37
14	action	history	33
16	menu	1	38
17	module	ps.pl	39
17	action	add	40
17	nextsub	openinvoices	41
18	action	openinvoices	42
18	module	ps.pl	43
19	module	ps.pl	44
19	action	receipts	46
20	module	rc.pl	47
20	action	till_closing	48
20	pos	true	49
21	menu	1	50
22	action	add	52
22	module	ap.pl	51
23	action	add	53
23	type	invoice	55
23	module	ir.pl	54
24	menu	1	56
25	action	search	58
25	nextsub	transactions	59
25	module	ap.pl	57
26	action	search	61
26	nextsub	transactions	62
26	module	ap.pl	60
27	module	rp.pl	63
27	action	report	64
28	module	rp.pl	66
28	action	report	67
28	report	tax_collected	68
27	report	tax_paid	65
29	module	rp.pl	69
29	action	report	70
29	report	report	71
30	menu	1	72
31	module	ct.pl	73
31	action	add	74
31	db	vendor	75
32	menu	1	76
33	module	ct.pl	77
33	action	history	79
33	db	vendor	78
34	module	ct.pl	80
34	action	add	81
34	db	vendor	82
35	menu	1	83
36	module	cp.pl	84
36	action	payment	85
36	type	receipt	86
37	module	cp.pl	87
38	module	cp.pl	90
38	action	payment	91
37	type	receipt	89
37	action	payments	88
38	type	check	92
39	module	cp.pl	93
39	type	check	95
39	action	payments	94
40	module	gl.pl	96
40	action	add	97
40	transfer	1	98
41	menu	1	99
42	module	rp.pl	100
42	action	report	101
42	report	receipts	102
43	module	rp.pl	103
43	action	report	104
43	report	payments	105
45	module	rc.pl	106
45	action	reconciliation	107
44	module	rc.pl	108
44	action	reconciliation	109
44	report	1	110
46	menu	1	111
47	menu	1	112
48	module	hr.pl	113
48	action	add	114
48	db	employee	115
49	module	hr.pl	116
49	db	employee	118
49	action	search	117
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
65	type	consolidate_sales_order	152
64	type	receive_order	149
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
72	action	search	168
72	type	request_quotation	167
73	menu	1	169
74	module	gl.pl	170
74	action	add	171
75	module	gl.pl	172
75	action	add_pos_adjust	174
75	rowcount	3	175
75	pos_adjust	1	176
75	reference	Adjusting Till: (Till)  Source: (Source)	177
75	descripton	Adjusting till due to data entry error	178
76	module	gl.pl	180
76	action	search	181
77	menu	1	182
78	module	ic.pl	183
78	action	add	184
78	item	part	185
79	module	ic.pl	186
79	action	add	187
79	item	service	188
80	module	ic.pl	189
80	action	add	190
81	module	ic.pl	192
81	action	add	193
81	item	part	194
80	item	labor	191
82	action	add	195
82	module	pe.pl	196
83	action	add	198
83	module	pe.pl	199
83	type	partsgroup	200
82	type	pricegroup	197
84	module	ic.pl	202
84	action	stock_assembly	203
85	menu	1	204
86	module	ic.pl	205
87	action	search	206
86	action	search	207
87	module	ic.pl	208
86	searchitems	all	209
88	module	ic.pl	211
88	action	requirements	212
89	action	search	213
89	module	ic.pl	214
89	searchitems	service	215
87	searchitems	part	210
90	action	search	216
90	module	ic.pl	217
90	searchitems	labor	218
91	module	pe.pl	221
91	type	pricegroup	222
91	action	search	220
92	module	pe.pl	224
92	type	partsgroup	225
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
102	menu	1	255
104	module	pe.pl	256
104	type	project	258
104	action	search	257
105	action	report	260
105	report	projects	261
105	module	rp.pl	262
106	module	jc.pl	263
106	action	search	264
106	type	timecard	265
106	project	project	266
107	menu	1	268
108	module	pe.pl	269
108	action	translation	270
108	translation	project	271
109	menu	1	272
110	module	ca.pl	273
110	action	chart_of_accounts	274
111	action	report	275
111	module	rp.pl	276
111	report	trial_balance	277
112	action	report	278
112	module	rp.pl	279
112	report	income_statement	280
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
118	type	invoice	301
117	type	sales_order	296
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
126	type	request_quotation	328
127	vc	employee	333
128	menu	1	334
129	module	am.pl	337
130	module	am.pl	338
131	module	am.pl	339
129	action	audit_control	340
130	taxes	audit_control	341
131	action	defaults	342
130	action	taxes	343
132	module	am.pl	346
132	action	yearend	347
133	menu	1	348
134	module	am.pl	349
135	module	am.pl	350
134	action	backup	351
135	action	backup	352
134	media	file	353
135	media	email	354
137	module	am.pl	355
138	module	am.pl	356
139	module	am.pl	357
140	module	am.pl	358
137	action	add_account	359
138	action	list_account	360
139	action	add_gifi	361
140	action	list_gifi	362
141	menu	1	363
142	module	am.pl	364
143	module	am.pl	365
142	action	add_warehouse	366
143	action	list_warehouse	367
145	module	am.pl	368
146	module	am.pl	369
145	action	add_department	370
146	action	list_department	371
147	menu	1	372
148	module	am.pl	373
149	module	am.pl	374
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
188	menu	1	521
189	module	am.pl	522
189	action	list_templates	523
189	template	pos_invoice	524
189	format	TEXT	525
190	action	display_stylesheet	526
190	module	am.pl	527
191	module	am.pl	528
191	action	config	529
193	module	login.pl	532
193	action	logout	533
193	target	_top	534
192	menu	1	530
192	new	1	531
\.


--
-- Name: menu_attribute_id_key; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_id_key UNIQUE (id);


--
-- Name: menu_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_pkey PRIMARY KEY (node_id, attribute);


--
-- Name: menu_attribute_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ledgersmb
--

ALTER TABLE ONLY menu_attribute
    ADD CONSTRAINT menu_attribute_node_id_fkey FOREIGN KEY (node_id) REFERENCES menu_node(id);


--
-- PostgreSQL database dump complete
--

--

CREATE TABLE menu_acl (
    id serial NOT NULL,
    role_name character varying,
    acl_type character varying,
    node_id integer,
    CONSTRAINT menu_acl_acl_type_check CHECK ((((acl_type)::text = 'allow'::text) OR ((acl_type)::text = 'deny'::text)))
);



ALTER TABLE ONLY menu_acl
    ADD CONSTRAINT menu_acl_pkey PRIMARY KEY (id);


ALTER TABLE ONLY menu_acl
    ADD CONSTRAINT menu_acl_node_id_fkey FOREIGN KEY (node_id) REFERENCES menu_node(id);


--
-- PostgreSQL database dump complete
--

CREATE TYPE menu_item AS (
   position int,
   id int,
   level int,
   label varchar,
   path varchar,
   args varchar[]
);

CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS 
$$
DECLARE 
	item menu_item;
	arg menu_attribute%ROWTYPE;
	
BEGIN
	FOR item IN 
		SELECT n.position, n.id, c.level, n.label, c.path, '{}' 
		FROM connectby('menu_node', 'id', 'parent', 'position', '0', 
				0, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
	LOOP
		FOR arg IN 
			SELECT *
			FROM menu_attribute
			WHERE node_id = item.id
		LOOP
			item.args := item.args || 
				(arg.attribute || '=' || arg.value)::varchar;
		END LOOP;
		RETURN NEXT item;
	END LOOP;
END;
$$ language plpgsql;
--
-- PostgreSQL database dump
--

CREATE VIEW menu_friendly AS
    SELECT t."level", t.path, t.list_order, (repeat(' '::text, (2 * t."level")) || (n.label)::text) AS label, n.id, n."position" FROM (connectby('menu_node'::text, 'id'::text, 'parent'::text, 'position'::text, '0'::text, 0, ','::text) t(id integer, parent integer, "level" integer, path text, list_order integer) JOIN menu_node n USING (id));


ALTER TABLE public.menu_friendly OWNER TO ledgersmb;

--
-- PostgreSQL database dump complete
--

