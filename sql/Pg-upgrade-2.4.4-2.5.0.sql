--
alter table ar add ponumber text;
alter table ap add ponumber text;
alter table oe add ponumber text;
--
alter table project add startdate date;
alter table project add enddate date;
--
create table recurring (id int, reference text, startdate date, nextdate date, enddate date, repeat int2, unit varchar(6), howmany int, payment bool default 'f');
create table recurringemail (id int, formname text, format text, message text);
create table recurringprint (id int, formname text, format text, printer text);
--
create function del_recurring() returns opaque as '
begin
  delete from recurring where id = old.id;
  delete from recurringemail where id = old.id;
  delete from recurringprint where id = old.id;
  return NULL;
end;
' language 'plpgsql';
--end function
create trigger del_recurring after delete on ar for each row execute procedure del_recurring();
-- end trigger
create trigger del_recurring after delete on ap for each row execute procedure del_recurring();
-- end trigger
create trigger del_recurring after delete on gl for each row execute procedure del_recurring();
-- end trigger
create trigger del_recurring after delete on oe for each row execute procedure del_recurring();
-- end trigger
--
update defaults set version = '2.5.0';
