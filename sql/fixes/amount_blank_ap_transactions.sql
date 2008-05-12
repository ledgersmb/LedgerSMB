BEGIN;

UPDATE ap 
SET netamount = 
	(select sum(amount) from acc_trans 
	where trans_id = ap.id 
		AND ((chart_id IN (select id from chart where link = 'AP')
			     AND amount > 0)
			OR (chart_id IN 
				(select id from chart where link like '%tax%')
			)
		)
	)
WHERE netamount IS NULL;

UPDATE ar
SET netamount = -1 *
	(select sum(amount) from acc_trans 
	where trans_id = ar.id 
		AND ((chart_id IN (select id from chart where link = 'AR')
			     AND amount < 0)
			OR (chart_id IN 
				(select id from chart where link like '%tax%')
			)
		)
	)
WHERE netamount IS NULL;

commit;
