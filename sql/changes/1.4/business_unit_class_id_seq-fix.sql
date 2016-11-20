
SELECT pgcatalog.setval('', (SELECT MAX(id) FROM business_unit_class), true);
