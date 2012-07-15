CREATE LANGUAGE PLPGSQL; -- separate transaction since may already exist
CREATE EXTENSION tablefunc; -- Separate transaction, only needed for 9.1
CREATE EXTENSION pg_trgm; -- Separate transaction, only needed for 9.1
CREATE EXTENSION btree_gist; -- Separate transaction, only needed for 9.1

begin;
CREATE SEQUENCE id;
-- As of 1.3 there is no central db anymore. --CT

CREATE OR REPLACE FUNCTION concat_colon(TEXT, TEXT) returns TEXT as
$$
select CASE WHEN $1 IS NULL THEN $2 ELSE $1 || ':' || $2 END;
$$ language sql;

COMMENT ON FUNCTION concat_colon(TEXT, TEXT) IS $$
This function takes two arguments and creates a list out  of them.  It's useful 
as an aggregate base (see aggregate concat_colon).  However this is a temporary
function only and should not be relied upon.$$; --'

CREATE AGGREGATE concat_colon (
	BASETYPE = text,
	STYPE = text,
	SFUNC = concat_colon
);

COMMENT ON AGGREGATE concat_colon(text) IS 
$$ This is a sumple aggregate to return values from the database in a 
colon-separated list.  Other programs probably should not rely on this since 
it is primarily included for the chart view.$$;

CREATE TABLE account_heading (
  id serial not null unique,
  accno text primary key,
  parent_id int references account_heading(id),
  description text
);

COMMENT ON TABLE account_heading IS $$
This table holds the account headings in the system.  Each account must belong 
to a heading, and a heading can belong to another heading.  In this way it is 
possible to nest accounts for reporting purposes.$$;

CREATE TABLE account (
  id serial not null unique,
  accno text primary key,
  description text,
  category CHAR(1) NOT NULL,
  gifi_accno text,
  heading int not null references account_heading(id),
  contra bool not null default false,
  tax bool not null default false
);

COMMENT ON TABLE  account IS
$$ This table stores the main account info.$$;

CREATE TABLE account_checkpoint (
  end_date date not null, 
  account_id int not null references account(id), 
  amount numeric not null,
  id serial not null unique,
  debits NUMERIC,
  credits NUMERIC,
  primary key (end_date, account_id)
);

COMMENT ON TABLE account_checkpoint IS
$$ This table holds account balances at various dates.  Transactions MUST NOT
be posted prior to the latest end_date in this table, and no unapproved 
transactions (vouchers or drafts) can remain in the closed period.$$;

CREATE TABLE account_link_description (
    description text    primary key,
    summary     boolean not null,
    custom      boolean not null   
);

COMMENT ON TABLE account_link_description IS 
$$ This is a lookup table which provide basic information as to categories and
dropdowns of accounts.  In general summary accounts cannot belong to more than 
one category (an AR summary account cannot appear in other dropdowns for 
example).  Custom fields are not overwritten when the account is edited from
the front-end.$$;

INSERT INTO account_link_description (description, summary, custom) 
VALUES 
--summary links
('AR', TRUE, FALSE),
('AP', TRUE, FALSE),
('IC', TRUE, FALSE),
--custom links NOT INCLUDED
('AR_amount',      FALSE, FALSE),
('AR_tax',         FALSE, FALSE),
('AR_paid',        FALSE, FALSE),
('AR_overpayment', FALSE, FALSE),
('AR_discount',    FALSE, FALSE),
('AP_amount',      FALSE, FALSE),
('AP_expense',     FALSE, FALSE),
('AP_tax',         FALSE, FALSE),
('AP_paid',        FALSE, FALSE),
('AP_overpayment', FALSE, FALSE),
('AP_discount',    FALSE, FALSE),
('IC_sale',        FALSE, FALSE),
('IC_tax',         FALSE, FALSE),
('IC_cogs',        FALSE, FALSE),
('IC_taxpart',     FALSE, FALSE),
('IC_taxservice',  FALSE, FALSE),
('IC_income',      FALSE, FALSE),
('IC_expense',     FALSE, FALSE),
('Asset_Dep',      FALSE, FALSE),
('Fixed_Asset',    FALSE, FALSE),
('asset_expense',  FALSE, FALSE),
('asset_gain',     FALSE, FALSE),
('asset_loss',     FALSE, FALSE);


CREATE TABLE account_link (
   account_id int references account(id),
   description text references account_link_description(description),
   primary key (account_id, description)
);

CREATE VIEW chart AS
SELECT id, accno, description, 'H' as charttype, NULL as category, NULL as link, NULL as account_heading, null as gifi_accno, false as contra, false as tax from account_heading UNION
select c.id, c.accno, c.description, 'A' as charttype, c.category, concat_colon(l.description) as link, heading, gifi_accno, contra, tax from account c left join account_link l ON (c.id = l.account_id) group by c.id, c.accno, c.description, c.category, c.heading, c.gifi_accno, c.contra, c.tax;

GRANT SELECT ON chart TO public;

COMMENT ON VIEW chart IS $$Compatibility chart for 1.2 and earlier.$$;
-- pricegroup added here due to references
CREATE TABLE pricegroup (
  id serial PRIMARY KEY,
  pricegroup text
);


COMMENT ON TABLE pricegroup IS
$$ Pricegroups are groups of customers who are assigned prices and discounts
together.$$;
--TABLE language moved here because of later references
CREATE TABLE language (
  code varchar(6) PRIMARY KEY,
  description text
);
COMMENT ON TABLE language IS
$$ Languages for manual translations and so forth.$$;
INSERT INTO language (code, description)
VALUES ('ar_EG', 'Arabic (Egypt)'),
       ('es_AR', 'Spanish (Argentina)'),
       ('bg',    'Bulgarian'), 
       ('ca',    'Catalan'),
       ('cs',    'Czech'),
       ('da',    'Danish'),
       ('de',    'German'),
       ('de_CH', 'German (Switzerland)'),
       ('el',    'Greek'),
       ('en',    'English'),
       ('en_US', 'English (US)'),
       ('en_GB', 'English (UK)'),
       ('es',    'Spanish'),
       ('es_CO', 'Spanish (Colombia)'),
       ('es_EC', 'Spanish (Ecuador)'),
       ('es_MX', 'Spanish (Mexico)'),
       ('es_PA', 'Spanish (Panama)'),
       ('es_PY', 'Spanish (Paraguay)'),
       ('es_VE', 'Spanish (Venezuela)'),
       ('et',    'Estonian'),
       ('fi',    'Finnish'),
       ('fr',    'French'),
       ('fr_BE', 'French (Belgium)'),
       ('fr_CA', 'French (Canada)'),
       ('hu',    'Hungarian'),
       ('id',    'Indonesian'),
       ('is',    'Icelandic'),
       ('it',    'Italian'),
       ('lt',    'Latvian'),
       ('nb',    'Norwegian'),
       ('nl',    'Dutch'),
       ('nl_BE', 'Dutch (Belgium)'),
       ('pl',    'Polish'),
       ('pt',    'Portuguese'),
       ('pt_BR', 'Portuguese (Brazil)'),
       ('ru',    'Russian'),
       ('sv',    'Swedish'),
       ('tr',    'Turkish'),
       ('uk',    'Ukranian'),
       ('zh_CN', 'Chinese (China)'),
       ('zh_TW', 'Chinese (Taiwan)');
-- country and tax form

CREATE TABLE country (
  id serial PRIMARY KEY,
  name text check (name ~ '[[:alnum:]_]') NOT NULL,
  short_name text check (short_name ~ '[[:alnum:]_]') NOT NULL,
  itu text);

COMMENT ON COLUMN country.itu IS $$ The ITU Telecommunication Standardization Sector code for calling internationally. For example, the US is 1, Great Britain is 44 $$;

CREATE UNIQUE INDEX country_name_idx on country(lower(name));

-- Populate some country data

INSERT INTO country(short_name,name) VALUES ('AC','Ascension Island');
INSERT INTO country(short_name,name) VALUES ('AD','Andorra');
INSERT INTO country(short_name,name) VALUES ('AE','United Arab Emirates');
INSERT INTO country(short_name,name) VALUES ('AF','Afghanistan');
INSERT INTO country(short_name,name) VALUES ('AG','Antigua and Barbuda');
INSERT INTO country(short_name,name) VALUES ('AI','Anguilla');
INSERT INTO country(short_name,name) VALUES ('AL','Albania');
INSERT INTO country(short_name,name) VALUES ('AM','Armenia');
INSERT INTO country(short_name,name) VALUES ('AN','Netherlands Antilles');
INSERT INTO country(short_name,name) VALUES ('AO','Angola');
INSERT INTO country(short_name,name) VALUES ('AQ','Antarctica');
INSERT INTO country(short_name,name) VALUES ('AR','Argentina');
INSERT INTO country(short_name,name) VALUES ('AS','American Samoa');
INSERT INTO country(short_name,name) VALUES ('AT','Austria');
INSERT INTO country(short_name,name) VALUES ('AU','Australia');
INSERT INTO country(short_name,name) VALUES ('AW','Aruba');
INSERT INTO country(short_name,name) VALUES ('AX','Aland Islands');
INSERT INTO country(short_name,name) VALUES ('AZ','Azerbaijan');
INSERT INTO country(short_name,name) VALUES ('BA','Bosnia and Herzegovina');
INSERT INTO country(short_name,name) VALUES ('BB','Barbados');
INSERT INTO country(short_name,name) VALUES ('BD','Bangladesh');
INSERT INTO country(short_name,name) VALUES ('BE','Belgium');
INSERT INTO country(short_name,name) VALUES ('BF','Burkina Faso');
INSERT INTO country(short_name,name) VALUES ('BG','Bulgaria');
INSERT INTO country(short_name,name) VALUES ('BH','Bahrain');
INSERT INTO country(short_name,name) VALUES ('BI','Burundi');
INSERT INTO country(short_name,name) VALUES ('BJ','Benin');
INSERT INTO country(short_name,name) VALUES ('BM','Bermuda');
INSERT INTO country(short_name,name) VALUES ('BN','Brunei Darussalam');
INSERT INTO country(short_name,name) VALUES ('BO','Bolivia');
INSERT INTO country(short_name,name) VALUES ('BR','Brazil');
INSERT INTO country(short_name,name) VALUES ('BS','Bahamas');
INSERT INTO country(short_name,name) VALUES ('BT','Bhutan');
INSERT INTO country(short_name,name) VALUES ('BV','Bouvet Island');
INSERT INTO country(short_name,name) VALUES ('BW','Botswana');
INSERT INTO country(short_name,name) VALUES ('BY','Belarus');
INSERT INTO country(short_name,name) VALUES ('BZ','Belize');
INSERT INTO country(short_name,name) VALUES ('CA','Canada');
INSERT INTO country(short_name,name) VALUES ('CC','Cocos (Keeling) Islands');
INSERT INTO country(short_name,name) VALUES ('CD','Congo, Democratic Republic');
INSERT INTO country(short_name,name) VALUES ('CF','Central African Republic');
INSERT INTO country(short_name,name) VALUES ('CG','Congo');
INSERT INTO country(short_name,name) VALUES ('CH','Switzerland');
INSERT INTO country(short_name,name) VALUES ('CI','Cote D''Ivoire (Ivory Coast)');
INSERT INTO country(short_name,name) VALUES ('CK','Cook Islands');
INSERT INTO country(short_name,name) VALUES ('CL','Chile');
INSERT INTO country(short_name,name) VALUES ('CM','Cameroon');
INSERT INTO country(short_name,name) VALUES ('CN','China');
INSERT INTO country(short_name,name) VALUES ('CO','Colombia');
INSERT INTO country(short_name,name) VALUES ('CR','Costa Rica');
INSERT INTO country(short_name,name) VALUES ('CS','Czechoslovakia (former)');
INSERT INTO country(short_name,name) VALUES ('CU','Cuba');
INSERT INTO country(short_name,name) VALUES ('CV','Cape Verde');
INSERT INTO country(short_name,name) VALUES ('CX','Christmas Island');
INSERT INTO country(short_name,name) VALUES ('CY','Cyprus');
INSERT INTO country(short_name,name) VALUES ('CZ','Czech Republic');
INSERT INTO country(short_name,name) VALUES ('DE','Germany');
INSERT INTO country(short_name,name) VALUES ('DJ','Djibouti');
INSERT INTO country(short_name,name) VALUES ('DK','Denmark');
INSERT INTO country(short_name,name) VALUES ('DM','Dominica');
INSERT INTO country(short_name,name) VALUES ('DO','Dominican Republic');
INSERT INTO country(short_name,name) VALUES ('DZ','Algeria');
INSERT INTO country(short_name,name) VALUES ('EC','Ecuador');
INSERT INTO country(short_name,name) VALUES ('EE','Estonia');
INSERT INTO country(short_name,name) VALUES ('EG','Egypt');
INSERT INTO country(short_name,name) VALUES ('EH','Western Sahara');
INSERT INTO country(short_name,name) VALUES ('ER','Eritrea');
INSERT INTO country(short_name,name) VALUES ('ES','Spain');
INSERT INTO country(short_name,name) VALUES ('ET','Ethiopia');
INSERT INTO country(short_name,name) VALUES ('FI','Finland');
INSERT INTO country(short_name,name) VALUES ('FJ','Fiji');
INSERT INTO country(short_name,name) VALUES ('FK','Falkland Islands (Malvinas)');
INSERT INTO country(short_name,name) VALUES ('FM','Micronesia');
INSERT INTO country(short_name,name) VALUES ('FO','Faroe Islands');
INSERT INTO country(short_name,name) VALUES ('FR','France');
INSERT INTO country(short_name,name) VALUES ('FX','France, Metropolitan');
INSERT INTO country(short_name,name) VALUES ('GA','Gabon');
INSERT INTO country(short_name,name) VALUES ('GB','Great Britain (UK)');
INSERT INTO country(short_name,name) VALUES ('GD','Grenada');
INSERT INTO country(short_name,name) VALUES ('GE','Georgia');
INSERT INTO country(short_name,name) VALUES ('GF','French Guiana');
INSERT INTO country(short_name,name) VALUES ('GH','Ghana');
INSERT INTO country(short_name,name) VALUES ('GI','Gibraltar');
INSERT INTO country(short_name,name) VALUES ('GL','Greenland');
INSERT INTO country(short_name,name) VALUES ('GM','Gambia');
INSERT INTO country(short_name,name) VALUES ('GN','Guinea');
INSERT INTO country(short_name,name) VALUES ('GP','Guadeloupe');
INSERT INTO country(short_name,name) VALUES ('GQ','Equatorial Guinea');
INSERT INTO country(short_name,name) VALUES ('GR','Greece');
INSERT INTO country(short_name,name) VALUES ('GS','S. Georgia and S. Sandwich Isls.');
INSERT INTO country(short_name,name) VALUES ('GT','Guatemala');
INSERT INTO country(short_name,name) VALUES ('GU','Guam');
INSERT INTO country(short_name,name) VALUES ('GW','Guinea-Bissau');
INSERT INTO country(short_name,name) VALUES ('GY','Guyana');
INSERT INTO country(short_name,name) VALUES ('HK','Hong Kong');
INSERT INTO country(short_name,name) VALUES ('HM','Heard and McDonald Islands');
INSERT INTO country(short_name,name) VALUES ('HN','Honduras');
INSERT INTO country(short_name,name) VALUES ('HR','Croatia (Hrvatska)');
INSERT INTO country(short_name,name) VALUES ('HT','Haiti');
INSERT INTO country(short_name,name) VALUES ('HU','Hungary');
INSERT INTO country(short_name,name) VALUES ('ID','Indonesia');
INSERT INTO country(short_name,name) VALUES ('IE','Ireland');
INSERT INTO country(short_name,name) VALUES ('IL','Israel');
INSERT INTO country(short_name,name) VALUES ('IM','Isle of Man');
INSERT INTO country(short_name,name) VALUES ('IN','India');
INSERT INTO country(short_name,name) VALUES ('IO','British Indian Ocean Territory');
INSERT INTO country(short_name,name) VALUES ('IQ','Iraq');
INSERT INTO country(short_name,name) VALUES ('IR','Iran');
INSERT INTO country(short_name,name) VALUES ('IS','Iceland');
INSERT INTO country(short_name,name) VALUES ('IT','Italy');
INSERT INTO country(short_name,name) VALUES ('JE','Jersey');
INSERT INTO country(short_name,name) VALUES ('JM','Jamaica');
INSERT INTO country(short_name,name) VALUES ('JO','Jordan');
INSERT INTO country(short_name,name) VALUES ('JP','Japan');
INSERT INTO country(short_name,name) VALUES ('KE','Kenya');
INSERT INTO country(short_name,name) VALUES ('KG','Kyrgyzstan');
INSERT INTO country(short_name,name) VALUES ('KH','Cambodia');
INSERT INTO country(short_name,name) VALUES ('KI','Kiribati');
INSERT INTO country(short_name,name) VALUES ('KM','Comoros');
INSERT INTO country(short_name,name) VALUES ('KN','Saint Kitts and Nevis');
INSERT INTO country(short_name,name) VALUES ('KP','Korea (North)');
INSERT INTO country(short_name,name) VALUES ('KR','Korea (South)');
INSERT INTO country(short_name,name) VALUES ('KW','Kuwait');
INSERT INTO country(short_name,name) VALUES ('KY','Cayman Islands');
INSERT INTO country(short_name,name) VALUES ('KZ','Kazakhstan');
INSERT INTO country(short_name,name) VALUES ('LA','Laos');
INSERT INTO country(short_name,name) VALUES ('LB','Lebanon');
INSERT INTO country(short_name,name) VALUES ('LC','Saint Lucia');
INSERT INTO country(short_name,name) VALUES ('LI','Liechtenstein');
INSERT INTO country(short_name,name) VALUES ('LK','Sri Lanka');
INSERT INTO country(short_name,name) VALUES ('LR','Liberia');
INSERT INTO country(short_name,name) VALUES ('LS','Lesotho');
INSERT INTO country(short_name,name) VALUES ('LT','Lithuania');
INSERT INTO country(short_name,name) VALUES ('LU','Luxembourg');
INSERT INTO country(short_name,name) VALUES ('LV','Latvia');
INSERT INTO country(short_name,name) VALUES ('LY','Libya');
INSERT INTO country(short_name,name) VALUES ('MA','Morocco');
INSERT INTO country(short_name,name) VALUES ('MC','Monaco');
INSERT INTO country(short_name,name) VALUES ('MD','Moldova');
INSERT INTO country(short_name,name) VALUES ('MG','Madagascar');
INSERT INTO country(short_name,name) VALUES ('MH','Marshall Islands');
INSERT INTO country(short_name,name) VALUES ('MK','F.Y.R.O.M. (Macedonia)');
INSERT INTO country(short_name,name) VALUES ('ML','Mali');
INSERT INTO country(short_name,name) VALUES ('MM','Myanmar');
INSERT INTO country(short_name,name) VALUES ('MN','Mongolia');
INSERT INTO country(short_name,name) VALUES ('MO','Macau');
INSERT INTO country(short_name,name) VALUES ('MP','Northern Mariana Islands');
INSERT INTO country(short_name,name) VALUES ('MQ','Martinique');
INSERT INTO country(short_name,name) VALUES ('MR','Mauritania');
INSERT INTO country(short_name,name) VALUES ('MS','Montserrat');
INSERT INTO country(short_name,name) VALUES ('MT','Malta');
INSERT INTO country(short_name,name) VALUES ('MU','Mauritius');
INSERT INTO country(short_name,name) VALUES ('MV','Maldives');
INSERT INTO country(short_name,name) VALUES ('MW','Malawi');
INSERT INTO country(short_name,name) VALUES ('MX','Mexico');
INSERT INTO country(short_name,name) VALUES ('MY','Malaysia');
INSERT INTO country(short_name,name) VALUES ('MZ','Mozambique');
INSERT INTO country(short_name,name) VALUES ('NA','Namibia');
INSERT INTO country(short_name,name) VALUES ('NC','New Caledonia');
INSERT INTO country(short_name,name) VALUES ('NE','Niger');
INSERT INTO country(short_name,name) VALUES ('NF','Norfolk Island');
INSERT INTO country(short_name,name) VALUES ('NG','Nigeria');
INSERT INTO country(short_name,name) VALUES ('NI','Nicaragua');
INSERT INTO country(short_name,name) VALUES ('NL','Netherlands');
INSERT INTO country(short_name,name) VALUES ('NO','Norway');
INSERT INTO country(short_name,name) VALUES ('NP','Nepal');
INSERT INTO country(short_name,name) VALUES ('NR','Nauru');
INSERT INTO country(short_name,name) VALUES ('NT','Neutral Zone');
INSERT INTO country(short_name,name) VALUES ('NU','Niue');
INSERT INTO country(short_name,name) VALUES ('NZ','New Zealand (Aotearoa)');
INSERT INTO country(short_name,name) VALUES ('OM','Oman');
INSERT INTO country(short_name,name) VALUES ('PA','Panama');
INSERT INTO country(short_name,name) VALUES ('PE','Peru');
INSERT INTO country(short_name,name) VALUES ('PF','French Polynesia');
INSERT INTO country(short_name,name) VALUES ('PG','Papua New Guinea');
INSERT INTO country(short_name,name) VALUES ('PH','Philippines');
INSERT INTO country(short_name,name) VALUES ('PK','Pakistan');
INSERT INTO country(short_name,name) VALUES ('PL','Poland');
INSERT INTO country(short_name,name) VALUES ('PM','St. Pierre and Miquelon');
INSERT INTO country(short_name,name) VALUES ('PN','Pitcairn');
INSERT INTO country(short_name,name) VALUES ('PR','Puerto Rico');
INSERT INTO country(short_name,name) VALUES ('PS','Palestinian Territory, Occupied');
INSERT INTO country(short_name,name) VALUES ('PT','Portugal');
INSERT INTO country(short_name,name) VALUES ('PW','Palau');
INSERT INTO country(short_name,name) VALUES ('PY','Paraguay');
INSERT INTO country(short_name,name) VALUES ('QA','Qatar');
INSERT INTO country(short_name,name) VALUES ('RE','Reunion');
INSERT INTO country(short_name,name) VALUES ('RO','Romania');
INSERT INTO country(short_name,name) VALUES ('RS','Serbia');
INSERT INTO country(short_name,name) VALUES ('RU','Russian Federation');
INSERT INTO country(short_name,name) VALUES ('RW','Rwanda');
INSERT INTO country(short_name,name) VALUES ('SA','Saudi Arabia');
INSERT INTO country(short_name,name) VALUES ('SB','Solomon Islands');
INSERT INTO country(short_name,name) VALUES ('SC','Seychelles');
INSERT INTO country(short_name,name) VALUES ('SD','Sudan');
INSERT INTO country(short_name,name) VALUES ('SE','Sweden');
INSERT INTO country(short_name,name) VALUES ('SG','Singapore');
INSERT INTO country(short_name,name) VALUES ('SH','St. Helena');
INSERT INTO country(short_name,name) VALUES ('SI','Slovenia');
INSERT INTO country(short_name,name) VALUES ('SJ','Svalbard & Jan Mayen Islands');
INSERT INTO country(short_name,name) VALUES ('SK','Slovak Republic');
INSERT INTO country(short_name,name) VALUES ('SL','Sierra Leone');
INSERT INTO country(short_name,name) VALUES ('SM','San Marino');
INSERT INTO country(short_name,name) VALUES ('SN','Senegal');
INSERT INTO country(short_name,name) VALUES ('SO','Somalia');
INSERT INTO country(short_name,name) VALUES ('SR','Suriname');
INSERT INTO country(short_name,name) VALUES ('ST','Sao Tome and Principe');
INSERT INTO country(short_name,name) VALUES ('SU','USSR (former)');
INSERT INTO country(short_name,name) VALUES ('SV','El Salvador');
INSERT INTO country(short_name,name) VALUES ('SY','Syria');
INSERT INTO country(short_name,name) VALUES ('SZ','Swaziland');
INSERT INTO country(short_name,name) VALUES ('TC','Turks and Caicos Islands');
INSERT INTO country(short_name,name) VALUES ('TD','Chad');
INSERT INTO country(short_name,name) VALUES ('TF','French Southern Territories');
INSERT INTO country(short_name,name) VALUES ('TG','Togo');
INSERT INTO country(short_name,name) VALUES ('TH','Thailand');
INSERT INTO country(short_name,name) VALUES ('TJ','Tajikistan');
INSERT INTO country(short_name,name) VALUES ('TK','Tokelau');
INSERT INTO country(short_name,name) VALUES ('TM','Turkmenistan');
INSERT INTO country(short_name,name) VALUES ('TN','Tunisia');
INSERT INTO country(short_name,name) VALUES ('TO','Tonga');
INSERT INTO country(short_name,name) VALUES ('TP','East Timor');
INSERT INTO country(short_name,name) VALUES ('TR','Turkey');
INSERT INTO country(short_name,name) VALUES ('TT','Trinidad and Tobago');
INSERT INTO country(short_name,name) VALUES ('TV','Tuvalu');
INSERT INTO country(short_name,name) VALUES ('TW','Taiwan');
INSERT INTO country(short_name,name) VALUES ('TZ','Tanzania');
INSERT INTO country(short_name,name) VALUES ('UA','Ukraine');
INSERT INTO country(short_name,name) VALUES ('UG','Uganda');
INSERT INTO country(short_name,name) VALUES ('UK','United Kingdom');
INSERT INTO country(short_name,name) VALUES ('UM','US Minor Outlying Islands');
INSERT INTO country(short_name,name) VALUES ('US','United States');
INSERT INTO country(short_name,name) VALUES ('UY','Uruguay');
INSERT INTO country(short_name,name) VALUES ('UZ','Uzbekistan');
INSERT INTO country(short_name,name) VALUES ('VA','Vatican City State (Holy See)');
INSERT INTO country(short_name,name) VALUES ('VC','Saint Vincent & the Grenadines');
INSERT INTO country(short_name,name) VALUES ('VE','Venezuela');
INSERT INTO country(short_name,name) VALUES ('VG','British Virgin Islands');
INSERT INTO country(short_name,name) VALUES ('VI','Virgin Islands (U.S.)');
INSERT INTO country(short_name,name) VALUES ('VN','Viet Nam');
INSERT INTO country(short_name,name) VALUES ('VU','Vanuatu');
INSERT INTO country(short_name,name) VALUES ('WF','Wallis and Futuna Islands');
INSERT INTO country(short_name,name) VALUES ('WS','Samoa');
INSERT INTO country(short_name,name) VALUES ('YE','Yemen');
INSERT INTO country(short_name,name) VALUES ('YT','Mayotte');
INSERT INTO country(short_name,name) VALUES ('YU','Yugoslavia (former)');
INSERT INTO country(short_name,name) VALUES ('ZA','South Africa');
INSERT INTO country(short_name,name) VALUES ('ZM','Zambia');
INSERT INTO country(short_name,name) VALUES ('ZR','Zaire');
INSERT INTO country(short_name,name) VALUES ('ZW','Zimbabwe');



