#!/bin/sh

PGUSER=postgres PGPASSWORD=test dropdb lsmbinstalltest

PGUSER=postgres PGPASSWORD=test LSMB_TEST_DB=1 LSMB_NEW_DB=lsmbinstalltest make test
