


UPDATE ar
   SET amount_bc = amount,
       netamount_bc = netamount;

UPDATE ar
   SET amount_tc = amount_bc,
       netamount_tc = netamount_bc
 WHERE curr = (select value from defaults where setting_key = 'curr');

UPDATE ar
   SET amount_tc = amount_bc / (select buy from exchangerate e
                                 where e.transdate = ar.transdate
                                       and ar.curr = e.curr),
       netamount_tc = netamount_bc / (select buy from exchangerate e
                                 where e.transdate = ar.transdate
                                       and ar.curr = e.curr)
 WHERE NOT curr = (select value from defaults where setting_key = 'curr');


UPDATE ap
   SET amount_bc = amount,
       netamount_bc = netamount;

UPDATE ap
   SET amount_tc = amount_bc,
       netamount_tc = netamount_bc
 WHERE curr = (select value from defaults where setting_key = 'curr');

UPDATE ap
   SET amount_tc = amount_bc / (select sell from exchangerate e
                                 where e.transdate = ap.transdate
                                       and ap.curr = e.curr),
       netamount_tc = netamount_bc / (select sell from exchangerate e
                                 where e.transdate = ap.transdate
                                       and ap.curr = e.curr)
 WHERE NOT curr = (select value from defaults where setting_key = 'curr');
