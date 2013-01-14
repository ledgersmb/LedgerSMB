
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
        unit_label text not null,
        short_name text not null unique,
	unit_class int not null references asset_unit_class(id) 
);

comment on column asset_dep_method.method IS 
$$ These are keyed to specific stored procedures.  Currently only "straight_line" is supported$$;

INSERT INTO asset_dep_method(method, unit_class, sproc, unit_label, short_name) 
values ('Annual Straight Line Daily', 1, 'asset_dep_straight_line_yr_d', 'in years', 'SLYD');


INSERT INTO asset_dep_method(method, unit_class, sproc, unit_label, short_name) 
values ('Whole Month Straight Line', 1, 'asset_dep_straight_line_whl_m', 
'in months', 'SLMM');

INSERT INTO asset_dep_method(method, unit_class, sproc, unit_label, short_name) 
values ('Annual Straight Line Daily', 1, 'asset_dep_straight_line_yr_m', 'in years', 'SLYM');

CREATE TABLE asset_class (
	id serial not null unique,
	label text primary key,
	asset_account_id int references account(id),
	dep_account_id int references account(id),
	method int references asset_dep_method(id)
);

COMMENT ON TABLE asset_class IS $$
The account fields here set the defaults for the individual asset items.  They
are non-authoritative.
$$;

CREATE TABLE asset_disposal_method (
       label text primary key,
       id serial unique,
       multiple int check (multiple in (1, 0, -1)),
       short_label char(1)
);

INSERT INTO asset_disposal_method (label, multiple, short_label)
values ('Abandonment', '0', 'A');
INSERT INTO asset_disposal_method (label, multiple, short_label)
values ('Sale', '1', 'S');

CREATE TABLE asset_rl_to_disposal_method (
       report_id int references asset_report(id),
       asset_id int references asset_item(id),
       disposal_method_id int references asset_disposal_method(id),
       percent_disposed numeric,
       primary key (report_id, asset_id, disposal_method_id)
);

CREATE TABLE asset_item (
	id serial primary key, -- needed due to possible null in natural key
	description text,
	tag text not null,
	purchase_value numeric,
	salvage_value numeric,
	usable_life numeric,
	purchase_date date  not null,
        start_depreciation date not null,
	location_id int references warehouse(id),
	department_id int references department(id),
	invoice_id int references ap(id),
	asset_account_id int references account(id),
	dep_account_id int references account(id),
	exp_account_id int references account(id),
        obsolete_by int references asset_item(id),
	asset_class_id int references asset_class(id),
        unique (tag, obsolete_by) -- part 1 of natural key enforcement
);

CREATE UNIQUE INDEX asset_item_active_tag_u ON asset_item(tag) 
              WHERE obsolete_by is null; -- part 2 of natural key enforcement

COMMENT ON column asset_item.tag IS $$ This can be plugged into other routines to generate it automatically via ALTER TABLE .... SET DEFAULT.....$$;

CREATE TABLE asset_note (
    foreign key (ref_key) references asset_item(id),
    check (note_class = 4)
) inherits (note);

INSERT INTO note_class (id, class) values (4, 'Asset');
ALTER TABLE asset_note alter column note_class set default 4;

CREATE TABLE asset_report_class (
	id int not null unique,
	class text primary key
);

INSERT INTO asset_report_class (id, class) values (1, 'depreciation');
INSERT INTO asset_report_class (id, class) values (2, 'disposal');
INSERT INTO asset_report_class (id, class) values (3, 'import');
INSERT INTO asset_report_class (id, class) values (4, 'partial disposal');

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
        dont_approve bool default false,
	submitted bool not null default false
);

CREATE TABLE asset_report_line(
	asset_id bigint references asset_item(id),
        report_id bigint references asset_report(id),
	amount numeric,
	department_id int references department(id),
	warehouse_id int references warehouse(id),
	PRIMARY KEY(asset_id, report_id)
);

COMMENT ON COLUMN asset_report_line.department_id IS
$$ In case assets are moved between departments, we have to store this here.$$;
