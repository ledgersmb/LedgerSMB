
create table custom_attribute_metadata (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  obsolete boolean not null default false,
  type text not null,
  description text,
  config jsonb not null default '{}'::jsonb
  );

comment on table custom_attribute_metadata is
  $$Description of custom attributes, including configuration of UI elements.

  Do not delete records from this table; instead, mark records as 'obsolete'.
  $$;

comment on column custom_attribute_metadata.id is
  $$UUID-valued keys in the 'custom_attribute' jsonb field (of various tables)
  refer to this column; all UUIDs must exist in this table.

  Non-UUID valued keys in the 'custom_attribute' jsonb field of those tables
  will be ignored by the UI.
  $$;

comment on column custom_attribute_metadata.name is
  $$Technical name of the attribute.

  Used as the label in the UI if the `config` does not provide labels.$$;

comment on column custom_attribute_metadata.obsolete is
  $$Attributes with `obsolete` set to true`, will not be available in the
  UI except as a read-only attribute when the value is already assigned.

  The only available action for these attributes is deletion.$$;

comment on column custom_attribute_metadata.type is
  $$Indicates the type of data stored. Supported values:

  - boolean
  - text
  - multiline
  - integer
  - float
  - numeric
  - url
  $$;

comment on column custom_attribute_metadata.description is
  $$The functional description of the attribute. $$;

comment on column custom_attribute_metadata.config is
  $$A json object with configuration dependant on the `type`. $$;

alter table account
  add column custom_attributes jsonb;

alter table asset_item
  add column custom_attributes jsonb;

alter table entity
  add column custom_attributes jsonb;

alter table parts
  add column custom_attributes jsonb;

alter table sic
  add column custom_attributes jsonb;

comment on column account.custom_attributes is
  $$Allows users to add arbitrary attributes.

  Toplevel keys that are UUIDs must exist in the `custom_attribute_metadata`
  table and will be presented in the UI. Storing UUID toplevel keys that
  are not in the metadata table constitutes an error.

  Non-UUID toplevel keys are ignored by the UI, but will be available through
  the API.$$;

comment on column asset_item.custom_attributes is
  $$Allows users to add arbitrary attributes.

  Toplevel keys that are UUIDs must exist in the `custom_attribute_metadata`
  table and will be presented in the UI. Storing UUID toplevel keys that
  are not in the metadata table constitutes an error.

  Non-UUID toplevel keys are ignored by the UI, but will be available through
  the API.$$;

comment on column entity.custom_attributes is
  $$Allows users to add arbitrary attributes.

  Toplevel keys that are UUIDs must exist in the `custom_attribute_metadata`
  table and will be presented in the UI. Storing UUID toplevel keys that
  are not in the metadata table constitutes an error.

  Non-UUID toplevel keys are ignored by the UI, but will be available through
  the API.$$;

comment on column parts.custom_attributes is
  $$Allows users to add arbitrary attributes.

  Toplevel keys that are UUIDs must exist in the `custom_attribute_metadata`
  table and will be presented in the UI. Storing UUID toplevel keys that
  are not in the metadata table constitutes an error.

  Non-UUID toplevel keys are ignored by the UI, but will be available through
  the API.$$;

comment on column sic.custom_attributes is
  $$Allows users to add arbitrary attributes.

  Toplevel keys that are UUIDs must exist in the `custom_attribute_metadata`
  table and will be presented in the UI. Storing UUID toplevel keys that
  are not in the metadata table constitutes an error.

  Non-UUID toplevel keys are ignored by the UI, but will be available through
  the API.$$;

