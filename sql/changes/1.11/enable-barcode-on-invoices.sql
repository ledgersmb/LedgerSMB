
INSERT INTO defaults
SELECT 'have_barcodes', 'auto'
 WHERE EXISTS (select 1
                 from makemodel
                where barcode is not null);