create table country_tax_form (country_id int  references country(id) not null,
   form_name text not null,
   id serial not null unique,
   default_reportable bool not null default false,
   primary key(country_id, form_name)
);

COMMENT ON TABLE country_tax_form IS 
$$ This table was designed for holding information relating to reportable
sales or purchases, such as IRS 1099 forms and international equivalents.$$;

-- BEGIN new entity management
CREATE TABLE entity_class (
  id serial primary key,
  class text check (class ~ '[[:alnum:]_]') NOT NULL,
  country_id int references country(id),
  active boolean not null default TRUE);
  
COMMENT ON TABLE entity_class IS $$ Defines the class type such as vendor, customer, contact, employee $$;
COMMENT ON COLUMN entity_class.id IS $$ The first 7 values are reserved and 
permanent.  Individuals who create new classes, however, should coordinate 
with others for ranges to use.$$;  

CREATE index entity_class_idx ON entity_class(lower(class));

CREATE TABLE entity (
  id serial UNIQUE,
  name text check (name ~ '[[:alnum:]_]'),
  entity_class integer references entity_class(id) not null ,
  created date not null default current_date,
  control_code text unique,
  country_id int references country(id) not null,
  PRIMARY KEY(control_code, entity_class));
  
COMMENT ON TABLE entity IS $$ The primary entity table to map to all contacts $$;
COMMENT ON COLUMN entity.name IS $$ This is the common name of an entity. If it was a person it may be Joshua Drake, a company Acme Corp. You may also choose to use a domain such as commandprompt.com $$;


ALTER TABLE entity ADD FOREIGN KEY (entity_class) REFERENCES entity_class(id);

INSERT INTO entity_class (id,class) VALUES (1,'Vendor');
INSERT INTO entity_class (id,class) VALUES (2,'Customer');
INSERT INTO entity_class (id,class) VALUES (3,'Employee');
INSERT INTO entity_class (id,class) VALUES (4,'Contact');
INSERT INTO entity_class (id,class) VALUES (5,'Lead');
INSERT INTO entity_class (id,class) VALUES (6,'Referral');

SELECT setval('entity_class_id_seq',7);

CREATE TABLE entity_class_to_entity (
  entity_class_id integer not null references entity_class(id) ON DELETE CASCADE,
  entity_id integer not null references entity(id) ON DELETE CASCADE,
  PRIMARY KEY(entity_class_id,entity_id)
  );

COMMENT ON TABLE entity_class_to_entity IS $$ Relation builder for classes to entity $$;

-- USERS stuff --
CREATE TABLE users (
    id serial UNIQUE, 
    username varchar(30) primary key,
    notify_password interval not null default '7 days'::interval,
    entity_id int not null references entity(id) on delete cascade
);

COMMENT ON TABLE users IS $$username is the actual primary key here because we 
do not want duplicate users$$;

CREATE OR REPLACE FUNCTION person__get_my_entity_id() RETURNS INT AS
$$
	SELECT entity_id from users where username = SESSION_USER;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION person__get_my_entity_id() IS
$$ Returns the entity_id of the current, logged in user.$$;

create table lsmb_roles (
    
    user_id integer not null references users(id) ON DELETE CASCADE,
    role text not null
    
);

COMMENT ON TABLE lsmb_roles IS 
$$ Tracks role assignments in the front end.  Not sure why we need this.  Will
rethink for 1.4.
$$;


-- Session tracking table


CREATE TABLE session(
session_id serial PRIMARY KEY,
token VARCHAR(32) CHECK(length(token) = 32),
last_used TIMESTAMP default now(),
ttl int default 3600 not null,
users_id INTEGER NOT NULL references users(id),
notify_pasword interval not null default '7 days'::interval
);

COMMENT ON TABLE session IS
$$ This table is used to track sessions on a database level across page 
requests (discretionary locks,open forms for anti-xsrf measures).
Because of the way LedgerSMB authentication works currently we do 
not time out authentication when the session times out.  We do time out 
highly pessimistic locks used for large batch payment workflows.$$;

CREATE TABLE open_forms (
id SERIAL PRIMARY KEY,
session_id int REFERENCES session(session_id) ON DELETE CASCADE
);

COMMENT ON TABLE open_forms IS
$$ This is our primary anti-xsrf measure, as this allows us to require a full
round trip to the web server in order to save data.$$;
--
CREATE TABLE transactions (
  id int PRIMARY KEY,
  table_name text,
  locked_by int references "session" (session_id) ON DELETE SET NULL,
  approved_by int references entity (id),
  approved_at timestamp
);

CREATE INDEX transactions_locked_by_i ON transactions(locked_by);

COMMENT on TABLE transactions IS 
$$ This table provides referential integrity between AR, AP, GL tables on one
hand and acc_trans on the other, pending the refactoring of those tables.  It
also is used to provide discretionary locking of financial transactions across 
database connections, for example in batch payment workflows.$$;

CREATE OR REPLACE FUNCTION lock_record (in_id int, in_session_id int) 
returns bool as 
$$
declare
   locked int;
begin
   SELECT locked_by into locked from transactions where id = $1;
   IF NOT FOUND THEN
	RETURN FALSE;
   ELSEIF locked is not null AND locked <> $2 THEN
        RETURN FALSE;
   END IF;
   UPDATE transactions set locked_by = $2 where id = $1;
   RETURN TRUE;
end;
$$ language plpgsql;

COMMENT ON FUNCTION lock_record(int, int) is $$
This function seeks to lock a record with an id of in_id to a session with an
id of in_session_id.  If possible, it returns true.  If it is already locked,
false.  These are not hard locks and the application is free to disregard or 
not even ask.  They time out when the session is destroyed.
$$;

COMMENT ON column transactions.locked_by IS
$$ This should only be used in pessimistic locking measures as required by large
batch work flows. $$;

-- LOCATION AND COUNTRY

CREATE TABLE location_class (
  id serial UNIQUE,
  class text check (class ~ '[[:alnum:]_]') not null,
  authoritative boolean not null,
  PRIMARY KEY (class,authoritative));

COMMENT ON TABLE location_class is $$
Individuals seeking to add new location classes should coordinate with others.
$$;

CREATE UNIQUE INDEX lower_class_unique ON location_class(lower(class));

