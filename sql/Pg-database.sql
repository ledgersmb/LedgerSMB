
begin;

-- Base sections for modules and roles

CREATE TABLE lsmb_module (
     id int not null unique,
     label text primary key
);

COMMENT ON TABLE lsmb_module IS
$$ This stores categories functionality into modules.  Addons may add rows here, but
the id should be hardcoded.  As always 900-1000 will be reserved for internal use,
and negative numbers will be reserved for testing.$$;

INSERT INTO lsmb_module (id, label)
VALUES (1, 'AR'),
       (2, 'AP'),
       (3, 'GL'),
       (4, 'Entity'),
       (5, 'Manufacturing'),
       (6, 'Fixed Assets'),
       (7, 'Timecards');

--function person__get_my_entity_id() defined 2 times in Pg-database.sql, also defined in Person.sql
--this first,dummy? definition needed because function is called in subsequent default statements in this file?
CREATE OR REPLACE FUNCTION person__get_my_entity_id() RETURNS INT AS
$$ SELECT -1;$$ LANGUAGE SQL;

CREATE SEQUENCE id;
-- As of 1.3 there is no central db anymore. --CT
--
CREATE TABLE language (
  code varchar(6) PRIMARY KEY,
  description text
);

COMMENT ON TABLE language IS
$$ Languages for manual translations and so forth.$$;

CREATE TABLE account_heading (
  id serial not null unique,
  accno text primary key,
  parent_id int references account_heading(id),
  description text,
  category char(1) check (category IN ('A','L','Q','I','E'))
);

COMMENT ON TABLE account_heading IS $$
This table holds the account headings in the system.  Each account must belong
to a heading, and a heading can belong to another heading.  In this way it is
possible to nest accounts for reporting purposes.$$;

COMMENT ON COLUMN account_heading.category IS $$
Same as the column account.category, except that if NULL the category
is automatically derived from the linked accounts.
$$;

CREATE TABLE account (
  id serial not null unique,
  accno text primary key,
  description text,
  is_temp bool not null default false,
  category CHAR(1) NOT NULL check (category IN ('A','L','Q','I','E')),
  gifi_accno text,
  heading int not null references account_heading(id),
  contra bool not null default false,
  tax bool not null default false,
  obsolete bool not null default false
);

COMMENT ON COLUMN account.category IS
$$ A=asset,L=liability,Q=Equity,I=Income,E=expense $$;

COMMENT ON COLUMN account.is_temp IS
$$ Only affects equity accounts.  If set, close at end of year. $$;

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
example).$$;

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
('IC_returns',     FALSE, FALSE),
('Asset_Dep',      FALSE, FALSE),
('Fixed_Asset',    FALSE, FALSE),
('asset_expense',  FALSE, FALSE),
('asset_gain',     FALSE, FALSE),
('asset_loss',     FALSE, FALSE);


CREATE TABLE account_link (
   account_id int references account(id) on delete cascade,
   description text references account_link_description(description),
   primary key (account_id, description)
);

-- pricegroup added here due to references
CREATE TABLE pricegroup (
  id serial PRIMARY KEY,
  pricegroup text
);


COMMENT ON TABLE pricegroup IS
$$ Pricegroups are groups of customers who are assigned prices and discounts
together.$$;
--TABLE language moved here because of later references
-- Keep this in sync with the Locale::CLDR::Locales::* required in cpanfile
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
       ('en_CA', 'English (Canada)'),
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
       ('ms_MY','Malay'),
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
   is_accrual bool not null default false,
   primary key(country_id, form_name)
);

COMMENT ON TABLE country_tax_form IS
$$ This table was designed for holding information relating to reportable
sales or purchases, such as IRS 1099 forms and international equivalents.$$;

