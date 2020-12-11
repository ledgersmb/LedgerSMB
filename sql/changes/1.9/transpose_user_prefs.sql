
alter table user_preference rename to old_user_preference;
alter table old_user_preference drop constraint user_preference_pkey;


create table user_preference (
   id      serial primary key,
   user_id int check (user_id is null or user_id > 0)
                references users(id) on delete cascade,
   "name"  text not null,
   "value" text not null
);

create unique index user_preference_unique_setting
       on user_preference (coalesce(user_id, 0), "name");

comment on index user_preference_unique_setting is
$$This index replaces the uniqueness check of a primary key and
maps NULL `user_id` values to zero to support uniqueness checks.$$;

comment on table user_preference is
$$This table lists user and global preferences, one preference per row.

Global preferences are stored using a NULL `user_id` value, requiring
a workaround to check uniqueness of the preference `name` column.
$$;

comment on column user_preference.id is
$$This column is a surrogate primary key.

It compensates for the fact that we cannot require `user_id` to be not-null
because global settings will be stored with a NULL `user_id`. It exists to
allow interactive software (e.g. PgAdmin4) to edit rows in the table.$$;

insert into user_preference (id, "name", "value")
select id, 'language', language
from old_user_preference where language is not null
union all
select id, 'stylesheet', stylesheet
from old_user_preference where stylesheet is not null
union all
select id, 'printer', printer
from old_user_preference where printer is not null
union all
select id, 'dateformat', dateformat
from old_user_preference where dateformat is not null
union all
select id, 'numberformat', numberformat
from old_user_preference where numberformat is not null;


drop table old_user_preference;

-- insert global defaults as they used to be set
-- on the columns of the user preference table
insert into user_preference ("name", "value")
values ('stylesheet', 'ledgersmb.css'),
       ('dateformat', 'yyyy-mm-dd'),
       ('numberformat', '1000.00');
