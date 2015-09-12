--tshvr use lsmb12 if 1.2 db public schema has already been renamed to lsmb12
SET search_path = lsmb12, public, pg_catalog;

SELECT count(*), customernumber from customer
GROUP BY customernumber
HAVING count(*) > 1;

SELECT count(*), vendornumber from vendor
GROUP BY vendornumber
HAVING count(*) > 1;

SELECT * FROM chart where link LIKE '%CT_tax%';

SELECT * FROM employee where employeenumber IS NULL;

SELECT * FROM employee WHERE employeenumber IN
       (SELECT employeenumber FROM employee GROUP BY employeenumber
        HAVING count(*) > 1);

select partnumber, count(*) from parts
 WHERE obsolete is not true
group by partnumber having count(*) > 1;

SELECT invnumber, count(*) from ar
group by invnumber having count(*) > 1;
SELECT invnumber, count(*) from ap group by invnumber having count(*) > 1;

SELECT trans_id,count(trans_id) FROM acc_trans where trans_id not in (select id from ap union select id from ar union select id from gl) group by trans_id;
SELECT trans_id,count(trans_id) FROM invoice where trans_id not in (select id from ap union select id from ar union select id from gl) group by trans_id;

select setting_key,value from defaults where setting_key='curr';