INSERT INTO location_class(id,class,authoritative) VALUES ('1','Billing',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('2','Sales',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('3','Shipping',TRUE);

SELECT SETVAL('location_class_id_seq',4);
  
CREATE TABLE location (
  id serial PRIMARY KEY,
  line_one text check (line_one ~ '[[:alnum:]_]') NOT NULL,
  line_two text,
  line_three text,
  city text check (city ~ '[[:alnum:]_]') NOT NULL,
  state text check(state ~ '[[:alnum:]_]'),
  country_id integer not null REFERENCES country(id),
  mail_code text not null check (mail_code ~ '[[:alnum:]_]'),
  created date not null default now(),
  inactive_date timestamp default null,
  active boolean not null default TRUE
);

COMMENT ON TABLE location IS $$
This table stores addresses, such as shipto and bill to addresses.
$$;
  
CREATE TABLE company (
  id serial UNIQUE,
  entity_id integer not null references entity(id),
  legal_name text check (legal_name ~ '[[:alnum:]_]'),
  tax_id text,
  sic_code varchar,
  created date default current_date not null,
  PRIMARY KEY (entity_id,legal_name));
  
COMMENT ON COLUMN company.tax_id IS $$ In the US this would be a EIN. $$;  

CREATE TABLE company_to_location (
  location_id integer references location(id) not null,
  location_class integer not null references location_class(id),
  company_id integer not null references company(id) ON DELETE CASCADE,
  PRIMARY KEY(location_id,company_id, location_class));

COMMENT ON TABLE company_to_location IS
$$ This table is used for locations generic to companies.  For contract-bound
addresses, use eca_to_location instead $$;

CREATE TABLE salutation (
 id serial unique,
 salutation text primary key);

INSERT INTO salutation (id,salutation) VALUES ('1','Dr.');
INSERT INTO salutation (id,salutation) VALUES ('2','Miss.');
INSERT INTO salutation (id,salutation) VALUES ('3','Mr.');
INSERT INTO salutation (id,salutation) VALUES ('4','Mrs.');
INSERT INTO salutation (id,salutation) VALUES ('5','Ms.');
INSERT INTO salutation (id,salutation) VALUES ('6','Sir.');

SELECT SETVAL('salutation_id_seq',7);

CREATE TABLE person (
    id serial PRIMARY KEY,
    entity_id integer references entity(id) not null,
    salutation_id integer references salutation(id),
    first_name text check (first_name ~ '[[:alnum:]_]') NOT NULL,
    middle_name text,
    last_name text check (last_name ~ '[[:alnum:]_]') NOT NULL,
    created date not null default current_date,
    unique(entity_id) -- needed due to entity_employee assumptions --CT
 );
 
COMMENT ON TABLE person IS $$ Every person, must have an entity to derive a common or display name. The correct way to get class information on a person would be person.entity_id->entity_class_to_entity.entity_id. $$;

create table entity_employee (
    
    entity_id integer references entity(id) not null unique,
    startdate date not null default current_date,
    enddate date,
    role varchar(20),
    ssn text,
    sales bool default 'f',
    manager_id integer references entity(id),
    employeenumber varchar(32),
    dob date,
    PRIMARY KEY (entity_id)
);

COMMENT ON TABLE entity_employee IS 
$$ This contains employee-specific extensions to person/entity. $$;

CREATE TABLE person_to_location (
  location_id integer not null references location(id),
  location_class integer not null references location_class(id),
  person_id integer not null references person(id) ON DELETE CASCADE,
  PRIMARY KEY (location_id,person_id));

CREATE TABLE person_to_company (
  location_id integer references location(id) not null,
  person_id integer not null references person(id) ON DELETE CASCADE,
  company_id integer not null references company(id) ON DELETE CASCADE,
  PRIMARY KEY (location_id,person_id)); 

COMMENT ON TABLE person_to_company IS
$$ currently unused in the front-end, but can be used to map persons
to companies.$$;

CREATE TABLE entity_other_name (
 entity_id integer not null references entity(id) ON DELETE CASCADE,
 other_name text check (other_name ~ '[[:alnum:]_]'),
 PRIMARY KEY (other_name, entity_id));
 
COMMENT ON TABLE entity_other_name IS $$ Similar to company_other_name, a person
may be jd, Joshua Drake, linuxpoet... all are the same person.  Currently
unused in the front-end but will likely be added in future versions.$$;

CREATE TABLE person_to_entity (
 person_id integer not null references person(id) ON DELETE CASCADE,
 entity_id integer not null check (entity_id != person_id) references entity(id) ON DELETE CASCADE,
 related_how text,
 created date not null default current_date,
 PRIMARY KEY (person_id,entity_id));

COMMENT ON TABLE person_to_entity IS
$$ This provides a map so that entities can also be used like groups.$$;
 
CREATE TABLE company_to_entity (
 company_id integer not null references company(id) ON DELETE CASCADE,
 entity_id integer check (company_id != entity_id) not null references entity(id) ON DELETE CASCADE,
 related_how text,
 created date not null default current_date,
 PRIMARY KEY (company_id,entity_id));
 
COMMENT ON TABLE company_to_entity IS
$$ This provides a map so that entities can also be used like groups.$$;

CREATE TABLE contact_class (
  id serial UNIQUE,
  class text check (class ~ '[[:alnum:]_]') NOT NULL, 
  PRIMARY KEY (class));

COMMENT ON TABLE contact_class IS 
$$ Stores type of contact information attached to companies and persons.
Please coordinate with others before adding new types.$$;
 
CREATE UNIQUE INDEX contact_class_class_idx ON contact_class(lower(class));

INSERT INTO contact_class (id,class) values (1,'Primary Phone');
INSERT INTO contact_class (id,class) values (2,'Secondary Phone');
INSERT INTO contact_class (id,class) values (3,'Cell Phone');
INSERT INTO contact_class (id,class) values (4,'AIM');
INSERT INTO contact_class (id,class) values (5,'Yahoo');
INSERT INTO contact_class (id,class) values (6,'Gtalk');
INSERT INTO contact_class (id,class) values (7,'MSN');
INSERT INTO contact_class (id,class) values (8,'IRC');
INSERT INTO contact_class (id,class) values (9,'Fax');
INSERT INTO contact_class (id,class) values (10,'Generic Jabber');
INSERT INTO contact_class (id,class) values (11,'Home Phone');
-- The e-mail classes are hard-coded into LedgerSMB/Form.pm by class_id
-- i.e. 'class_id's 12 - 17
INSERT INTO contact_class (id,class) values (12,'Email');
INSERT INTO contact_class (id,class) values (13,'CC');
INSERT INTO contact_class (id,class) values (14,'BCC');
INSERT INTO contact_class (id,class) values (15,'Billing Email');
INSERT INTO contact_class (id,class) values (16,'Billing CC');
INSERT INTO contact_class (id,class) values (17,'Billing BCC');

SELECT SETVAL('contact_class_id_seq',17);

CREATE TABLE person_to_contact (
  person_id integer not null references person(id) ON DELETE CASCADE,
  contact_class_id integer references contact_class(id) not null,
  contact text check(contact ~ '[[:alnum:]_]') not null,
  description text,
  PRIMARY KEY (person_id,contact_class_id,contact));
  
COMMENT ON TABLE person_to_contact IS 
$$ This table stores contact information for persons$$;
  
CREATE TABLE company_to_contact (
  company_id integer not null references company(id) ON DELETE CASCADE,
  contact_class_id integer references contact_class(id) not null,
  contact text check(contact ~ '[[:alnum:]_]') not null,
  description text,
  PRIMARY KEY (company_id, contact_class_id,  contact));  

COMMENT ON TABLE person_to_contact IS 
$$ This table stores contact information for companies$$;

CREATE TABLE entity_bank_account (
    id serial not null,
    entity_id int not null references entity(id) ON DELETE CASCADE,
    bic varchar,
    iban varchar,
    UNIQUE (id),
    PRIMARY KEY (entity_id, bic, iban)
);

COMMENT ON TABLE entity_bank_account IS 
$$This stores bank account information for both companies and persons.$$;

COMMENT ON COLUMN entity_bank_account.bic IS
$$ Banking Institution Code, such as routing number of SWIFT code.$$;

COMMENT ON COLUMN entity_bank_account.iban IS
$$ International Bank Account Number.  used to store the actual account number
for the banking institution.$$;

CREATE TABLE entity_credit_account (
    id serial not null unique,
    entity_id int not null references entity(id) ON DELETE CASCADE,
    entity_class int not null references entity_class(id) check ( entity_class in (1,2) ),
    pay_to_name text,
    discount numeric, 
    description text,
    discount_terms int default 0,
    discount_account_id int references account(id),
    taxincluded bool default 'f',
    creditlimit NUMERIC default 0,
    terms int2 default 0,
    meta_number varchar(32),
    business_id int,
    language_code varchar(6) DEFAULT 'en' references language(code) ON DELETE SET DEFAULT,
    pricegroup_id int references pricegroup(id),
    curr char(3),
    startdate date DEFAULT CURRENT_DATE,
    enddate date,
    threshold numeric default 0,
    employee_id int references entity_employee(entity_id),
    primary_contact int references person(id),
    ar_ap_account_id int references account(id),
    cash_account_id int references account(id),
    bank_account int references entity_bank_account(id),
    taxform_id int references country_tax_form(id),
    PRIMARY KEY(entity_id, meta_number, entity_class),
    CHECK (ar_ap_account_id IS NOT NULL OR entity_id = 0)
);

COMMENT ON TABLE entity_credit_account IS
$$This table stores information relating to general relationships regarding 
moneys owed on invoice.  Invoices, whether AR or AP, must be attached to 
a record in this table.$$;

COMMENT ON COLUMN entity_credit_account.meta_number IS
$$ This stores the human readable control code for the customer/vendor record.
This is typically called the customer/vendor "account" in the application.$$;

CREATE UNIQUE INDEX entity_credit_ar_accno_idx_u 
ON entity_credit_account(meta_number)
WHERE entity_class = 2;

COMMENT ON INDEX entity_credit_ar_accno_idx_u IS
$$This index is used to ensure that AR accounts are not reused.$$;

CREATE TABLE eca_to_contact (
  credit_id integer not null references entity_credit_account(id) 
	ON DELETE CASCADE,
  contact_class_id integer references contact_class(id) not null,
  contact text check(contact ~ '[[:alnum:]_]') not null,
  description text,
  PRIMARY KEY (credit_id, contact_class_id,  contact));  

COMMENT ON TABLE eca_to_contact IS $$ To keep track of the relationship between multiple contact methods and a single vendor or customer account. For generic 
contacts, use company_to_contact or person_to_contact instead.$$;
  
CREATE TABLE eca_to_location (
  location_id integer references location(id) not null,
  location_class integer not null references location_class(id),
  credit_id integer not null references entity_credit_account(id) 
	ON DELETE CASCADE,
  PRIMARY KEY(location_id,credit_id, location_class));

CREATE UNIQUE INDEX eca_to_location_billing_u ON eca_to_location(credit_id)
	WHERE location_class = 1;

COMMENT ON TABLE eca_to_location IS
$$ This table is used for locations bound to contracts.  For generic contact
addresses, use company_to_location instead $$;

-- Begin rocking notes interface
-- Begin rocking notes interface
CREATE TABLE note_class(id serial primary key, class text not null check (class ~ '[[:alnum:]_]'));
INSERT INTO note_class(id,class) VALUES (1,'Entity');
INSERT INTO note_class(id,class) VALUES (2,'Invoice');
INSERT INTO note_class(id,class) VALUES (3,'Entity Credit Account');
CREATE UNIQUE INDEX note_class_idx ON note_class(lower(class));

COMMENT ON TABLE note_class IS 
$$ Coordinate with others before adding entries. $$;

CREATE TABLE note (id serial primary key, 
                   note_class integer not null references note_class(id), 
                   note text not null, 
                   vector tsvector not null default '', 
                   created timestamp not null default now(),
                   created_by text DEFAULT SESSION_USER,
                   ref_key integer not null,
                   subject text);

COMMENT ON TABLE note IS 
$$ This is an abstract table which should have zero rows.  It is inherited by
other tables for specific notes.$$;

COMMENT ON COLUMN note.ref_key IS
$$ Subclassed tables use this column as a foreign key against the table storing
the record a note is attached to.$$;

COMMENT ON COLUMN note.note IS $$Body of note.$$;
COMMENT ON COLUMN note.vector IS $$tsvector for full text indexing, requires 
both setting up tsearch dictionaries and adding triggers to use at present.$$;

CREATE TABLE entity_note(
      entity_id int references entity(id), 
      primary key(id)) INHERITS (note);
ALTER TABLE entity_note ADD CHECK (note_class = 1);
ALTER TABLE entity_note ADD FOREIGN KEY (ref_key) REFERENCES entity(id) ON DELETE CASCADE;
CREATE INDEX entity_note_id_idx ON entity_note(id);
CREATE UNIQUE INDEX entity_note_class_idx ON note_class(lower(class));
CREATE INDEX entity_note_vectors_idx ON entity_note USING gist(vector);
CREATE TABLE invoice_note(primary key(id)) INHERITS (note);
CREATE INDEX invoice_note_id_idx ON invoice_note(id);
CREATE UNIQUE INDEX invoice_note_class_idx ON note_class(lower(class));
CREATE INDEX invoice_note_vectors_idx ON invoice_note USING gist(vector);

CREATE TABLE eca_note(primary key(id)) 
	INHERITS (note);
ALTER TABLE eca_note ADD CHECK (note_class = 3);
ALTER TABLE eca_note ADD FOREIGN KEY (ref_key) 
	REFERENCES entity_credit_account(id) 
	ON DELETE CASCADE;

COMMENT ON TABLE eca_note IS
$$ Notes for entity_credit_account entries.$$;

COMMENT ON COLUMN eca_note.ref_key IS
$$ references entity_credit_account.id$$;

-- END entity   

--
CREATE TABLE makemodel (
  parts_id int PRIMARY KEY,
  make text,
  model text
);

COMMENT ON TABLE makemodel IS
$$ A single parts entry can have multiple make/model entries.  These
store manufacturer/model number info.$$;
--
CREATE TABLE gl (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  reference text,
  description text,
  transdate date DEFAULT current_date,
  person_id integer references person(id),
  notes text,
  approved bool default true,
  department_id int default 0
);

COMMENT ON TABLE gl IS
$$ This table holds summary information for entries in the general journal.
Does not hold summary information in 1.3 for AR or AP entries.$$;

COMMENT ON COLUMN gl.person_id is $$ the person_id of the employee who created
the entry.$$;
--
CREATE TABLE gifi (
  accno text PRIMARY KEY,
  description text
);

COMMENT ON TABLE gifi IS 
$$ GIFI labels for accounts, used in Canada and some EU countries for tax 
reporting$$;
--
CREATE TABLE defaults (
  setting_key text primary key,
  value text
);

COMMENT ON TABLE defaults IS 
$$  This is a free-form table for managing application settings per company
database.  We use key-value modelling here because this most accurately maps 
the actual semantics of the data.
$$ ;

\COPY defaults FROM stdin WITH DELIMITER '|'
timeout|90 minutes
sinumber|1
sonumber|1
yearend|1
businessnumber|1
version|1.3.20
closedto|\N
revtrans|1
ponumber|1
sqnumber|1
rfqnumber|1
audittrail|0
vinumber|1
employeenumber|1
partnumber|1
customernumber|1
vendornumber|1
glnumber|1
projectnumber|1
queue_payments|0
poll_frequency|1
rcptnumber|1
paynumber|1
separate_duties|1
entity_control|A-00001
batch_cc|B-11111
check_prefix|CK
\.

-- */
-- batch stuff

CREATE TABLE batch_class (
  id serial unique,
  class varchar primary key
);

COMMENT ON TABLE batch_class IS 
$$ These values are hard-coded.  Please coordinate before adding standard
values.$$;

insert into batch_class (id,class) values (1,'ap');
insert into batch_class (id,class) values (2,'ar');
insert into batch_class (id,class) values (3,'payment');
insert into batch_class (id,class) values (4,'payment_reversal');
insert into batch_class (id,class) values (5,'gl');
insert into batch_class (id,class) values (6,'receipt');

SELECT SETVAL('batch_class_id_seq',6);

CREATE TABLE batch (
  id serial primary key,
  batch_class_id integer references batch_class(id) not null,
  control_code text NOT NULL,
  description text,
  default_date date not null,
  approved_on date default null,
  approved_by int references entity_employee(entity_id),
  created_by int references entity_employee(entity_id),
  locked_by int references session(session_id),
  created_on date default now(),
  CHECK (length(control_code) > 0)
);

COMMENT ON TABLE batch IS
$$ Stores batch header info.  Batches are groups of vouchers that are posted
together.$$;

COMMENT ON COLUMN batch.batch_class_id IS
$$ Note that this field is largely used for sorting the vouchers.  A given batch is NOT restricted to this type.$$;


-- Although I am moving the primary key to voucher.id for now, as of 1.4, I 
-- would expect trans_id to be primary key
CREATE TABLE voucher (
  trans_id int REFERENCES transactions(id) NOT NULL,
  batch_id int references batch(id) not null,
  id serial PRIMARY KEY,
  batch_class int references batch_class(id) not null
);

COMMENT ON TABLE voucher IS 
$$Mapping transactions to batches for batch approval.$$;

COMMENT ON COLUMN voucher.batch_class IS $$ This is the authoritative class of the 
voucher. $$;

COMMENT ON COLUMN voucher.id IS $$ This is simply a surrogate key for easy reference.$$;

CREATE TABLE acc_trans (
  trans_id int NOT NULL REFERENCES transactions(id),
  chart_id int NOT NULL REFERENCES  account(id),
  amount NUMERIC,
  transdate date DEFAULT current_date,
  source text,
  cleared bool DEFAULT 'f',
  fx_transaction bool DEFAULT 'f',
  project_id int,
  memo text,
  invoice_id int,
  approved bool default true,
  cleared_on date,
  reconciled_on date,
  voucher_id int references voucher(id),
  entry_id SERIAL PRIMARY KEY
);

COMMENT ON TABLE acc_trans IS
$$This table stores line items for financial transactions.  Please note that
payments in 1.3 are not full-fledged transactions.$$;

COMMENT ON COLUMN acc_trans.source IS
$$Document Source identifier for individual line items, usually used 
for payments.$$;

CREATE INDEX acc_trans_voucher_id_idx ON acc_trans(voucher_id);
--
CREATE TABLE parts (
  id serial PRIMARY KEY,
  partnumber text,
  description text,
  unit varchar(5),
  listprice NUMERIC,
  sellprice NUMERIC,
  lastcost NUMERIC,
  priceupdate date DEFAULT current_date,
  weight numeric,
  onhand numeric DEFAULT 0,
  notes text,
  makemodel bool DEFAULT 'f',
  assembly bool DEFAULT 'f',
  alternate bool DEFAULT 'f',
  rop numeric, 
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  bin text,
  obsolete bool DEFAULT 'f',
  bom bool DEFAULT 'f',
  image text,
  drawing text,
  microfiche text,
  partsgroup_id int,
  project_id int,
  avgcost NUMERIC
);

COMMENT ON TABLE parts IS
$$This stores detail information about goods and services.  The type of part
is currently defined according to the following rules:
* If assembly is true, then an assembly
* If inventory_accno_id, income_accno_id, and expense_accno_id are not null then
  a part.
* If inventory_accno_id is null but the other two are not, then a service.
* Otherwise, a labor/overhead entry.
$$;

COMMENT ON COLUMN parts.rop IS
$$Re-order point.  Used to select parts for short inventory report.$$;

COMMENT ON COLUMN parts.bin IS
$$Text identifier for where a part is stored.$$;

COMMENT ON COLUMN parts.bom is
$$Show on Bill of Materials.$$;

COMMENT ON COLUMN parts.image IS
$$Hyperlink to product image.$$;
	
CREATE UNIQUE INDEX parts_partnumber_index_u ON parts (partnumber) 
WHERE obsolete is false;
CREATE TABLE invoice (
  id serial PRIMARY KEY,
  trans_id int REFERENCES transactions(id),
  parts_id int REFERENCES parts(id),
  description text,
  qty NUMERIC,
  allocated integer,
  sellprice NUMERIC,
  precision int,
  fxsellprice NUMERIC,
  discount numeric,
  assemblyitem bool DEFAULT 'f',
  unit varchar(5),
  project_id int,
  deliverydate date,
  serialnumber text,
  notes text
);

COMMENT ON TABLE invoice IS
$$Line items of invoices with goods/services attached.$$;

COMMENT ON COLUMN invoice.allocated IS
$$Number of allocated items, negative relative to qty.
When qty + allocated = 0, then the item is fully used for purposes of COGS 
calculations.$$;

COMMENT ON COLUMN invoice.qty IS
$$Positive is normal for sales invoices, negative for vendor invoices.$$;

-- Added for Entity but can't be added due to order
ALTER TABLE invoice_note ADD FOREIGN KEY (ref_key) REFERENCES invoice(id);

--

--

-- THe following credit accounts are used for inventory adjustments.
INSERT INTO entity (id, name, entity_class, control_code,country_id) 
values (0, 'Inventory Entity', 1, 'AUTO-01','232');

INSERT INTO company (legal_name, entity_id) 
values ('Inventory Entity', 0);

INSERT INTO entity_credit_account (entity_id, meta_number, entity_class)
VALUES 
(0, '00000', 1);
INSERT INTO entity_credit_account (entity_id, meta_number, entity_class)
VALUES 
(0, '00000', 2);


--
CREATE TABLE assembly (
  id int REFERENCES parts(id),
  parts_id int REFERENCES parts(id),
  qty numeric,
  bom bool,
  adj bool,
  PRIMARY KEY (id, parts_id)
);

COMMENT ON TABLE assembly IS
$$Holds mapping for parts that are members of assemblies.$$;

COMMENT ON COLUMN assembly.id IS
$$This is the id of the assembly the part is being mapped to.$$;

COMMENT ON COLUMN assembly.parts_id IS
$$ID of part that is a member of the assembly.$$;


--
CREATE TABLE ar (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  invnumber text,
  transdate date DEFAULT current_date,
  entity_id int REFERENCES entity(id),
  taxincluded bool,
  amount NUMERIC,
  netamount NUMERIC,
  paid NUMERIC,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  shippingpoint text,
  terms int2 DEFAULT 0,
  notes text,
  curr char(3) CHECK ( (amount IS NULL AND curr IS NULL) 
      OR (amount IS NOT NULL AND curr IS NOT NULL)),
  ordnumber text,
  person_id integer references entity_employee(entity_id),
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  on_hold bool default false,
  reverse bool default false,
  approved bool default true,
  entity_credit_account int references entity_credit_account(id) not null,
  force_closed bool,
  description text,
  unique(invnumber) -- probably a good idea as per Erik's request --CT
);

COMMENT ON TABLE ar IS
$$ Summary/header information for AR transactions and sales invoices.
Note that some constraints here are hard to enforce because we haven not gotten 
to rewriting the relevant code here.
HV TODO drop entity_id
$$;

COMMENT ON COLUMN ar.invnumber IS
$$ Text identifier for the invoice.  Must be unique.$$;

COMMENT ON COLUMN ar.invoice IS
$$ True if the transaction tracks goods/services purchase using the invoice
table.  False otherwise.$$;

COMMENT ON COLUMN ar.amount IS
$$ This stores the total amount (including taxes) for the transaction.$$;

COMMENT ON COLUMN ar.netamount IS
$$ Total amount excluding taxes for the transaction.$$;

COMMENT ON COLUMN ar.curr IS $$ 3 letters to identify the currency.$$;

COMMENT ON COLUMN ar.ordnumber IS $$ Order Number$$;

COMMENT ON COLUMN ar.ponumber is $$Purchase Order Number$$; 

COMMENT ON COLUMN ar.person_id IS $$Person who created the transaction$$;

COMMENT ON COLUMN ar.quonumber IS $$Quotation Number$$;

COMMENT ON COLUMN ar.notes IS 
$$These notes are displayed on the invoice when printed or emailed$$;

COMMENT ON COLUMN ar.intnotes IS
$$These notes are not displayed when the invoice is printed or emailed and
may be updated without reposting hte invocie.$$;

COMMENT ON COLUMN ar.reverse IS
$$If true numbers are displayed after multiplying by -1$$;

COMMENT ON COLUMN ar.approved IS
$$Only show in financial reports if true.$$;

COMMENT ON COLUMN ar.entity_credit_account IS
$$ reference for the customer account used.$$;

COMMENT ON COLUMN ar.force_closed IS
$$ Not exposed to the UI, but can be set to prevent an invoice from showing up
for payment or in outstanding reports.$$;

--
CREATE TABLE ap (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  invnumber text,
  transdate date DEFAULT current_date,
  entity_id int REFERENCES entity(id),
  taxincluded bool DEFAULT 'f',
  amount NUMERIC,
  netamount NUMERIC,
  paid NUMERIC,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  ordnumber text,
  curr char(3) CHECK ( (amount IS NULL AND curr IS NULL) 
    OR (amount IS NOT NULL AND curr IS NOT NULL)) , -- This can be null, but shouldn't be.
  notes text,
  person_id integer references entity_employee(entity_id),
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int DEFAULT 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  shippingpoint text,
  on_hold bool default false,
  approved bool default true,
  reverse bool default false,
  terms int2 DEFAULT 0,
  description text,
  force_closed bool,
  entity_credit_account int references entity_credit_account(id) NOT NULL
);

COMMENT ON TABLE ap IS
$$ Summary/header information for AP transactions and vendor invoices.
Note that some constraints here are hard to enforce because we haven not gotten 
to rewriting the relevant code here.
HV TODO drop entity_id
$$;

COMMENT ON COLUMN ap.invnumber IS
$$ Text identifier for the invoice.  Must be unique.$$;

COMMENT ON COLUMN ap.invoice IS
$$ True if the transaction tracks goods/services purchase using the invoice
table.  False otherwise.$$;

COMMENT ON COLUMN ap.amount IS
$$ This stores the total amount (including taxes) for the transaction.$$;

COMMENT ON COLUMN ap.netamount IS
$$ Total amount excluding taxes for the transaction.$$;

COMMENT ON COLUMN ap.curr IS $$ 3 letters to identify the currency.$$;

COMMENT ON COLUMN ap.ordnumber IS $$ Order Number$$;

COMMENT ON COLUMN ap.ponumber is $$Purchase Order Number$$; 

COMMENT ON COLUMN ap.person_id IS $$Person who created the transaction$$;

COMMENT ON COLUMN ap.quonumber IS $$Quotation Number$$;

COMMENT ON COLUMN ap.notes IS 
$$These notes are displayed on the invoice when printed or emailed$$;

COMMENT ON COLUMN ap.intnotes IS
$$These notes are not displayed when the invoice is printed or emailed and
may be updated without reposting hte invocie.$$;

COMMENT ON COLUMN ap.reverse IS
$$If true numbers are displayed after multiplying by -1$$;

COMMENT ON COLUMN ap.approved IS
$$Only show in financial reports if true.$$;

COMMENT ON COLUMN ap.entity_credit_account IS
$$ reference for the vendor account used.$$;

COMMENT ON COLUMN ap.force_closed IS
$$ Not exposed to the UI, but can be set to prevent an invoice from showing up
for payment or in outstanding reports.$$;

--
CREATE TABLE taxmodule (
  taxmodule_id serial PRIMARY KEY,
  taxmodulename text NOT NULL
);

COMMENT ON TABLE taxmodule IS
$$This is used to store information on tax modules.  the module name is used
to determine the Perl class for the taxes.$$;
--
CREATE TABLE taxcategory (
  taxcategory_id serial PRIMARY KEY,
  taxcategoryname text NOT NULL,
  taxmodule_id int NOT NULL,
  FOREIGN KEY (taxmodule_id) REFERENCES taxmodule (taxmodule_id)
);
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int,
  taxcategory_id int,
  PRIMARY KEY (parts_id, chart_id),
  FOREIGN KEY (parts_id) REFERENCES parts (id) on delete cascade,
  FOREIGN KEY (chart_id) REFERENCES  account(id),
  FOREIGN KEY (taxcategory_id) REFERENCES taxcategory (taxcategory_id)
);

COMMENT ON TABLE partstax IS $$ Mapping of parts to taxes.$$;
--
CREATE TABLE tax (
  chart_id int REFERENCES account(id),
  rate numeric,
  minvalue numeric,
  maxvalue numeric,
  taxnumber text,
  validto timestamp not null default 'infinity',
  pass integer DEFAULT 0 NOT NULL,
  taxmodule_id int DEFAULT 1 NOT NULL,
  FOREIGN KEY (chart_id) REFERENCES  account(id),
  FOREIGN KEY (taxmodule_id) REFERENCES taxmodule (taxmodule_id),
  PRIMARY KEY (chart_id, validto)
);

COMMENT ON TABLE tax IS
$$Information on tax rates.$$;

COMMENT ON COLUMN tax.pass IS
$$This is an integer indicating the pass of the tax. This is to support 
cumultative sales tax rules (for example, Quebec charging taxes on the federal
taxes collected).$$;
--
CREATE TABLE customertax (
  customer_id int references entity_credit_account(id) on delete cascade,
  chart_id int REFERENCES account(id),
  PRIMARY KEY (customer_id, chart_id)
);

COMMENT ON TABLE customertax IS $$ Mapping customer to taxes.$$;
--
CREATE TABLE vendortax (
  vendor_id int references entity_credit_account(id) on delete cascade,
  chart_id int REFERENCES account(id),
  PRIMARY KEY (vendor_id, chart_id)
);
--
COMMENT ON TABLE vendortax IS $$ Mapping vendor to taxes.$$;

CREATE TABLE oe_class (
  id smallint unique check(id IN (1,2,3,4)),
  oe_class text primary key);
  
INSERT INTO oe_class(id,oe_class) values (1,'Sales Order');
INSERT INTO oe_class(id,oe_class) values (2,'Purchase Order');
INSERT INTO oe_class(id,oe_class) values (3,'Quotation');
INSERT INTO oe_class(id,oe_class) values (4,'RFQ');

-- Moving this comment to SQL comments because it is about this code rather than
-- the database structure as API. --CT
-- This could probably be done better. But I need to remove the 
-- customer_id/vendor_id relationship and instead rely on a classification;
-- JD

COMMENT ON TABLE oe_class IS 
$$ Hardwired classifications for orders and quotations. 
Coordinate before adding.$$;

CREATE TABLE oe (
  id serial PRIMARY KEY,
  ordnumber text,
  transdate date default current_date,
  entity_id integer references entity(id),
  amount NUMERIC,
  netamount NUMERIC,
  reqdate date,
  taxincluded bool,
  shippingpoint text,
  notes text,
  curr char(3),
  person_id integer references person(id),
  closed bool default 'f',
  quotation bool default 'f',
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  terms int2 DEFAULT 0,
  entity_credit_account int references entity_credit_account(id) not null,
  oe_class_id int references oe_class(id) NOT NULL
);

COMMENT ON TABLE oe IS $$ Header information for:
* Sales orders
* Purchase Orders
* Quotations
* Requests for Quotation
$$;
--
CREATE TABLE orderitems (
  id serial PRIMARY KEY,
  trans_id int,
  parts_id int,
  description text,
  qty numeric,
  sellprice NUMERIC,
  precision int,
  discount numeric,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship numeric,
  serialnumber text,
  notes text
);

COMMENT ON TABLE orderitems IS
$$ Line items for sales/purchase orders and quotations.$$;
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  buy numeric,
  sell numeric,
  PRIMARY KEY (curr, transdate)
);
COMMENT ON TABLE exchangerate IS
$$ When you receive money in a foreign currency, it is worth to you in your local currency
whatever you can get for it when you sell the acquired currency (sell rate).
When you have to pay someone in a foreign currency, the equivalent amount is the amount
you have to spend to acquire the foreign currency (buy rate).$$;
--
CREATE TABLE project (
  id serial PRIMARY KEY,
  projectnumber text,
  description text,
  startdate date,
  enddate date,
  parts_id int,
  production numeric default 0,
  completed numeric default 0,
  credit_id int references entity_credit_account(id)
);

