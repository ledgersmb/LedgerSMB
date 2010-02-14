BEGIN;
\i Base.sql

DELETE FROM account_checkpoint;
DELETE FROM yearend;

INSERT INTO gl (id, reference, description, transdate, approved)  
values (-1000, 'test', 'test', '20020-01-01', true); -- way in the future.
INSERT INTO acc_trans (trans_id, account_id, transdate, amount, approved) 
values (-1000, '-1000', '20020-01-01', '10000', true);
INSERT INTO acc_trans (trans_id, account_id, transdate, amount, approved) 
values (-1000, '-1001', '20020-01-01', '-10000', true);

insert into test_result (success, test_name)
select eoy_close_books('20020-01-01', 'test', 'test', '-1002'), 
'Close books succeeded';

insert into test_result (success, test_name)
select amount = 1000, 'Account checkpoint added'
from account_checkpoint where end_date = '20020-01-01' and account_id = -1000;

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
