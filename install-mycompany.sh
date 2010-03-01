#!/bin/bash

CWD=`pwd`

MYCOMPANY='cmd'
MYUSER='lacey_cmd'
PGVERSION=8.4
MYUSER_FIRSTNAME='Sample'
MYUSER_LASTNAME='User'
MYUSER_COUNTRYCODE='US'
MYUSER_PASSWORD='gfewtrwiecngra'
# The following path can vary per distribution
# Debian/Ubuntu
CONTRIB=/usr/share/postgresql/$PGVERSION/contrib/
# Compiled from source.
#CONTRIB=/usr/local/pgsql/share/contrib


echo \
"This script will create a $MYCOMPANY dataset per INSTALL. Ctrl-C to cancel
within 5 sec."

sleep 5;

export LSMB_USERNAME=$MYUSER
export PG_CONTRIB_DIR=$CONTRIB
export LSMB_NEW_DB=$MYCOMPANY
export LSMB_INSTALL_DB=1
export LSMB_TEST_DB=1
export LSMB_PASSWORD=$MYUSER_PASSWORD
export LSMB_LOAD_COA=General

if test ! -f Makefile
then 
    perl Makefile.PL
fi

# Build and test the db.
make test



# ending here.  Preserving old code for now.

exit
dropdb -i -U postgres $MYCOMPANY 
for role in `psql -U postgres -t -c "SELECT rolname FROM pg_roles WHERE rolname LIKE 'lsmb_${MYCOMPANY}%';"`; do dropuser -U postgres $role; done
dropuser -U postgres $MYUSER 
dropuser -U postgres ledgersmb 
createuser --no-superuser --createdb --no-createrole -U postgres --pwprompt --encrypted ledgersmb 
createdb -U postgres -O ledgersmb $MYCOMPANY  
createlang -U postgres plpgsql -d $MYCOMPANY 
if [[ "$PGVERSION" == "8.0" || "$PGVERSION" == "8.1" || "$PGVERSION" == "8.2" ]]; then
   psql -U postgres -d $MYCOMPANY -f $CONTRIB/tsearch2.sql
fi
psql -U postgres -d $MYCOMPANY -f $CONTRIB/tablefunc.sql
psql -U postgres -d $MYCOMPANY -f $CONTRIB/pg_trgm.sql
psql -U postgres -d $MYCOMPANY -f $CWD/sql/Pg-database.sql
psql -U postgres -d $MYCOMPANY -f $CWD/sql/modules/install.sql 
psql -U postgres -d $MYCOMPANY -f $CWD/sql/coa/us/chart/General.sql
sed  -e "s/<?lsmb dbname ?>/$MYCOMPANY/g" $CWD/sql/modules/Roles.sql > $CWD/${MYCOMPANY}_roles.sql 
psql -U postgres -d $MYCOMPANY -f $CWD/${MYCOMPANY}_roles.sql  
createuser --no-superuser --createdb --no-createrole -U postgres --pwprompt --encrypted $MYUSER 
psql -U postgres -d $MYCOMPANY --tuples-only -t -c "INSERT INTO entity (name, entity_class, created, control_code, country_id) VALUES ('$MYUSER', 3, NOW(), '123', 238) RETURNING id;"
psql -U postgres -d $MYCOMPANY -t -c "INSERT INTO person (entity_id, first_name, last_name, created) VALUES (1, 'Firstname', 'Lastname', NOW()) RETURNING entity_id, first_name, last_name, created;" 
psql -U postgres -d $MYCOMPANY -t -c "INSERT INTO entity_employee (entity_id, startdate, role) VALUES (1, NOW(), '$MYUSER') RETURNING entity_id, startdate, role;" 
psql -U postgres -d $MYCOMPANY -t -c "INSERT INTO users (username, entity_id) VALUES ('$MYUSER', 1) RETURNING username, entity_id;" 
psql -U postgres -d $MYCOMPANY -t -c "INSERT INTO user_preference (id) VALUES (1) RETURNING id;" 
psql -U postgres -d $MYCOMPANY -t -c "CREATE OR REPLACE FUNCTION grant_all_roles(in_login varchar) RETURNS INT as \$\$ DECLARE role_info RECORD; BEGIN FOR role_info IN select * from pg_roles WHERE rolname LIKE 'lsmb%' LOOP EXECUTE 'GRANT ' || role_info.rolname || ' TO ' || in_login; END LOOP; RETURN 1; END; \$\$ language plpgsql;"
psql -U postgres -d $MYCOMPANY -t -c "SELECT grant_all_roles('$MYUSER');" 