COMMENT ON COLUMN project.parts_id IS
$$ Job costing/manufacturing here not implemented.$$;
--
CREATE TABLE partsgroup (
  id serial PRIMARY KEY,
  partsgroup text
);

COMMENT ON TABLE partsgroup is $$ Groups of parts for Point of Sale screen.$$;
--
CREATE TABLE status (
  trans_id int,
  formname text,
  printed bool default 'f',
  emailed bool default 'f',
  spoolfile text,
  PRIMARY KEY (trans_id, formname)
);

COMMENT ON TABLE status IS
$$ Whether AR/AP transactions and invoices have been emailed and/or printed $$;

--
CREATE TABLE department (
  id serial PRIMARY KEY,
  description text,
  role char(1) default 'P'
);

COMMENT ON COLUMN department.role IS $$P for Profit Center, C for Cost Center$$;
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id int PRIMARY KEY,
  department_id int
);

COMMENT ON TABLE dpt_trans IS $$Department to Transaction Map$$;
--
-- business table
CREATE TABLE business (
  id serial PRIMARY KEY,
  description text,
  discount numeric
);

COMMENT ON TABLE business IS $$Groups of Customers assigned joint discounts.$$;
--
-- SIC
CREATE TABLE sic (
  code varchar(6) PRIMARY KEY,
  sictype char(1),
  description text
);

COMMENT ON TABLE sic IS $$
This can be used SIC codes or any equivalent, such as ISIC, NAICS, etc.
$$;

--
CREATE TABLE warehouse (
  id serial PRIMARY KEY,
  description text
);
--
CREATE TABLE inventory (
  entity_id integer references entity_employee(entity_id),
  warehouse_id int,
  parts_id int,
  trans_id int,
  orderitems_id int,
  qty numeric,
  shippingdate date,
  entry_id SERIAL PRIMARY KEY
);

COMMENT ON TABLE inventory IS
$$ This table contains inventory mappings to warehouses, not general inventory
management data.$$;
--
CREATE TABLE yearend (
  trans_id int PRIMARY KEY REFERENCES gl(id),
  reversed bool default false,
  transdate date
);

COMMENT ON TABLE yearend IS
$$ An extension to the gl table to track transactionsactions which close out 
the books at yearend.$$;
--
CREATE TABLE partsvendor (
  credit_id int not null references entity_credit_account(id) on delete cascade,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost NUMERIC,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);

COMMENT ON TABLE partsvendor IS
$$ Tracks vendor's pricing, as well as vendor's part number, lead time 
required and currency.$$;
--
CREATE TABLE partscustomer (
  parts_id int,
  credit_id int references entity_credit_account(id) on delete cascade,
  pricegroup_id int references pricegroup(id),
  pricebreak numeric,
  sellprice NUMERIC,
  validfrom date,
  validto date,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);

COMMENT ON TABLE partscustomer IS
$$ Tracks per-customer pricing.  Discounts can be offered for periods of time
and for pricegroups as well as per customer$$;
--
--
CREATE TABLE audittrail (
  trans_id int,
  tablename text,
  reference text,
  formname text,
  action text,
  transdate timestamp default current_timestamp,
  person_id integer references person(entity_id) not null,
  entry_id BIGSERIAL PRIMARY KEY
);

COMMENT ON TABLE audittrail IS
$$ This stores information on who entered or updated rows in the ar, ap, or gl
tables.$$;
--

CREATE TABLE translation (
  trans_id int,
  language_code varchar(6),
  description text,
  PRIMARY KEY (trans_id, language_code)
);

COMMENT ON TABLE translation IS 
$$abstract table for manual translation data. Should have zero rows.$$;

CREATE TABLE parts_translation 
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE parts_translation ADD foreign key (trans_id) REFERENCES parts(id);

COMMENT ON TABLE parts_translation IS
$$ Translation information for parts.$$;

CREATE TABLE project_translation 
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE project_translation 
ADD foreign key (trans_id) REFERENCES project(id);

COMMENT ON TABLE project_translation IS
$$ Translation information for projects.$$;

CREATE TABLE partsgroup_translation 
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE partsgroup_translation 
ADD foreign key (trans_id) REFERENCES partsgroup(id);

COMMENT ON TABLE partsgroup_translation IS
$$ Translation information for partsgroups.$$;

--
CREATE TABLE user_preference (
    id int PRIMARY KEY REFERENCES users(id),
    language varchar(6) REFERENCES language(code),
    stylesheet text default 'ledgersmb.css' not null,
    printer text,
    dateformat text default 'yyyy-mm-dd' not null,
    numberformat text default '1000.00' not null
);

-- user_preference is here due to a dependency on language.code
COMMENT ON TABLE user_preference IS 
$$ This table sets the basic preferences for formats, languages, printers, and user-selected stylesheets.$$;

CREATE TABLE recurring (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
  reference text,
  startdate date,
  nextdate date,
  enddate date,
  repeat int2,
  unit varchar(6),
  howmany int,
  payment bool default 'f'
);

COMMENT ON TABLE recurring IS
$$ Stores recurring information on transactions which will recur in the future.
Note that this means that only fully posted transactions can recur. 
I would highly recommend depricating this table and working instead on extending
the template transaction addon to handle recurring information.$$;

CREATE TABLE payment_type (
  id serial not null unique,
  label text primary key
);

--
CREATE TABLE recurringemail (
  id int,
  formname text,
  format text,
  message text,
  PRIMARY KEY (id, formname)
);

COMMENT ON TABLE recurringemail IS 
$$Email  to be sent out when recurring transaction is posted.$$;
--
CREATE TABLE recurringprint (
  id int,
  formname text,
  format text,
  printer text,
  PRIMARY KEY (id, formname)
);

COMMENT ON TABLE recurringprint IS
$$ Template, printer etc. to print to when recurring transaction posts.$$;
--
CREATE TABLE jcitems (
  id serial PRIMARY KEY,
  project_id int,
  parts_id int,
  description text,
  qty numeric,
  allocated numeric,
  sellprice NUMERIC,
  fxsellprice NUMERIC,
  serialnumber text,
  checkedin timestamp with time zone,
  checkedout timestamp with time zone,
  person_id integer references person(id) not null,
  notes text,
  total numeric not null,
  non_billable numeric not null default 0
);

COMMENT ON TABLE jcitems IS $$ Time and materials cards. 
Materials cards not implemented.$$;

CREATE OR REPLACE FUNCTION track_global_sequence() RETURNS TRIGGER AS
$$
BEGIN
	IF tg_op = 'INSERT' THEN
		INSERT INTO transactions (id, table_name) 
		VALUES (new.id, TG_RELNAME);
	ELSEIF tg_op = 'UPDATE' THEN
		IF new.id = old.id THEN
			return new;
		ELSE
			UPDATE transactions SET id = new.id WHERE id = old.id;
		END IF;
	ELSE 
		DELETE FROM transactions WHERE id = old.id;
	END IF;
	RETURN new;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION track_global_sequence() is
$$ This trigger is used to track the id sequence entries across the 
transactions table, and with the ar, ap, and gl tables.  This is necessary 
because these have not been properly refactored yet.
$$;

CREATE TRIGGER ap_track_global_sequence BEFORE INSERT OR UPDATE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER ar_track_global_sequence BEFORE INSERT OR UPDATE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER gl_track_global_sequence BEFORE INSERT OR UPDATE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TABLE custom_table_catalog (
table_id SERIAL PRIMARY KEY,
extends TEXT,
table_name TEXT
);

COMMENT ON TABLE custom_table_catalog IS
$$ Deprecated, use only with old code.$$;

CREATE TABLE custom_field_catalog (
field_id SERIAL PRIMARY KEY,
table_id INT REFERENCES custom_table_catalog,
field_name TEXT
);

COMMENT ON TABLE custom_field_catalog IS
$$ Deprecated, use only with old code.$$;

INSERT INTO taxmodule (
  taxmodule_id, taxmodulename
  ) VALUES (
  1, 'Simple'
);

CREATE TABLE ac_tax_form (
        entry_id int references acc_trans(entry_id) primary key,
        reportable bool
);

COMMENT ON TABLE ac_tax_form IS
$$ Mapping acc_trans to country_tax_form for reporting purposes.$$;

CREATE TABLE invoice_tax_form (
        invoice_id int references invoice(id) primary key,
        reportable bool
);

COMMENT ON TABLE invoice_tax_form IS
$$ Maping invoice to country_tax_form.$$;

CREATE OR REPLACE FUNCTION gl_audit_trail_append()
RETURNS TRIGGER AS
$$
DECLARE
   t_reference text;
   t_row RECORD;
BEGIN

IF TG_OP = 'INSERT' then
   t_row := NEW;
ELSE
   t_row := OLD;
END IF;

IF TG_RELNAME IN ('ar', 'ap') THEN
    t_reference := t_row.invnumber;
ELSE 
    t_reference := t_row.reference;
END IF;

INSERT INTO audittrail (trans_id,tablename,reference, action, person_id)
values (t_row.id,TG_RELNAME,t_reference, TG_OP, person__get_my_entity_id());

return null; -- AFTER TRIGGER ONLY, SAFE
END;
$$ language plpgsql security definer;


COMMENT ON FUNCTION gl_audit_trail_append() IS
$$ This provides centralized support for insertions into audittrail.
$$;

CREATE TRIGGER gl_audit_trail AFTER insert or update or delete ON gl
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();

CREATE TRIGGER ar_audit_trail AFTER insert or update or delete ON ar
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();

CREATE TRIGGER ap_audit_trail AFTER insert or update or delete ON ap
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();
create index acc_trans_trans_id_key on acc_trans (trans_id);
create index acc_trans_chart_id_key on acc_trans (chart_id);
create index acc_trans_transdate_key on acc_trans (transdate);
create index acc_trans_source_key on acc_trans (lower(source));
--
create index ap_id_key on ap (id);
create index ap_transdate_key on ap (transdate);
create index ap_invnumber_key on ap (invnumber);
create index ap_ordnumber_key on ap (ordnumber);
create index ap_quonumber_key on ap (quonumber);
create index ap_curr_idz on ap(curr);
--
create index ar_id_key on ar (id);
create index ar_transdate_key on ar (transdate);
create index ar_ordnumber_key on ar (ordnumber);
create index ar_quonumber_key on ar (quonumber);
create index ar_curr_idz on ar(curr);
--
create index assembly_id_key on assembly (id);
--
create index customer_customer_id_key on customertax (customer_id);
--
create index exchangerate_ct_key on exchangerate (curr, transdate);
--
create unique index gifi_accno_key on gifi (accno);
--
create index gl_id_key on gl (id);
create index gl_transdate_key on gl (transdate);
create index gl_reference_key on gl (reference);
create index gl_description_key on gl (lower(description));
--
create index invoice_id_key on invoice (id);
create index invoice_trans_id_key on invoice (trans_id);
--
create index makemodel_parts_id_key on makemodel (parts_id);
create index makemodel_make_key on makemodel (lower(make));
create index makemodel_model_key on makemodel (lower(model));
--
create index oe_id_key on oe (id);
create index oe_transdate_key on oe (transdate);
create index oe_ordnumber_key on oe (ordnumber);
create index orderitems_trans_id_key on orderitems (trans_id);
create index orderitems_id_key on orderitems (id);
--
create index parts_id_key on parts (id);
create index parts_partnumber_key on parts (lower(partnumber));
create index parts_description_key on parts (lower(description));
create index partstax_parts_id_key on partstax (parts_id);
--
--
create index project_id_key on project (id);
create unique index projectnumber_key on project (projectnumber);
--
create index partsgroup_id_key on partsgroup (id);
create unique index partsgroup_key on partsgroup (partsgroup);
--
create index status_trans_id_key on status (trans_id);
--
create index department_id_key on department (id);
--
create index partsvendor_parts_id_key on partsvendor (parts_id);
--
create index pricegroup_pricegroup_key on pricegroup (pricegroup);
create index pricegroup_id_key on pricegroup (id);
--
create index audittrail_trans_id_key on audittrail (trans_id);
--
create index translation_trans_id_key on translation (trans_id);
--
create unique index language_code_key on language (code);
--
create index jcitems_id_key on jcitems (id);


--
CREATE FUNCTION del_yearend() RETURNS TRIGGER AS '
begin
  delete from yearend where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_yearend AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_yearend();
-- end trigger
--
CREATE FUNCTION del_department() RETURNS TRIGGER AS '
begin
  delete from dpt_trans where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_department AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
--
CREATE FUNCTION del_exchangerate() RETURNS TRIGGER AS '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(value,1,3) from defaults where setting_key = ''curr'';
  
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
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE FUNCTION check_department() RETURNS TRIGGER AS '

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
--
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ar FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ap FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON gl FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON oe FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
--
CREATE FUNCTION del_recurring() RETURNS TRIGGER AS '
BEGIN
  DELETE FROM recurring WHERE id = old.id;
  DELETE FROM recurringemail WHERE id = old.id;
  DELETE FROM recurringprint WHERE id = old.id;
  RETURN NULL;
END;
' language 'plpgsql';
--end function
CREATE TRIGGER del_recurring AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
CREATE TRIGGER del_recurring AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
CREATE TRIGGER del_recurring AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
--
CREATE FUNCTION avgcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_qty float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost, v_qty SUM(i.sellprice * i.qty), SUM(i.qty)
  FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id;
  
  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

  IF NOT v_qty IS NULL THEN
    IF v_qty = 0 THEN
      v_cost := 0;
    ELSE
      v_cost := v_cost/v_qty;
    END IF;
  END IF;

RETURN v_cost;
END;
' language 'plpgsql';
-- end function
--
CREATE FUNCTION lastcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost sellprice FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id
  ORDER BY a.transdate desc, a.id desc
  LIMIT 1;

  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

RETURN v_cost;
END;
' language plpgsql;
-- end function
--

CREATE OR REPLACE FUNCTION trigger_parts_short() RETURNS TRIGGER
AS
'
BEGIN
  IF NEW.onhand >= NEW.rop THEN
    NOTIFY parts_short;
  END IF;
  RETURN NEW;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE TRIGGER parts_short AFTER UPDATE ON parts 
FOR EACH ROW EXECUTE PROCEDURE trigger_parts_short();
-- end function

