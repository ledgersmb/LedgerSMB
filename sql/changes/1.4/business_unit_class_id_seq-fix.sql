
SELECT pg_catalog.setval('business_unit_class_id_seq',
                         (SELECT MAX(id) FROM business_unit_class), true);
