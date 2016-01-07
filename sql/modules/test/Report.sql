BEGIN;
\i Base.sql

COPY gl(id, transdate, approved) FROM stdin DELIMITER '|';
-1000|1900-01-01|TRUE
-1001|1900-01-03|TRUE
\.

COPY acc_trans(trans_id,chart_id,amount,transdate,approved,entry_id) FROM stdin DELIMITER '|';
-1000|-1000|100.00|1900-01-01|TRUE|-1000
-1001|-1000|100.00|1900-01-03|TRUE|-1001
\.


INSERT INTO test_result(test_name, success)
SELECT 'first transaction balance = 100 (with pre-posting start-date)',
    running_balance = 100
 FROM report__gl(NULL, -- reference
                 (select accno from account where id = -1000),
                 NULL, NULL, -- category, source
                 NULL, NULL, -- memo, description
                 '1899-12-31'::date, -- from_date
                 '1900-01-01'::date, -- to_date
                 NULL, -- approved
                 NULL, NULL, -- from_amount, to_amount
                 NULL -- business_units
                 );

INSERT INTO test_result(test_name, success)
SELECT 'first transaction balance = 100 (NULL start-date)',
    running_balance = 100
 FROM report__gl(NULL, -- reference
                 (select accno from account where id = -1000),
                 NULL, NULL, -- category, source
                 NULL, NULL, -- memo, description
                 NULL, -- from_date
                 '1900-01-01'::date, -- to_date
                 NULL, -- approved
                 NULL, NULL, -- from_amount, to_amount
                 NULL -- business_units
                 );

INSERT INTO test_result(test_name, success)
SELECT 'first transaction balance = 100 (start-date matches transdate)',
    running_balance = 100
 FROM report__gl(NULL, -- reference
                 (select accno from account where id = -1000),
                 NULL, NULL, -- category, source
                 NULL, NULL, -- memo, description
                 '1900-01-01'::date, -- from_date
                 '1900-01-02'::date, -- to_date
                 NULL, -- approved
                 NULL, NULL, -- from_amount, to_amount
                 NULL -- business_units
                 );

INSERT INTO test_result(test_name, success)
SELECT 'end-dates-match balance = 200',
    running_balance = 200
 FROM report__gl(NULL, -- reference
                 (select accno from account where id = -1000),
                 NULL, NULL, -- category, source
                 NULL, NULL, -- memo, description
                 '1900-01-02'::date, -- from_date
                 '1900-01-03'::date, -- to_date
                 NULL, -- approved
                 NULL, NULL, -- from_amount, to_amount
                 NULL -- business_units
                 );

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
