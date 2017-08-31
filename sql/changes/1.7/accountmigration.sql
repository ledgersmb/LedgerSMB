BEGIN;

ALTER TABLE account RENAME TO old_account;
ALTER TABLE account_heading RENAME TO old_account_heading;

ALTER TABLE account_translation RENAME TO old_account_translation;
ALTER TABLE account_heading_translation RENAME TO old_account_heading_translation;

CREATE OR REPLACE FUNCTION account_is_unique(int) RETURNS BOOL
LANGUAGE SQL STABLE AS
$$ select true; $$; -- stub

CREATE OR REPLACE FUNCTION account_doesnt_cycle(in_id int) RETURNS BOOL
LANGUAGE SQL STABLE AS
$$ SELECT TRUE; $$; --stub

CREATE TABLE coa_node (
  id serial NOT NULL UNIQUE,
  parent int,
  number text PRIMARY KEY,
  description text NOT NULL,
  obsolete bool default false,
  CHECK (account_is_unique(id)),
  CHECK (account_doesnt_cycle(id)),
  CHECK (FALSE) NO INHERIT -- abstract table
);

CREATE TABLE account_heading(
  LIKE coa_node INCLUDING INDEXES,
  CHECK (NOT OBSOLETE) OR no_children(id),
  FOREIGN KEY (parent) REFERENCES account_heading(id)
    ON UPDATE CASCADE -- needed for avoiding id collisions later
    DEFERRABLE
) INHERITS (coa_node);

CREATE TABLE account (
  LIKE coa_node INCLUDING INDEXES,
  contra bool default false,
  gifi text,
  FOREIGN KEY (parent) references account_heading(id)
    ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION account_doesnt_cycle(in_id int) RETURNS BOOL
LANGUAGE SQL STABLE AS
$$
WITH RECURSIVE traversal AS (
   SELECT parent, id = parent as cycles, array[id] as seen
     FROM coa_node
    UNION ALL
   SELECT n.parent, n.parent = ANY(t.seen), t.seen || n.id
     FROM traversal t
     JOIN account_heading n ON t.parent = n.id
    WHERE NOT id = ANY(t.seen) -- cycle is looking one level ahead 
)
SELECT count(*) = 0 from traversal where cycles;
$$;

CREATE TABLE coa_translation (
  coa_id int,
  language_code text,
  description text,
  PRIMARY KEY (coa_id, language_code),
  CHECK (FALSE) NO INHERIT
);

CREATE TABLE account_translation (
  LIKE coa_translation INCLUDING INDEXES,
  FOREIGN KEY (coa_id) REFERENCES account(id)
) INHERITS (coa_translation);

CREATE TABLE account_heading_translation (
  LIKE coa_translation INCLUDING INDEXES,
  FOREIGN KEY (coa_id) REFERENCES account_heading(id) ON UPDATE CASCADE
) INHERITS (coa_translation);

CREATE TABLE account_context (
    id serial not null unique,
    module text,
    context text,
    primary key (module, context)
);

CREATE TABLE coa_to_context (
   coa_id int not null,
   context_id int not null,
   primary key (coa_id, context_id) ,
   CHECK (false) NO INHERIT
);

CREATE TABLE account_to_context (
    LIKE coa_to_context INCLUDING INDEXES,
    FOREIGN KEY (coa_id) references account(id),
    FOREIGN KEY (context_id) references account_context(id)
) INHERITS (coa_to_context);

CREATE TABLE account_heading_to_context (
    LIKE coa_to_context INCLUDING INDEXES,
    FOREIGN KEY (coa_id) references account(id) ON UPDATE CASCADE,
    FOREIGN KEY (context_id) references account_context(id)
) INHERITS (coa_to_context);


-- TODO:
-- ALTER TABLE account_heading SET ... DEFERRED

INSERT INTO account_heading (id, parent, number, description)
SELECT id, parent_id, accno, description from old_account_heading;

INSERT INTO account (id, parent, number, description, contra, gifi, obsolete)
SELECT id, heading, accno, description, contra, gifi_accno, obsolete FROM old_account;

CREATE TEMPORARY TABLE link_to_context (module text, context text, link text);
INSERT INTO link_to_context
VALUES ('COA', 'Recon', null),
       ('Tax', 'Collected', null),
       ('Tax', 'Paid AP', null),
       ('Tax', 'Paid', null),
       ('AR', 'Summary', 'AR'),
       ('AP', 'Summary', 'AP'),
       ('IC', 'Summary', 'IC'),
       ('AP', 'Amount', 'AP_amount'),
       ('AP', 'Tax', 'AP_tax'),
       ('AP', 'Payment', 'AP_paid'),
       ('AP', 'Overpayment', 'AP_Overpayment'),
       ('AP', 'Discount', 'AP_discount'),
       ('AR', 'Amount', 'AR_amount'),
       ('AR', 'Tax', 'AR_tax'),
       ('AR', 'Payment', 'AR_Paid'),
       ('AR', 'Overpayment', 'AR_Overpayment'),
       ('AR', 'Discount', 'AR_Discount'),
       ('Inventory', 'Sales', 'IC_sale'),
       ('Inventory', 'Cost', 'IC_cogs'),
       ('Inventory', 'Income', 'IC_income'),
       ('Inventory', 'Expense', 'IC_expense'),
       ('Inventory', 'Returns', 'IC_returns'),
       ('Assets', 'Depreciation', 'Asset_Dep'),
       ('Assets', 'Summary', 'Fixed_Asset'),
       ('Assets', 'Expense', 'asset_expense'),
       ('Assets', 'Gain',    'asset_gain'),
       ('Assets', 'Loss',    'asset_loss'),
       ('FX', 'Loss',    null),
       ('FX', 'Gain', null);

INSERT INTO account_context (module, context)
SELECT module, context FROM link_to_context;


INSERT INTO account_to_context (coa_id, context_id)
SELECT a.id, c.id
  FROM old_account a
  JOIN account_link al ON a.id = al.account_id
  JOIN link_to_context lc ON al.description = lc.link
  JOIN account_context c ON (lc.module, lc.context) = (c.module, c.context);

INSERT INTO account_to_context (coa_id, context_id)
SELECT a.chart_id, c.id
  FROM cr_coa_to_account a
  JOIN account_context c ON c.module = 'COA' and c.context = 'Recon';

INSERT INTO account_to_context (coa_id, context_id)
SELECT a.id, c.id
  FROM old_account a
  JOIN account_context c ON c.module = 'Tax';

INSERT INTO account_translation (coa_id, language_code, description)
SELECT trans_id, language_code, description FROM old_account_translation;

INSERT INTO account_heading_translation (coa_id, language_code, description)
SELECT trans_id, language_code, description 
  from old_account_heading_translation;

UPDATE account_heading SET id = nextval('coa_node_id_seq') where id in (select id from account);

-- enable constraint
CREATE OR REPLACE FUNCTION acount_is_unique(int) RETURNS BOOL
LANGUAGE SQL STABLE AS
$$ -- very simple two-step index lookup
SELECT count(*) = 1 FROM coa_node WHERE id = $1;
$$;

-- TODO: move constraints and other things

DROP TABLE old_account;
DROP TABLE old_account_heading;
DROP TABLE old_account_translation;
DROP TABLE old_account_heading_translation;

ROLLBACK;