CREATE OR REPLACE FUNCTION add_custom_field (table_name VARCHAR, new_field_name VARCHAR, field_datatype VARCHAR) 
RETURNS BOOL AS
'
BEGIN
	perform TABLE_ID FROM custom_table_catalog 
		WHERE extends = table_name;
	IF NOT FOUND THEN
		BEGIN
			INSERT INTO custom_table_catalog (extends) 
				VALUES (table_name);
			EXECUTE ''CREATE TABLE '' || 
                               quote_ident(''custom_'' ||table_name) ||
				'' (row_id INT PRIMARY KEY)'';
		EXCEPTION WHEN duplicate_table THEN
			-- do nothing
		END;
	END IF;
	INSERT INTO custom_field_catalog (field_name, table_id)
	values (new_field_name, (SELECT table_id 
                                        FROM custom_table_catalog
		WHERE extends = table_name));
	EXECUTE ''ALTER TABLE ''|| quote_ident(''custom_''||table_name) || 
                '' ADD COLUMN '' || quote_ident(new_field_name) || '' '' || 
                  quote_ident(field_datatype);
	RETURN TRUE;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE OR REPLACE FUNCTION drop_custom_field (VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
custom_field_name ALIAS FOR $2;
BEGIN
	DELETE FROM custom_field_catalog 
	WHERE field_name = custom_field_name AND 
		table_id = (SELECT table_id FROM custom_table_catalog 
			WHERE extends = table_name);
	EXECUTE ''ALTER TABLE '' || quote_ident(''custom_'' || table_name) || 
		'' DROP COLUMN '' || quote_ident(custom_field_name);
	RETURN TRUE;	
END;
' LANGUAGE PLPGSQL;
-- end function
CREATE TABLE menu_node (
    id serial NOT NULL,
    label character varying NOT NULL,
    parent integer,
    "position" integer NOT NULL
);

COMMENT ON TABLE menu_node IS
$$This table stores the tree structure of the menu.$$;
--ALTER TABLE public.menu_node OWNER TO ledgersmb;

--
-- Name: menu_node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ledgersmb
--

SELECT pg_catalog.setval('menu_node_id_seq', 242, true);


--
-- Data for Name: menu_node; Type: TABLE DATA; Schema: public; Owner: ledgersmb
--

COPY menu_node (id, label, parent, "position") FROM stdin;
205	Transaction Approval	0	5
206	Batches	205	1
46	HR	0	6
50	Order Entry	0	7
63	Shipping	0	8
67	Quotations	0	9
73	General Journal	0	10
77	Goods and Services	0	11
0	Top-level	\N	0
1	AR	0	1
2	Add Transaction	1	1
5	Transactions	4	1
6	Outstanding	4	2
7	AR Aging	4	3
9	Taxable Sales	4	4
10	Non-Taxable	4	5
12	Add Customer	11	1
13	Reports	11	2
14	Search	13	1
15	History	13	2
16	Point of Sale	0	2
17	Sale	16	1
18	Open	16	2
19	Receipts	16	3
20	Close Till	16	4
21	AP	0	3
22	Add Transaction	21	1
145	Add Department	144	1
25	Transactions	24	1
26	Outstanding	24	2
27	AP Aging	24	3
28	Taxable	24	4
29	Non-taxable	24	5
31	Add Vendor	30	1
32	Reports	30	2
33	Search	32	1
34	History	32	2
35	Cash	0	4
36	Receipt	35	1
38	Payment	35	3
223	Use Overpayment	35	4
37	Use AR Overpayment	35	2
146	List Departments	144	2
42	Receipts	41	1
43	Payments	41	2
44	Reconciliation	41	3
47	Employees	46	1
48	Add Employee	47	1
49	Search	47	2
51	Sales Order	50	1
52	Purchase Order	50	2
53	Reports	50	3
54	Sales Orders	53	1
55	Purchase Orders	53	2
57	Sales Orders	56	1
58	Purchase Orders	56	2
56	Generate	50	4
60	Consolidate	50	5
61	Sales Orders	60	1
62	Purchase Orders	60	2
64	Ship	63	1
65	Receive	63	2
66	Transfer	63	3
68	Quotation	67	1
69	RFQ	67	2
70	Reports	67	3
71	Quotations	70	1
72	RFQs	70	2
74	Journal Entry	73	1
75	Adjust Till	73	2
76	Reports	73	3
78	Add Part	77	1
79	Add Service	77	2
80	Add Assembly	77	3
81	Add Overhead	77	4
82	Add Group	77	5
83	Add Pricegroup	77	6
84	Stock Assembly	77	7
85	Reports	77	8
86	All Items	85	1
87	Parts	85	2
88	Requirements	85	3
89	Services	85	4
90	Labor	85	5
91	Groups	85	6
92	Pricegroups	85	7
93	Assembly	85	8
94	Components	85	9
95	Translations	77	9
96	Description	95	1
97	Partsgroup	95	2
99	Add Project	98	1
100	Add Timecard	98	2
101	Generate	98	3
102	Sales Orders	101	1
103	Reports	98	4
104	Search	103	1
105	Transactions	103	2
106	Time Cards	103	3
107	Translations	98	5
108	Description	107	1
110	Chart of Accounts	109	1
111	Trial Balance	109	2
112	Income Statement	109	3
113	Balance Sheet	109	4
114	Inventory Activity	109	5
117	Sales Invoices	116	1
118	Sales Orders	116	2
119	Checks	116	3
120	Work Orders	116	4
121	Quotations	116	5
122	Packing Lists	116	6
123	Pick Lists	116	7
124	Purchase Orders	116	8
125	Bin Lists	116	9
126	RFQs	116	10
127	Time Cards	116	11
129	Audit Control	128	1
130	Taxes	128	2
131	Defaults	128	3
132	Yearend	128	4
137	Add Accounts	136	1
138	List Accounts	136	2
139	Add GIFI	136	3
140	List GIFI	136	4
142	Add Warehouse	141	1
143	List Warehouse	141	2
148	Add Business	147	1
149	List Businesses	147	2
151	Add Language	150	1
152	List Languages	150	2
154	Add SIC	153	1
155	List SIC	153	2
157	Income Statement	156	1
158	Balance Sheet	156	2
159	Invoice	156	3
160	AR Transaction	156	4
161	AP Transaction	156	5
162	Packing List	156	6
163	Pick List	156	7
164	Sales Order	156	8
165	Work Order	156	9
166	Purchase Order	156	10
167	Bin List	156	11
168	Statement	156	12
169	Quotation	156	13
170	RFQ	156	14
171	Timecard	156	15
241	Letterhead	156	16
173	Invoice	172	1
174	AR Transaction	172	2
175	AP Transaction	172	3
176	Packing List	172	4
177	Pick List	172	5
178	Sales Order	172	6
179	Work Order	172	7
180	Purchase Order	172	8
181	Bin List	172	9
182	Statement	172	10
183	Check	172	11
184	Receipt	172	12
185	Quotation	172	13
186	RFQ	172	14
187	Timecard	172	15
242	Letterhead	172	16
189	POS Invoice	188	1
198	AR Voucher	1	2
3	Sales Invoice	1	3
11	Customers	1	7
4	Reports	1	6
194	Credit Note	1	4
195	Credit Invoice	1	5
199	AP Voucher	21	2
23	Vendor Invoice	21	3
24	Reports	21	6
30	Vendors	21	7
196	Debit Note	21	4
197	Debit Invoice	21	5
200	Vouchers	35	5
40	Transfer	35	6
41	Reports	35	8
45	Reconciliation	35	7
203	Receipts	200	3
204	Reverse Receipts	200	4
201	Payments	200	1
202	Reverse Payment	200	2
98	Projects	0	12
109	Reports	0	13
115	Recurring Transactions	0	14
210	Drafts	205	2
211	Reconciliation	205	3
217	Tax Forms	0	15
218	Add Tax Form	217	1
219	Admin Users	128	5
188	Text Templates	128	15
172	LaTeX Templates	128	14
156	HTML Templates	128	13
153	SIC	128	12
150	Language	128	11
147	Type of Business	128	10
144	Departments	128	9
141	Warehouses	128	8
136	Chart of Accounts	128	7
220	Add User	219	1
221	Search Users	219	2
222	Sessions	219	3
225	List Tax Forms	217	2
226	Reports	217	3
227	Fixed Assets	0	17
193	Logout	0	23
192	New Window	0	22
191	Preferences	0	21
190	Stylesheet	0	20
128	System	0	19
116	Batch Printing	0	18
228	Asset Classes	227	1
229	Assets	227	2
230	Add Class	228	1
231	List Classes	228	2
232	Add Assets	229	1
233	Search Assets	229	2
235	Import	229	3
234	Depreciate	229	4
237	Net Book Value	236	1
238	Disposal	229	5
236	Reports	229	11
239	Depreciation	236	2
240	Disposal	236	3
\.

--
-- Name: menu_node_parent_key; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_key UNIQUE (parent, "position");


--
-- Name: menu_node_pkey; Type: CONSTRAINT; Schema: public; Owner: ledgersmb; Tablespace: 
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_pkey PRIMARY KEY (id);


--
-- Name: menu_node_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ledgersmb
--

ALTER TABLE ONLY menu_node
    ADD CONSTRAINT menu_node_parent_fkey FOREIGN KEY (parent) REFERENCES menu_node(id);



CREATE TABLE menu_attribute (
    node_id integer NOT NULL references menu_node(id),
    attribute character varying NOT NULL,
    value character varying NOT NULL,
    id serial NOT NULL,
    primary key(node_id, attribute)
);

COMMENT ON TABLE menu_attribute IS
$$ This table stores the callback information for each menu item.  The 
attributes are stored in key/value modelling because of the fact that this
best matches the semantic structure of the information.

Each node should have EITHER a menu or a module attribute, menu for a menu with 
sub-items, module for an executiable script.  The module attribute identifies
the perl script to be run.  The action attribute identifies the entry point.

Beyond this, any other attributes that should be passed in can be done as other
attributes.
$$;

--
-- Name: menu_attribute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ledgersmb
--

SELECT pg_catalog.setval('menu_attribute_id_seq', 649, true);


--
-- Data for Name: menu_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY menu_attribute (node_id, attribute, value, id) FROM stdin;
26	outstanding	1	584
205	menu	1	574
206	module	vouchers.pl	575
206	action	search_batch	576
1	menu	1	1
2	module	ar.pl	2
2	action	add	3
3	action	add	4
3	module	is.pl	5
3	type	invoice	6
4	menu	1	7
5	module	ar.pl	8
5	action	search	9
5	nextsub	transactions	10
6	module	ar.pl	12
6	action	search	13
6	nextsub	transactions	14
7	module	rp.pl	15
7	action	report	16
7	report	ar_aging	17
6	outstanding	1	18
9	module	rp.pl	21
9	action	report	22
9	report	tax_collected	23
10	module	rp.pl	24
10	action	report	25
10	report	nontaxable_sales	26
11	menu	1	27
12	module	customer.pl	28
12	action	add	29
13	menu	1	31
14	module	customer.pl	32
14	action	search	36
15	db	customer	37
15	action	history	33
16	menu	1	38
17	module	ps.pl	39
17	action	add	40
17	nextsub	openinvoices	41
18	action	openinvoices	42
18	module	ps.pl	43
19	module	ps.pl	44
19	action	receipts	46
20	module	ps.pl	47
20	action	till_closing	48
20	pos	true	49
21	menu	1	50
22	action	add	52
22	module	ap.pl	51
23	action	add	53
23	type	invoice	55
23	module	ir.pl	54
24	menu	1	56
25	action	search	58
25	nextsub	transactions	59
25	module	ap.pl	57
26	action	search	61
26	nextsub	transactions	62
26	module	ap.pl	60
27	module	rp.pl	63
27	action	report	64
28	module	rp.pl	66
28	action	report	67
28	report	tax_collected	68
27	report	tax_paid	65
29	module	rp.pl	69
29	action	report	70
29	report	nontaxable_purchases	71
30	menu	1	72
31	module	vendor.pl	73
31	action	add	74
31	db	vendor	75
32	menu	1	76
33	module	vendor.pl	77
33	action	search	79
33	db	vendor	78
34	module	vendor.pl	80
34	action	history	81
34	db	vendor	82
35	menu	1	83
36	module	payment.pl	84
36	action	payment	85
36	type	receipt	86
36	account_class	2	551
37	module	payment.pl	87
37	account_class	2	89
37	action	use_overpayment	88
223	module	payment.pl	607
223	account_class	1	608
223	action	use_overpayment	609
38	module	payment.pl	90
38	action	payment	91
38	type	check	92
38	account_class	1	554
194	module	ar.pl	538
194	action	add	539
40	module	gl.pl	96
40	action	add	97
40	transfer	1	98
41	menu	1	99
42	module	rp.pl	100
42	action	report	101
42	report	receipts	102
43	module	rp.pl	103
43	action	report	104
43	report	payments	105
44	report	1	110
46	menu	1	111
47	menu	1	112
48	module	employee.pl	113
48	action	add	114
49	action	search	117
50	menu	1	119
51	module	oe.pl	120
51	action	add	121
51	type	sales_order	122
52	module	oe.pl	123
52	action	add	124
52	type	purchase_order	125
53	menu	1	126
54	module	oe.pl	127
54	type	sales_order	129
54	action	search	128
55	module	oe.pl	130
55	type	purchase_order	132
55	action	search	131
56	menu	1	133
57	module	oe.pl	134
57	action	search	136
58	module	oe.pl	137
58	action	search	139
57	type	generate_sales_order	135
58	type	generate_purchase_order	138
60	menu	1	550
61	module	oe.pl	140
61	action	search	141
62	module	oe.pl	143
62	action	search	144
62	type	consolidate_purchase_order	145
61	type	consolidate_sales_order	142
63	menu	1	146
64	module	oe.pl	147
64	action	search	148
64	type	ship_order	149
65	module	oe.pl	150
65	action	search	151
65	type	receive_order	152
66	module	oe.pl	153
66	action	search_transfer	154
67	menu	1	155
68	module	oe.pl	156
68	action	add	157
69	module	oe.pl	159
69	action	add	160
49	module	employee.pl	118
68	type	sales_quotation	158
69	type	request_quotation	161
70	menu	1	162
71	module	oe.pl	163
71	type	sales_quotation	165
71	action	search	164
72	module	oe.pl	166
72	action	search	168
72	type	request_quotation	167
73	menu	1	169
74	module	gl.pl	170
74	action	add	171
75	module	gl.pl	172
75	action	add_pos_adjust	174
75	rowcount	3	175
75	pos_adjust	1	176
75	reference	Adjusting Till: (Till)  Source: (Source)	177
75	descripton	Adjusting till due to data entry error	178
76	module	gl.pl	180
76	action	search	181
77	menu	1	182
78	module	ic.pl	183
78	action	add	184
78	item	part	185
79	module	ic.pl	186
79	action	add	187
79	item	service	188
80	module	ic.pl	189
80	action	add	190
81	module	ic.pl	192
81	action	add	193
81	item	labor	194
80	item	assembly	191
82	action	add	195
82	module	pe.pl	196
83	action	add	198
83	module	pe.pl	199
83	type	pricegroup	200
82	type	partsgroup	197
84	module	ic.pl	202
84	action	stock_assembly	203
85	menu	1	204
86	module	ic.pl	205
86	action	search	610
86	searchitems	all	611
87	module	ic.pl	612
87	action	search	206
87	searchitems	part	210
88	module	ic.pl	211
88	action	requirements	212
89	action	search	213
89	module	ic.pl	214
89	searchitems	service	215
90	action	search	216
90	module	ic.pl	217
90	searchitems	labor	218
91	module	pe.pl	221
91	type	partsgroup	222
91	action	search	220
92	module	pe.pl	224
92	type	pricegroup	225
92	action	search	223
93	action	search	226
93	module	ic.pl	227
93	searchitems	assembly	228
94	action	search	229
94	module	ic.pl	230
94	searchitems	component	231
95	menu	1	232
96	module	pe.pl	233
96	action	translation	234
96	translation	description	235
97	module	pe.pl	236
97	action	translation	237
97	translation	partsgroup	238
98	menu	1	239
99	module	pe.pl	240
99	action	add	241
99	type	project	242
100	module	jc.pl	243
100	action	add	244
99	project	project	245
100	project	project	246
100	type	timecard	247
101	menu	1	248
102	module	pe.pl	249
102	action	project_sales_order	250
103	menu	1	255
104	module	pe.pl	256
104	type	project	258
104	action	search	257
105	action	report	260
105	report	projects	261
105	module	rp.pl	262
106	module	jc.pl	263
106	action	search	264
106	type	timecard	265
106	project	project	266
107	menu	1	268
108	module	pe.pl	269
108	action	translation	270
108	translation	project	271
109	menu	1	272
110	module	ca.pl	273
110	action	chart_of_accounts	274
111	action	report	275
111	module	rp.pl	276
111	report	trial_balance	277
112	action	report	278
112	module	rp.pl	279
112	report	income_statement	280
113	action	report	281
113	module	rp.pl	282
113	report	balance_sheet	283
114	action	report	284
114	module	rp.pl	285
114	report	inv_activity	286
115	action	recurring_transactions	287
115	module	am.pl	288
116	menu	1	289
119	module	bp.pl	290
119	action	search	291
119	type	check	292
119	vc	vendor	293
117	module	bp.pl	294
117	action	search	295
117	vc	customer	297
117	type	invoice	296
118	module	bp.pl	298
118	action	search	299
118	vc	customer	300
118	type	sales_order	301
120	module	bp.pl	302
120	action	search	303
120	vc	customer	304
121	module	bp.pl	306
121	action	search	307
121	vc	customer	308
122	module	bp.pl	310
122	action	search	311
122	vc	customer	312
120	type	work_order	305
121	type	sales_quotation	309
122	type	packing_list	313
123	module	bp.pl	314
123	action	search	315
123	vc	customer	316
123	type	pick_list	317
124	module	bp.pl	318
124	action	search	319
124	vc	vendor	321
124	type	purchase_order	320
125	module	bp.pl	322
125	action	search	323
125	vc	vendor	325
126	module	bp.pl	326
126	action	search	327
126	vc	vendor	329
127	module	bp.pl	330
127	action	search	331
127	type	timecard	332
125	type	bin_list	324
126	type	request_quotation	328
127	vc	employee	333
128	menu	1	334
129	module	am.pl	337
130	module	am.pl	338
131	module	am.pl	339
129	action	audit_control	340
130	taxes	audit_control	341
131	action	defaults	342
130	action	taxes	343
132	module	account.pl	346
132	action	yearend_info	347
138	module	am.pl	356
139	module	am.pl	357
140	module	am.pl	358
138	action	list_account	360
139	action	add_gifi	361
140	action	list_gifi	362
141	menu	1	363
142	module	am.pl	364
143	module	am.pl	365
142	action	add_warehouse	366
143	action	list_warehouse	367
145	module	am.pl	368
146	module	am.pl	369
145	action	add_department	370
146	action	list_department	371
147	menu	1	372
148	module	am.pl	373
149	module	am.pl	374
148	action	add_business	375
149	action	list_business	376
150	menu	1	377
151	module	am.pl	378
152	module	am.pl	379
151	action	add_language	380
152	action	list_language	381
153	menu	1	382
154	module	am.pl	383
155	module	am.pl	384
154	action	add_sic	385
155	action	list_sic	386
156	menu	1	387
157	module	am.pl	388
158	module	am.pl	389
159	module	am.pl	390
160	module	am.pl	391
161	module	am.pl	392
162	module	am.pl	393
163	module	am.pl	394
164	module	am.pl	395
165	module	am.pl	396
166	module	am.pl	397
167	module	am.pl	398
168	module	am.pl	399
169	module	am.pl	400
170	module	am.pl	401
171	module	am.pl	402
241	module	am.pl	642
157	action	list_templates	403
158	action	list_templates	404
159	action	list_templates	405
160	action	list_templates	406
161	action	list_templates	407
162	action	list_templates	408
163	action	list_templates	409
164	action	list_templates	410
165	action	list_templates	411
166	action	list_templates	412
167	action	list_templates	413
168	action	list_templates	414
169	action	list_templates	415
170	action	list_templates	416
171	action	list_templates	417
241	action	list_templates	643
157	template	income_statement	418
158	template	balance_sheet	419
159	template	invoice	420
160	template	ar_transaction	421
161	template	ap_transaction	422
162	template	packing_list	423
163	template	pick_list	424
164	template	sales_order	425
165	template	work_order	426
166	template	purchase_order	427
167	template	bin_list	428
168	template	statement	429
169	template	sales_quotation	430
170	template	request_quotation	431
171	template	timecard	432
241	template	letterhead	644
157	format	HTML	433
158	format	HTML	434
159	format	HTML	435
160	format	HTML	436
161	format	HTML	437
162	format	HTML	438
163	format	HTML	439
164	format	HTML	440
165	format	HTML	441
166	format	HTML	442
167	format	HTML	443
168	format	HTML	444
169	format	HTML	445
170	format	HTML	446
171	format	HTML	447
241	format	HTML	645
172	menu	1	448
173	action	list_templates	449
174	action	list_templates	450
175	action	list_templates	451
176	action	list_templates	452
177	action	list_templates	453
178	action	list_templates	454
179	action	list_templates	455
180	action	list_templates	456
181	action	list_templates	457
182	action	list_templates	458
183	action	list_templates	459
184	action	list_templates	460
185	action	list_templates	461
186	action	list_templates	462
187	action	list_templates	463
242	action	list_templates	646
173	module	am.pl	464
174	module	am.pl	465
175	module	am.pl	466
176	module	am.pl	467
177	module	am.pl	468
178	module	am.pl	469
179	module	am.pl	470
180	module	am.pl	471
181	module	am.pl	472
182	module	am.pl	473
183	module	am.pl	474
184	module	am.pl	475
185	module	am.pl	476
186	module	am.pl	477
187	module	am.pl	478
242	module	am.pl	647
173	format	LATEX	479
174	format	LATEX	480
175	format	LATEX	481
176	format	LATEX	482
177	format	LATEX	483
178	format	LATEX	484
179	format	LATEX	485
180	format	LATEX	486
181	format	LATEX	487
182	format	LATEX	488
183	format	LATEX	489
184	format	LATEX	490
185	format	LATEX	491
186	format	LATEX	492
187	format	LATEX	493
242	format	LATEX	648
173	template	invoice	506
174	template	ar_transaction	507
175	template	ap_transaction	508
176	template	packing_list	509
177	template	pick_list	510
178	template	sales_order	511
179	template	work_order	512
180	template	purchase_order	513
181	template	bin_list	514
182	template	statement	515
185	template	quotation	518
186	template	rfq	519
187	template	timecard	520
183	template	check	516
184	template	receipt	517
242	template	letterhead	649
188	menu	1	521
189	module	am.pl	522
189	action	list_templates	523
189	template	pos_invoice	524
189	format	TEXT	525
190	action	display_stylesheet	526
190	module	am.pl	527
193	module	login.pl	532
193	action	logout	533
193	target	_top	534
192	menu	1	530
192	new	1	531
0	menu	1	535
136	menu	1	536
144	menu	1	537
195	action	add	540
195	module	is.pl	541
196	action	add	543
196	module	ap.pl	544
197	action	add	545
197	module	ir.pl	547
196	type	debit_note	549
194	type	credit_note	548
195	type	credit_invoice	542
197	type	debit_invoice	546
202	batch_type	payment_reversal	570
204	batch_type	receipt_reversal	573
200	menu	1	552
198	action	create_batch	554
198	module	vouchers.pl	553
199	module	vouchers.pl	559
199	action	create_batch	560
201	module	vouchers.pl	562
201	action	create_batch	563
203	module	vouchers.pl	565
203	action	create_batch	566
203	batch_type	receipts	567
202	module	vouchers.pl	568
202	action	create_batch	569
204	module	vouchers.pl	571
204	action	create_batch	572
201	batch_type	payment	564
210	action	search	585
210	module	drafts.pl	586
199	batch_type	ap	561
15	module	customer.pl	35
45	module	recon.pl	106
45	action	new_report	107
44	module	recon.pl	108
44	action	search	109
211	module	recon.pl	587
211	action	search	588
211	hide_status	1	589
211	approved	0	590
211	submitted	1	591
198	batch_type	ar	555
191	module	user.pl	528
191	action	preference_screen	529
217	menu	1	597
218	action	add_taxform	598
218	module	taxform.pl	599
137	module	account.pl	355
137	action	new	359
219	menu	1	600
220	module	admin.pl	601
220	action	new_user	602
221	module	admin.pl	603
221	action	search_users	604
222	module	admin.pl	605
222	action	list_sessions	606
49	l_last_name	1	115
49	l_employeenumber	1	116
49	l_first_name	1	613
49	l_id	1	614
49	l_startdate	1	615
49	l_enddate	1	616
225	module	taxform.pl	613
225	action	list_all	614
226	module	taxform.pl	615
227	menu	1	616
228	menu	1	617
229	menu	1	618
230	action	asset_category_screen	620
231	action	asset_category_search	622
232	action	asset_screen	624
233	action	asset_search	626
234	module	asset.pl	627
234	action	new_report	628
235	module	asset.pl	630
235	action	import	631
236	menu	1	632
237	module	asset.pl	633
237	action	display_nbv	634
232	module	asset.pl	623
230	module	asset.pl	619
231	module	asset.pl	621
233	module	asset.pl	625
234	depreciation	1	629
238	action	new_report	636
238	module	asset.pl	635
239	module	asset.pl	637
239	action	search_reports	638
239	depreciation	1	639
240	module	asset.pl	640
240	action	search_reports	641
\.


--
-- PostgreSQL database dump complete
--

--

CREATE TABLE menu_acl (
    id serial NOT NULL,
    role_name character varying,
    acl_type character varying,
    node_id integer,
    CONSTRAINT menu_acl_acl_type_check CHECK ((((acl_type)::text = 'allow'::text) OR ((acl_type)::text = 'deny'::text))),
    PRIMARY KEY (node_id, role_name)
);

COMMENT ON TABLE menu_acl IS
$$Provides access control list entries for menu nodes.$$;

COMMENT ON COLUMN menu_acl.acl_type IS 
$$ Nodes are hidden unless a role is found of which the user is a member, and
where the acl_type for that role type and node is set to 'allow' and no acl is 
found for any role of which the user is a member, where the acl_type is set to
'deny'.$$;



ALTER TABLE ONLY menu_acl
    ADD CONSTRAINT menu_acl_node_id_fkey FOREIGN KEY (node_id) REFERENCES menu_node(id);


--
-- PostgreSQL database dump complete
--

CREATE OR REPLACE FUNCTION to_args (in_base text[], in_args text[])
RETURNS text[] AS
$$
SELECT CASE WHEN $2[1] IS NULL OR $2[2] IS NULL THEN $1 
            ELSE $1 || ($2[1]::text || '=' || $2[2]::text)
       END;
$$ language sql;

COMMENT ON FUNCTION to_args(text[], text[]) IS
$$
This function takes two arguments.  The first is a one-dimensional array 
representing the  base state of the argument array.  The second is a two 
element array of {key, value}.

If either of the args is null, it returns the first argument.  Otherwise it 
returns the first initial array, concatenated with key || '=' || value.

It primarily exists for the to_args aggregate.
$$;

CREATE AGGREGATE to_args (
     basetype = text[],
     sfunc = to_args,
     stype = text[],
     INITCOND = '{}'
);

COMMENT ON AGGREGATE to_args(text[]) IS
$$ Turns a setof ARRAY[key,value] into an 
ARRAY[key||'='||value, key||'='||value,...]
$$;

CREATE TYPE menu_item AS (
   position int,
   id int,
   level int,
   label varchar,
   path varchar,
   args varchar[]
);


CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS 
$$
DECLARE 
	item menu_item;
	arg menu_attribute%ROWTYPE;
BEGIN
	FOR item IN 
		SELECT n.position, n.id, c.level, n.label, c.path, 
                       to_args(array[ma.attribute, ma.value])
		FROM connectby('menu_node', 'id', 'parent', 'position', '0', 
				0, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id 
                                FROM menu_acl
                                JOIN (select rolname FROM pg_roles
                                      UNION 
                                     select 'public') pgr 
                                     ON pgr.rolname = role_name
                               WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public') 
                                                                    = 'public'
                                                      THEN current_user
                                                      ELSE pgr.rolname
                                                   END, 'USAGE')
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM connectby('menu_node', 'id', 'parent', 
                                                'position', '0', 0, ',')
                                      cc(id integer, parent integer, 
                                         "level" integer, path text,
                                         list_order integer)
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN 
                                      (select node_id FROM menu_acl
                                        JOIN (select rolname FROM pg_roles
                                              UNION 
                                              select 'public') pgr 
                                              ON pgr.rolname = role_name
                                        WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public') 
                                                                    = 'public'
                                                      THEN current_user
                                                      ELSE pgr.rolname
                                                   END, 'USAGE')
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type 
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type 
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path like c.path || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.list_order
            ORDER BY c.list_order
                             
	LOOP
		RETURN NEXT item;
	END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION menu_generate() IS
$$
This function returns the complete menu tree.  It is used to generate nested
menus for the web interface.
$$;

CREATE OR REPLACE FUNCTION menu_children(in_parent_id int) RETURNS SETOF menu_item
AS $$
declare 
	item menu_item;
	arg menu_attribute%ROWTYPE;
begin
        FOR item IN
		SELECT n.position, n.id, c.level, n.label, c.path, 
                       to_args(array[ma.attribute, ma.value])
		FROM connectby('menu_node', 'id', 'parent', 'position', 
				in_parent_id, 1, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id 
                                FROM menu_acl
                                JOIN (select rolname FROM pg_roles
                                      UNION 
                                      select 'public') pgr 
                                      ON pgr.rolname = role_name
                                WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public') 
                                                                    = 'public'
                                                               THEN current_user
                                                               ELSE pgr.rolname
                                                               END, 'USAGE')
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM connectby('menu_node', 'id', 'parent', 
                                                'position', '0', 0, ',')
                                      cc(id integer, parent integer, 
                                         "level" integer, path text,
                                         list_order integer)
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN 
                                      (select node_id FROM menu_acl
                                         JOIN (select rolname FROM pg_roles
                                              UNION 
                                              select 'public') pgr 
                                              ON pgr.rolname = role_name
                                        WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public') 
                                                                    = 'public'
                                                               THEN current_user
                                                               ELSE pgr.rolname
                                                               END, 'USAGE')
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type 
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type 
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path like c.path || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.list_order
            ORDER BY c.list_order
        LOOP
                return next item;
        end loop;
end;
$$ language plpgsql;

COMMENT ON FUNCTION menu_children(int) IS 
$$ This function returns all menu  items which are children of in_parent_id 
(the only input parameter). 

It is thus similar to menu_generate() but it only returns the menu items 
associated with nodes directly descendant from the parent.  It is used for
menues for frameless browsers.$$;

CREATE OR REPLACE FUNCTION 
menu_insert(in_parent_id int, in_position int, in_label text)
returns int
AS $$
DECLARE
	new_id int;
BEGIN
	UPDATE menu_node 
	SET position = position * -1
	WHERE parent = in_parent_id
		AND position >= in_position;

	INSERT INTO menu_node (parent, position, label)
	VALUES (in_parent_id, in_position, in_label);

	SELECT INTO new_id currval('menu_node_id_seq');

	UPDATE menu_node 
	SET position = (position * -1) + 1
	WHERE parent = in_parent_id
		AND position < 0;

	RETURN new_id;
END;
$$ language plpgsql;

comment on function menu_insert(int, int, text) is $$
This function inserts menu items at arbitrary positions.  The arguments are, in
order:  parent, position, label.  The return value is the id number of the menu
item created. $$;


CREATE VIEW menu_friendly AS
SELECT t."level", t.path, t.list_order, 
       (repeat(' '::text, (2 * t."level")) || (n.label)::text) AS label, 
        n.id, n."position" 
  FROM (connectby('menu_node'::text, 'id'::text, 'parent'::text, 
                  'position'::text, '0'::text, 0, ','::text
        ) t(id integer, parent integer, "level" integer, path text, 
        list_order integer) 
   JOIN menu_node n USING (id));

COMMENT ON VIEW menu_friendly IS
$$ A nice human-readable view for investigating the menu tree.  Does not
show menu attributes or acls.$$;


--ALTER TABLE public.menu_friendly OWNER TO ledgersmb;

--
-- PostgreSQL database dump complete
--

CREATE AGGREGATE as_array (
	BASETYPE = ANYELEMENT,
	STYPE = ANYARRAY,
	SFUNC = ARRAY_APPEND,
	INITCOND = '{}'
);

COMMENT ON AGGREGATE as_array(ANYELEMENT) IS
$$ A basic array aggregate to take elements and return a one-dimensional array.

Example:  SELECT as_array(id) from entity_class;
$$;

CREATE AGGREGATE compound_array (
	BASETYPE = ANYARRAY,
	STYPE = ANYARRAY,
	SFUNC = ARRAY_CAT,
	INITCOND = '{}'
);

COMMENT ON AGGREGATE compound_array(ANYARRAY) is
$$ Returns an n dimensional array.

Example: SELECT as_array(ARRAY[id::text, class]) from contact_class
$$;

CREATE INDEX ap_approved_idx ON ap(approved);
CREATE INDEX ar_approved_idx ON ar(approved);
CREATE INDEX gl_approved_idx ON gl(approved);

CREATE TABLE pending_job (
	id serial not null unique,
	batch_class int references batch_class(id),
	entered_by text REFERENCES users(username)
		not null default SESSION_USER,
	entered_at timestamp default now(),
	batch_id int references batch(id),
	completed_at timestamp,
	success bool,
	error_condition text,
	CHECK (completed_at IS NULL OR success IS NOT NULL),
	CHECK (success IS NOT FALSE OR error_condition IS NOT NULL)
);
COMMENT ON table pending_job IS
$$ Purpose:  This table stores pending/queued jobs to be processed async.
Additionally, this functions as a log of all such processing for purposes of 
internal audits, performance tuning, and the like. $$;

CREATE INDEX pending_job_batch_id_pending ON pending_job(batch_id) where success IS NULL;

CREATE INDEX pending_job_entered_by ON pending_job(entered_by);

CREATE OR REPLACE FUNCTION trigger_pending_job() RETURNS TRIGGER
AS
$$
BEGIN
  IF NEW.success IS NULL THEN
    NOTIFY job_entered;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER notify_pending_jobs BEFORE INSERT OR UPDATE ON pending_job
FOR EACH ROW EXECUTE PROCEDURE trigger_pending_job();

CREATE TABLE payments_queue (
	transactions numeric[], 
	batch_id int, 
	source text, 
	total numeric,
	ar_ap_accno text, 
	cash_accno text, 
	payment_date date, 
	account_class int,
	job_id int references pending_job(id) 
		DEFAULT currval('pending_job_id_seq')
);

CREATE INDEX payments_queue_job_id ON payments_queue(job_id);

COMMENT ON table payments_queue IS 
$$ This is a holding table and hence not a candidate for normalization.
Jobs should be deleted from this table when they complete successfully.$$;

CREATE TABLE new_shipto (
	id serial primary key,
	trans_id int references transactions(id),
	oe_id int references oe(id),
	location_id int references location(id)
);

COMMENT ON TABLE new_shipto IS
$$ Tracks ship_to information for orders and invoices.$$;

CREATE TABLE tax_extended (
    tax_basis numeric,
    rate numeric,
    entry_id int primary key references acc_trans(entry_id)
);

COMMENT ON TABLE tax_extended IS 
$$ This stores extended information for manual tax calculations.$$;

CREATE OR REPLACE VIEW periods AS
SELECT 'ytd' as id, 'Year to Date' as label, now()::date as date_to, 
       (extract('year' from now())::text || '-01-01')::date as date_from
UNION
SELECT 'last_year', 'Last Year', 
       ((extract('YEAR' from now()) - 1)::text || '-12-31')::date as date_to,
       ((extract('YEAR' from now()) - 1)::text || '-01-01')::date as date_from
;

GRANT SELECT ON periods TO public;

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

COMMENT ON TABLE asset_dep_method IS
$$ Stores asset depreciation methods, and their relevant stored procedures.

The fixed asset system is such depreciation methods can be plugged in via this
table.$$;

COMMENT ON COLUMN asset_dep_method.sproc IS
$$The sproc mentioned here is a stored procedure which must have the following
arguments: (in_asset_ids int[],  in_report_date date, in_report_id int).

Here in_asset_ids are the assets to be depreciated, in_report_date is the date
of the report, and in_report_id is the id of the report.  The sproc MUST
insert the relevant lines into asset_report_line. $$;

comment on column asset_dep_method.method IS 
$$ These are keyed to specific stored procedures.  Currently only "straight_line" is supported$$;

INSERT INTO asset_dep_method(method, unit_class, sproc, unit_label, short_name) 
values ('Annual Straight Line Daily', 1, 'asset_dep_straight_line_yr_d', 'in years', 'SLYD');


INSERT INTO asset_dep_method(method, unit_class, sproc, unit_label, short_name) 
values ('Whole Month Straight Line', 1, 'asset_dep_straight_line_whl_m', 
'in months', 'SLMM');

INSERT INTO asset_dep_method(method, unit_class, sproc, unit_label, short_name) 
values ('Annual Straight Line Monthly', 1, 'asset_dep_straight_line_yr_m', 'in years', 'SLYM');

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

COMMENT ON TABLE asset_item IS 
$$ Stores details of asset items.  The account fields here are authoritative,
while the ones in the asset_class table are defaults.$$;

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

COMMENT ON TABLE asset_report_class IS 
$$  By default only four types of asset reports are supported.  In the future
others may be added.  Please correspond on the list before adding more types.$$;

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

COMMENT ON TABLE asset_report IS
$$ Asset reports are discrete sets of depreciation or disposal transctions,
and each one may be turned into no more than one GL transaction.$$;

CREATE TABLE asset_report_line(
	asset_id bigint references asset_item(id),
        report_id bigint references asset_report(id),
	amount numeric,
	department_id int references department(id),
	warehouse_id int references warehouse(id),
	PRIMARY KEY(asset_id, report_id)
);

COMMENT ON column asset_report_line.department_id IS
$$ In case assets are moved between departments, we have to store this here.$$;

CREATE TABLE asset_rl_to_disposal_method (
       report_id int references asset_report(id),
       asset_id int references asset_item(id),
       disposal_method_id int references asset_disposal_method(id),
       percent_disposed numeric,
       primary key (report_id, asset_id, disposal_method_id)
);

COMMENT ON TABLE asset_rl_to_disposal_method IS
$$ Maps disposal method to line items in the asset disposal report.$$;

CREATE TABLE mime_type (
       id serial not null unique,
       mime_type text primary key,
       invoice_include bool default false
);

COMMENT ON TABLE mime_type IS
$$ This is a lookup table for storing MIME types.$$;

INSERT INTO mime_type (mime_type) VALUES('all/all');
INSERT INTO mime_type (mime_type) VALUES('all/allfiles');
INSERT INTO mime_type (mime_type) VALUES('audio/x-flac');
INSERT INTO mime_type (mime_type) VALUES('audio/x-ape');
INSERT INTO mime_type (mime_type) VALUES('audio/x-scpls');
INSERT INTO mime_type (mime_type) VALUES('audio/mp4');
INSERT INTO mime_type (mime_type) VALUES('audio/mpeg');
INSERT INTO mime_type (mime_type) VALUES('audio/x-iriver-pla');
INSERT INTO mime_type (mime_type) VALUES('audio/x-speex+ogg');
INSERT INTO mime_type (mime_type) VALUES('audio/x-mod');
INSERT INTO mime_type (mime_type) VALUES('audio/x-tta');
INSERT INTO mime_type (mime_type) VALUES('audio/annodex');
INSERT INTO mime_type (mime_type) VALUES('audio/x-mo3');
INSERT INTO mime_type (mime_type) VALUES('audio/midi');
INSERT INTO mime_type (mime_type) VALUES('audio/mp2');
INSERT INTO mime_type (mime_type) VALUES('audio/x-musepack');
INSERT INTO mime_type (mime_type) VALUES('audio/x-minipsf');
INSERT INTO mime_type (mime_type) VALUES('audio/x-mpegurl');
INSERT INTO mime_type (mime_type) VALUES('audio/x-aiff');
INSERT INTO mime_type (mime_type) VALUES('audio/x-xm');
INSERT INTO mime_type (mime_type) VALUES('audio/x-aifc');
INSERT INTO mime_type (mime_type) VALUES('audio/x-m4b');
INSERT INTO mime_type (mime_type) VALUES('audio/aac');
INSERT INTO mime_type (mime_type) VALUES('audio/x-psflib');
INSERT INTO mime_type (mime_type) VALUES('audio/x-pn-realaudio-plugin');
INSERT INTO mime_type (mime_type) VALUES('audio/basic');
INSERT INTO mime_type (mime_type) VALUES('audio/x-ms-wma');
INSERT INTO mime_type (mime_type) VALUES('audio/AMR-WB');
INSERT INTO mime_type (mime_type) VALUES('audio/x-riff');
INSERT INTO mime_type (mime_type) VALUES('audio/x-psf');
INSERT INTO mime_type (mime_type) VALUES('audio/x-adpcm');
INSERT INTO mime_type (mime_type) VALUES('audio/ogg');
INSERT INTO mime_type (mime_type) VALUES('audio/x-wav');
INSERT INTO mime_type (mime_type) VALUES('audio/x-matroska');
INSERT INTO mime_type (mime_type) VALUES('audio/x-voc');
INSERT INTO mime_type (mime_type) VALUES('audio/ac3');
INSERT INTO mime_type (mime_type) VALUES('audio/x-flac+ogg');
INSERT INTO mime_type (mime_type) VALUES('audio/x-aiffc');
INSERT INTO mime_type (mime_type) VALUES('audio/x-it');
INSERT INTO mime_type (mime_type) VALUES('audio/AMR');
INSERT INTO mime_type (mime_type) VALUES('audio/x-s3m');
INSERT INTO mime_type (mime_type) VALUES('audio/x-speex');
INSERT INTO mime_type (mime_type) VALUES('audio/x-wavpack');
INSERT INTO mime_type (mime_type) VALUES('audio/x-xi');
INSERT INTO mime_type (mime_type) VALUES('audio/x-xmf');
INSERT INTO mime_type (mime_type) VALUES('audio/x-wavpack-correction');
INSERT INTO mime_type (mime_type) VALUES('audio/prs.sid');
INSERT INTO mime_type (mime_type) VALUES('audio/x-gsm');
INSERT INTO mime_type (mime_type) VALUES('audio/x-ms-asx');
INSERT INTO mime_type (mime_type) VALUES('audio/x-vorbis+ogg');
INSERT INTO mime_type (mime_type) VALUES('audio/x-stm');
INSERT INTO mime_type (mime_type) VALUES('x-epoc/x-sisx-app');
INSERT INTO mime_type (mime_type) VALUES('image/x-fpx');
INSERT INTO mime_type (mime_type) VALUES('image/x-panasonic-raw');
INSERT INTO mime_type (mime_type) VALUES('image/x-xwindowdump');
INSERT INTO mime_type (mime_type) VALUES('image/x-nikon-nef');
INSERT INTO mime_type (mime_type) VALUES('image/x-niff');
INSERT INTO mime_type (mime_type) VALUES('image/x-pict');
INSERT INTO mime_type (mime_type) VALUES('image/svg+xml-compressed');
INSERT INTO mime_type (mime_type) VALUES('image/jp2');
INSERT INTO mime_type (mime_type) VALUES('image/x-msod');
INSERT INTO mime_type (mime_type) VALUES('image/x-dds');
INSERT INTO mime_type (mime_type) VALUES('image/x-olympus-orf');
INSERT INTO mime_type (mime_type) VALUES('image/x-portable-graymap');
INSERT INTO mime_type (mime_type) VALUES('image/x-skencil');
INSERT INTO mime_type (mime_type) VALUES('image/x-sony-srf');
INSERT INTO mime_type (mime_type) VALUES('image/x-dib');
INSERT INTO mime_type (mime_type) VALUES('image/x-emf');
INSERT INTO mime_type (mime_type) VALUES('image/x-eps');
INSERT INTO mime_type (mime_type) VALUES('image/ief');
INSERT INTO mime_type (mime_type) VALUES('image/x-pcx');
INSERT INTO mime_type (mime_type) VALUES('image/x-gzeps');
INSERT INTO mime_type (mime_type) VALUES('image/x-xcf');
INSERT INTO mime_type (mime_type) VALUES('image/x-portable-pixmap');
INSERT INTO mime_type (mime_type) VALUES('image/x-kde-raw');
INSERT INTO mime_type (mime_type) VALUES('image/openraster');
INSERT INTO mime_type (mime_type) VALUES('image/x-macpaint');
INSERT INTO mime_type (mime_type) VALUES('image/x-wmf');
INSERT INTO mime_type (mime_type) VALUES('image/x-win-bitmap');
INSERT INTO mime_type (mime_type) VALUES('image/x-sgi');
INSERT INTO mime_type (mime_type) VALUES('image/x-ilbm');
INSERT INTO mime_type (mime_type) VALUES('image/x-sony-sr2');
INSERT INTO mime_type (mime_type) VALUES('image/x-sigma-x3f');
INSERT INTO mime_type (mime_type) VALUES('image/x-bzeps');
INSERT INTO mime_type (mime_type) VALUES('image/x-icns');
INSERT INTO mime_type (mime_type) VALUES('image/g3fax');
INSERT INTO mime_type (mime_type) VALUES('image/x-applix-graphics');
INSERT INTO mime_type (mime_type) VALUES('image/x-xcursor');
INSERT INTO mime_type (mime_type) VALUES('image/x-kodak-dcr');
INSERT INTO mime_type (mime_type) VALUES('image/x-hdr');
INSERT INTO mime_type (mime_type) VALUES('image/x-cmu-raster');
INSERT INTO mime_type (mime_type) VALUES('image/x-sun-raster');
INSERT INTO mime_type (mime_type) VALUES('image/fax-g3');
INSERT INTO mime_type (mime_type) VALUES('image/x-kodak-kdc');
INSERT INTO mime_type (mime_type) VALUES('image/jpeg');
INSERT INTO mime_type (mime_type) VALUES('image/tiff');
INSERT INTO mime_type (mime_type) VALUES('image/dpx');
INSERT INTO mime_type (mime_type) VALUES('image/x-dcraw');
INSERT INTO mime_type (mime_type) VALUES('image/x-adobe-dng');
INSERT INTO mime_type (mime_type) VALUES('image/x-canon-crw');
INSERT INTO mime_type (mime_type) VALUES('image/bmp');
INSERT INTO mime_type (mime_type) VALUES('image/x-xfig');
INSERT INTO mime_type (mime_type) VALUES('image/x-lwo');
INSERT INTO mime_type (mime_type) VALUES('image/x-fuji-raf');
INSERT INTO mime_type (mime_type) VALUES('image/x-xbitmap');
INSERT INTO mime_type (mime_type) VALUES('image/x-pentax-pef');
INSERT INTO mime_type (mime_type) VALUES('image/x-exr');
INSERT INTO mime_type (mime_type) VALUES('image/rle');
INSERT INTO mime_type (mime_type) VALUES('image/x-3ds');
INSERT INTO mime_type (mime_type) VALUES('image/svg+xml');
INSERT INTO mime_type (mime_type) VALUES('image/x-lws');
INSERT INTO mime_type (mime_type) VALUES('image/x-tga');
INSERT INTO mime_type (mime_type) VALUES('image/x-compressed-xcf');
INSERT INTO mime_type (mime_type) VALUES('image/fits');
INSERT INTO mime_type (mime_type) VALUES('image/x-kodak-k25');
INSERT INTO mime_type (mime_type) VALUES('image/x-portable-bitmap');
INSERT INTO mime_type (mime_type) VALUES('image/x-quicktime');
INSERT INTO mime_type (mime_type) VALUES('image/x-sony-arw');
INSERT INTO mime_type (mime_type) VALUES('image/x-xpixmap');
INSERT INTO mime_type (mime_type) VALUES('image/gif');
INSERT INTO mime_type (mime_type) VALUES('image/x-portable-anymap');
INSERT INTO mime_type (mime_type) VALUES('image/x-jng');
INSERT INTO mime_type (mime_type) VALUES('image/x-iff');
INSERT INTO mime_type (mime_type) VALUES('image/x-canon-cr2');
INSERT INTO mime_type (mime_type) VALUES('image/cgm');
INSERT INTO mime_type (mime_type) VALUES('image/x-photo-cd');
INSERT INTO mime_type (mime_type) VALUES('image/png');
INSERT INTO mime_type (mime_type) VALUES('image/x-minolta-mrw');
INSERT INTO mime_type (mime_type) VALUES('image/x-rgb');
INSERT INTO mime_type (mime_type) VALUES('image/x-pic');
INSERT INTO mime_type (mime_type) VALUES('message/disposition-notification');
INSERT INTO mime_type (mime_type) VALUES('message/news');
INSERT INTO mime_type (mime_type) VALUES('message/partial');
INSERT INTO mime_type (mime_type) VALUES('message/x-gnu-rmail');
INSERT INTO mime_type (mime_type) VALUES('message/delivery-status');
INSERT INTO mime_type (mime_type) VALUES('message/external-body');
INSERT INTO mime_type (mime_type) VALUES('message/rfc822');
INSERT INTO mime_type (mime_type) VALUES('uri/mmst');
INSERT INTO mime_type (mime_type) VALUES('uri/rtspu');
INSERT INTO mime_type (mime_type) VALUES('uri/pnm');
INSERT INTO mime_type (mime_type) VALUES('uri/mmsu');
INSERT INTO mime_type (mime_type) VALUES('uri/rtspt');
INSERT INTO mime_type (mime_type) VALUES('uri/mms');
INSERT INTO mime_type (mime_type) VALUES('text/x-tcl');
INSERT INTO mime_type (mime_type) VALUES('text/directory');
INSERT INTO mime_type (mime_type) VALUES('text/htmlh');
INSERT INTO mime_type (mime_type) VALUES('text/x-literate-haskell');
INSERT INTO mime_type (mime_type) VALUES('text/xmcd');
INSERT INTO mime_type (mime_type) VALUES('text/x-ms-regedit');
INSERT INTO mime_type (mime_type) VALUES('text/x-microdvd');
INSERT INTO mime_type (mime_type) VALUES('text/x-erlang');
INSERT INTO mime_type (mime_type) VALUES('text/x-ssa');
INSERT INTO mime_type (mime_type) VALUES('text/plain');
INSERT INTO mime_type (mime_type) VALUES('text/spreadsheet');
INSERT INTO mime_type (mime_type) VALUES('text/sgml');
INSERT INTO mime_type (mime_type) VALUES('text/x-uil');
INSERT INTO mime_type (mime_type) VALUES('text/x-troff-mm');
INSERT INTO mime_type (mime_type) VALUES('text/x-gettext-translation');
INSERT INTO mime_type (mime_type) VALUES('text/x-vhdl');
INSERT INTO mime_type (mime_type) VALUES('text/x-java');
INSERT INTO mime_type (mime_type) VALUES('text/x-nfo');
INSERT INTO mime_type (mime_type) VALUES('text/csv');
INSERT INTO mime_type (mime_type) VALUES('text/x-install');
INSERT INTO mime_type (mime_type) VALUES('text/x-c++src');
INSERT INTO mime_type (mime_type) VALUES('text/x-subviewer');
INSERT INTO mime_type (mime_type) VALUES('text/x-adasrc');
INSERT INTO mime_type (mime_type) VALUES('text/x-dsl');
INSERT INTO mime_type (mime_type) VALUES('text/x-chdr');
INSERT INTO mime_type (mime_type) VALUES('text/calendar');
INSERT INTO mime_type (mime_type) VALUES('text/x-csharp');
INSERT INTO mime_type (mime_type) VALUES('text/x-lua');
INSERT INTO mime_type (mime_type) VALUES('text/x-ocaml');
INSERT INTO mime_type (mime_type) VALUES('text/x-iMelody');
INSERT INTO mime_type (mime_type) VALUES('text/enriched');
INSERT INTO mime_type (mime_type) VALUES('text/richtext');
INSERT INTO mime_type (mime_type) VALUES('text/x-objchdr');
INSERT INTO mime_type (mime_type) VALUES('text/x-makefile');
INSERT INTO mime_type (mime_type) VALUES('text/x-copying');
INSERT INTO mime_type (mime_type) VALUES('text/x-pascal');
INSERT INTO mime_type (mime_type) VALUES('text/x-credits');
INSERT INTO mime_type (mime_type) VALUES('text/x-mup');
INSERT INTO mime_type (mime_type) VALUES('text/x-opml+xml');
INSERT INTO mime_type (mime_type) VALUES('text/x-rpm-spec');
INSERT INTO mime_type (mime_type) VALUES('text/x-xmi');
INSERT INTO mime_type (mime_type) VALUES('text/x-dsrc');
INSERT INTO mime_type (mime_type) VALUES('text/x-patch');
INSERT INTO mime_type (mime_type) VALUES('text/x-authors');
INSERT INTO mime_type (mime_type) VALUES('text/x-ldif');
INSERT INTO mime_type (mime_type) VALUES('text/x-moc');
INSERT INTO mime_type (mime_type) VALUES('text/x-tex');
INSERT INTO mime_type (mime_type) VALUES('text/x-dcl');
INSERT INTO mime_type (mime_type) VALUES('text/x-python');
INSERT INTO mime_type (mime_type) VALUES('text/x-lilypond');
INSERT INTO mime_type (mime_type) VALUES('text/x-katefilelist');
INSERT INTO mime_type (mime_type) VALUES('text/troff');
INSERT INTO mime_type (mime_type) VALUES('text/x-hex');
INSERT INTO mime_type (mime_type) VALUES('text/x-google-video-pointer');
INSERT INTO mime_type (mime_type) VALUES('text/x-haskell');
INSERT INTO mime_type (mime_type) VALUES('text/x-ocl');
INSERT INTO mime_type (mime_type) VALUES('text/x-idl');
INSERT INTO mime_type (mime_type) VALUES('text/x-troff-me');
INSERT INTO mime_type (mime_type) VALUES('text/x-bibtex');
INSERT INTO mime_type (mime_type) VALUES('text/x-sql');
INSERT INTO mime_type (mime_type) VALUES('text/x-emacs-lisp');
INSERT INTO mime_type (mime_type) VALUES('text/x-eiffel');
INSERT INTO mime_type (mime_type) VALUES('text/css');
INSERT INTO mime_type (mime_type) VALUES('text/x-fortran');
INSERT INTO mime_type (mime_type) VALUES('text/x-xslfo');
INSERT INTO mime_type (mime_type) VALUES('text/x-matlab');
INSERT INTO mime_type (mime_type) VALUES('text/x-uri');
INSERT INTO mime_type (mime_type) VALUES('text/x-setext');
INSERT INTO mime_type (mime_type) VALUES('text/x-readme');
INSERT INTO mime_type (mime_type) VALUES('text/x-troff-ms');
INSERT INTO mime_type (mime_type) VALUES('text/x-cmake');
INSERT INTO mime_type (mime_type) VALUES('text/tab-separated-values');
INSERT INTO mime_type (mime_type) VALUES('text/x-log');
INSERT INTO mime_type (mime_type) VALUES('text/x-mpsub');
INSERT INTO mime_type (mime_type) VALUES('text/x-mof');
INSERT INTO mime_type (mime_type) VALUES('text/html');
INSERT INTO mime_type (mime_type) VALUES('text/x-txt2tags');
INSERT INTO mime_type (mime_type) VALUES('text/x-csrc');
INSERT INTO mime_type (mime_type) VALUES('text/rfc822-headers');
INSERT INTO mime_type (mime_type) VALUES('text/x-mrml');
INSERT INTO mime_type (mime_type) VALUES('text/x-vala');
INSERT INTO mime_type (mime_type) VALUES('text/x-iptables');
INSERT INTO mime_type (mime_type) VALUES('text/x-c++hdr');
INSERT INTO mime_type (mime_type) VALUES('text/x-scheme');
INSERT INTO mime_type (mime_type) VALUES('text/x-texinfo');
INSERT INTO mime_type (mime_type) VALUES('text/x-objcsrc');
INSERT INTO mime_type (mime_type) VALUES('text/x-changelog');
INSERT INTO mime_type (mime_type) VALUES('x-content/audio-dvd');
INSERT INTO mime_type (mime_type) VALUES('x-content/video-svcd');
INSERT INTO mime_type (mime_type) VALUES('x-content/video-hddvd');
INSERT INTO mime_type (mime_type) VALUES('x-content/blank-dvd');
INSERT INTO mime_type (mime_type) VALUES('x-content/video-vcd');
INSERT INTO mime_type (mime_type) VALUES('x-content/unix-software');
INSERT INTO mime_type (mime_type) VALUES('x-content/blank-cd');
INSERT INTO mime_type (mime_type) VALUES('x-content/audio-cdda');
INSERT INTO mime_type (mime_type) VALUES('x-content/win32-software');
INSERT INTO mime_type (mime_type) VALUES('x-content/blank-hddvd');
INSERT INTO mime_type (mime_type) VALUES('x-content/audio-player');
INSERT INTO mime_type (mime_type) VALUES('x-content/video-dvd');
INSERT INTO mime_type (mime_type) VALUES('x-content/image-picturecd');
INSERT INTO mime_type (mime_type) VALUES('x-content/blank-bd');
INSERT INTO mime_type (mime_type) VALUES('x-content/video-bluray');
INSERT INTO mime_type (mime_type) VALUES('x-content/image-dcf');
INSERT INTO mime_type (mime_type) VALUES('x-content/software');
INSERT INTO mime_type (mime_type) VALUES('model/vrml');
INSERT INTO mime_type (mime_type) VALUES('fonts/package');
INSERT INTO mime_type (mime_type) VALUES('application/x-hwp');
INSERT INTO mime_type (mime_type) VALUES('application/x-pkcs7-certificates');
INSERT INTO mime_type (mime_type) VALUES('application/x-shockwave-flash');
INSERT INTO mime_type (mime_type) VALUES('application/x-turtle');
INSERT INTO mime_type (mime_type) VALUES('application/x-rar');
INSERT INTO mime_type (mime_type) VALUES('application/x-bittorrent');
INSERT INTO mime_type (mime_type) VALUES('application/prs.plucker');
INSERT INTO mime_type (mime_type) VALUES('application/smil');
INSERT INTO mime_type (mime_type) VALUES('application/x-abiword');
INSERT INTO mime_type (mime_type) VALUES('application/x-blender');
INSERT INTO mime_type (mime_type) VALUES('application/x-oleo');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-sunos-news');
INSERT INTO mime_type (mime_type) VALUES('application/x-tex-gf');
INSERT INTO mime_type (mime_type) VALUES('application/x-netshow-channel');
INSERT INTO mime_type (mime_type) VALUES('application/x-m4');
INSERT INTO mime_type (mime_type) VALUES('application/x-kexiproject-sqlite2');
INSERT INTO mime_type (mime_type) VALUES('application/x-kpovmodeler');
INSERT INTO mime_type (mime_type) VALUES('application/illustrator');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-snf');
INSERT INTO mime_type (mime_type) VALUES('application/x-gedcom');
INSERT INTO mime_type (mime_type) VALUES('application/x-kexiproject-shortcut');
INSERT INTO mime_type (mime_type) VALUES('application/andrew-inset');
INSERT INTO mime_type (mime_type) VALUES('application/x-bzdvi');
INSERT INTO mime_type (mime_type) VALUES('application/x-siag');
INSERT INTO mime_type (mime_type) VALUES('application/x-ktheme');
INSERT INTO mime_type (mime_type) VALUES('application/x-kspread');
INSERT INTO mime_type (mime_type) VALUES('application/x-cbr');
INSERT INTO mime_type (mime_type) VALUES('application/x-cmakecache');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-framemaker');
INSERT INTO mime_type (mime_type) VALUES('application/x-msx-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-vfont');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-ttx');
INSERT INTO mime_type (mime_type) VALUES('application/x-uml');
INSERT INTO mime_type (mime_type) VALUES('application/x-cdrdao-toc');
INSERT INTO mime_type (mime_type) VALUES('application/x-kpresenter');
INSERT INTO mime_type (mime_type) VALUES('application/x-kseg');
INSERT INTO mime_type (mime_type) VALUES('application/x-dvi');
INSERT INTO mime_type (mime_type) VALUES('application/x-java-applet');
INSERT INTO mime_type (mime_type) VALUES('application/x-palm-database');
INSERT INTO mime_type (mime_type) VALUES('application/pgp-encrypted');
INSERT INTO mime_type (mime_type) VALUES('application/x-pocket-word');
INSERT INTO mime_type (mime_type) VALUES('application/x-kmplot');
INSERT INTO mime_type (mime_type) VALUES('application/x-core');
INSERT INTO mime_type (mime_type) VALUES('application/x-profile');
INSERT INTO mime_type (mime_type) VALUES('application/x-mswinurl');
INSERT INTO mime_type (mime_type) VALUES('application/x-lha');
INSERT INTO mime_type (mime_type) VALUES('application/x-netcdf');
INSERT INTO mime_type (mime_type) VALUES('application/msword');
INSERT INTO mime_type (mime_type) VALUES('application/x-dar');
INSERT INTO mime_type (mime_type) VALUES('application/pgp-signature');
INSERT INTO mime_type (mime_type) VALUES('application/x-dmod');
INSERT INTO mime_type (mime_type) VALUES('application/x-fictionbook+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-gettext-translation');
INSERT INTO mime_type (mime_type) VALUES('application/x-ace');
INSERT INTO mime_type (mime_type) VALUES('application/x-macbinary');
INSERT INTO mime_type (mime_type) VALUES('application/x-nintendo-ds-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-troff-man-compressed');
INSERT INTO mime_type (mime_type) VALUES('application/x-java');
INSERT INTO mime_type (mime_type) VALUES('application/x-mimearchive');
INSERT INTO mime_type (mime_type) VALUES('application/xml-dtd');
INSERT INTO mime_type (mime_type) VALUES('application/x-smaf');
INSERT INTO mime_type (mime_type) VALUES('application/x-pw');
INSERT INTO mime_type (mime_type) VALUES('application/x-lhz');
INSERT INTO mime_type (mime_type) VALUES('application/x-dia-diagram');
INSERT INTO mime_type (mime_type) VALUES('application/x-kugar');
INSERT INTO mime_type (mime_type) VALUES('application/x-sv4cpio');
INSERT INTO mime_type (mime_type) VALUES('application/x-kcachegrind');
INSERT INTO mime_type (mime_type) VALUES('application/x-gnumeric');
INSERT INTO mime_type (mime_type) VALUES('application/x-fluid');
INSERT INTO mime_type (mime_type) VALUES('application/x-quattropro');
INSERT INTO mime_type (mime_type) VALUES('application/x-gzip');
INSERT INTO mime_type (mime_type) VALUES('application/x-shared-library-la');
INSERT INTO mime_type (mime_type) VALUES('application/x-gba-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-sc');
INSERT INTO mime_type (mime_type) VALUES('application/x-glade');
INSERT INTO mime_type (mime_type) VALUES('application/x-catalog');
INSERT INTO mime_type (mime_type) VALUES('application/x-php');
INSERT INTO mime_type (mime_type) VALUES('application/x-kexiproject-sqlite3');
INSERT INTO mime_type (mime_type) VALUES('application/x-asp');
INSERT INTO mime_type (mime_type) VALUES('application/x-sqlite2');
INSERT INTO mime_type (mime_type) VALUES('application/x-tzo');
INSERT INTO mime_type (mime_type) VALUES('application/x-wais-source');
INSERT INTO mime_type (mime_type) VALUES('application/x-jbuilder-project');
INSERT INTO mime_type (mime_type) VALUES('application/x-package-list');
INSERT INTO mime_type (mime_type) VALUES('application/annodex');
INSERT INTO mime_type (mime_type) VALUES('application/x-toutdoux');
INSERT INTO mime_type (mime_type) VALUES('application/x-stuffit');
INSERT INTO mime_type (mime_type) VALUES('application/pkcs10');
INSERT INTO mime_type (mime_type) VALUES('application/x-sv4crc');
INSERT INTO mime_type (mime_type) VALUES('application/x-java-keystore');
INSERT INTO mime_type (mime_type) VALUES('application/x-kommander');
INSERT INTO mime_type (mime_type) VALUES('application/x-sami');
INSERT INTO mime_type (mime_type) VALUES('application/xspf+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-killustrator');
INSERT INTO mime_type (mime_type) VALUES('application/x-kgetlist');
INSERT INTO mime_type (mime_type) VALUES('application/x-hdf');
INSERT INTO mime_type (mime_type) VALUES('application/x-mobipocket-ebook');
INSERT INTO mime_type (mime_type) VALUES('application/x-shellscript');
INSERT INTO mime_type (mime_type) VALUES('application/xhtml+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-compressed-tar');
INSERT INTO mime_type (mime_type) VALUES('application/x-nzb');
INSERT INTO mime_type (mime_type) VALUES('application/x-markaby');
INSERT INTO mime_type (mime_type) VALUES('application/x-sms-rom');
INSERT INTO mime_type (mime_type) VALUES('application/rtf');
INSERT INTO mime_type (mime_type) VALUES('application/x-tuberling');
INSERT INTO mime_type (mime_type) VALUES('application/x-kgeo');
INSERT INTO mime_type (mime_type) VALUES('application/x-n64-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-smb-server');
INSERT INTO mime_type (mime_type) VALUES('application/pkix-crl');
INSERT INTO mime_type (mime_type) VALUES('application/x-dbf');
INSERT INTO mime_type (mime_type) VALUES('application/x-webarchive');
INSERT INTO mime_type (mime_type) VALUES('application/x-smb-workgroup');
INSERT INTO mime_type (mime_type) VALUES('application/x-gnome-theme-package');
INSERT INTO mime_type (mime_type) VALUES('application/epub+zip');
INSERT INTO mime_type (mime_type) VALUES('application/x-kchart');
INSERT INTO mime_type (mime_type) VALUES('application/x-aportisdoc');
INSERT INTO mime_type (mime_type) VALUES('application/x-cisco-vpn-settings');
INSERT INTO mime_type (mime_type) VALUES('application/x-egon');
INSERT INTO mime_type (mime_type) VALUES('application/x-kword');
INSERT INTO mime_type (mime_type) VALUES('application/x-xbel');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-type1');
INSERT INTO mime_type (mime_type) VALUES('application/x-lzip');
INSERT INTO mime_type (mime_type) VALUES('application/x-gdbm');
INSERT INTO mime_type (mime_type) VALUES('application/x-executable');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-linux-psf');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-tex-tfm');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-afm');
INSERT INTO mime_type (mime_type) VALUES('application/x-kcsrc');
INSERT INTO mime_type (mime_type) VALUES('application/x-kontour');
INSERT INTO mime_type (mime_type) VALUES('application/x-msi');
INSERT INTO mime_type (mime_type) VALUES('application/x-cd-image');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-libgrx');
INSERT INTO mime_type (mime_type) VALUES('application/x-designer');
INSERT INTO mime_type (mime_type) VALUES('application/x-nautilus-link');
INSERT INTO mime_type (mime_type) VALUES('application/x-zerosize');
INSERT INTO mime_type (mime_type) VALUES('application/x-superkaramba');
INSERT INTO mime_type (mime_type) VALUES('application/x-quanta');
INSERT INTO mime_type (mime_type) VALUES('application/ram');
INSERT INTO mime_type (mime_type) VALUES('application/javascript');
INSERT INTO mime_type (mime_type) VALUES('application/rdf+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-spss-por');
INSERT INTO mime_type (mime_type) VALUES('application/x-gnuplot');
INSERT INTO mime_type (mime_type) VALUES('application/x-kformula');
INSERT INTO mime_type (mime_type) VALUES('application/x-mif');
INSERT INTO mime_type (mime_type) VALUES('application/x-amipro');
INSERT INTO mime_type (mime_type) VALUES('application/x-slp');
INSERT INTO mime_type (mime_type) VALUES('application/x-audacity-project');
INSERT INTO mime_type (mime_type) VALUES('application/x-archive');
INSERT INTO mime_type (mime_type) VALUES('application/x-windows-themepack');
INSERT INTO mime_type (mime_type) VALUES('application/x-t602');
INSERT INTO mime_type (mime_type) VALUES('application/x-mswrite');
INSERT INTO mime_type (mime_type) VALUES('application/dicom');
INSERT INTO mime_type (mime_type) VALUES('application/x-gzdvi');
INSERT INTO mime_type (mime_type) VALUES('application/x-chm');
INSERT INTO mime_type (mime_type) VALUES('application/x-lzma-compressed-tar');
INSERT INTO mime_type (mime_type) VALUES('application/x-7z-compressed');
INSERT INTO mime_type (mime_type) VALUES('application/postscript');
INSERT INTO mime_type (mime_type) VALUES('application/x-gtktalog');
INSERT INTO mime_type (mime_type) VALUES('application/x-alz');
INSERT INTO mime_type (mime_type) VALUES('application/x-ustar');
INSERT INTO mime_type (mime_type) VALUES('application/x-troff-man');
INSERT INTO mime_type (mime_type) VALUES('application/xml');
INSERT INTO mime_type (mime_type) VALUES('application/sieve');
INSERT INTO mime_type (mime_type) VALUES('application/x-konsole');
INSERT INTO mime_type (mime_type) VALUES('application/x-dc-rom');
INSERT INTO mime_type (mime_type) VALUES('application/xsd');
INSERT INTO mime_type (mime_type) VALUES('application/pkcs7-mime');
INSERT INTO mime_type (mime_type) VALUES('application/x-xz');
INSERT INTO mime_type (mime_type) VALUES('application/x-cda');
INSERT INTO mime_type (mime_type) VALUES('application/x-abicollab');
INSERT INTO mime_type (mime_type) VALUES('application/x-cpio');
INSERT INTO mime_type (mime_type) VALUES('application/x-tgif');
INSERT INTO mime_type (mime_type) VALUES('application/x-class-file');
INSERT INTO mime_type (mime_type) VALUES('application/x-desktop');
INSERT INTO mime_type (mime_type) VALUES('application/x-reject');
INSERT INTO mime_type (mime_type) VALUES('application/x-xz-compressed-tar');
INSERT INTO mime_type (mime_type) VALUES('application/x-kivio');
INSERT INTO mime_type (mime_type) VALUES('application/x-kopete-emoticons');
INSERT INTO mime_type (mime_type) VALUES('application/x-kexi-connectiondata');
INSERT INTO mime_type (mime_type) VALUES('application/x-compress');
INSERT INTO mime_type (mime_type) VALUES('application/x-gmc-link');
INSERT INTO mime_type (mime_type) VALUES('application/x-krita');
INSERT INTO mime_type (mime_type) VALUES('application/x-java-archive');
INSERT INTO mime_type (mime_type) VALUES('application/x-theme');
INSERT INTO mime_type (mime_type) VALUES('application/x-deb');
INSERT INTO mime_type (mime_type) VALUES('application/x-gnucash');
INSERT INTO mime_type (mime_type) VALUES('application/x-cabri');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-otf');
INSERT INTO mime_type (mime_type) VALUES('application/x-kexiproject-sqlite');
INSERT INTO mime_type (mime_type) VALUES('application/x-lzma');
INSERT INTO mime_type (mime_type) VALUES('application/rss+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-khtml-adaptor');
INSERT INTO mime_type (mime_type) VALUES('application/x-gzpostscript');
INSERT INTO mime_type (mime_type) VALUES('application/x-bzip');
INSERT INTO mime_type (mime_type) VALUES('application/mathml+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-chess-pgn');
INSERT INTO mime_type (mime_type) VALUES('application/x-remote-connection');
INSERT INTO mime_type (mime_type) VALUES('application/x-gameboy-rom');
INSERT INTO mime_type (mime_type) VALUES('application/pkix-pkipath');
INSERT INTO mime_type (mime_type) VALUES('application/x-shorten');
INSERT INTO mime_type (mime_type) VALUES('application/x-snes-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-quicktime-media-link');
INSERT INTO mime_type (mime_type) VALUES('application/x-ruby');
INSERT INTO mime_type (mime_type) VALUES('application/x-tarz');
INSERT INTO mime_type (mime_type) VALUES('application/ogg');
INSERT INTO mime_type (mime_type) VALUES('application/x-ole-storage');
INSERT INTO mime_type (mime_type) VALUES('application/x-shar');
INSERT INTO mime_type (mime_type) VALUES('application/x-ksysv-package');
INSERT INTO mime_type (mime_type) VALUES('application/x-x509-ca-cert');
INSERT INTO mime_type (mime_type) VALUES('application/x-par2');
INSERT INTO mime_type (mime_type) VALUES('application/x-linguist');
INSERT INTO mime_type (mime_type) VALUES('application/x-trig');
INSERT INTO mime_type (mime_type) VALUES('application/mac-binhex40');
INSERT INTO mime_type (mime_type) VALUES('application/x-qw');
INSERT INTO mime_type (mime_type) VALUES('application/xml-external-parsed-entity');
INSERT INTO mime_type (mime_type) VALUES('application/octet-stream');
INSERT INTO mime_type (mime_type) VALUES('application/x-matroska');
INSERT INTO mime_type (mime_type) VALUES('application/x-applix-spreadsheet');
INSERT INTO mime_type (mime_type) VALUES('application/x-plasma');
INSERT INTO mime_type (mime_type) VALUES('application/x-e-theme');
INSERT INTO mime_type (mime_type) VALUES('application/x-cbz');
INSERT INTO mime_type (mime_type) VALUES('application/x-java-jnlp-file');
INSERT INTO mime_type (mime_type) VALUES('application/x-kns');
INSERT INTO mime_type (mime_type) VALUES('application/x-win-lnk');
INSERT INTO mime_type (mime_type) VALUES('application/x-ufraw');
INSERT INTO mime_type (mime_type) VALUES('application/x-drgeo');
INSERT INTO mime_type (mime_type) VALUES('application/x-perl');
INSERT INTO mime_type (mime_type) VALUES('application/pkcs7-signature');
INSERT INTO mime_type (mime_type) VALUES('application/x-ms-dos-executable');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-tex');
INSERT INTO mime_type (mime_type) VALUES('application/x-kolf');
INSERT INTO mime_type (mime_type) VALUES('application/x-planperfect');
INSERT INTO mime_type (mime_type) VALUES('application/x-go-sgf');
INSERT INTO mime_type (mime_type) VALUES('application/x-kwallet');
INSERT INTO mime_type (mime_type) VALUES('application/x-rpm');
INSERT INTO mime_type (mime_type) VALUES('application/sdp');
INSERT INTO mime_type (mime_type) VALUES('application/x-java-pack200');
INSERT INTO mime_type (mime_type) VALUES('application/relaxng');
INSERT INTO mime_type (mime_type) VALUES('application/x-servicepack');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-bdf');
INSERT INTO mime_type (mime_type) VALUES('application/pkix-cert');
INSERT INTO mime_type (mime_type) VALUES('application/x-ipod-firmware');
INSERT INTO mime_type (mime_type) VALUES('application/x-object');
INSERT INTO mime_type (mime_type) VALUES('application/x-ica');
INSERT INTO mime_type (mime_type) VALUES('application/x-it87');
INSERT INTO mime_type (mime_type) VALUES('application/x-zoo');
INSERT INTO mime_type (mime_type) VALUES('application/x-gzpdf');
INSERT INTO mime_type (mime_type) VALUES('application/x-magicpoint');
INSERT INTO mime_type (mime_type) VALUES('application/docbook+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-csh');
INSERT INTO mime_type (mime_type) VALUES('application/x-nes-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-graphite');
INSERT INTO mime_type (mime_type) VALUES('application/x-spss-sav');
INSERT INTO mime_type (mime_type) VALUES('application/x-tar');
INSERT INTO mime_type (mime_type) VALUES('application/x-kvtml');
INSERT INTO mime_type (mime_type) VALUES('application/metalink+xml');
INSERT INTO mime_type (mime_type) VALUES('application/ecmascript');
INSERT INTO mime_type (mime_type) VALUES('application/x-hwt');
INSERT INTO mime_type (mime_type) VALUES('application/x-pak');
INSERT INTO mime_type (mime_type) VALUES('application/x-sqlite3');
INSERT INTO mime_type (mime_type) VALUES('application/x-trash');
INSERT INTO mime_type (mime_type) VALUES('application/x-arj');
INSERT INTO mime_type (mime_type) VALUES('application/x-k3b');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-pcf');
INSERT INTO mime_type (mime_type) VALUES('application/oda');
INSERT INTO mime_type (mime_type) VALUES('application/x-genesis-rom');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-ttf');
INSERT INTO mime_type (mime_type) VALUES('application/zip');
INSERT INTO mime_type (mime_type) VALUES('application/x-cbt');
INSERT INTO mime_type (mime_type) VALUES('application/x-kspread-crypt');
INSERT INTO mime_type (mime_type) VALUES('application/x-pef-executable');
INSERT INTO mime_type (mime_type) VALUES('application/x-brasero');
INSERT INTO mime_type (mime_type) VALUES('application/x-cb7');
INSERT INTO mime_type (mime_type) VALUES('application/x-frame');
INSERT INTO mime_type (mime_type) VALUES('application/x-lyx');
INSERT INTO mime_type (mime_type) VALUES('application/x-lzop');
INSERT INTO mime_type (mime_type) VALUES('application/x-planner');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnc');
INSERT INTO mime_type (mime_type) VALUES('application/atom+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-gz-font-linux-psf');
INSERT INTO mime_type (mime_type) VALUES('application/x-xliff');
INSERT INTO mime_type (mime_type) VALUES('application/mathematica');
INSERT INTO mime_type (mime_type) VALUES('application/xslt+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-sharedlib');
INSERT INTO mime_type (mime_type) VALUES('application/x-kwordquiz');
INSERT INTO mime_type (mime_type) VALUES('application/x-bzpostscript');
INSERT INTO mime_type (mime_type) VALUES('application/x-pkcs12');
INSERT INTO mime_type (mime_type) VALUES('application/x-mozilla-bookmarks');
INSERT INTO mime_type (mime_type) VALUES('application/x-awk');
INSERT INTO mime_type (mime_type) VALUES('application/x-navi-animation');
INSERT INTO mime_type (mime_type) VALUES('application/x-cpio-compressed');
INSERT INTO mime_type (mime_type) VALUES('application/x-arc');
INSERT INTO mime_type (mime_type) VALUES('application/x-icq');
INSERT INTO mime_type (mime_type) VALUES('application/x-bzpdf');
INSERT INTO mime_type (mime_type) VALUES('application/mbox');
INSERT INTO mime_type (mime_type) VALUES('application/x-ksysguard');
INSERT INTO mime_type (mime_type) VALUES('application/x-java-jce-keystore');
INSERT INTO mime_type (mime_type) VALUES('application/x-subrip');
INSERT INTO mime_type (mime_type) VALUES('application/x-karbon');
INSERT INTO mime_type (mime_type) VALUES('application/x-python-bytecode');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-dos');
INSERT INTO mime_type (mime_type) VALUES('application/pgp-keys');
INSERT INTO mime_type (mime_type) VALUES('application/x-font-speedo');
INSERT INTO mime_type (mime_type) VALUES('application/pdf');
INSERT INTO mime_type (mime_type) VALUES('application/x-cue');
INSERT INTO mime_type (mime_type) VALUES('application/x-gnome-saved-search');
INSERT INTO mime_type (mime_type) VALUES('application/x-bcpio');
INSERT INTO mime_type (mime_type) VALUES('application/x-applix-word');
INSERT INTO mime_type (mime_type) VALUES('application/mxf');
INSERT INTO mime_type (mime_type) VALUES('application/x-wpg');
INSERT INTO mime_type (mime_type) VALUES('application/x-bzip-compressed-tar');
INSERT INTO mime_type (mime_type) VALUES('application/x-kword-crypt');
INSERT INTO mime_type (mime_type) VALUES('application/x-kig');
INSERT INTO mime_type (mime_type) VALUES('application/gnunet-directory');
INSERT INTO mime_type (mime_type) VALUES('application/x-kourse');
INSERT INTO mime_type (mime_type) VALUES('application/x-kudesigner');
INSERT INTO mime_type (mime_type) VALUES('application/x-tex-pk');
INSERT INTO mime_type (mime_type) VALUES('video/x-ms-asf');
INSERT INTO mime_type (mime_type) VALUES('video/mp4');
INSERT INTO mime_type (mime_type) VALUES('video/mpeg');
INSERT INTO mime_type (mime_type) VALUES('video/annodex');
INSERT INTO mime_type (mime_type) VALUES('video/x-sgi-movie');
INSERT INTO mime_type (mime_type) VALUES('video/isivideo');
INSERT INTO mime_type (mime_type) VALUES('video/x-ogm+ogg');
INSERT INTO mime_type (mime_type) VALUES('video/x-mng');
INSERT INTO mime_type (mime_type) VALUES('video/x-flv');
INSERT INTO mime_type (mime_type) VALUES('video/x-flic');
INSERT INTO mime_type (mime_type) VALUES('video/x-theora+ogg');
INSERT INTO mime_type (mime_type) VALUES('video/3gpp');
INSERT INTO mime_type (mime_type) VALUES('video/x-ms-wmv');
INSERT INTO mime_type (mime_type) VALUES('video/ogg');
INSERT INTO mime_type (mime_type) VALUES('video/dv');
INSERT INTO mime_type (mime_type) VALUES('video/x-matroska');
INSERT INTO mime_type (mime_type) VALUES('video/vivo');
INSERT INTO mime_type (mime_type) VALUES('video/quicktime');
INSERT INTO mime_type (mime_type) VALUES('video/x-ms-wmp');
INSERT INTO mime_type (mime_type) VALUES('video/x-msvideo');
INSERT INTO mime_type (mime_type) VALUES('video/x-anim');
INSERT INTO mime_type (mime_type) VALUES('video/wavelet');
INSERT INTO mime_type (mime_type) VALUES('video/x-nsv');
INSERT INTO mime_type (mime_type) VALUES('interface/x-winamp-skin');
INSERT INTO mime_type (mime_type) VALUES('multipart/encrypted');
INSERT INTO mime_type (mime_type) VALUES('multipart/x-mixed-replace');
INSERT INTO mime_type (mime_type) VALUES('multipart/related');
INSERT INTO mime_type (mime_type) VALUES('multipart/report');
INSERT INTO mime_type (mime_type) VALUES('multipart/signed');
INSERT INTO mime_type (mime_type) VALUES('multipart/appledouble');
INSERT INTO mime_type (mime_type) VALUES('multipart/mixed');
INSERT INTO mime_type (mime_type) VALUES('multipart/alternative');
INSERT INTO mime_type (mime_type) VALUES('multipart/digest');
INSERT INTO mime_type (mime_type) VALUES('audio/vnd.rn-realaudio');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.dwg');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.djvu');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.rn-realpix');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.dxf');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.wap.wbmp');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.ms-modi');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.microsoft.icon');
INSERT INTO mime_type (mime_type) VALUES('image/vnd.adobe.photoshop');
INSERT INTO mime_type (mime_type) VALUES('text/vnd.wap.wml');
INSERT INTO mime_type (mime_type) VALUES('text/vnd.wap.wmlscript');
INSERT INTO mime_type (mime_type) VALUES('text/vnd.sun.j2me.app-descriptor');
INSERT INTO mime_type (mime_type) VALUES('text/vnd.abc');
INSERT INTO mime_type (mime_type) VALUES('text/vnd.rn-realtext');
INSERT INTO mime_type (mime_type) VALUES('text/vnd.graphviz');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.mozilla.xul+xml');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.text-web');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.kexi');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-word.document.macroenabled.12');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.scribus');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.writer.global');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.emusic-emusic_package');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.hp-pcl');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.mail');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.google-earth.kml+xml');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.plan');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.kde.okular-archive');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.openxmlformats-officedocument.presentationml.presentation');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-wpl');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.formula');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.text-flat-xml');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.chart');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.plan.work');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-excel.sheet.macroenabled.12');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.lotus-1-2-3');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.hp-hpgl');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.writer');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.text-master');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.corel-draw');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.draw');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.spreadsheet');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.calc');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-powerpoint.presentation.macroenabled.12');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.kplato');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.text');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.math');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.writer');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.graphics-flat-xml');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.impress');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.spreadsheet-flat-xml');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.htmldoc-book');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.symbian.install');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-excel.sheet.binary.macroenabled.12');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.google-earth.kmz');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.kplato.work');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-excel');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.kde.kphotoalbum-import');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.draw');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.openxmlformats-officedocument.presentationml.slideshow');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.calc');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-cab-compressed');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.base');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.sun.xml.math');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-powerpoint');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.apple.mpegurl');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-works');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.image');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.contactgroup');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.presentation');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.rn-realmedia');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.database');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.impress');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-access');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.openofficeorg.extension');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-xpsdocument');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.presentation-flat-xml');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.stardivision.chart');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.wordperfect');
INSERT INTO mime_type (mime_type) VALUES('application/x-vnd.kde.kugar.mixed');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.iccprofile');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.oasis.opendocument.graphics');
INSERT INTO mime_type (mime_type) VALUES('application/vnd.ms-tnef');
INSERT INTO mime_type (mime_type) VALUES('video/vnd.rn-realvideo');

