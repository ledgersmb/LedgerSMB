
update menu_node
   set url = replace(
     replace(
       url,
       '?action=',
       '?__action='
     ),
     '&action=',
     '&__action='
   );
