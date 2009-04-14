#!/bin/bash

echo 'This script will create a mycompany dataset per INSTALL. Ctrl-C to cancel.'

dropdb -i -U postgres mycompany ; 
for role in `psql -U postgres -t -c "SELECT rolname FROM pg_roles WHERE rolname LIKE 'lsmb_mycompany%';"`; do dropuser -U postgres $role; done
dropuser -U postgres myuser ; 
createdb -U postgres -O ledgersmb mycompany ; 
createlang plpgsql mycompany ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/Pg-database.sql ;
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Drafts.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/chart.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Account.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Session.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Business_type.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Location.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Company.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Customer.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Date.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Defaults.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Settings.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Employee.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Entity.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Payment.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Person.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Report.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Voucher.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Reconciliation.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Inventory.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/modules/Vendor.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/sql/coa/us/chart/General.sql
sed -e "s/<?lsmb dbname ?>/mycompany/g" /path/to/ledgersmb13/sql/modules/Roles.sql > /path/to/ledgersmb13/mycompany_roles.sql ; 
psql -U postgres -d mycompany -f /path/to/ledgersmb13/mycompany_roles.sql ; 
createuser --no-superuser --createdb --no-createrole -U postgres --pwprompt --encrypted myuser ; 
psql -U postgres -d mycompany -t -c "INSERT INTO entity (name, entity_class, created) VALUES ('myuser', 3, NOW()) RETURNING name, entity_class, created;" ; 
psql -U postgres -d mycompany -t -c "INSERT INTO person (entity_id, first_name, last_name, created) VALUES (2, 'Firstname', 'Lastname', NOW()) RETURNING entity_id, first_name, last_name, created;" ; 
psql -U postgres -d mycompany -t -c "INSERT INTO entity_employee (person_id, entity_id, startdate, role) VALUES (1, 2, NOW(), 'myuser') RETURNING person_id, entity_id, startdate, role;" ; 
psql -U postgres -d mycompany -t -c "INSERT INTO users (username, entity_id) VALUES ('myuser', 2) RETURNING username, entity_id;" ; 
psql -U postgres -d mycompany -t -c "INSERT INTO user_preference (id) VALUES (1) RETURNING id;" ; 
psql -U postgres -d mycompany -t -c "CREATE OR REPLACE FUNCTION grant_all_roles(in_login varchar) RETURNS INT as \$\$ DECLARE role_info RECORD; BEGIN FOR role_info IN select * from pg_roles WHERE rolname LIKE 'lsmb%' LOOP EXECUTE 'GRANT ' || role_info.rolname || ' TO ' || in_login; END LOOP; RETURN 1; END; \$\$ language plpgsql;" ; 
psql -U postgres -d mycompany -t -c "SELECT grant_all_roles('myuser');" ; 