UPDATE mime_type SET invoice_include = 'true' where mime_type like 'image/%';

CREATE TABLE file_class (
       id serial not null unique,
       class text primary key
);

insert into file_class values (1, 'transaction');
insert into file_class values (2, 'order');
insert into file_class values (3, 'part');

COMMENT ON TABLE file_class IS
$$ File classes are collections of files attached against rows in specific 
tables in the database.  They can be used in the future to implement other form 
of file attachment. $$;

CREATE TABLE file_base (
       content bytea NOT NULL,
       mime_type_id int not null references mime_type(id),
       file_name text not null,
       description text,
       uploaded_by int not null references entity(id),
       uploaded_at timestamp not null default now(),
       id serial not null unique,
       ref_key int not null,
       file_class int not null references file_class(id),
       primary key (ref_key, file_name, file_class)
);

COMMENT ON TABLE file_base IS
$$Abstract table, holds no records.  Inheriting table store actual file
attachment data. Can be queried however to retrieve lists of all files. $$;

COMMENT ON COLUMN file_base.ref_key IS
$$This column inheriting tables is used to reference the database row for the
attachment.  Inheriting tables MUST set the foreign key here appropriately.

This can also be used to create classifications of other documents, such as by
source of automatic import (where the file is not yet attached) or
even standard,
long-lived documents.$$;

