BEGIN;

UPDATE ap 
SET netamount = 
	CASE WHEN amount > 0 THEN -1 *
		(select sum(amount) from acc_trans 
		where trans_id = ap.id 
			AND ((chart_id IN (select id from chart where link = 'AP')
				     AND amount > 0)
				OR (chart_id IN 
					(select id from chart where link like '%tax%')
				)
			)
		)
	ELSE
		-1 *
		(select sum(amount) from acc_trans 
		where trans_id = ap.id 
			AND ((chart_id IN 
				(select id from chart where link = 'AP')
				     AND amount > 0)
				OR (chart_id IN 
					(select id from chart 
					where link like '%tax%')
				)
			)
		)
	END
WHERE netamount IS NULL;

update ap set datepaid = NULL where paid = 0;

UPDATE ar
SET netamount = 
	CASE WHEN amount > 0 THEN -1 *
		(select sum(amount) from acc_trans 
		where trans_id = ar.id 
			AND ((chart_id IN 
				(select id from chart where link = 'AR')
				     AND amount < 0)
				OR (chart_id IN 
					(select id from chart 
					where link like '%tax%')
				)
			)
		)
	ELSE 
		(select sum(amount) from acc_trans 
		where trans_id = ar.id 
			AND ((chart_id IN (select id from chart 
				where link = 'AR')
				     AND amount < 0)
			OR (chart_id IN 
				(select id from chart where link like '%tax%')
				)
			)
		)
	END
WHERE netamount IS NULL;

update ar set datepaid = NULL where paid = 0;
commit;
