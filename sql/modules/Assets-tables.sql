CREATE TABLE asset_unit_class (
	id int not null unique,
	class text primary key
);

INSERT INTO asset_unit_class (id, class) values (1, 'time');
INSERT INTO asset_unit_class (id, class) values (2, 'production'); 
-- production-based depreciation is unlikely to be supported initially

CREATE TABLE asset_dep_method(
	id serial unique not null,
	method text primary key,
        sproc text not null unique,
	unit_class int not null references asset_unit_class(id) 
);

comment on column asset_dep_method.method IS 
$$ These are keyed to specific stored procedures.  Currently only "straight_line" is supported$$;

INSERT INTO asset_dep_method(method, unit_class, sproc) 
values ('Straight Line', 1, 'asset_dep_straight_line');

CREATE TABLE asset_life_unit(
	id serial unique not null,
	unit text primary key,
	unit_class int not null references asset_unit_class(id),
	div numeric not null
);

INSERT INTO asset_life_unit(unit, unit_class, div) values ('year', 1, 1);
-- year is only supported unit at present

CREATE TABLE asset_class (
	id serial not null unique,
	label text primary key,
	asset_account_id int references account(id),
	dep_account_id int references account(id),
	method int references asset_dep_method(id),
	life_unit int references asset_life_unit(id)
);

CREATE TABLE asset_item (
	id serial not null unique,
	description text,
	tag text primary key,
	purchase_value numeric,
	salvage_value numeric,
	usable_life numeric,
	purchase_date date  not null,
	asset_class_id int references asset_class(id)
);

COMMENT ON column asset_item.tag IS $$ This can be plugged into other routines to generate it automatically via ALTER TABLE .... SET DEFAULT.....$$;

CREATE TABLE asset_report_class (
	id int not null unique,
	class text primary key
);

INSERT INTO asset_report_class (id, class) values (1, 'depreciation');
INSERT INTO asset_report_class (id, class) values (2, 'disposal');

CREATE TABLE asset_report (
	id serial primary key,
	report_date date,
	gl_id bigint references gl(id) unique,
	asset_class bigint references asset_class(id),
	report_class int references asset_report_class(id),
	entered_by bigint not null references entity(id),
	approved_by bigint references entity(id),
	entered_at timestamp default now(),
	approved_at timestamp,
	depreciated_qty numeric,
	submitted bool not null default false
);

CREATE TABLE asset_report_line(
	asset_id bigint references asset_item(id),
        report_id bigint references asset_report(id),
	amount numeric,
	PRIMARY KEY(asset_id, report_id)
);
