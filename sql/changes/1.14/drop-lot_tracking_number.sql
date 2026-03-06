
insert into defaults (setting_key, value)
values ('lotnumber', nextval('lot_tracking_number'));

alter table mfg_lot
  alter column lot_number drop default;

drop sequence if exists lot_tracking_number;