CREATE TABLE file_transaction (
       check (file_class = 1),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) REFERENCES transactions(id)
) inherits (file_base);

COMMENT ON TABLE file_transaction IS
$$ File attachments primarily attached to AR/AP/GL.$$;

CREATE TABLE file_order (
       check (file_class=2),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references oe(id)
) inherits (file_base);

COMMENT ON TABLE file_order IS
$$ File attachments primarily attached to orders and quotations.$$;

CREATE TABLE file_part (
       check (file_class=3),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references parts(id)
) inherits (file_base);

COMMENT ON TABLE file_part IS
$$ File attachments primarily attached to orders and quotations.$$;

CREATE TABLE file_secondary_attachment (
       file_id int not null,
       source_class int references file_class(id),
       ref_key int not null,
       dest_class int references file_class(id),
       attached_by int not null references entity(id),
       attached_at timestamp not null default now(),
       PRIMARY KEY(file_id, source_class, dest_class, ref_key)
);

COMMENT ON TABLE file_secondary_attachment IS
$$Another abstract table.  This one will use rewrite rules to make inserts safe
because of the difficulty in managing inserts otherwise. Inheriting tables 
provide secondary links between the file and other database objects.

Due to the nature of database inheritance and unique constraints
in PostgreSQL, this must be partitioned in a star format.$$;

