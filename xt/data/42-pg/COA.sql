-- Import the US General.xml. Data from 1.13 as of Saturday, May 2, 2026 12:51:47 CDT

-- Exclude old style testing data with an id < 0
SELECT count(*) = 0 AS no_accounts FROM account WHERE id > 0
\gset

-- Only add these CoA if there are no accounts with id > 0
\if :no_accounts

--
-- Data for Name: account_heading; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY account_heading (id, accno, parent_id, description, category) FROM stdin;
1	1000	\N	CURRENT ASSETS	\N
2	1500	\N	INVENTORY ASSETS	\N
3	1800	\N	CAPITAL ASSETS	\N
4	2000	\N	CURRENT LIABILITIES	\N
5	2600	\N	LONG TERM LIABILITIES	\N
6	3300	\N	SHARE CAPITAL	\N
7	3500	\N	RETAINED EARNINGS	\N
8	4000	\N	SALES REVENUE	\N
9	4400	\N	OTHER REVENUE	\N
10	5000	\N	COST OF GOODS SOLD	\N
11	5400	\N	PAYROLL EXPENSES	\N
12	5600	\N	GENERAL & ADMINISTRATIVE EXPENSES	\N
\.

--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY account (id, accno, description, is_temp, category, gifi_accno, heading, contra, tax, obsolete, heading_negative_balance, custom_attributes) FROM stdin;
1	1060	Checking Account	f	A	\N	1	f	f	f	\N	\N
2	1065	Petty Cash	f	A	\N	1	f	f	f	\N	\N
3	1200	Accounts Receivables	f	A	\N	1	f	f	f	\N	\N
4	1205	Allowance for doubtful accounts	f	A	\N	1	f	f	f	\N	\N
5	1510	Inventory	f	A	\N	2	f	f	f	\N	\N
6	1820	Office Furniture & Equipment	f	A	\N	3	f	f	f	\N	\N
7	1825	Accum. Amort. -Furn. & Equip.	f	A	\N	3	t	f	f	\N	\N
8	1840	Vehicle	f	A	\N	3	f	f	f	\N	\N
9	1845	Accum. Amort. -Vehicle	f	A	\N	3	t	f	f	\N	\N
10	2100	Accounts Payable	f	L	\N	4	f	f	f	\N	\N
11	2110	Accrued Income Tax - Federal	f	L	\N	4	f	f	f	\N	\N
12	2120	Accrued Income Tax - State	f	L	\N	4	f	f	f	\N	\N
13	2130	Accrued Franchise Tax	f	L	\N	4	f	f	f	\N	\N
14	2140	Accrued Real & Personal Prop Tax	f	L	\N	4	f	f	f	\N	\N
15	2150	Sales Tax	f	L	\N	4	f	t	f	\N	\N
16	2160	Accrued Use Tax Payable	f	L	\N	4	f	f	f	\N	\N
17	2210	Accrued Wages	f	L	\N	4	f	f	f	\N	\N
18	2220	Accrued Comp Time	f	L	\N	4	f	f	f	\N	\N
19	2230	Accrued Holiday Pay	f	L	\N	4	f	f	f	\N	\N
20	2240	Accrued Vacation Pay	f	L	\N	4	f	f	f	\N	\N
21	2310	Accr. Benefits - 401K	f	L	\N	4	f	f	f	\N	\N
22	2320	Accr. Benefits - Stock Purchase	f	L	\N	4	f	f	f	\N	\N
23	2330	Accr. Benefits - Med, Den	f	L	\N	4	f	f	f	\N	\N
24	2340	Accr. Benefits - Payroll Taxes	f	L	\N	4	f	f	f	\N	\N
25	2350	Accr. Benefits - Credit Union	f	L	\N	4	f	f	f	\N	\N
26	2360	Accr. Benefits - Savings Bond	f	L	\N	4	f	f	f	\N	\N
27	2370	Accr. Benefits - Garnish	f	L	\N	4	f	f	f	\N	\N
28	2380	Accr. Benefits - Charity Cont.	f	L	\N	4	f	f	f	\N	\N
29	2620	Bank Loans	f	L	\N	5	f	f	f	\N	\N
30	2680	Loans from Shareholders	f	L	\N	5	f	f	f	\N	\N
31	3350	Common Shares	f	Q	\N	6	f	f	f	\N	\N
32	3590	Retained Earnings - prior years	f	Q	\N	7	f	f	f	\N	\N
33	4010	Sales	f	I	\N	8	f	f	f	\N	\N
34	4430	Shipping & Handling	f	I	\N	9	f	f	f	\N	\N
35	4440	Interest	f	I	\N	9	f	f	f	\N	\N
36	4450	Foreign Exchange Gain	f	I	\N	9	f	f	f	\N	\N
37	5010	Purchases	f	E	\N	10	f	f	f	\N	\N
38	5100	Freight	f	E	\N	10	f	f	f	\N	\N
39	5410	Wages & Salaries	f	E	\N	11	f	f	f	\N	\N
40	5420	Wages - Overtime	f	E	\N	11	f	f	f	\N	\N
41	5430	Benefits - Comp Time	f	E	\N	11	f	f	f	\N	\N
42	5440	Benefits - Payroll Taxes	f	E	\N	11	f	f	f	\N	\N
43	5450	Benefits - Workers Comp	f	E	\N	11	f	f	f	\N	\N
44	5460	Benefits - Pension	f	E	\N	11	f	f	f	\N	\N
45	5470	Benefits - General Benefits	f	E	\N	11	f	f	f	\N	\N
46	5510	Inc Tax Exp - Federal	f	E	\N	11	f	f	f	\N	\N
47	5520	Inc Tax Exp - State	f	E	\N	11	f	f	f	\N	\N
48	5530	Taxes - Real Estate	f	E	\N	11	f	f	f	\N	\N
49	5540	Taxes - Personal Property	f	E	\N	11	f	f	f	\N	\N
50	5550	Taxes - Franchise	f	E	\N	11	f	f	f	\N	\N
51	5560	Taxes - Foreign Withholding	f	E	\N	11	f	f	f	\N	\N
52	5610	Accounting & Legal	f	E	\N	12	f	f	f	\N	\N
53	5615	Advertising & Promotions	f	E	\N	12	f	f	f	\N	\N
54	5620	Bad Debts	f	E	\N	12	f	f	f	\N	\N
55	5660	Amortization Expense	f	E	\N	12	f	f	f	\N	\N
56	5685	Insurance	f	E	\N	12	f	f	f	\N	\N
57	5690	Interest & Bank Charges	f	E	\N	12	f	f	f	\N	\N
58	5700	Office Supplies	f	E	\N	12	f	f	f	\N	\N
59	5760	Rent	f	E	\N	12	f	f	f	\N	\N
60	5765	Repair & Maintenance	f	E	\N	12	f	f	f	\N	\N
61	5780	Telephone	f	E	\N	12	f	f	f	\N	\N
62	5785	Travel & Entertainment	f	E	\N	12	f	f	f	\N	\N
63	5790	Utilities	f	E	\N	12	f	f	f	\N	\N
64	5795	Registrations	f	E	\N	12	f	f	f	\N	\N
65	5800	Licenses	f	E	\N	12	f	f	f	\N	\N
66	5810	Foreign Exchange Loss	f	E	\N	12	f	f	f	\N	\N
\.

