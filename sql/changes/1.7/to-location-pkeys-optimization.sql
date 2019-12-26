

-- When querying the location-entity link tables (eca_to_location
-- and entity_to_location), we're most likely to start with an
-- entity/eca, looking for a location (of a specific class).

-- This means the current index/primary key is highly inefficiently
-- organized: with the location first in the index, we need to know
-- the location id before being able to query the index.

-- However, with the entity/eca id first, the pkey index can be
-- used to *quickly* look up locations associated with an entity/eca
-- (the regular use-case, I'm assuming).


alter table entity_to_location
   drop constraint entity_to_location_pkey,
   add constraint entity_to_location_pkey
                  primary key (entity_id, location_class, location_id);

alter table eca_to_location
   drop constraint eca_to_location_pkey,
   add constraint eca_to_location_pkey
                  primary key (credit_id, location_class, location_id);

