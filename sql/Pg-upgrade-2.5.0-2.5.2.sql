--
create sequence jcitemsid;
create table jcitems (id int default nextval('jcitemsid'), project_id int, parts_id int, description text, qty float4, allocated float4, sellprice float8, fxsellprice float8, serialnumber text, checkedin timestamp with time zone, checkedout timestamp with time zone, employee_id int);
create index jcitems_id_key on jcitems (id);
--
alter table project add parts_id int;
alter table project add production float; 
alter table project add completed float;
alter table project add customer_id int;
alter table project alter production set default 0;
alter table project alter completed set default 0;
update project set production = 0, completed = 0;
--
alter table parts add project_id int;
--
alter table parts add avgcost float;
--
create function avgcost(int) returns float as '

declare

v_cost float;
v_qty float;
v_parts_id alias for $1;

begin

  select into v_cost, v_qty sum(i.sellprice * i.qty), sum(i.qty)
    from invoice i
    join ap a on (a.id = i.trans_id)
    where i.parts_id = v_parts_id;

  if not v_qty is null then
    v_cost := v_cost/v_qty;
  end if;

  if v_cost is null then
    v_cost := 0;
  end if;

return v_cost;

end;
' language 'plpgsql';
-- end function
--
create function lastcost(int) returns float as '

declare

v_cost float;
v_parts_id alias for $1;

begin

  select into v_cost sellprice from invoice i
    join ap a on (a.id = i.trans_id)
    where i.parts_id = v_parts_id
    order by a.transdate desc
    limit 1;

  if v_cost is null then
    v_cost := 0;
  end if;

return v_cost;

end;
' language 'plpgsql';
-- end function
--
alter table inventory rename oe_id to trans_id;
--
alter table ap add shippingpoint text;
alter table ap add terms int2;
--
drop trigger check_inventory on oe;
drop function check_inventory();
create function check_inventory() returns opaque as '

declare
  itemid int;
  row_data inventory%rowtype;

begin

  if not old.quotation then
    for row_data in select * from inventory where trans_id = old.id loop
      select into itemid id from orderitems where trans_id = old.id and id = row_data.orderitems_id;

      if itemid is null then
        delete from inventory where trans_id = old.id and orderitems_id = row_data.orderitems_id;
      end if;
    end loop;
  end if;
return old;
end;
' language 'plpgsql';
-- end function
--
create trigger check_inventory after update on oe for each row execute procedure check_inventory();
-- end trigger
--
alter table orderitems alter id drop default;
--
create function temp() returns int as '

declare
  v_last int;

begin

  SELECT INTO v_last last_value FROM orderitemsid;
  drop sequence orderitemsid;
  create sequence orderitemsid;
  perform setval(''orderitemsid'', v_last);

return NULL;
end;
' language 'plpgsql';
-- end function
--
select temp();
drop function temp();
--
alter table orderitems alter id set default nextval('orderitemsid');
--
alter table chart add contra boolean;
alter table chart alter contra set default 'f';
update chart set category = 'A', contra = '1' where category = 'C';
update chart set contra = '0' where contra is null;
--
alter table defaults add glnumber text;
--
update defaults set version = '2.5.2';

