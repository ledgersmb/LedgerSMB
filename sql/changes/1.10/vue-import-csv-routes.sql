
update menu_node
   set url = regexp_replace(url, '.*&type=([a-z_]+).*', '/import-csv/\1')
 where url like '%import_csv%';
