SELECT count(*), customernumber from lsmb12.customer
GROUP BY customernumber
HAVING count(*) > 1;

SELECT count(*), vendornumber from lsmb12.vendor
GROUP BY vendornumber
HAVING count(*) > 1;

SELECT * FROM lsmb12.chart where link LIKE '%CT_tax%';

SELECT * FROM lsmb12.employee where employeenumber IS NULL;
