

-- Note that I sure hope that *nobody* *ever* *in their right mind*
-- used this functionality; we should provide a way out to those who
-- did though.

ALTER TABLE gl ADD COLUMN curr char(3);

UPDATE gl
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE NOT EXISTS (select 1 from acc_trans at where at.trans_id = gl.id
                                                and at.fx_transaction);
