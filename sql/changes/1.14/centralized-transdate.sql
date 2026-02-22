
drop view cash_impact cascade;

drop trigger ar_prevent_closed on ar;

alter table ar
  drop column transdate;


drop trigger ap_prevent_closed on ap;

alter table ap
  drop column transdate;


drop trigger gl_prevent_closed on gl;

alter table gl
  drop column transdate;


--###BUG??? The cash impact below doesn't take 'approved' into account?
CREATE VIEW cash_impact AS
  SELECT id, '1'::numeric
           AS portion, 'gl' as rel, txn.transdate
    FROM gl JOIN transactions txn USING (id)
   UNION ALL
  SELECT id,
         CASE
           WHEN ar.amount_bc = 0 THEN 0 -- avoid div by 0
           WHEN txn.transdate = ac.transdate THEN 1 + sum(ac.amount_bc) / ar.amount_bc
           ELSE 1 - (ar.amount_bc - sum(ac.amount_bc)) / ar.amount_bc
           END,
         'ar' as rel,
         ac.transdate
    FROM ar JOIN transactions txn USING (id)
           JOIN acc_trans ac ON ac.trans_id = ar.id
           JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AR'
   GROUP BY ar.id, ar.amount_bc, ac.transdate, txn.transdate
   UNION ALL
  SELECT id,
         CASE
           WHEN ap.amount_bc = 0 THEN 0
           WHEN txn.transdate = ac.transdate THEN 1 - sum(ac.amount_bc) / ap.amount_bc
           ELSE 1 - (ap.amount_bc + sum(ac.amount_bc)) / ap.amount_bc
           END,
         'ap' as rel,
         ac.transdate
    FROM ap JOIN transactions txn USING (id)
           JOIN acc_trans ac ON ac.trans_id = ap.id
           JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AP'
   GROUP BY ap.id, ap.amount_bc, ac.transdate, txn.transdate;

COMMENT ON VIEW cash_impact IS
$$ This view is used by cash basis reports to determine the fraction of a
transaction to be counted.$$;