CREATE TABLE file_tx_to_order (
       PRIMARY KEY(file_id, source_class, dest_class, ref_key),
       foreign key (file_id) references file_transaction(id),
       foreign key (ref_key) references oe(id),
       check (source_class = 1),
       check (dest_class = 2)
) INHERITS (file_secondary_attachment);

CREATE RULE file_sec_insert_tx_oe AS ON INSERT TO file_secondary_attachment
WHERE source_class = 1 and dest_class = 2
DO INSTEAD
INSERT INTO file_tx_to_order(file_id, source_class, ref_key, dest_class,
attached_by, attached_at) 
VALUES (new.file_id, 1, new.ref_key, 2, 
       new.attached_by,
       coalesce(new.attached_at, now()));

COMMENT ON TABLE file_tx_to_order IS 
$$ Secondary links from transactions to orders.$$;

CREATE TABLE file_order_to_order (
       PRIMARY KEY(file_id, source_class, dest_class, ref_key),
       foreign key (file_id) references file_order(id),
       foreign key (ref_key) references oe(id),
       check (source_class = 2),
       check (dest_class = 2)
) INHERITS (file_secondary_attachment);

COMMENT ON TABLE file_order_to_order IS
$$ Secondary links from one order to another, for example to support order
consolidation.$$;

CREATE RULE file_sec_insert_oe_oe AS ON INSERT TO file_secondary_attachment
WHERE source_class = 2 and dest_class = 2
DO INSTEAD
INSERT INTO file_order_to_order(file_id, source_class, ref_key, dest_class,
attached_by, attached_at) 
VALUES (new.file_id, 2, new.ref_key, 2, 
       new.attached_by,
       coalesce(new.attached_at, now()));

CREATE TABLE file_order_to_tx (
       PRIMARY KEY(file_id, source_class, dest_class, ref_key),
       foreign key (file_id) references file_order(id),
       foreign key (ref_key) references transactions(id),
       check (source_class = 2),
       check (dest_class = 1)
) INHERITS (file_secondary_attachment);

COMMENT ON TABLE file_order_to_tx IS
$$ Secondary links from orders to transactions, for example to track files when
invoices are generated from orders.$$;

CREATE RULE file_sec_insert_oe_tx AS ON INSERT TO file_secondary_attachment
WHERE source_class = 2 and dest_class = 1
DO INSTEAD
INSERT INTO file_order_to_order(file_id, source_class, ref_key, dest_class,
attached_by, attached_at)
VALUES (new.file_id, 2, new.ref_key, 1,
       new.attached_by,
       coalesce(new.attached_at, now()));

CREATE TABLE file_view_catalog (
       file_class int references file_class(id) primary key,
       view_name text not null unique
);

CREATE TABLE cr_report (
    id bigserial primary key not null,
    chart_id int not null references account(id),
    their_total numeric not null,
    approved boolean not null default 'f',
    submitted boolean not null default 'f',
    end_date date not null default now(),
    updated timestamp not null default now(),
    entered_by int not null default person__get_my_entity_id() references entity(id),
    entered_username text not null default SESSION_USER,
    deleted boolean not null default 'f'::boolean,
    deleted_by int references entity(id),
    approved_by int references entity(id),
    approved_username text,
    recon_fx bool default false,
    CHECK (deleted is not true or approved is not true)
);

COMMENT ON TABLE cr_report IS
$$This table holds header data for cash reports.$$;

CREATE TABLE cr_report_line (
    id bigserial primary key not null,
    report_id int NOT NULL references cr_report(id),
    scn text, -- SCN is the check #
    their_balance numeric,
    our_balance numeric,
    errorcode INT,
    "user" int references entity(id) not null, 
    clear_time date,
    insert_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    trans_type text, 
    post_date date,
    ledger_id int REFERENCES acc_trans(entry_id),
    voucher_id int REFERENCES voucher(id),
    overlook boolean not null default 'f',
    cleared boolean not null default 'f'
);

COMMENT ON TABLE cr_report_line IS
$$ This stores line item data on transaction lines and whether they are 
cleared.$$;

COMMENT ON COLUMN cr_report_line.scn IS
$$ This is the check number.  Maps to acc_trans.source $$;

CREATE TABLE cr_coa_to_account (
    chart_id int not null references account(id),
    account text not null
);

COMMENT ON TABLE cr_coa_to_account IS
$$ Provides name mapping for the cash reconciliation screen.$$;

--
-- WE NEED A PAYMENT TABLE 
--

CREATE TABLE payment (
  id serial primary key,
  reference text NOT NULL,
  gl_id     integer references gl(id),
  payment_class integer NOT NULL,
  payment_date date default current_date,
  closed bool default FALSE,
  entity_credit_id   integer references entity_credit_account(id),
  employee_id integer references person(id),
  currency char(3),
  notes text,
  department_id integer default 0);
              
COMMENT ON TABLE payment IS $$ This table will store the main data on a payment, prepayment, overpayment, et$$;
COMMENT ON COLUMN payment.reference IS $$ This field will store the code for both receipts and payment order  $$; 
COMMENT ON COLUMN payment.closed IS $$ This will store the current state of a payment/receipt order $$;
COMMENT ON COLUMN payment.gl_id IS $$ A payment should always be linked to a GL movement $$;
CREATE  INDEX payment_id_idx ON payment(id);
                  
CREATE TABLE payment_links (
  payment_id integer references Payment(id),
  entry_id   integer references acc_trans(entry_id),
  type       integer);
COMMENT ON TABLE payment_links IS $$  
 An explanation to the type field.
 * A type 0 means the link is referencing an ar/ap  and was created
   using an overpayment movement after the receipt was created 
 * A type 1 means the link is referencing an ar/ap and  was made 
   on the payment creation, its not the product of an overpayment movement 
 * A type 2 means the link is not referencing an ar/ap and its the product
   of the overpayment logic 

 With this ideas in order we can do the following

 To get the payment amount we will sum the entries with type > 0.
 To get the linked amount we will sum the entries with type < 2.
 The overpayment account can be obtained from the entries with type = 2.

 This reasoning is hacky and i hope it can dissapear when we get to 1.4 - D.M.
$$;
 
commit;
