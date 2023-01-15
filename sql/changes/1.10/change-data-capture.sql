
/*

1.10.0 through 1.10.9 included 'moddatetime' for change data capture. This
turned out to be a mistake, because due to the untrusted nature of the
extension (it being a C extension), it can only be created by a super user.

However, we want the database to be creatable by a user with 'createdb'
rights. Those rights are insufficient to create the moddatetime extension.


Note that there is *no* "old version" (@1) version of this file, because
that would prevent this file from being run on those installations where
the old content has already run. However, in order to fix the situation,
we *do* want the content in this file to run...

 */


-- drop all triggers based on moddatetime in a single blow
drop extension if exists moddatetime cascade;

create or replace function cdc_update_last_updated()
  returns trigger as
$$
BEGIN
END;
$$ LANGUAGE PLPGSQL;

-- fix triggers that may have been created in 1.10.0-1.10.9..
drop trigger if exists business_update_last_updated on business;
create trigger business_update_last_updated
   before update on business
   for each row execute procedure cdc_update_last_updated();

drop trigger if exists gifi_update_last_updated on gifi;
create trigger gifi_update_last_updated
   before update on gifi
   for each row execute procedure cdc_update_last_updated();

drop trigger if exists language_update_last_updated on language;
create trigger language_update_last_updated
   before update on language
   for each row execute procedure cdc_update_last_updated();

drop trigger if exists pricegroup_update_last_updated on pricegroup;
create trigger pricegroup_update_last_updated
   before update on pricegroup
   for each row execute procedure cdc_update_last_updated();

drop trigger if exists sic_update_last_updated on sic;
create trigger sic_update_last_updated
  before update on sic
  for each row execute procedure cdc_update_last_updated();

drop trigger if exists warehouse_update_last_updated on warehouse;
create trigger warehouse_update_last_updated
   before update on warehouse
   for each row execute procedure cdc_update_last_updated();

