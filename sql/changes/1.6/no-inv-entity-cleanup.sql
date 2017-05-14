
-- Views

-- Views integrated into inventory__search_part() in Goods.sql
DROP VIEW IF EXISTS order_sum CASCADE;
DROP VIEW IF EXISTS invoice_sum CASCADE;


-- Functions
DROP FUNCTION IF EXISTS inventory_adj__get(int) CASCADE;
DROP FUNCTION IF EXISTS inventory_adj__details(int) CASCADE;
DROP FUNCTION IF EXISTS inventory_adj__search(date, date, text, text) CASCADE;
DROP FUNCTION IF EXISTS inventory_report__add_line(int, int, int, int) CASCADE;
DROP FUNCTION IF EXISTS inventory_report__approve(int) CASCADE;
DROP FUNCTION IF EXISTS inventory_report__delete(int) CASCADE;
DROP FUNCTION IF EXISTS inventory_create_report(date) CASCADE;

DROP FUNCTION IF EXISTS partsgroups__list_all() CASCADE;

-- Types
DROP TYPE IF EXISTS inventory_adjustment_info CASCADE;
DROP TYPE IF EXISTS inventory_adjustment_line CASCADE;

-- Aggregates
DROP AGGREGATE IF EXISTS product(numeric);
DROP FUNCTION IF EXISTS product(numeric, numeric);

