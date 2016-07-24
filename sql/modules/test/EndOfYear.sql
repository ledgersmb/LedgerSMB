

BEGIN;
\i Base.sql

INSERT INTO gl (id, reference, description, transdate, approved)
values (-1000, 'test', 'test', '1520-01-01', true); -- way in the future.
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, approved)
values (-1000, '-1000', '1520-01-01', '10000', true);
INSERT INTO acc_trans (trans_id, chart_id, transdate, amount, approved)
values (-1000, '-1001', '1520-01-01', '-10000', true);

insert into test_result(success, test_name)
select account__obtain_balance('1519-12-31'::date, -1000) = 0,
       'account__obtain_balance (before any transaction)';

insert into test_result(success, test_name)
select account__obtain_balance('1520-01-01'::date, -1000) = 10000,
       'account__obtain_balance (after first transaction)';

DELETE FROM account_checkpoint;
DELETE FROM yearend;



insert into test_result (success, test_name)
select eoy_close_books('1520-05-01', 'test', 'test', '-1002'),
'Close books succeeded';

insert into test_result (success, test_name)
select amount = 10000, 'Account checkpoint added'
from account_checkpoint where end_date = '1520-05-01' and account_id = -1000;

insert into test_result(success, test_name)
select account__obtain_balance('1520-05-01'::date, -1000) = 10000,
       'account__obtain_balance (on checkpoint)';

insert into test_result(success, test_name)
select account__obtain_balance('1520-05-02'::date, -1000) = 10000,
       'account__obtain_balance (after checkpoint)';


SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
