
drop view cash_impact cascade;



CREATE VIEW cash_impact AS
SELECT id, '1'::numeric AS portion, 'gl' as rel, gl.transdate FROM gl
UNION ALL
SELECT id, CASE WHEN gl.amount_bc = 0 THEN 0 -- avoid div by 0
                WHEN gl.transdate = ac.transdate
                     THEN 1 + sum(ac.amount_bc) / gl.amount_bc
                ELSE
                     1 - (gl.amount_bc - sum(ac.amount_bc)) / gl.amount_bc
                END , 'ar' as rel, ac.transdate
  FROM ar gl
  JOIN acc_trans ac ON ac.trans_id = gl.id
  JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AR'
 GROUP BY gl.id, gl.amount_bc, ac.transdate, gl.transdate
UNION ALL
SELECT id, CASE WHEN gl.amount_bc = 0 THEN 0
                WHEN gl.transdate = ac.transdate
                     THEN 1 - sum(ac.amount_bc) / gl.amount_bc
                ELSE
                     1 - (gl.amount_bc + sum(ac.amount_bc)) / gl.amount_bc
            END, 'ap' as rel, ac.transdate
  FROM ap gl
  JOIN acc_trans ac ON ac.trans_id = gl.id
  JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AP'
 GROUP BY gl.id, gl.amount_bc, ac.transdate, gl.transdate;

COMMENT ON VIEW cash_impact IS
$$ This view is used by cash basis reports to determine the fraction of a
transaction to be counted.$$;



