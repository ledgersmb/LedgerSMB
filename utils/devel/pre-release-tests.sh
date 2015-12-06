#!/bin/sh

sh tools/delete-company-database.sh lsmb13installtest

rm -f /tmp/ledgersmb/dblog*

PGUSER=postgres PGPASSWORD=test dropdb lsmbinstall

PGUSER=postgres PGPASSWORD=test LSMB_TEST_DB=1 LSMB_NEW_DB=lsmbinstall make test
