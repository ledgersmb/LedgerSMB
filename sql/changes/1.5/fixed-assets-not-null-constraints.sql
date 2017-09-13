

alter table asset_item
  alter column purchase_value set not null,
  alter column salvage_value set not null,
  alter column usable_life set not null;


