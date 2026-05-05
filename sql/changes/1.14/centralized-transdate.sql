
drop view if exists cash_impact cascade;

drop trigger ar_prevent_closed on ar;

alter table ar
  drop column transdate;


drop trigger ap_prevent_closed on ap;

alter table ap
  drop column transdate;


drop trigger gl_prevent_closed on gl;

alter table gl
  drop column transdate;


create trigger transactions_prevent_closed
  before insert or update
  on transactions
  for each row execute function prevent_closed_transactions();
