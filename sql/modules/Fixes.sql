BEGIN; -- 1.3.4, fix for menu-- David Bandel
update menu_attribute set value = 'receive_order' where value  =
'consolidate_sales_order' and node_id = '65';

update menu_attribute set id = '149' where value  = 'receive_order'
and node_id = '65';

update menu_attribute set value = 'consolidate_sales_order' where
value  = 'receive_order' and node_id = '64';

update menu_attribute set id = '152' where value  =
'consolidate_sales_order' and node_id = '64';

COMMIT;
