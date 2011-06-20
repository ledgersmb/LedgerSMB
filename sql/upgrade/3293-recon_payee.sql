
CREATE OR REPLACE VIEW recon_payee AS
 SELECT n.name AS payee, rr.id, rr.report_id, rr.scn, rr.their_balance, rr.our_balance, rr.errorcode, rr."user", rr.clear_time, rr.insert_time, rr.trans_type, rr.post_date, rr.ledger_id, rr.voucher_id, rr.overlook, rr.cleared
   FROM cr_report_line rr
   LEFT JOIN acc_trans ac ON rr.ledger_id = ac.entry_id
   LEFT JOIN gl ON ac.trans_id = gl.id
   LEFT JOIN (( SELECT ap.id, e.name
   FROM ap
   JOIN entity_credit_account eca ON ap.entity_credit_account = eca.id
   JOIN entity e ON eca.entity_id = e.id
UNION 
 SELECT ar.id, e.name
   FROM ar
   JOIN entity_credit_account eca ON ar.entity_credit_account = eca.id
   JOIN entity e ON eca.entity_id = e.id)
UNION 
 SELECT gl.id, gl.description
   FROM gl) n ON n.id = ac.trans_id;


CREATE OR REPLACE FUNCTION reconciliation__report_details_payee (in_report_id INT) RETURNS setof recon_payee as $$
   DECLARE
        row recon_payee;
    BEGIN    
        FOR row IN 
        	select * from recon_payee where report_id = in_report_id 
        	order by scn, post_date
        LOOP
          RETURN NEXT row;
        END LOOP;    
    END;
$$ language 'plpgsql';