--view definition put here as documentation for the moment.
--if using this view really , move it from here
--some reflections made by Chris Travers, good to know
--CTE,common table expression, is optimization fence, one loses optimization possibilities by db-engine
-- better unfold CTE and put logic in main query

drop view IF EXISTS ap_paid_nok;
drop view IF EXISTS ap_paid_nok1;

--View definition with cte
CREATE VIEW ap_paid_nok AS
 WITH cte(ap_id, ac_amount) AS (
         SELECT ap.id, sum(ac.amount) AS sum
           FROM ap ap
      JOIN acc_trans ac ON ac.trans_id = ap.id
   JOIN account_link al ON al.account_id = ac.chart_id
  WHERE al.description = 'AP'::text
  GROUP BY ap.id
 HAVING sum(ac.amount) <> 0::numeric
        )
 SELECT cte.ac_amount, e.name, ap.id, ap.invnumber, ap.transdate, ap.taxincluded, ap.amount, ap.netamount, ap.duedate, ap.invoice, ap.ordnumber, ap.curr, ap.notes, ap.person_id, ap.till, ap.quonumber, ap.intnotes, ap.shipvia, ap.language_code, ap.ponumber, ap.shippingpoint, ap.on_hold, ap.approved, ap.reverse, ap.terms, ap.description, ap.force_closed, ap.crdate
   FROM ap ap, entity_credit_account eca, entity e, cte cte
  WHERE ap.id = cte.ap_id AND ap.entity_credit_account = eca.id AND eca.entity_id = e.id;

--View definition unfolded
CREATE VIEW ap_paid_nok1 AS
SELECT sum(ac.amount) AS balance, e.name, ap.id, ap.invnumber, ap.transdate, ap.taxincluded, ap.amount, ap.netamount, ap.duedate, ap.invoice, ap.ordnumber, ap.curr, ap.notes, ap.person_id, ap.till, ap.quonumber, ap.intnotes, ap.shipvia, ap.language_code, ap.ponumber, ap.shippingpoint, ap.on_hold, ap.approved, ap.reverse, ap.terms, ap.description, ap.force_closed, ap.crdate
   FROM ap
   JOIN entity_credit_account eca ON ap.entity_credit_account = eca.id
   JOIN entity e ON eca.entity_id = e.id
   JOIN acc_trans ac ON ac.trans_id = ap.id
   JOIN account_link al ON al.description = 'AP'::text AND al.account_id = ac.chart_id
  GROUP BY e.name, ap.id, ap.invnumber, ap.transdate, ap.taxincluded, ap.amount, ap.netamount, ap.duedate, ap.invoice, ap.ordnumber, ap.curr, ap.notes, ap.person_id, ap.till, ap.quonumber, ap.intnotes, ap.shipvia, ap.language_code, ap.ponumber, ap.shippingpoint, ap.on_hold, ap.approved, ap.reverse, ap.terms, ap.description, ap.force_closed, ap.crdate
 HAVING sum(ac.amount) <> 0::numeric;

--example of instead trigger on view working under openjpa
CREATE OR REPLACE FUNCTION ap_paid_nok1_delete()
RETURNS TRIGGER AS
$$
BEGIN
 IF TG_OP <> 'DELETE' then
  RAISE EXCEPTION 'TG_OP should be DELETE';
 END IF;
 delete from acc_trans where trans_id=OLD.id;
 DELETE FROM ap WHERE id=OLD.id;
return OLD;
END;
$$ language plpgsql;

CREATE TRIGGER ap_paid_nok1_delete INSTEAD OF DELETE ON ap_paid_nok1 FOR EACH ROW EXECUTE PROCEDURE ap_paid_nok1_delete();

