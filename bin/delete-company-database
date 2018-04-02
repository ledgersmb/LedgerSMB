#!/bin/sh

# Simple check to print usage, and prevent runaway deletion
if test -z "$1"
then
  echo "Usage: $0 COMPANY [ USER ]"
  echo "\"COMPANY\" is the name of the company database, such as the name given"
  echo "to --company when using the prepare-company-database.sh script."
  echo "\"USER\" is an optional PGSQL user (owner of the database) to remove."
  exit 1
fi

cmd="select rolname FROM pg_roles WHERE rolname LIKE 'lsmb_${1}__%';"
company_roles=`su -c "psql -U postgres -t -c \"$cmd\"" postgres`

su -c "dropdb -U postgres $1" postgres

for role in $company_roles
do
  su -c "dropuser -U postgres \"$role\"" postgres
done

if test -n "$2"
then
  su -c "dropuser -U postgres \"$2\"" postgres
fi
