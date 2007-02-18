#
#
#
# SQL-Ledger Dataset name and Dataset Owner
#
SLDB=sqlledger
SLOWN=SQL-Ledger_Owner

#
# Ledger-SMB Dataset name and Dataset Owner
#
LSDB=lsmbprod
LSOWN=ledgersmb

# Installation directory

IDIR=`pwd`

psql template1 -c "DROP DATABASE ${LSDB};"

pg_dump ${SLDB} > sl2ls.sql

sed -i -e "s/${SLOWN}/${LSOWN}/" sl2ls.sql
sed -i -e "s/SQL_ASCII/LATIN1/" sl2ls.sql

createdb -O ${LSOWN} ${LSDB}

psql ${LSDB} ${LSOWN} -c "\i ${IDIR}/sql/Pg-central.sql"

psql template1 -c "ALTER USER ${LSOWN} WITH superuser;"

psql ${LSDB} ${LSOWN} -c "\i sl2ls.sql"

psql template1 -c "ALTER USER ${LSOWN} WITH nosuperuser;"

cd ${IDIR}/sql/legacy/

psql ${LSDB} ${LSOWN} -c "SELECT version FROM defaults;"

psql ${LSDB} ${LSOWN} -c "\i Pg-upgrade-2.6.12-2.6.17.sql"

psql ${LSDB} ${LSOWN} -c "SELECT version FROM defaults;"

psql ${LSDB} ${LSOWN} -c "\i Pg-upgrade-2.6.17-2.6.18.sql"

psql ${LSDB} ${LSOWN} -c "SELECT version FROM defaults;"

psql ${LSDB} ${LSOWN} -c "\i Pg-upgrade-2.6.18-2.6.19.sql"

echo '###############################################################'
echo
echo 'Should error with--> ERROR:  column "version" does not exist'
echo
echo '###############################################################'

psql ${LSDB} ${LSOWN} -c "SELECT version FROM defaults;"

psql ${LSDB} ${LSOWN} -c "update users_conf set password = md5('apasswrd');"

cd ${IDIR}

./import_members.pl users/members

psql ${LSDB} ${LSOWN} -c "SELECT * FROM users;"

exit