-- BEGIN new entity management
--table entity_class contained field country_id, the idea was that we could have country-specific entity classes, nobody uses this , it can be removed from 1.4.
CREATE TABLE entity_class (
  id serial primary key,
  class text check (class ~ '[[:alnum:]_]') NOT NULL,
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

INSERT INTO entity_class (id,class)
VALUES (1,'Vendor'),
       (2,'Customer'),
       (3,'Employee'),
       (4,'Contact'),
       (5,'Lead'),
       (6,'Referral'),
       (7,'Hot Lead'),
       (8,'Cold Lead');

SELECT setval('entity_class_id_seq',8);

-- USERS stuff --
CREATE TABLE users (
    id serial UNIQUE,
    username varchar(30) primary key,
    notify_password interval not null default '7 days'::interval,
    entity_id int not null references entity(id) on delete cascade
);

COMMENT ON TABLE users IS
$$ This table maps lsmb entities to postgresql roles, which are used to
authenticate lsmb users. The username field maps to the postgresql role name
and is therefore subject to its limitations.

A role name is considered an Identifier and as such must begin with
a letter or an underscore and is limited by default to 63 bytes (could be
fewer characters if unicode) as documented here:
https://www.postgresql.org/docs/current/static/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS

Lsmb restricts the length of username, but this is an arbitrary restriction
beyond the postgresql role name limitations already described.
$$;

-- Session tracking table

CREATE TABLE session(
session_id serial PRIMARY KEY,
token VARCHAR(32) CHECK(length(token) = 32),
last_used TIMESTAMP default now(),
ttl int default 3600 not null,
users_id INTEGER NOT NULL references users(id) on delete cascade,
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
  approved bool,
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

create table location_class_to_entity_class (
  id serial unique,
  location_class int not null references location_class(id),
  entity_class int not null references entity_class(id)
);

COMMENT ON TABLE location_class_to_entity_class IS
$$This determines which location classes go with which entity classes$$;

CREATE UNIQUE INDEX lower_class_unique ON location_class(lower(class));

INSERT INTO location_class(id,class,authoritative) VALUES ('1','Billing',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('2','Sales',FALSE);
INSERT INTO location_class(id,class,authoritative) VALUES ('3','Shipping',FALSE);
INSERT INTO location_class(id,class,authoritative) VALUES ('4','Physical',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('5','Mailing',FALSE);

SELECT SETVAL('location_class_id_seq',5);

INSERT INTO location_class_to_entity_class
       (location_class, entity_class)
SELECT lc.id, ec.id
  FROM entity_class ec
 cross
  join location_class lc
 WHERE ec.id <> 3 and lc.id < 4;

INSERT INTO location_class_to_entity_class (location_class, entity_class)
SELECT id, 3 from location_class lc where lc.id > 3;

CREATE TABLE location (
  id serial PRIMARY KEY,
  line_one text check (line_one ~ '[[:alnum:]_]') NOT NULL,
  line_two text,
  line_three text,
  city text check (city ~ '[[:alnum:]_]') NOT NULL,
  state text check(state ~ '[[:alnum:]_]'),
  country_id integer not null REFERENCES country(id),
  mail_code text check (mail_code ~ '[[:alnum:]_-]'),
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
  sales_tax_id text,
  license_number text,
  sic_code varchar,
  created date default current_date not null,
  PRIMARY KEY (entity_id,legal_name));

COMMENT ON COLUMN company.tax_id IS $$ In the US this would be a EIN. $$;

CREATE TABLE entity_to_location (
  location_id integer references location(id) not null,
  location_class integer not null references location_class(id),
  entity_id integer not null references entity(id) ON DELETE CASCADE,
  PRIMARY KEY(location_id, entity_id, location_class));

COMMENT ON TABLE entity_to_location IS
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
    birthdate date,
    personal_id text,
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
    is_manager bool default false,
    PRIMARY KEY (entity_id)
);

COMMENT ON TABLE entity_employee IS
$$ This contains employee-specific extensions to person/entity. $$;

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
INSERT INTO contact_class (id,class) values (18,'EDI Interchange ID');
INSERT INTO contact_class (id,class) values (19,'EDI ID');

SELECT SETVAL('contact_class_id_seq',19);

CREATE TABLE entity_to_contact (
  entity_id integer not null references entity(id) ON DELETE CASCADE,
  contact_class_id integer references contact_class(id) not null,
  contact text check(contact ~ '[[:alnum:]_]') not null,
  description text,
  PRIMARY KEY (entity_id,contact_class_id,contact));

COMMENT ON TABLE entity_to_contact IS
$$ This table stores contact information for entities$$;

CREATE TABLE entity_bank_account (
    id serial not null,
    entity_id int not null references entity(id) ON DELETE CASCADE,
    bic varchar,
    iban varchar,
    remark varchar,
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

COMMENT ON COLUMN entity_bank_account.remark IS
$$ This field contains the notes for an account, like: This is USD account, this one is HUF account, this one is the default account, this account for paying specific taxes. If a $
$$;



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

COMMENT ON TABLE entity IS $$ The primary entity table to map to all contacts $$;
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
contacts, use entity_to_contact instead.$$;

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
addresses, use entity_to_location instead $$;

CREATE TABLE employee_class (
    label text not null primary key,
    id serial not null unique
);

CREATE TABLE employee_to_ec (
    employee_id int references entity_employee(entity_id),
    ec_id int references employee_class(id),
    primary key(employee_id)
);


-- Begin payroll section
CREATE TABLE payroll_income_class (
   id int not null,
   country_id int not null references country(id),
   label text not null,
   unique (id, country_id),
   primary key (country_id, label)
);

CREATE TABLE payroll_income_category (
   id serial not null unique,
   label text
);

INSERT INTO payroll_income_category (label)
values ('Salary'),
       ('Hourly'),
       ('Chord'),
       ('Non-cash');

CREATE TABLE payroll_income_type (
   id serial not null unique,
   account_id int not null references account(id),
   pic_id int not null,
   country_id int not null,
   label text not null,
   unit text not null,
   default_amount numeric,
   foreign key(pic_id, country_id)
              references payroll_income_class(id, country_id)
);

CREATE TABLE payroll_wage (
   entry_id serial not null unique,
   entity_id int references entity(id),
   type_id int references payroll_income_type(id),
   rate numeric not null,
   PRIMARY KEY(entity_id, type_id)
);

CREATE TABLE payroll_employee_class (
   id serial not null unique,
   label text primary key
);

CREATE TABLE payroll_employee_class_to_income_type (
   ec_id int references payroll_employee_class (id),
   it_id int references payroll_income_type(id),
   primary key(ec_id, it_id)
);

CREATE TABLE payroll_deduction_class (
   id int not null,
   country_id int not null references country(id),
   label text not null,
   stored_proc_name name not null,
   unique (id, country_id),
   primary key (country_id, label)
);

CREATE TABLE payroll_deduction_type (
   id serial not null unique,
   account_id int not null references account(id),
   pdc_id int not null,
   country_id int not null,
   label text not null,
   unit text not null,
   default_amount numeric,
   calc_percent bool not null,
   foreign key(pdc_id, country_id)
              references payroll_deduction_class(id, country_id)
);

CREATE TABLE payroll_deduction (
   entry_id serial not null unique,
   entity_id int references entity(id),
   type_id int references payroll_deduction_type(id),
   rate numeric not null,
   PRIMARY KEY(entity_id, type_id)
);

CREATE TABLE payroll_report (
   id serial not null primary key,
   ec_id int not null references payroll_employee_class(id),
   payment_date date not null,
   created_by int references entity_employee(entity_id),
   approved_by int references  entity_employee(entity_id)
);

CREATE TABLE payroll_report_line (
   id serial not null unique,
   report_id int not null references payroll_report(id),
   employee_id int not null references entity(id),
   it_id int not null references payroll_income_type(id),
   qty numeric not null,
   rate numeric not null,
   description text,
   primary key (it_id, employee_id, report_id)
);

CREATE TABLE payroll_pto_class (
   id serial not null unique,
   label text primary key
);

CREATE TABLE payroll_paid_timeoff (
   employee_id int not null references entity(id),
   pto_class_id int not null references payroll_pto_class(id),
   report_id int not null references payroll_report(id),
   amount numeric not null
);

--TODO:  Add payroll line items, approval process, registry for locale functions, etc
-- Begin rocking notes interface
CREATE TABLE note_class(id serial primary key, class text not null check (class ~ '[[:alnum:]_]'));
INSERT INTO note_class(id,class) VALUES (1,'Entity');
INSERT INTO note_class(id,class) VALUES (2,'Invoice');
INSERT INTO note_class(id,class) VALUES (3,'Entity Credit Account');
INSERT INTO note_class(id,class) VALUES (5,'Journal Entry');
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
  parts_id int,
  barcode text,
  make text,
  model text,
  primary key(parts_id, make, model)
);

COMMENT ON TABLE makemodel IS
$$ A single parts entry can have multiple make/model entries.  These
store manufacturer/model number info.$$;
--
CREATE TABLE journal_type (
   id serial not null unique,
   name text primary key
);

COMMENT ON TABLE journal_type IS
$$ This table describes the journal entry type of the transaction.  The
following values are hard coded by default:
1:  General journal
2:  Sales (AR)
3:  Purchases (AP)
4:  Receipts
5:  Payments

$$;

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
    max_ac_id int,
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
    ledger_id int,
    voucher_id int,
    overlook boolean not null default 'f',
    cleared boolean not null default 'f'
);


COMMENT ON TABLE cr_report_line IS
$$ This stores line item data on transaction lines and whether they are
cleared.$$;

COMMENT ON COLUMN cr_report_line.scn IS
$$ This is the check number.  Maps to gl.reference $$;

CREATE TABLE cr_coa_to_account (
    chart_id int not null references account(id) PRIMARY KEY,
    account text not null
);

COMMENT ON TABLE cr_coa_to_account IS
$$ Provides name mapping for the cash reconciliation screen.$$;

INSERT INTO journal_type (id, name)
VALUES (1, 'General'),
       (2, 'Sales'),
       (3, 'Purchases'),
       (4, 'Receipts'),
       (5, 'Payments');


CREATE TABLE journal_entry (
    id serial not null,
    reference text not null,
    description text,
    locked_by int references session(session_id) on delete set null,
    journal int references journal_type(id),
    post_date date not null default now(),
    effective_start date not null,
    effective_end date not null,
    currency char(3) not null,
    approved bool default false,
    is_template bool default false,
    entered_by int not null references entity(id),
    approved_by int references entity(id),
    primary key (id),
    check (is_template is false or approved is false)
);


COMMENT ON TABLE journal_entry IS $$
This tale records the header information for each transaction.  It replaces
parts of the following tables:  acc_trans, ar, ap, gl, transactions.

Note now all ar/ap transactions are also journal entries.$$;

COMMENT ON COLUMN journal_entry.reference IS
$$ Invoice number or journal entry number.$$;

COMMENT ON COLUMN journal_entry.effective_start IS
$$ For transactions whose effects are spread out over a period of time, this is
the effective start date for the transaction.  To be used by add-ons for
automating adjustments.$$;

COMMENT ON COLUMN journal_entry.effective_end IS
$$ For transactions whose effects are spread out over a period of time, this is
the effective end date for the transaction.  To be used by add-ons for
automating adjustments.$$;

COMMENT ON COLUMN journal_entry.is_template IS
$$ Set true for template transactions.  Templates can never be approved but can
be copied into new transactions and are useful for recurrances. $$;

CREATE UNIQUE INDEX je_unique_source ON journal_entry (journal, reference)
WHERE journal IN (1, 2); -- cannot reuse GL source and AR invoice numbers

CREATE TABLE journal_line (
    id serial,
    account_id int references account(id)  not null,
    journal_id int references journal_entry(id) not null,
    amount numeric not null check (amount <> 'NaN'),
    cleared bool not null default false,
    reconciliation_report int references cr_report(id),
    line_type text references account_link_description,
    primary key (id)
);

COMMENT ON TABLE journal_line IS
$$ Replaces acc_trans as the main account transaction line table.$$;

COMMENT ON COLUMN journal_line.cleared IS
$$ Still needed both for legacy data and in case reconciliation data must
eventually be purged.$$;

CREATE TABLE eca_invoice (
     order_id int, -- TODO reference inventory_order when added
    journal_id int references journal_entry(id),
    on_hold bool default false,
    reverse bool default false,
    credit_id int references entity_credit_account(id) not null,
    due date not null,
    language_code char(6) references language(code),
    force_closed bool not null default false,
    order_number text,
    PRIMARY KEY  (journal_id)
);

COMMENT ON TABLE eca_invoice IS
$$ Replaces the rest of the ar and ap tables.
Also tracks payments and receipts. $$;

COMMENT ON COLUMN eca_invoice.order_id IS
$$ Link to order it was created from$$;

COMMENT ON COLUMN eca_invoice.on_hold IS
$$ On hold invoices can not be paid, and overpayments that are on hold cannot
be used to pay invoices.$$;

COMMENT ON COLUMN eca_invoice.reverse IS
$$ When this is set to true, the invoice is shown with opposite normal numbers,
i.e. negatives appear as positives, and positives appear as negatives.$$;

COMMENT ON COLUMN eca_invoice.force_closed IS
$$ When this is set to true, the invoice does not show up on outstanding reports
and cannot be paid.  Overpayments where this is set to true do not appear on
outstanding reports and cannot be paid.$$;

COMMENT ON COLUMN eca_invoice.order_number IS
$$ This is the order number of the other party.  So for a sales invoice, this
would be a purchase order, and for a vendor invoice, this would be a sales
order.$$;

--
CREATE TABLE gl (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY REFERENCES transactions(id),
  reference text,
  description text,
  transdate date DEFAULT current_date,
  person_id integer references person(id),
  notes text,
  approved bool default true
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

COPY defaults FROM stdin WITH DELIMITER '|';
timeout|90 minutes
sinumber|1
sonumber|1
businessnumber|1
version|1.11.25
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
rcptnumber|1
paynumber|1
separate_duties|1
entity_control|A-00001
batch_cc|B-11111
check_prefix|CK
decimal_places|2
disable_back|0
dojo_theme|claro
vclimit|9999
check_max_invoices|45
\.

-- Sequence handling


CREATE TABLE lsmb_sequence (
   label text primary key,
   setting_key text not null references defaults(setting_key),
   prefix text,
   suffix text,
   sequence text not null default '1',
   accept_input bool default true
);

-- */
-- batch stuff

CREATE TABLE batch_class (
  id serial unique,
  class varchar primary key
);

COMMENT ON TABLE batch_class IS
$$ These values are hard-coded.  Please coordinate before adding standard
values. Values from 900 to 999 are reserved for local use.$$;

insert into batch_class (id,class) values (1,'ap');
insert into batch_class (id,class) values (2,'ar');
insert into batch_class (id,class) values (3,'payment');
insert into batch_class (id,class) values (4,'payment_reversal');
insert into batch_class (id,class) values (5,'gl');
insert into batch_class (id,class) values (6,'receipt');
insert into batch_class (id,class) values (7,'receipt_reversal');
insert into batch_class (id,class) values (8,'sales_invoice');
insert into batch_class (id,class) values (9,'vendor_invoice');

SELECT SETVAL('batch_class_id_seq',9);

CREATE TABLE batch (
  id serial primary key,
  batch_class_id integer references batch_class(id) not null,
  control_code text NOT NULL,
  description text,
  default_date date not null,
  approved_on date default null,
  approved_by int references entity_employee(entity_id),
  created_by int references entity_employee(entity_id),
  locked_by int references session(session_id) ON DELETE SET NULL,
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
  amount NUMERIC NOT NULL,
  transdate date DEFAULT current_date,
  source text,
  cleared bool DEFAULT 'f',
  fx_transaction bool DEFAULT 'f',
  memo text,
  invoice_id int,
  approved bool default true,
  cleared_on date,
  reconciled_on date,
  voucher_id int references voucher(id),
  entry_id SERIAL PRIMARY KEY
);

ALTER TABLE cr_report ADD FOREIGN KEY (max_ac_id) REFERENCES acc_trans(entry_id);

COMMENT ON TABLE acc_trans IS
$$This table stores line items for financial transactions.  Please note that
payments in 1.3 are not full-fledged transactions.$$;

COMMENT ON COLUMN acc_trans.source IS
$$Document Source identifier for individual line items, usually used
for payments.$$;

COMMENT ON COLUMN acc_trans.fx_transaction IS
$$When 'f', indicates that the amount column states the amount in the currency
as specified in the associated ar, ap, payment or gl record.

When 't', indicates that the amount column states the difference between
the foreighn currency amount and the base amount so that their sum equals the
base amount.$$;

CREATE INDEX acc_trans_voucher_id_idx ON acc_trans(voucher_id);

-- preventing closed transactions


--
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
  inventory_accno_id int references account(id),
  income_accno_id int references account(id),
  expense_accno_id int references account(id),
  returns_accno_id int references account(id),
  bin text,
  obsolete bool DEFAULT 'f',
  bom bool DEFAULT 'f',
  image text,
  drawing text,
  microfiche text,
  partsgroup_id int,
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

CREATE SEQUENCE lot_tracking_number;
CREATE TABLE mfg_lot (
    id serial not null unique,
    lot_number text not null unique default nextval('lot_tracking_number')::text,
    parts_id int not null references parts(id),
    qty numeric not null,
    stock_date date not null default now()::date
);

COMMENT ON TABLE mfg_lot IS
$$ This tracks assembly restocks.  This is designed to work with old code and
may change as we refactor the parts.$$;

CREATE TABLE mfg_lot_item (
    id serial not null unique,
    mfg_lot_id int not null references mfg_lot(id),
    parts_id int not null references parts(id),
    qty numeric not null
);

COMMENT ON TABLE mfg_lot_item IS
$$ This tracks items used in assembly restocking.$$;

CREATE TABLE invoice (
  id serial PRIMARY KEY,
  trans_id int REFERENCES transactions(id),
  parts_id int REFERENCES parts(id),
  description text,
  qty NUMERIC,
  allocated NUMERIC,
  sellprice NUMERIC,
  precision int,
  fxsellprice NUMERIC,
  discount numeric,
  assemblyitem bool DEFAULT 'f',
  unit varchar,
  deliverydate date,
  serialnumber text,
  vendor_sku text,
  notes text
  CONSTRAINT invoice_allocation_constraint
      CHECK (allocated*-1 BETWEEN least(0,qty) AND greatest(qty,0))
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

CREATE TABLE journal_note (
   internal_only bool not null default false,
   primary key (id),
   check(note_class = 5),
   foreign key(ref_key) references journal_entry(id)
) INHERITS (note);

COMMENT ON TABLE journal_note IS
$$ This stores notes attached to journal entries, including payments and
invoices.$$;

COMMENT ON COLUMN journal_note.internal_only IS
$$ When set to true, does not show up in notes list for invoice templates$$;


--
CREATE TABLE assembly (
  id int REFERENCES parts(id) on delete cascade,
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
  shipvia text,
  language_code varchar(6),
  ponumber text,
  on_hold bool default false,
  reverse bool default false,
  approved bool default true,
  entity_credit_account int references entity_credit_account(id) not null,
  force_closed bool,
  description text,
  is_return bool default false,
  crdate date,
  setting_sequence text,
  check (invnumber is not null or not approved)
);

CREATE UNIQUE INDEX ar_invnumber_key ON ar(invnumber) where invnumber is not null;

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
--TODO 1.6 ap invnumber text check (invnumber ~ '[[:alnum:]_]') NOT NULL
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
  crdate date,
  is_return bool default false,
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

-- INVENTORY ADJUSTMENTS

CREATE TABLE inventory_report (
   id serial primary key, -- these are not tied to external sources usually
   transdate date NOT NULL,
   source text, -- may be null
   ar_trans_id int,  -- would be null if no items were adjusted down
   ap_trans_id int  -- would be null if no items were adjusted up
);

CREATE TABLE inventory_report_line (
   adjust_id int REFERENCES inventory_report(id),
   parts_id int REFERENCES parts(id),
   counted numeric,
   expected numeric,
   variance numeric,
   PRIMARY KEY (adjust_id, parts_id)
);

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
  --FOREIGN KEY (chart_id) REFERENCES  account(id),--already defined before
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
CREATE TABLE eca_tax (
  eca_id int references entity_credit_account(id) on delete cascade,
  chart_id int REFERENCES account(id),
  PRIMARY KEY (eca_id, chart_id)
);

COMMENT ON TABLE eca_tax IS $$ Mapping customers and vendors to taxes.$$;
--
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

CREATE TABLE business_unit_class (
    id serial not null unique,
    label text primary key,
    active bool not null default false,
    ordering int
);

COMMENT ON TABLE business_unit_class IS
$$ Consolidates projects and departments, and allows this to be extended for
funds accounting and other purposes.$$;

INSERT INTO business_unit_class (id, label, active, ordering)
VALUES (1, 'Department', '0', '10'),
       (2, 'Project', '0', '20'),
       (3, 'Job', '0', '30'),
       (4, 'Fund', '0', '40'),
       (5, 'Customer', '0', '50'),
       (6, 'Vendor', '0', '60'),
       (7, 'Lot',  '0', 50);

SELECT pg_catalog.setval('business_unit_class_id_seq', 7, true);


CREATE TABLE bu_class_to_module (
   bu_class_id int references business_unit_class(id),
   module_id int references lsmb_module(id),
   primary key (bu_class_id, module_id)
);

INSERT INTO  bu_class_to_module (bu_class_id, module_id)
SELECT business_unit_class.id, lsmb_module.id
  FROM business_unit_class
 CROSS
  JOIN lsmb_module; -- by default activate all existing business units on all modules


CREATE TABLE business_unit (
  id serial PRIMARY KEY,
  class_id int not null references business_unit_class(id),
  control_code text,
  description text,
  start_date date,
  end_date date,
  parent_id int references business_unit(id),
  credit_id int references entity_credit_account(id),
  UNIQUE(id, class_id), -- needed for foreign keys
  UNIQUE(class_id, control_code)
);

CREATE TABLE job (
  bu_id int primary key references business_unit(id),
  parts_id int,
  production numeric default 0,
  completed numeric default 0
);

CREATE TABLE business_unit_jl (
    entry_id int references journal_line(id),
    bu_class int references business_unit_class(id),
    bu_id int references business_unit(id) NOT NULL,
    PRIMARY KEY(entry_id, bu_class)
);

CREATE TABLE business_unit_ac (
  entry_id int references acc_trans(entry_id) on delete cascade,
  class_id int references business_unit_class(id),
  bu_id int,
  primary key(bu_id, class_id, entry_id),
  foreign key(class_id, bu_id) references business_unit(class_id, id)
);
-- The index is required for fast lookup when deleting acc_trans lines
-- which happens when not-approved transactions are deleted
CREATE INDEX business_unit_ac_entry_id_idx ON business_unit_ac(entry_id);

CREATE TABLE business_unit_inv (
  entry_id int references invoice(id) on delete cascade,
  class_id int references business_unit_class(id),
  bu_id int,
  primary key(bu_id, class_id, entry_id),
  foreign key(class_id, bu_id) references business_unit(class_id, id)
);
-- The index is required for fast lookup when deleting invoices
-- which happens when not-approved transactions are deleted
CREATE INDEX business_unit_inv_entry_id_idx ON business_unit_inv(entry_id);

CREATE TABLE business_unit_oitem (
  entry_id int references orderitems(id) on delete cascade,
  class_id int references business_unit_class(id),
  bu_id int,
  primary key(bu_id, class_id, entry_id),
  foreign key(class_id, bu_id) references business_unit(class_id, id)
);
-- The index is required for fast lookup when deleting order item lines
-- which happens when not-approved transactions are deleted
CREATE INDEX business_unit_oitem_entry_id_idx ON business_unit_oitem(entry_id);

COMMENT ON TABLE business_unit IS
$$ Tracks Projects, Departments, Funds, Etc.$$;

CREATE TABLE budget_info (
   id serial not null unique,
   start_date date not null,
   end_date date not null,
   reference text primary key,
   description text not null,
   entered_by int not null references entity(id)
                  default person__get_my_entity_id(),
   approved_by int references entity(id),
   obsolete_by int references entity(id),
   entered_at timestamp not null default now(),
   approved_at timestamp,
   obsolete_at timestamp,
   check (start_date < end_date)
);

CREATE TABLE budget_to_business_unit (
    budget_id int not null unique references budget_info(id),
    bu_id int not null references business_unit(id),
    bu_class int references business_unit_class(id),
    primary key (budget_id, bu_class)
);


CREATE TABLE budget_line (
    budget_id int not null references budget_info(id),
    account_id int not null references account(id),
    description text,
    amount numeric not null,
    primary key (budget_id, account_id)
);

INSERT INTO note_class (id, class) values ('6', 'Budget');

CREATE TABLE budget_note (
    primary key(id),
    check (note_class = 6),
    foreign key(ref_key) references budget_info(id)
) INHERITS (note);
ALTER TABLE budget_note ALTER COLUMN note_class SET DEFAULT 6;

COMMENT ON COLUMN job.parts_id IS
$$ Job costing/manufacturing here not implemented.$$;
--
CREATE TABLE partsgroup (
  id serial primary key,
  partsgroup text,
  parent int references partsgroup(id)
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
CREATE TABLE warehouse_inventory (
  entity_id integer references entity_employee(entity_id),
  warehouse_id int,
  parts_id int,
  trans_id int,
  orderitems_id int,
  qty numeric,
  shippingdate date,
  entry_id SERIAL PRIMARY KEY
);

COMMENT ON TABLE warehouse_inventory IS
$$ This table contains inventory mappings to warehouses, not general inventory
management data.$$;
--
CREATE TABLE yearend (
  trans_id int PRIMARY KEY REFERENCES gl(id),
  reversed bool default false,
  transdate date
);

COMMENT ON TABLE yearend IS
$$ An extension to the journal_entry table to track transactionsactions which close out
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

CREATE TABLE business_unit_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE business_unit_translation
ADD foreign key (trans_id) REFERENCES business_unit(id);

COMMENT ON TABLE business_unit_translation IS
$$ Translation information for projects, departments, etc.$$;

CREATE TABLE partsgroup_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE partsgroup_translation
ADD foreign key (trans_id) REFERENCES partsgroup(id);

COMMENT ON TABLE partsgroup_translation IS
$$ Translation information for partsgroups.$$;

CREATE TABLE account_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE account_translation
ADD foreign key (trans_id) REFERENCES account(id);

COMMENT ON TABLE account_translation IS
$$Translations for account descriptions.$$;

CREATE TABLE account_heading_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE account_heading_translation
ADD foreign key (trans_id) REFERENCES account_heading(id);

COMMENT ON TABLE account_heading_translation IS
$$Translations for account heading descriptions.$$;




--
CREATE TABLE user_preference (
    id int PRIMARY KEY REFERENCES users(id) on delete cascade,
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
  id int not null references transactions(id) unique,
  reference text,
  startdate date,
  nextdate date,
  enddate date,
  recurring_interval interval,
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
  id int references recurring(id),
  formname text,
  format text,
  message text,
  PRIMARY KEY (id, formname)
);

COMMENT ON TABLE recurringemail IS
$$Email  to be sent out when recurring transaction is posted.$$;
--
CREATE TABLE recurringprint (
  id int references recurring(id),
  formname text,
  format text,
  printer text,
  PRIMARY KEY (id, formname)
);

COMMENT ON TABLE recurringprint IS
$$ Template, printer etc. to print to when recurring transaction posts.$$;
--
CREATE TABLE jctype (
  id int not null unique, -- hand assigned
  label text primary key,
  description text not null,
  is_service bool default true,
  is_timecard bool default true
);

INSERT INTO jctype (id, label, description, is_service, is_timecard)
VALUES (1, 'time', 'Timecards for project services', true, true);

INSERT INTO jctype (id, label, description, is_service, is_timecard)
VALUES (2, 'materials', 'Materials for projects', false, false);

INSERT INTO jctype (id, label, description, is_service, is_timecard)
VALUES (3, 'overhead', 'Time/Overhead for payroll, manufacturing, etc', false, true);

CREATE TABLE jcitems (
  id serial PRIMARY KEY,
  business_unit_id int references business_unit(id),
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
  non_billable numeric not null default 0,
  jctype int not null,
  curr char(3) not null
);

COMMENT ON TABLE jcitems IS $$ Time and materials cards.
Materials cards not implemented.$$;

CREATE OR REPLACE FUNCTION track_global_sequence() RETURNS TRIGGER AS
$$
BEGIN
  -- dummy; actual function defined in modules/triggers.sql
  -- exists here in order to be able to create the triggers below
  RETURN new;
END;
$$ LANGUAGE PLPGSQL;


CREATE TRIGGER ap_track_global_sequence BEFORE INSERT OR UPDATE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER ar_track_global_sequence BEFORE INSERT OR UPDATE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER gl_track_global_sequence BEFORE INSERT OR UPDATE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();


INSERT INTO taxmodule (
  taxmodule_id, taxmodulename
  ) VALUES (1, 'Simple'),
  (2, 'Rounded');

CREATE TABLE ac_tax_form (
        entry_id int references acc_trans(entry_id) primary key,
        reportable bool
);

COMMENT ON TABLE ac_tax_form IS
$$ Mapping journal_line to country_tax_form for reporting purposes.$$;

CREATE TABLE invoice_tax_form (
        invoice_id int references invoice(id) primary key,
        reportable bool
);

COMMENT ON TABLE invoice_tax_form IS
$$ Maping invoice to country_tax_form.$$;


CREATE FUNCTION prevent_closed_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- dummy; actual function defined in modules/triggers.sql
  -- exists here in order to be able to create the triggers below
  RETURN new;
END;
$$;

CREATE TRIGGER acc_trans_prevent_closed BEFORE INSERT ON acc_trans
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
CREATE TRIGGER ap_prevent_closed BEFORE INSERT ON ap
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
CREATE TRIGGER ar_prevent_closed BEFORE INSERT ON ar
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
CREATE TRIGGER gl_prevent_closed BEFORE INSERT ON gl
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();


CREATE OR REPLACE FUNCTION gl_audit_trail_append()
RETURNS TRIGGER AS
$$
BEGIN
  -- dummy; actual function defined in modules/triggers.sql
  -- exists here in order to be able to create the triggers below
  IF tg_op = 'INSERT' OR tg_op = 'UPDATE' THEN
    RETURN new;
  ELSE
    RETURN NULL;
  END IF;
END;
$$ language plpgsql security definer;

CREATE TRIGGER gl_audit_trail AFTER INSERT OR UPDATE OR DELETE ON gl
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();

CREATE TRIGGER ar_audit_trail AFTER INSERT OR UPDATE OR DELETE ON ar
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();

CREATE TRIGGER ap_audit_trail AFTER INSERT OR UPDATE OR DELETE ON ap
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();

CREATE TRIGGER je_audit_trail AFTER insert or update or delete ON journal_entry
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();

create index assembly_id_key on assembly (id);
--
create index exchangerate_ct_key on exchangerate (curr, transdate);
--
create unique index gifi_accno_key on gifi (accno);
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
--
create index partsgroup_id_key on partsgroup (id);
create unique index partsgroup_key on partsgroup (partsgroup);
--
create index status_trans_id_key on status (trans_id);
--
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


CREATE OR REPLACE FUNCTION trigger_parts_short() RETURNS TRIGGER
AS
'
BEGIN
  -- dummy; actual function defined in modules/triggers.sql
  -- exists here in order to be able to create the triggers below
  RETURN new;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE TRIGGER parts_short AFTER UPDATE ON parts
FOR EACH ROW EXECUTE PROCEDURE trigger_parts_short();
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

SELECT pg_catalog.setval('menu_node_id_seq', 253, true);

--
-- Data for Name: menu_node; Type: TABLE DATA; Schema: public; Owner: ledgersmb
--

COPY menu_node (id, label, parent, "position") FROM stdin WITH DELIMITER '|';
91|Search Groups|77|6
92|Search Pricegroups|77|8
6|Import Inventory|77|13
106|Search|98|1
101|Generate|98|4
8|Import|98|3
114|Inventory Activity|85|2
11|Import AR Batch|249|3
13|Import AP Batch|250|3
16|Enter Inventory|77|14
206|Batches|205|1
14|Search|19|2
12|Add Contact|19|3
15|Customer History|4|6
34|Vendor History|24|6
110|Chart of Accounts|73|5
137|Add Accounts|73|6
0|Top-level|\N|0
20|Invoice Vouchers|249|2
2|Add Transaction|1|1
7|AR Aging|4|3
39|Invoice Vouchers|250|2
22|Add Transaction|21|1
27|AP Aging|24|3
25|Search|21|7
36|Receipt|35|1
38|Payment|35|3
223|Use Overpayment|35|4
37|Use AR Overpayment|35|2
42|Receipts|41|1
43|Payments|41|2
44|Reconciliation|41|3
47|Employees|46|1
48|Add Employee|47|1
49|Search|47|2
51|Sales Order|50|1
52|Purchase Order|50|2
53|Reports|50|3
54|Sales Orders|53|1
55|Purchase Orders|53|2
57|Sales Orders|56|1
58|Purchase Orders|56|2
56|Generate|50|4
61|Sales Orders|60|1
62|Purchase Orders|60|2
64|Ship|63|1
65|Receive|63|2
66|Transfer|63|3
68|Quotation|67|1
69|RFQ|67|2
70|Reports|67|3
71|Quotations|70|1
72|RFQs|70|2
74|Journal Entry|73|1
96|Description|95|1
97|Partsgroup|95|2
100|Add Timecard|98|2
102|Sales Orders|101|1
107|Translations|98|5
108|Description|107|1
113|Balance Sheet|109|4
130|Taxes|128|2
131|Defaults|128|3
142|Add Warehouse|141|1
143|List Warehouse|141|2
148|Add Business|147|1
149|List Businesses|147|2
151|Add Language|150|1
152|List Languages|150|2
154|Add SIC|153|1
155|List SIC|153|2
173|Invoice|172|1
205|Transaction Approval|0|6
1|AR|0|2
21|AP|0|4
35|Cash|0|5
19|Contacts|0|1
246|Import Chart|73|7
136|GIFI|128|7
24|Reports|21|9
250|Vouchers|21|8
200|Vouchers|35|5
40|Transfer|35|6
41|Reports|35|8
45|Reconciliation|35|7
132|Year End|73|3
111|Trial Balance|109|1
112|Income Statement|109|2
60|Combine|50|5
78|Add Part|77|2
79|Add Service|77|3
80|Add Assembly|77|4
86|Search|77|1
201|Payments|200|1
202|Reverse Payment|200|2
210|Drafts|205|2
211|Reconciliation|205|3
218|Add Tax Form|217|1
172|LaTeX Templates|128|14
156|HTML Templates|128|13
153|SIC|128|12
150|Language|128|11
147|Type of Business|128|10
144|Reporting Units|128|9
141|Warehouses|128|8
222|Sessions|128|5
225|List Tax Forms|217|2
203|Receipts|200|4
226|Reports|217|3
228|Asset Classes|227|1
229|Assets|227|2
230|Add Class|228|1
231|List Classes|228|2
232|Add Assets|229|1
233|Search Assets|229|2
235|Import|229|3
234|Depreciate|229|4
237|Net Book Value|236|1
238|Disposal|229|5
236|Reports|229|11
239|Depreciation|236|2
240|Disposal|236|3
243|Import Batch|21|3
23|Vendor Invoice|21|4
196|Debit Note|21|5
197|Debit Invoice|21|6
244|Import Batch|1|3
3|Sales Invoice|1|4
194|Credit Note|1|5
195|Credit Invoice|1|6
245|Import|73|2
76|Search and GL|73|4
139|Add GIFI|136|4
140|List GIFI|136|5
247|Import GIFI|136|6
248|Import|153|3
198|AR Voucher|249|1
199|AP Voucher|250|1
252|Add Budget|251|1
253|Search|251|2
251|Budgets|0|7
46|HR|0|8
50|Order Entry|0|9
63|Shipping|0|10
67|Quotations|0|11
73|General Journal|0|12
77|Goods and Services|0|13
109|Reports|0|15
115|Recurring Transactions|0|16
217|Tax Forms|0|17
227|Fixed Assets|0|19
193|Logout|0|25
192|New Window|0|24
191|Preferences|0|23
128|System|0|21
9|Outstanding|4|1
10|Outstanding|24|1
81|Add Overhead|77|5
82|Add Group|77|7
83|Add Pricegroup|77|9
84|Stock Assembly|77|10
95|Translations|77|12
85|Reports|77|11
98|Timecards|0|14
17|Sequences|128|4
204|Reverse Receipts|200|5
18|Reverse Overpay|200|3
26|Reverse AR Overpay|200|6
59|Inventory|205|4
75|Inventory and COGS|109|5
159|Invoice|156|4
160|AR Transaction|156|5
161|AP Transaction|156|6
162|Packing List|156|7
163|Pick List|156|8
164|Sales Order|156|9
165|Work Order|156|10
166|Purchase Order|156|11
167|Bin List|156|12
168|Statement|156|13
169|Quotation|156|14
170|RFQ|156|15
171|Timecard|156|16
241|Letterhead|156|17
174|AR Transaction|172|3
175|AP Transaction|172|4
176|Packing List|172|5
177|Pick List|172|6
178|Sales Order|172|7
179|Work Order|172|8
180|Purchase Order|172|9
181|Bin List|172|10
182|Statement|172|11
183|Check|172|12
184|Receipt|172|13
185|Quotation|172|14
186|RFQ|172|15
187|Timecard|172|16
242|Letterhead|172|17
90|Product Receipt|172|2
99|Product Receipt|156|2
129|Add Return|1|7
5|Search|1|8
4|Reports|1|10
249|Vouchers|1|9
\.


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

SELECT pg_catalog.setval('menu_attribute_id_seq', 681, true);


--
-- Data for Name: menu_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--


COPY menu_attribute (node_id, attribute, value, id) FROM stdin WITH DELIMITER '|';
205|menu|1|574
1|menu|1|1
2|module|ar.pl|2
2|action|add|3
3|action|add|4
3|module|is.pl|5
3|type|invoice|6
4|menu|1|7
12|action|add|29
21|menu|1|50
22|action|add|52
22|module|ap.pl|51
23|action|add|53
23|type|invoice|55
23|module|ir.pl|54
24|menu|1|56
35|menu|1|83
36|module|payment.pl|84
36|action|payment|85
36|type|receipt|86
36|account_class|2|551
37|module|payment.pl|87
37|account_class|2|89
37|action|use_overpayment|88
223|module|payment.pl|607
223|account_class|1|608
223|action|use_overpayment|609
38|module|payment.pl|90
38|action|payment|91
38|type|check|92
194|module|ar.pl|538
194|action|add|539
40|module|gl.pl|96
40|action|add|97
40|transfer|1|98
41|menu|1|99
44|report|1|110
46|menu|1|111
47|menu|1|112
48|module|contact.pl|113
48|action|add|114
50|menu|1|119
51|module|oe.pl|120
51|action|add|121
51|type|sales_order|122
52|module|oe.pl|123
52|action|add|124
52|type|purchase_order|125
53|menu|1|126
56|menu|1|133
60|menu|1|550
63|menu|1|146
66|module|oe.pl|153
66|action|search_transfer|154
67|menu|1|155
68|module|oe.pl|156
68|action|add|157
69|module|oe.pl|159
69|action|add|160
68|type|sales_quotation|158
69|type|request_quotation|161
70|menu|1|162
7|module|reports.pl|15
7|action|start_report|16
7|report_name|aging|17
27|module|reports.pl|63
27|report_name|aging|65
12|module|contact.pl|28
14|action|start_report|36
14|module|reports.pl|32
14|module_name|gl|27
15|action|start_report|33
15|report_name|purchase_history|37
34|action|start_report|81
34|report_name|purchase_history|82
34|module|reports.pl|80
5|action|start_report|9
25|action|start_report|58
73|menu|1|169
74|module|gl.pl|170
74|action|add|171
77|menu|1|182
78|module|ic.pl|183
78|action|add|184
78|item|part|185
79|module|ic.pl|186
206|module|reports.pl|575
206|action|start_report|576
38|account_class|1|39
49|module|reports.pl|118
79|action|add|187
79|item|service|188
80|module|ic.pl|189
80|action|add|190
81|module|ic.pl|192
81|action|add|193
81|item|labor|194
80|item|assembly|191
82|action|add|195
82|module|pe.pl|196
83|action|add|198
83|module|pe.pl|199
84|module|ic.pl|202
5|module|invoice.pl|8
25|module|invoice.pl|57
5|report_name|invoice_search|10
25|report_name|invoice_search|59
42|module|payment.pl|100
42|action|get_search_criteria|101
42|account_class|2|102
43|action|get_search_criteria|104
43|module|payment.pl|103
43|account_class|1|105
49|action|start_report|117
54|module|order.pl|127
55|module|order.pl|130
71|module|order.pl|163
72|module|order.pl|166
54|action|get_criteria|128
55|action|get_criteria|131
71|action|get_criteria|164
72|action|get_criteria|168
54|search_type|search|129
55|search_type|search|132
71|search_type|search|165
72|search_type|search|167
57|action|get_criteria|136
58|action|get_criteria|139
61|action|get_criteria|141
62|action|get_criteria|144
62|search_type|combine|145
61|search_type|combine|142
61|module|order.pl|140
62|module|order.pl|143
57|module|order.pl|134
58|module|order.pl|137
57|search_type|generate|135
58|search_type|generate|138
64|action|get_criteria|148
65|action|get_criteria|151
64|search_type|ship|149
64|module|order.pl|147
65|module|order.pl|150
84|action|stock_assembly|203
85|menu|1|204
95|menu|1|232
96|module|pe.pl|233
96|action|translation|234
96|translation|description|235
91|action|start_report|220
92|action|start_report|223
97|module|pe.pl|236
97|action|translation|237
97|translation|partsgroup|238
98|menu|1|239
100|module|timecard.pl|243
100|action|new|244
100|project|project|246
100|type|timecard|247
101|menu|1|248
102|module|pe.pl|249
102|action|project_sales_order|250
107|menu|1|268
108|module|pe.pl|269
108|action|translation|270
108|translation|project|271
109|menu|1|272
110|action|chart_of_accounts|274
113|action|start_report|281
113|module|reports.pl|282
113|report_name|balance_sheet|283
115|action|recurring_transactions|287
115|module|am.pl|288
76|module|reports.pl|180
76|action|start_report|181
110|module|journal.pl|273
128|menu|1|334
130|module|am.pl|338
130|taxes|audit_control|341
130|action|taxes|343
132|module|account.pl|346
132|action|yearend_info|347
139|module|am.pl|357
140|module|reports.pl|358
139|action|add_gifi|361
140|action|list_gifi|362
141|menu|1|363
142|module|am.pl|364
143|module|reports.pl|365
142|action|add_warehouse|366
131|module|configuration.pl|339
111|report_name|trial_balance|277
111|action|start_report|275
131|action|defaults_screen|342
143|action|list_warehouse|367
144|module|business_unit.pl|368
144|action|list_classes|370
147|menu|1|372
148|module|am.pl|373
149|module|reports.pl|374
112|action|start_report|278
112|module|reports.pl|279
112|report_name|income_statement|280
148|action|add_business|375
149|action|list_business_types|376
150|menu|1|377
151|module|am.pl|378
152|module|reports.pl|379
151|action|add_language|380
152|action|list_language|381
153|menu|1|382
154|module|am.pl|383
155|module|reports.pl|384
154|action|add_sic|385
155|action|list_sic|386
86|action|search_screen|610
156|menu|1|387
159|module|template.pl|390
160|module|template.pl|391
161|module|template.pl|392
162|module|template.pl|393
163|module|template.pl|394
164|module|template.pl|395
165|module|template.pl|396
166|module|template.pl|397
167|module|template.pl|398
168|module|template.pl|399
169|module|template.pl|400
170|module|template.pl|401
171|module|template.pl|402
241|module|template.pl|642
159|action|display|405
160|action|display|406
161|action|display|407
162|action|display|408
163|action|display|409
164|action|display|410
165|action|display|411
166|action|display|412
167|action|display|413
114|module|reports.pl|285
114|report_name|inventory_activity|286
114|action|start_report|284
168|action|display|414
169|action|display|415
170|action|display|416
171|action|display|417
241|action|display|643
159|template_name|invoice|420
160|template_name|ar_transaction|421
161|template_name|ap_transaction|422
162|template_name|packing_list|423
163|template_name|pick_list|424
164|template_name|sales_order|425
165|template_name|work_order|426
166|template_name|purchase_order|427
106|action|start_report|264
106|module_name|timecards|265
106|report_name|timecards|266
167|template_name|bin_list|428
168|template_name|statement|429
169|template_name|sales_quotation|430
170|template_name|rfq|431
171|template_name|timecard|432
241|template_name|letterhead|644
159|format|html|435
160|format|html|436
161|format|html|437
162|format|html|438
163|format|html|439
164|format|html|440
165|format|html|441
166|format|html|442
167|format|html|443
168|format|html|444
169|format|html|445
170|format|html|446
171|format|html|447
241|format|html|645
172|menu|1|448
173|action|display|449
174|action|display|450
175|action|display|451
176|action|display|452
177|action|display|453
178|action|display|454
179|action|display|455
180|action|display|456
181|action|display|457
182|action|display|458
183|action|display|459
184|action|display|460
185|action|display|461
186|action|display|462
187|action|display|463
242|action|display|646
173|module|template.pl|464
174|module|template.pl|465
175|module|template.pl|466
176|module|template.pl|467
177|module|template.pl|468
178|module|template.pl|469
179|module|template.pl|470
180|module|template.pl|471
181|module|template.pl|472
182|module|template.pl|473
183|module|template.pl|474
184|module|template.pl|475
185|module|template.pl|476
186|module|template.pl|477
187|module|template.pl|478
242|module|template.pl|647
173|format|tex|479
174|format|tex|480
175|format|tex|481
176|format|tex|482
177|format|tex|483
178|format|tex|484
179|format|tex|485
180|format|tex|486
181|format|tex|487
182|format|tex|488
183|format|tex|489
184|format|tex|490
185|format|tex|491
186|format|tex|492
187|format|tex|493
242|format|tex|648
173|template_name|invoice|506
174|template_name|ar_transaction|507
175|template_name|ap_transaction|508
176|template_name|packing_list|509
177|template_name|pick_list|510
178|template_name|sales_order|511
179|template_name|work_order|512
180|template_name|purchase_order|513
181|template_name|bin_list|514
182|template_name|statement|515
185|template_name|quotation|518
186|template_name|rfq|519
187|template_name|timecard|520
183|template_name|check|516
184|template_name|receipt|517
242|template_name|letterhead|649
193|module|login.pl|532
193|action|logout|533
193|target|_top|534
192|new|1|531
0|menu|1|535
136|menu|1|536
195|action|add|540
195|module|is.pl|541
196|action|add|543
196|module|ap.pl|544
197|action|add|545
197|module|ir.pl|547
196|type|debit_note|549
194|type|credit_note|548
195|type|credit_invoice|542
197|type|debit_invoice|546
202|batch_type|payment_reversal|570
204|batch_type|receipt_reversal|573
200|menu|1|552
198|action|create_batch|554
198|module|vouchers.pl|553
199|module|vouchers.pl|559
199|action|create_batch|560
201|module|vouchers.pl|562
201|action|create_batch|563
203|module|vouchers.pl|565
203|action|create_batch|566
202|module|vouchers.pl|568
202|action|create_batch|569
204|module|vouchers.pl|571
204|action|create_batch|572
201|batch_type|payment|564
199|batch_type|ap|561
45|module|recon.pl|106
45|action|new_report|107
44|module|recon.pl|108
44|action|search|109
211|module|recon.pl|587
211|action|search|588
211|hide_status|1|589
211|approved|0|590
211|submitted|1|591
198|batch_type|ar|555
191|module|user.pl|528
191|action|preference_screen|529
217|menu|1|597
218|action|add_taxform|598
218|module|taxform.pl|599
137|module|account.pl|355
137|action|new|359
222|module|admin.pl|605
222|action|list_sessions|606
225|module|taxform.pl|613
225|action|list_all|614
226|module|taxform.pl|615
226|action|report|201
227|menu|1|616
228|menu|1|617
229|menu|1|618
230|action|asset_category_screen|620
231|action|asset_category_search|622
232|action|asset_screen|624
233|action|asset_search|626
234|module|asset.pl|627
234|action|new_report|628
235|module|asset.pl|630
236|menu|1|632
237|module|asset.pl|633
237|action|display_nbv|634
232|module|asset.pl|623
230|module|asset.pl|619
231|module|asset.pl|621
233|module|asset.pl|625
234|depreciation|1|629
238|action|new_report|636
238|module|asset.pl|635
239|module|asset.pl|637
239|action|search_reports|638
239|depreciation|1|639
240|module|asset.pl|640
240|action|search_reports|641
235|action|begin_import|631
249|menu|1|668
243|module|import_csv.pl|650
243|action|begin_import|651
243|type|ap_multi|652
244|module|import_csv.pl|653
244|action|begin_import|654
244|type|ar_multi|655
245|module|import_csv.pl|656
245|action|begin_import|657
245|type|gl|658
246|module|import_csv.pl|659
246|action|begin_import|660
246|type|chart|661
247|module|import_csv.pl|662
247|action|begin_import|663
247|type|gifi|664
248|module|import_csv.pl|665
248|action|begin_import|666
248|type|sic|667
83|type|pricegroup|200
82|type|partsgroup|197
203|batch_type|receipt|567
250|menu|1|669
7|module_name|gl|671
7|entity_class|2|672
27|entity_class|1|673
76|report_name|gl|530
27|action|start_report|64
27|module_name|gl|674
251|menu|1|675
252|module|budgets.pl|676
253|module|reports.pl|677
252|action|new_budget|678
253|report_name|budget_search|680
253|module_name|gl|681
253|action|start_report|679
76|module_name|gl|670
19|menu|1|11
14|report_name|contact_search|31
20|module|vouchers.pl|72
20|action|create_batch|73
20|batch_type|sales_invoice|74
39|module|vouchers.pl|75
39|action|create_batch|76
39|batch_type|vendor_invoice|77
15|module|reports.pl|35
34|entity_class|1|20
15|entity_class|2|19
5|entity_class|2|12
25|entity_class|1|13
210|module|reports.pl|586
49|module_name|gl|115
49|entity_class|3|43
206|module_name|gl|14
206|report_name|unapproved|18
206|search_type|batches|30
210|action|start_report|585
210|module_name|gl|44
210|report_name|unapproved|45
49|report_name|contact_search|116
111|module|reports.pl|276
111|module_name|gl|40
210|search_type|drafts|46
112|module_name|gl|79
65|search_type|ship|34
9|module|invoice.pl|21
9|action|start_report|22
9|entity_class|2|24
10|module|invoice.pl|25
10|action|start_report|26
10|entity_class|1|67
9|report_name|invoice_outstanding|23
10|report_name|invoice_outstanding|66
54|oe_class_id|1|62
55|oe_class_id|2|68
71|oe_class_id|3|69
72|oe_class_id|4|70
61|oe_class_id|1|38
62|oe_class_id|2|41
57|oe_class_id|2|42
58|oe_class_id|1|47
64|oe_class_id|1|48
65|oe_class_id|2|49
86|module|goods.pl|205
91|module|reports.pl|221
91|report_name|search_partsgroups|222
92|module|reports.pl|224
92|report_name|search_pricegroups|225
6|module|import_csv.pl|60
6|action|begin_import|61
6|type|inventory|71
8|module|import_csv.pl|78
8|action|begin_import|93
8|type|timecard|94
11|module|import_csv.pl|95
13|module|import_csv.pl|152
11|action|begin_import|172
13|action|begin_import|173
11|type|ar_multi|174
13|type|ap_multi|175
11|multi|1|176
13|multi|1|177
16|module|inventory.pl|178
16|action|begin_adjust|179
17|module|configuration.pl|206
17|action|sequence_screen|207
18|batch_type|payment_reversal|208
18|module|vouchers.pl|209
18|action|create_batch|210
18|overpayment|1|211
26|batch_type|receipt_reversal|212
26|module|vouchers.pl|213
26|action|create_batch|214
26|overpayment|1|215
59|module|reports.pl|216
59|action|start_report|217
59|report_name|inventory_adj|218
106|module|reports.pl|263
75|module|reports.pl|219
75|action|start_report|226
75|report_name|cogs_lines|227
90|module|template.pl|228
90|action|display|229
90|template_name|product_receipt|230
90|format|tex|231
99|module|template.pl|240
99|action|display|241
99|template_name|product_receipt|242
99|format|html|245
129|module|is.pl|251
129|action|add|252
129|type|customer_return|253
\.

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

CREATE INDEX menu_acl_node_id_idx ON menu_acl (node_id);

--
-- PostgreSQL database dump complete
--

CREATE TABLE new_shipto (
        id serial primary key,
        trans_id int references transactions(id),
        oe_id int references oe(id) on delete cascade,
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

INSERT INTO asset_dep_method
  (method, unit_class,
   sproc,
   unit_label, short_name)
values
  ('Annual Straight Line Daily', 1,
   'asset_dep_straight_line_yr_d',
   'in years', 'SLYD'),
  ('Whole Month Straight Line', 1,
   'asset_dep_straight_line_month',
   'in months', 'SLMM'),
  ('Annual Straight Line Monthly', 1,
   'asset_dep_straight_line_yr_m',
   'in years', 'SLYM');

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
        department_id int references business_unit(id),
        invoice_id int references eca_invoice(journal_id),
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
        department_id int references business_unit(id),
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

insert into file_class values (1, 'transaction'),
                              (2, 'order'),
                              (3, 'part'),
                              (4, 'entity'),
                              (5, 'eca'),
                              (6, 'internal'),
                              (7, 'incoming');


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
       foreign key (ref_key) references oe(id) on delete cascade
) inherits (file_base);

COMMENT ON TABLE file_order IS
$$ File attachments primarily attached to orders and quotations.$$;

CREATE TABLE file_part (
       check (file_class=3),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references parts(id) on delete cascade
) inherits (file_base);

COMMENT ON TABLE file_part IS
$$ File attachments primarily attached to goods and services.$$;

CREATE TABLE file_entity (
       check (file_class=4),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references entity(id)
) inherits (file_base);

COMMENT ON TABLE file_entity IS
$$ File attachments primarily attached to entities.$$;

CREATE TABLE file_eca (
       check (file_class=5),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references entity_credit_account(id)
) inherits (file_base);

COMMENT ON TABLE file_eca IS
$$ File attachments primarily attached to customer and vendor agreements.$$;

CREATE TABLE file_internal (
   check (file_class = 6),
   unique(id),
   primary key (ref_key, file_name, file_class),
   check (ref_key = 0)
) inherits (file_base);

COMMENT ON COLUMN file_internal.ref_key IS
$$ Always must be 0, and we have no primary key since these files all
are for internal use and against the company, not categorized.$$;

COMMENT ON TABLE file_internal IS
$$ This is for internal files used operationally by LedgerSMB.  For example,
company logos would be here.$$;

CREATE TABLE file_incoming (
   check (file_class = 7),
   unique(id),
   primary key (ref_key, file_name, file_class),
   check (ref_key = 0)
) inherits (file_base);


COMMENT ON COLUMN file_incoming.ref_key IS
$$ Always must be 0, and we have no primary key since these files all
are for interal incoming use, not categorized.$$;

COMMENT ON TABLE file_incoming IS
$$ This is essentially a spool for files to be reviewed and attached.  It is
important that the names are somehow guaranteed to be unique, so one may want to prepend them with an email equivalent or the like.$$;

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
$$ Secondary links from journal entries to orders.$$;

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
       foreign key (ref_key) references gl(id),
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

--function  person__get_my_entity_id() also defined in Person.sql, may disappear here?
CREATE OR REPLACE FUNCTION person__get_my_entity_id() RETURNS INT AS
$$
        SELECT entity_id from users where username = SESSION_USER;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION person__get_my_entity_id() IS
$$ Returns the entity_id of the current, logged in user.$$;
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
  notes text);

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

CREATE TABLE trial_balance__yearend_types (
    type text primary key
);
INSERT INTO trial_balance__yearend_types (type)
     VALUES ('none'), ('all'), ('last');


CREATE TYPE trial_balance__entry AS (
    id int,
    date_from date,
    date_to date,
    description text,
    yearend text,
    heading_id int,
    accounts int[]
);

ALTER TABLE cr_report_line ADD FOREIGN KEY(ledger_id) REFERENCES acc_trans(entry_id);


CREATE VIEW cash_impact AS
SELECT id, '1'::numeric AS portion, 'gl' as rel, gl.transdate FROM gl
UNION ALL
SELECT id, CASE WHEN gl.amount = 0 THEN 0 -- avoid div by 0
                WHEN gl.transdate = ac.transdate
                     THEN 1 + sum(ac.amount) / gl.amount
                ELSE
                     1 - (gl.amount - sum(ac.amount)) / gl.amount
                END , 'ar' as rel, ac.transdate
  FROM ar gl
  JOIN acc_trans ac ON ac.trans_id = gl.id
  JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AR'
 GROUP BY gl.id, gl.amount, ac.transdate, gl.transdate
UNION ALL
SELECT id, CASE WHEN gl.amount = 0 THEN 0
                WHEN gl.transdate = ac.transdate
                     THEN 1 - sum(ac.amount) / gl.amount
                ELSE
                     1 - (gl.amount + sum(ac.amount)) / gl.amount
            END, 'ap' as rel, ac.transdate
  FROM ap gl
  JOIN acc_trans ac ON ac.trans_id = gl.id
  JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AP'
 GROUP BY gl.id, gl.amount, ac.transdate, gl.transdate;

COMMENT ON VIEW cash_impact IS
$$ This view is used by cash basis reports to determine the fraction of a
transaction to be counted.$$;


CREATE TABLE template ( -- not for UI templates
    id serial not null unique,
    template_name text not null,
    language_code varchar(6) references language(code),
    template text not null,
    format text not null,
    unique(template_name, language_code, format)
);

CREATE UNIQUE INDEX template_name_idx_u ON template(template_name, format)
WHERE language_code is null; -- Pseudo-Pkey


commit;
