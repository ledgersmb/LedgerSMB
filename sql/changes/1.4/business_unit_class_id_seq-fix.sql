
SELECT pg_catalog.setval('', (SELECT MAX(id) FROM business_unit_class), true);
