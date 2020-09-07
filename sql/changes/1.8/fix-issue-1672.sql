
update menu_node
   set url = 'contact.pl?action=add&target_div=person_div&entity_class=3'
 where url = 'contact.pl?action=add'
   and label = 'Add Employee';
