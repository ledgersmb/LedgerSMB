
UPDATE menu_attribute
   SET value = 'request_quotation'
 WHERE attribute = 'template_name'
   AND value = 'rfq';

UPDATE menu_attribute
   SET value = 'sales_quotation'
 WHERE attribute = 'template_name'
   AND value = 'quotation';
