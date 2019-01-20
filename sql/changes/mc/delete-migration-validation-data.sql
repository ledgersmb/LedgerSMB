

DROP SCHEMA mc_migration_validation_data CASCADE;

DELETE FROM defaults WHERE setting_key = 'accept_mc';
