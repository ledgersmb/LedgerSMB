--
drop trigger del_customer on customer;
drop trigger del_vendor on vendor;
drop function del_customer();
drop function del_vendor();
--
create function del_customer() returns opaque as '
begin
  delete from shipto where trans_id = old.id;
  delete from customertax where customer_id = old.id;
  delete from partscustomer where customer_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
create trigger del_customer after delete on customer for each row execute procedure del_customer();
-- end trigger
--
create function del_vendor() returns opaque as '
begin
  delete from shipto where trans_id = old.id;
  delete from vendortax where vendor_id = old.id;
  delete from partsvendor where vendor_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
-- 
create trigger del_vendor after delete on vendor for each row execute procedure del_vendor();
-- end trigger
--
update defaults set version = '2.4.2';

