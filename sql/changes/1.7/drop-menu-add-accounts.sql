-- Now that the Chart of Accounts screen has 'Add Account' and 'Add Heading'
-- buttons. The menu option 'Add Accounts' is no longer required.
DELETE FROM menu_acl WHERE node_id=137;
DELETE FROM menu_attribute WHERE node_id=137;
DELETE FROM menu_node WHERE id=137;
