-- function check_department
create function check_department() returns opaque as '

declare
  dpt_id int;

begin
 
  if new.department_id = 0 then
    delete from dpt_trans where trans_id = new.id;
    return NULL;
  end if;

  select into dpt_id trans_id from dpt_trans where trans_id = new.id;
  
  if dpt_id > 0 then
    update dpt_trans set department_id = new.department_id where trans_id = dpt_id;
  else
    insert into dpt_trans (trans_id, department_id) values (new.id, new.department_id);
  end if;
return NULL;

end;
' language 'plpgsql';
-- end function

-- department transaction table
create table dpt_trans (trans_id int, department_id int);

-- function del_department
create function del_department() returns opaque as '
begin
  delete from dpt_trans where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function

-- triggers
--
create trigger check_department after insert or update on ar for each row execute procedure check_department();
-- end trigger
create trigger check_department after insert or update on ap for each row execute procedure check_department();
-- end trigger
create trigger check_department after insert or update on gl for each row execute procedure check_department();
-- end trigger
create trigger check_department after insert or update on oe for each row execute procedure check_department();
-- end trigger
--
--
create trigger del_department after delete on ar for each row execute procedure del_department();
-- end trigger
create trigger del_department after delete on ap for each row execute procedure del_department();
-- end trigger
create trigger del_department after delete on gl for each row execute procedure del_department();
-- end trigger
create trigger del_department after delete on oe for each row execute procedure del_department();
-- end trigger
--

-- business table
create table business (id int default nextval('id'), description text, discount float4);
--
-- SIC
create table sic (code text, sictype char(1), description text);
--
alter table vendor add column gifi_accno text;
alter table vendor add column business_id int;
alter table vendor add column taxnumber text;
alter table vendor add column sic_code text;
--
alter table customer add column business_id int;
alter table customer add column taxnumber text;
alter table customer add column sic_code text;
--
create function del_customer() returns opaque as '
begin
  delete from shipto where trans_id = old.id;
  delete from customertax where customer_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
create function del_vendor() returns opaque as '
begin
  delete from shipto where trans_id = old.id;
  delete from vendortax where vendor_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
create trigger del_customer after delete on customer for each row execute procedure del_customer();
-- end trigger
create trigger del_vendor after delete on vendor for each row execute procedure del_vendor();
-- end trigger
--
alter table acc_trans add column memo text;
--
alter table employee add column sales bool;
alter table employee alter column sales set default 't';
--
alter table vendor add discount float4;
alter table vendor add creditlimit float;
--
-- function del_exchangerate
create function del_exchangerate() returns opaque as '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(curr,1,3) from defaults;
  
  if TG_RELNAME = ''ar'' then
    select into t_curr, t_transdate curr, transdate from ar where id = old.id;
  end if;
  if TG_RELNAME = ''ap'' then
    select into t_curr, t_transdate curr, transdate from ap where id = old.id;
  end if;
  if TG_RELNAME = ''oe'' then
    select into t_curr, t_transdate curr, transdate from oe where id = old.id;
  end if;

  if d_curr != t_curr then

    select into t_id a.id from acc_trans ac
    join ar a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ar a where a.id = old.id
    
    union
    
    select a.id from acc_trans ac
    join ap a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate
    
    except select a.id from ap a where a.id = old.id
    
    union
    
    select o.id from oe o
    where o.curr = t_curr
    and o.transdate = t_transdate
    
    except select o.id from oe o where o.id = old.id;

    if not found then
      delete from exchangerate where curr = t_curr and transdate = t_transdate;
    end if;
  end if;
return old;

end;
' language 'plpgsql';
-- end function
--
-- triggers
--
create trigger del_exchangerate before delete on ar for each row execute procedure del_exchangerate();
-- end trigger
--
create trigger del_exchangerate before delete on ap for each row execute procedure del_exchangerate();
-- end trigger
--
create trigger del_exchangerate before delete on oe for each row execute procedure del_exchangerate();
-- end trigger
--
--
alter table orderitems add ship float4;
alter table orderitems add serialnumber text;
--
--
create sequence orderitemsid maxvalue 100000 cycle;
alter table orderitems add id int;
alter table orderitems alter id set default nextval('orderitemsid');
--
create table warehouse (id int default nextval('id'), description text);
--
create table inventory (warehouse_id int, parts_id int, oe_id int, orderitems_id int, qty float4, shippingdate date);
--
-- update orderitems, fill in id
create table temp (id int default nextval('orderitemsid'), tempid oid);
insert into temp (tempid) select oid from orderitems;
update orderitems set id = temp.id from temp where orderitems.oid = temp.tempid;
drop table temp;
--
create index orderitems_id_key on orderitems (id);
--
alter table ar add shipvia text;
alter table ap add shipvia text;
alter table oe add shipvia text;
--
--
alter table inventory add employee_id int;
--
--
create function check_inventory() returns opaque as '

