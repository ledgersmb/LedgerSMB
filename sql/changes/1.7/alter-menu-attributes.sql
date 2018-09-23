-- Changes url parameters used for
-- Transaction Approval->Batches menu option to allow `Batches`
-- to use a separate report filter template to `Drafts`.
DELETE FROM menu_attribute
WHERE node_id = 206
AND   attribute = 'module_name'
AND   value = 'gl';

DELETE FROM menu_attribute
WHERE node_id = 206
AND   attribute = 'search_type'
AND   value = 'batches';

UPDATE menu_attribute
SET value = 'batches'
WHERE node_id = 206
AND   attribute = 'report_name';


-- Drop unneeded attributes from
-- Transaction Approval->Drafts
DELETE FROM menu_attribute
WHERE node_id = 210
AND   attribute = 'module_name'
AND   value = 'gl';

DELETE FROM menu_attribute
WHERE node_id = 210
AND   attribute = 'search_type'
AND   value = 'drafts';
