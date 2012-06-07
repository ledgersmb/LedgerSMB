-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- Chris Travers

-- during 1.4m2
BEGIN; 

ALTER TABLE makemodel ADD barcode TEXT;

COMMIT;
