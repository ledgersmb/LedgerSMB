begin;

-- handle NULL chart_id's
SELECT account__save(null, '1000000000', 'Broken SQL-Ledger Data', 'L', null, null, false, false, '{}', false, false);

--handle duplicate transaction id's.
CREATE TEMPORARY TABLE id_agregator (id INT, table_name text);

insert into id_agregator (id, table_name) SELECT id, 'ar' from ar;
insert into id_agregator (id, table_name) SELECT id, 'ap' from ap;
insert into id_agregator (id, table_name) SELECT id, 'business' from business;
insert into id_agregator (id, table_name) SELECT id, 'chart' from chart;
insert into id_agregator (id, table_name) SELECT id, 'customer' from customer;
insert into id_agregator (id, table_name) 
	SELECT id, 'department' from department;
insert into id_agregator (id, table_name) SELECT id, 'employee' from employee;
insert into id_agregator (id, table_name) SELECT id, 'gl' from gl;
insert into id_agregator (id, table_name) SELECT id, 'oe' from oe;
insert into id_agregator (id, table_name) SELECT id, 'parts' from parts;
insert into id_agregator (id, table_name) 
	SELECT id, 'partsgroup' from partsgroup;
insert into id_agregator (id, table_name) SELECT id, 'project' from project;
insert into id_agregator (id, table_name) SELECT id, 'vendor' from vendor;
insert into id_agregator (id, table_name) SELECT id, 'warehouse' from warehouse;

CREATE TEMPORARY VIEW id_view1 AS
SELECT id, count(*) AS num_rows FROM id_agregator 
GROUP BY id HAVING count(*) > 1;

select setval('id', (select max(id) + 1 from id_agregator));

create function fix_dupes() RETURNS opaque AS
' 
DECLARE
dupe_id id_agregator%ROWTYPE;
BEGIN
FOR dupe_id IN SELECT id FROM id_agregator 
	WHERE id IN (SELECT id FROM id_view1)
LOOP
	EXECUTE ''UPDATE '' || dupe_id.table_name ||
			'' SET id = nextval(''''id'''') WHERE
		id = '' ||dupe_id.id;
	UPDATE acc_trans SET trans_id = currval(''id'') WHERE
		id = ||dupe_id.id;
	INSERT INTO acc_trans (trans_id, amount, chart_id) VALUES (
		currval(''id''), ''1'', (
			SELECT id FROM chart WHERE accno = ''1000000000''
		)
	);
	INSERT INTO acc_trans (trans_id, amount, chart_id) VALUES (
		currval(''id''), ''-1'', (
			SELECT id FROM chart WHERE accno = ''1000000000''
		)
	);

END LOOP;
RETURN NULL;
END;
' LANGUAGE PLPGSQL;

SELECT fix_dupes ();

drop function fix_dupes();


commit;