declare
  itemid int;
  row_data inventory%rowtype;

begin

  if not old.quotation then
    for row_data in select * from inventory where oe_id = old.id loop
      select into itemid id from orderitems where trans_id = old.id and id = row_data.orderitems_id;

      if itemid is null then
	delete from inventory where oe_id = old.id and orderitems_id = row_data.orderitems_id;
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
--
create table yearend (
  trans_id int,
  transdate date
);
--
-- function del_yearend
create function del_yearend() returns opaque as '
begin
  delete from yearend where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function

-- triggers
--
create trigger del_yearend after delete on gl for each row execute procedure del_yearend();
-- end trigger
--
--
create table temp (
  id int default nextval('id'),
  name varchar(64),
  addr1 varchar(64),
  addr2 varchar(64),
  addr3 varchar(64),
  addr4 varchar(64),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  discount float4,
  taxincluded bool,
  creditlimit float default 0,
  terms int2 default 0,
  customernumber varchar(64),
  cc text,
  bcc text,
  business_id int,
  taxnumber varchar(64),
  sic_code varchar(6),
  iban varchar(34),
  bic varchar(11)
);
insert into temp (id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, customernumber, cc, bcc, business_id, taxnumber, sic_code) select id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, customernumber, cc, bcc, business_id, taxnumber, sic_code from customer;
--
drop table customer;
--
alter table temp rename to customer;
--
create index customer_id_key on customer (id);
create index customer_customernumber_key on customer (customernumber);
create index customer_name_key on customer (name);
create index customer_contact_key on customer (contact);
--
create trigger del_customer after delete on customer for each row execute procedure del_customer();
-- end trigger
--
create table temp (
  id int default nextval('id'),
  name varchar(64),
  addr1 varchar(64),
  addr2 varchar(64),
  addr3 varchar(64),
  addr4 varchar(64),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms int2 default 0,
  taxincluded bool,
  vendornumber varchar(64),
  cc text,
  bcc text,
  gifi_accno varchar(30),
  business_id int,
  taxnumber varchar(64),
  sic_code varchar(6),
  discount float4,
  creditlimit float default 0,
  iban varchar(34),
  bic varchar(11)
);
insert into temp (id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, vendornumber, cc, bcc, business_id, taxnumber, sic_code) select id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, vendornumber, cc, bcc, business_id, taxnumber, sic_code from vendor;
--
drop table vendor;
--
alter table temp rename to vendor;
--
create index vendor_id_key on vendor (id);
create index vendor_name_key on vendor (name);
create index vendor_vendornumber_key on vendor (vendornumber);
create index vendor_contact_key on vendor (contact);
--
create trigger del_vendor after delete on vendor for each row execute procedure del_vendor();
-- end trigger
--
create table temp (
  code varchar(6),
  sictype char(1),
  description text
);
insert into temp (code, sictype, description) select code, sictype, description from sic;
drop table sic;
alter table temp rename to sic;
--
create table temp (
  trans_id int,
  shiptoname varchar(64),
  shiptoaddr1 varchar(64),
  shiptoaddr2 varchar(64),
  shiptoaddr3 varchar(64),
  shiptoaddr4 varchar(64),
  shiptocontact varchar(64),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
insert into temp (trans_id, shiptoname, shiptoaddr1, shiptoaddr2, shiptoaddr3, shiptoaddr4, shiptocontact, shiptophone, shiptofax, shiptoemail) select trans_id, shiptoname, shiptoaddr1, shiptoaddr2, shiptoaddr3, shiptoaddr4, shiptocontact, shiptophone, shiptofax, shiptoemail from shipto;
drop table shipto;
alter table temp rename to shipto;
create index shipto_trans_id_key on shipto (trans_id);
--
--
create table temp (
  id int default nextval('id'),
  login text,
  name varchar(64),
  addr1 varchar(64),
  addr2 varchar(64),
  addr3 varchar(64),
  addr4 varchar(64),
  workphone varchar(20),
  homephone varchar(20),
  startdate date default current_date,
  enddate date,
  notes text,
  role varchar(20),
  sales bool,
  email text,
  sin varchar(20),
  iban varchar(34),
  bic varchar(11)
);
insert into temp (id,login,name,addr1,addr2,addr3,addr4,workphone,homephone,startdate,enddate,notes,role,sales) select id,login,name,addr1,addr2,addr3,addr4,workphone,homephone,startdate,enddate,notes,role,sales from employee;
--
drop table employee;
alter table temp rename to employee;
--
create index employee_id_key on employee (id);
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (name);
--
update defaults set version = '2.3.1';