--
-- Data for Name: account_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY account_link (account_id, description) FROM stdin;
1	AR_paid
1	AP_paid
2	AR_paid
2	AP_paid
3	AR
5	IC
6	Fixed_Asset
7	Asset_Dep
8	Fixed_Asset
9	Asset_Dep
10	AP
15	AR_tax
15	AP_tax
15	IC_taxpart
15	IC_taxservice
30	AP_paid
33	AR_amount
33	IC_sale
33	IC_income
34	IC_income
37	AP_amount
37	IC_cogs
37	IC_expense
38	AP_amount
38	IC_expense
52	AP_amount
53	AP_amount
55	asset_expense
56	AP_amount
58	AP_amount
59	AP_amount
60	AP_amount
61	AP_amount
63	AP_amount
64	AP_amount
65	AP_amount
\.

--
-- Data for Name: account_link_description; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY account_link_description (description, summary, custom) FROM stdin;
AR	t	f
AP	t	f
IC	t	f
AR_amount	f	f
AR_tax	f	f
AR_paid	f	f
AR_overpayment	f	f
AR_discount	f	f
AP_amount	f	f
AP_expense	f	f
AP_tax	f	f
AP_paid	f	f
AP_overpayment	f	f
AP_discount	f	f
IC_sale	f	f
IC_tax	f	f
IC_cogs	f	f
IC_taxpart	f	f
IC_taxservice	f	f
IC_income	f	f
IC_expense	f	f
IC_returns	f	f
Asset_Dep	f	f
Fixed_Asset	f	f
asset_expense	f	f
asset_gain	f	f
asset_loss	f	f
\.

\endif
